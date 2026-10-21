import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Storage optimization

enum StorageOptimizationPreset: String, CaseIterable, Identifiable, Sendable {
    case high = "High Quality"
    case balanced = "Balanced"
    case maximumSavings = "Maximum Savings"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .high: return "Sharper art · ideal for large displays"
        case .balanced: return "Recommended · strong savings with good detail"
        case .maximumSavings: return "Smallest files · more visible compression"
        }
    }

    var jpegQuality: Double {
        switch self {
        case .high: return 0.86
        case .balanced: return 0.72
        case .maximumSavings: return 0.56
        }
    }

    var maxLongEdge: Int {
        switch self {
        case .high: return 2400
        case .balanced: return 1800
        case .maximumSavings: return 1350
        }
    }

    var estimatedFactor: Double {
        switch self {
        case .high: return 0.68
        case .balanced: return 0.43
        case .maximumSavings: return 0.27
        }
    }

    var systemImage: String {
        switch self {
        case .high: return "sparkles.rectangle.stack"
        case .balanced: return "scale.3d"
        case .maximumSavings: return "arrow.down.right.and.arrow.up.left"
        }
    }
}

struct StorageOptimizationResult: Sendable {
    let temporaryURL: URL
    let outputType: ComicType
    let originalBytes: Int64
    let optimizedBytes: Int64
    let pageCount: Int
    let preset: StorageOptimizationPreset

    var savedBytes: Int64 { max(0, originalBytes - optimizedBytes) }
    var savingsPercent: Int {
        guard originalBytes > 0 else { return 0 }
        return max(0, min(99, Int((Double(savedBytes) / Double(originalBytes) * 100).rounded())))
    }
}

enum StorageOptimizerError: LocalizedError {
    case fileMissing
    case invalidPDF
    case noPages
    case imageDecodeFailed
    case couldNotCreateArchive
    case outputInvalid

    var errorDescription: String? {
        switch self {
        case .fileMissing: return "The comic file is not available on this device."
        case .invalidPDF: return "The PDF could not be opened."
        case .noPages: return "No readable comic pages were found."
        case .imageDecodeFailed: return "A comic page could not be converted."
        case .couldNotCreateArchive: return "The optimized comic archive could not be created."
        case .outputInvalid: return "The optimized copy failed validation, so the original was left untouched."
        }
    }
}

enum StorageOptimizer {
    static func estimatedBytes(original: Int64, preset: StorageOptimizationPreset) -> Int64 {
        max(1, Int64(Double(original) * preset.estimatedFactor))
    }

    /// Creates a validated temporary CBZ. The original file is never touched here.
    static func optimize(
        type: ComicType,
        source: URL,
        preset: StorageOptimizationPreset,
        readerSettings: ReaderSettings
    ) async throws -> StorageOptimizationResult {
        let originalBytes = Int64((try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        guard FileManager.default.fileExists(atPath: source.path) else { throw StorageOptimizerError.fileMissing }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("PanelOptimized-\(UUID().uuidString).cbz")

        let pageCount = try await Task.detached(priority: .userInitiated) {
            switch type {
            case .epub:
                throw EPUBError.invalidPackage
            case .pdf:
                return try optimizePDFToCBZ(source: source, destination: output, preset: preset, readerSettings: readerSettings)
            case .cbz:
                return try optimizeCBZ(source: source, destination: output, preset: preset)
            }
        }.value

        guard pageCount > 0,
              FileManager.default.fileExists(atPath: output.path) else {
            try? FileManager.default.removeItem(at: output)
            throw StorageOptimizerError.outputInvalid
        }

        let optimizedBytes = Int64((try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        guard optimizedBytes > 0 else {
            try? FileManager.default.removeItem(at: output)
            throw StorageOptimizerError.outputInvalid
        }

        return StorageOptimizationResult(
            temporaryURL: output,
            outputType: .cbz,
            originalBytes: originalBytes,
            optimizedBytes: optimizedBytes,
            pageCount: pageCount,
            preset: preset
        )
    }

    static func discard(_ result: StorageOptimizationResult?) {
        guard let result else { return }
        try? FileManager.default.removeItem(at: result.temporaryURL)
    }

    // MARK: PDF -> optimized CBZ

    private static func optimizePDFToCBZ(
        source: URL,
        destination: URL,
        preset: StorageOptimizationPreset,
        readerSettings: ReaderSettings
    ) throws -> Int {
        guard let document = CGPDFDocument(source as CFURL) else { throw StorageOptimizerError.invalidPDF }
        let count = document.numberOfPages
        guard count > 0 else { throw StorageOptimizerError.noPages }

        let writer = try SimpleCBZWriter(url: destination)
        do {
            for index in 1...count {
                guard let page = document.page(at: index) else { continue }

                var crop = NormalizedCropRect.full
                if readerSettings.autoCropEnabled {
                    crop = PDFAutoCropService.detectNormalizedCrop(
                        fileURL: source,
                        pageIndex: index - 1,
                        strength: readerSettings.cropStrength,
                        trimFooter: readerSettings.trimWebFooter,
                        fullBleed: readerSettings.fullBleed
                    )
                }
                crop = crop.applyingManual(readerSettings.manualCrop)

                let jpeg = try rasterizedJPEG(page: page, crop: crop, preset: preset)
                try writer.addFile(name: String(format: "%05d.jpg", index), data: jpeg)
            }
            try writer.finish()
        } catch {
            writer.cancel()
            throw error
        }
        return count
    }

    // MARK: CBZ -> optimized CBZ

    private static func optimizeCBZ(
        source: URL,
        destination: URL,
        preset: StorageOptimizationPreset
    ) throws -> Int {
        let images = try CBZService.extractImages(from: source)
        guard !images.isEmpty else { throw StorageOptimizerError.noPages }

        let writer = try SimpleCBZWriter(url: destination)
        do {
            for (index, url) in images.enumerated() {
                let jpeg = try reencodedJPEG(url: url, preset: preset)
                try writer.addFile(name: String(format: "%05d.jpg", index + 1), data: jpeg)
            }
            try writer.finish()
        } catch {
            writer.cancel()
            throw error
        }
        return images.count
    }

    private static func rasterizedJPEG(
        page: CGPDFPage,
        crop: NormalizedCropRect,
        preset: StorageOptimizationPreset
    ) throws -> Data {
        let media = page.getBoxRect(.mediaBox)
        let normalized = crop.clamped()
        let cropRect = CGRect(
            x: media.minX + media.width * normalized.x,
            y: media.minY + media.height * (1 - normalized.y - normalized.height),
            width: media.width * normalized.width,
            height: media.height * normalized.height
        ).intersection(media)

        guard cropRect.width > 1, cropRect.height > 1 else { throw StorageOptimizerError.imageDecodeFailed }

        let longEdge = CGFloat(preset.maxLongEdge)
        let scale = min(longEdge / max(cropRect.width, cropRect.height), 4.0)
        let width = max(1, Int((cropRect.width * scale).rounded()))
        let height = max(1, Int((cropRect.height * scale).rounded()))

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw StorageOptimizerError.imageDecodeFailed }

        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.saveGState()
        context.scaleBy(x: CGFloat(width) / cropRect.width, y: CGFloat(height) / cropRect.height)
        context.translateBy(x: -cropRect.minX, y: -cropRect.minY)
        context.drawPDFPage(page)
        context.restoreGState()

        guard let image = context.makeImage() else { throw StorageOptimizerError.imageDecodeFailed }
        return try encodeJPEG(image: image, quality: preset.jpegQuality)
    }

    private static func reencodedJPEG(url: URL, preset: StorageOptimizationPreset) throws -> Data {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw StorageOptimizerError.imageDecodeFailed }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: preset.maxLongEdge,
            kCGImageSourceShouldCacheImmediately: false
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { throw StorageOptimizerError.imageDecodeFailed }
        return try encodeJPEG(image: image, quality: preset.jpegQuality)
    }

    private static func encodeJPEG(image: CGImage, quality: Double) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { throw StorageOptimizerError.imageDecodeFailed }

        let properties = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw StorageOptimizerError.imageDecodeFailed }
        return data as Data
    }
}

// MARK: - Minimal CBZ writer
// Comic page JPEGs are already compressed, so ZIP "store" mode avoids wasting CPU
// while still producing a standards-compliant .cbz archive.

private final class SimpleCBZWriter {
    private struct Entry {
        let name: Data
        let crc: UInt32
        let size: UInt32
        let offset: UInt32
    }

    private let url: URL
    private let handle: FileHandle
    private var entries: [Entry] = []
    private var offset: UInt32 = 0
    private var finished = false

    init(url: URL) throws {
        self.url = url
        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: url) else { throw StorageOptimizerError.couldNotCreateArchive }
        self.handle = handle
    }

    func addFile(name: String, data: Data) throws {
        guard !finished else { throw StorageOptimizerError.couldNotCreateArchive }
        let nameData = Data(name.utf8)
        guard nameData.count <= Int(UInt16.max), data.count <= Int(UInt32.max) else { throw StorageOptimizerError.couldNotCreateArchive }

        let crc = Self.crc32(data)
        let size = UInt32(data.count)
        let localOffset = offset

        var header = Data()
        header.appendLE(UInt32(0x04034b50))
        header.appendLE(UInt16(20))
        header.appendLE(UInt16(0))
        header.appendLE(UInt16(0)) // stored, JPEG is already compressed
        header.appendLE(UInt16(0))
        header.appendLE(UInt16(0))
        header.appendLE(crc)
        header.appendLE(size)
        header.appendLE(size)
        header.appendLE(UInt16(nameData.count))
        header.appendLE(UInt16(0))

        try handle.write(contentsOf: header)
        try handle.write(contentsOf: nameData)
        try handle.write(contentsOf: data)
        offset += UInt32(header.count + nameData.count + data.count)
        entries.append(Entry(name: nameData, crc: crc, size: size, offset: localOffset))
    }

    func finish() throws {
        guard !finished else { return }
        let centralStart = offset

        for entry in entries {
            var record = Data()
            record.appendLE(UInt32(0x02014b50))
            record.appendLE(UInt16(20))
            record.appendLE(UInt16(20))
            record.appendLE(UInt16(0))
            record.appendLE(UInt16(0))
            record.appendLE(UInt16(0))
            record.appendLE(UInt16(0))
            record.appendLE(entry.crc)
            record.appendLE(entry.size)
            record.appendLE(entry.size)
            record.appendLE(UInt16(entry.name.count))
            record.appendLE(UInt16(0))
            record.appendLE(UInt16(0))
            record.appendLE(UInt16(0))
            record.appendLE(UInt16(0))
            record.appendLE(UInt32(0))
            record.appendLE(entry.offset)
            try handle.write(contentsOf: record)
            try handle.write(contentsOf: entry.name)
            offset += UInt32(record.count + entry.name.count)
        }

        let centralSize = offset - centralStart
        guard entries.count <= Int(UInt16.max) else { throw StorageOptimizerError.couldNotCreateArchive }

        var end = Data()
        end.appendLE(UInt32(0x06054b50))
        end.appendLE(UInt16(0))
        end.appendLE(UInt16(0))
        end.appendLE(UInt16(entries.count))
        end.appendLE(UInt16(entries.count))
        end.appendLE(centralSize)
        end.appendLE(centralStart)
        end.appendLE(UInt16(0))
        try handle.write(contentsOf: end)
        try handle.close()
        finished = true
    }

    func cancel() {
        if !finished { try? handle.close() }
        try? FileManager.default.removeItem(at: url)
        finished = true
    }

    private static let crcTable: [UInt32] = (0..<256).map { value in
        var c = UInt32(value)
        for _ in 0..<8 {
            c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1
        }
        return c
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = crcTable[index] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
