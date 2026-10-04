import Foundation
import PDFKit
import UIKit
import libarchive

enum ComicArchiveError: LocalizedError {
    case unsupported(String)
    case noReadablePages
    case encryptedArchive
    case comicInfoUnreadable
    case archiveFailure(String)

    var errorDescription: String? {
        switch self {
        case .unsupported(let ext):
            return "Unsupported comic archive: \(ext.uppercased())."
        case .noReadablePages:
            return "The archive contains no readable comic pages."
        case .encryptedArchive:
            return "Password-protected archives are not supported yet."
        case .comicInfoUnreadable:
            return "ComicInfo.xml could not be read."
        case .archiveFailure(let message):
            return message
        }
    }
}

enum ComicArchiveService {
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "heic", "avif"]

    static func extractArchive(at source: URL, to destination: URL) throws {
        guard ComicArchiveFormat.supports(source) else {
            throw ComicArchiveError.unsupported(source.pathExtension)
        }

        // Preserve the mature low-overhead ZIP/CBZ path. Every other archive
        // format uses the same libarchive backend on iPad and Mac Catalyst.
        if ComicArchiveFormat.usesLegacyZipExtractor(source) {
            try ZipExtractor.extractArchive(
                atPath: source.path,
                toDirectory: destination.path
            )
            return
        }

        try withOpenArchive(source) { archive in
            let fm = FileManager.default
            try fm.createDirectory(at: destination, withIntermediateDirectories: true)

            var entry: OpaquePointer?
            while true {
                let status = archive_read_next_header(archive, &entry)
                if status == ARCHIVE_EOF { break }
                guard status >= ARCHIVE_WARN, let entry else {
                    throw mappedArchiveError(archive)
                }

                guard let cPath = archive_entry_pathname(entry) else {
                    archive_read_data_skip(archive)
                    continue
                }

                let rawPath = String(cString: cPath)
                guard let relativePath = safeRelativePath(rawPath) else {
                    archive_read_data_skip(archive)
                    continue
                }

                let name = URL(fileURLWithPath: relativePath).lastPathComponent
                let ext = URL(fileURLWithPath: relativePath).pathExtension.lowercased()
                let wanted = imageExtensions.contains(ext)
                    || name.caseInsensitiveCompare("ComicInfo.xml") == .orderedSame

                guard wanted,
                      let outputURL = safeOutputURL(relativePath: relativePath, destination: destination)
                else {
                    archive_read_data_skip(archive)
                    continue
                }

                try fm.createDirectory(
                    at: outputURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let data = try readCurrentEntry(archive)
                try data.write(to: outputURL, options: .atomic)
            }
        }
    }

    static func comicInfoData(from archiveURL: URL) throws -> Data? {
        guard ComicArchiveFormat.supports(archiveURL) else { return nil }

        return try withOpenArchive(archiveURL) { archive in
            var entry: OpaquePointer?
            while true {
                let status = archive_read_next_header(archive, &entry)
                if status == ARCHIVE_EOF { return nil }
                guard status >= ARCHIVE_WARN, let entry else {
                    throw mappedArchiveError(archive)
                }

                guard let cPath = archive_entry_pathname(entry) else {
                    archive_read_data_skip(archive)
                    continue
                }

                let path = String(cString: cPath)
                if URL(fileURLWithPath: path).lastPathComponent
                    .caseInsensitiveCompare("ComicInfo.xml") == .orderedSame {
                    return try readCurrentEntry(archive)
                }
                archive_read_data_skip(archive)
            }
        }
    }

    private static func withOpenArchive<T>(
        _ source: URL,
        operation: (OpaquePointer) throws -> T
    ) throws -> T {
        guard let archive = archive_read_new() else {
            throw ComicArchiveError.archiveFailure("Could not initialize the archive reader.")
        }
        defer { archive_read_free(archive) }

        archive_read_support_filter_all(archive)
        archive_read_support_format_all(archive)

        let openStatus = source.path.withCString {
            archive_read_open_filename(archive, $0, 64 * 1024)
        }
        guard openStatus == ARCHIVE_OK else {
            throw mappedArchiveError(archive)
        }
        return try operation(archive)
    }

    private static func readCurrentEntry(_ archive: OpaquePointer) throws -> Data {
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)

        while true {
            let readCount: Int = buffer.withUnsafeMutableBytes { rawBuffer in
                Int(archive_read_data(archive, rawBuffer.baseAddress, rawBuffer.count))
            }
            if readCount == 0 { break }
            guard readCount > 0 else { throw mappedArchiveError(archive) }
            result.append(contentsOf: buffer.prefix(readCount))
        }
        return result
    }

    private static func mappedArchiveError(_ archive: OpaquePointer) -> Error {
        let message: String
        if let cMessage = archive_error_string(archive) {
            message = String(cString: cMessage)
        } else {
            message = "The comic archive could not be read."
        }

        let lower = message.lowercased()
        if lower.contains("encrypt") || lower.contains("password") || lower.contains("passphrase") {
            return ComicArchiveError.encryptedArchive
        }
        return ComicArchiveError.archiveFailure(message)
    }

    private static func safeRelativePath(_ raw: String) -> String? {
        let normalized = raw.replacingOccurrences(of: "\\", with: "/")
        guard !normalized.hasPrefix("/"), !normalized.contains("\0") else { return nil }

        var parts: [String] = []
        for part in normalized.split(separator: "/", omittingEmptySubsequences: true) {
            let value = String(part)
            if value == "." { continue }
            guard value != "..", !value.hasPrefix("~") else { return nil }
            parts.append(value)
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: "/")
    }

    private static func safeOutputURL(relativePath: String, destination: URL) -> URL? {
        let base = destination.standardizedFileURL
        let target = base.appendingPathComponent(relativePath).standardizedFileURL
        let basePath = base.path.hasSuffix("/") ? base.path : base.path + "/"
        guard target.path.hasPrefix(basePath) else { return nil }
        return target
    }
}


// MARK: - Stage 20.4 Archive Writer / Repair Lab

struct ComicRepairPreview: Sendable {
    let pageCount: Int
    let likelyBlankPages: [Int]
    let suggestedTopCrop: Double
    let suggestedBottomCrop: Double
}

enum ComicRepairService {
    static func inspectPDF(_ url: URL) throws -> ComicRepairPreview {
        guard let document = PDFDocument(url: url) else {
            throw ComicArchiveError.archiveFailure("PDF could not be opened.")
        }

        var blanks: [Int] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let image = page.thumbnail(
                of: CGSize(width: 320, height: 480),
                for: .mediaBox
            )
            if imageContentRatio(image) < 0.006 {
                blanks.append(index)
            }
        }

        return ComicRepairPreview(
            pageCount: document.pageCount,
            likelyBlankPages: blanks,
            suggestedTopCrop: 0.045,
            suggestedBottomCrop: 0.065
        )
    }

    static func convertPDFToCBZ(
        source: URL,
        output: URL,
        title: String,
        removeBlankPages: Bool,
        topCrop: Double,
        bottomCrop: Double
    ) throws {
        guard let document = PDFDocument(url: source) else {
            throw ComicArchiveError.archiveFailure("PDF could not be opened.")
        }

        var entries: [(String, Data)] = []
        var kept = 0

        for index in 0..<document.pageCount {
            autoreleasepool {
                guard let page = document.page(at: index) else { return }
                let thumb = page.thumbnail(
                    of: CGSize(width: 2044, height: 3146),
                    for: .mediaBox
                )
                guard let cleaned = crop(
                    thumb,
                    top: topCrop,
                    bottom: bottomCrop
                ) else { return }

                if removeBlankPages,
                   imageContentRatio(cleaned) < 0.006 {
                    return
                }

                guard let data = cleaned.jpegData(
                    compressionQuality: 0.91
                ) else { return }

                kept += 1
                entries.append((
                    String(format: "%04d.jpg", kept),
                    data
                ))
            }
        }

        guard !entries.isEmpty else {
            throw ComicArchiveError.noReadablePages
        }

        entries.append((
            "ComicInfo.xml",
            basicComicInfoXML(
                title: title,
                pageCount: entries.count
            )
        ))
        try ComicArchiveService.writeZip(entries: entries, to: output)
    }

    static func repairArchiveToCBZ(
        source: URL,
        output: URL,
        title: String
    ) throws {
        let images = try CBZService.extractImages(from: source)
        guard !images.isEmpty else { throw ComicArchiveError.noReadablePages }

        var entries: [(String, Data)] = []
        for (offset, url) in images.enumerated() {
            guard let data = try? Data(contentsOf: url) else { continue }
            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension.lowercased()
            entries.append((String(format: "%04d.%@", offset + 1, ext), data))
        }
        guard !entries.isEmpty else { throw ComicArchiveError.noReadablePages }

        let existingInfo = try? ComicArchiveService.comicInfoData(from: source)
        entries.append((
            "ComicInfo.xml",
            existingInfo ?? basicComicInfoXML(
                title: title,
                pageCount: entries.count
            )
        ))
        try ComicArchiveService.writeZip(entries: entries, to: output)
    }

    static func rewriteArchiveWithComicInfo(
        source: URL,
        output: URL,
        xml: Data
    ) throws {
        let images = try CBZService.extractImages(from: source)
        guard !images.isEmpty else { throw ComicArchiveError.noReadablePages }
        var entries: [(String, Data)] = []
        for (offset, url) in images.enumerated() {
            guard let data = try? Data(contentsOf: url) else { continue }
            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension.lowercased()
            entries.append((String(format: "%04d.%@", offset + 1, ext), data))
        }
        entries.append(("ComicInfo.xml", xml))
        try ComicArchiveService.writeZip(entries: entries, to: output)
    }

    static func metadataXML(
        title: String,
        series: String,
        issue: String,
        year: String,
        publisher: String,
        creators: String,
        summary: String,
        pageCount: Int
    ) -> Data {
        func escape(_ value: String) -> String {
            value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&apos;")
        }
        var rows: [String] = ["<?xml version=\"1.0\" encoding=\"utf-8\"?>", "<ComicInfo>"]
        if !title.isEmpty { rows.append("  <Title>\(escape(title))</Title>") }
        if !series.isEmpty { rows.append("  <Series>\(escape(series))</Series>") }
        if !issue.isEmpty { rows.append("  <Number>\(escape(issue))</Number>") }
        if let y = Int(year) { rows.append("  <Year>\(y)</Year>") }
        if !publisher.isEmpty { rows.append("  <Publisher>\(escape(publisher))</Publisher>") }
        if !creators.isEmpty { rows.append("  <Writer>\(escape(creators))</Writer>") }
        if !summary.isEmpty { rows.append("  <Summary>\(escape(summary))</Summary>") }
        rows.append("  <PageCount>\(pageCount)</PageCount>")
        rows.append("</ComicInfo>")
        return Data(rows.joined(separator: "\n").utf8)
    }

    private static func basicComicInfoXML(
        title: String,
        pageCount: Int
    ) -> Data {
        metadataXML(
            title: title,
            series: "",
            issue: "",
            year: "",
            publisher: "",
            creators: "",
            summary: "",
            pageCount: pageCount
        )
    }

    private static func crop(
        _ image: UIImage,
        top: Double,
        bottom: Double
    ) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        let height = CGFloat(cg.height)
        let topPixels = CGFloat(max(0, min(0.20, top))) * height
        let bottomPixels = CGFloat(max(0, min(0.20, bottom))) * height
        let cropHeight = max(1, height - topPixels - bottomPixels)
        let rect = CGRect(
            x: 0,
            y: topPixels,
            width: CGFloat(cg.width),
            height: cropHeight
        ).integral
        guard let cropped = cg.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    private static func imageContentRatio(_ image: UIImage) -> Double {
        guard let cg = image.cgImage else { return 1 }
        let width = 64
        let height = 96
        var pixels = [UInt8](repeating: 255, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 1 }
        context.interpolationQuality = .low
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        var content = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let r = Int(pixels[index])
            let g = Int(pixels[index + 1])
            let b = Int(pixels[index + 2])
            if (r + g + b) / 3 < 242 { content += 1 }
        }
        return Double(content) / Double(width * height)
    }
}

extension ComicArchiveService {
    static func writeZip(
        entries: [(String, Data)],
        to outputURL: URL
    ) throws {
        let fm = FileManager.default
        try? fm.removeItem(at: outputURL)
        try fm.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard let archive = archive_write_new() else {
            throw ComicArchiveError.archiveFailure("Could not initialize archive writer.")
        }
        defer { archive_write_free(archive) }

        guard archive_write_set_format_zip(archive) == ARCHIVE_OK else {
            throw ComicArchiveError.archiveFailure("Could not configure ZIP writer.")
        }

        let openStatus = outputURL.path.withCString {
            archive_write_open_filename(archive, $0)
        }
        guard openStatus == ARCHIVE_OK else {
            throw ComicArchiveError.archiveFailure("Could not create CBZ file.")
        }
        defer { archive_write_close(archive) }

        for (name, data) in entries {
            guard let entry = archive_entry_new() else { continue }
            defer { archive_entry_free(entry) }

            name.withCString { archive_entry_set_pathname(entry, $0) }
            archive_entry_set_size(entry, Int64(data.count))
            // libarchive's AE_IFREG macro is not always exposed to Swift.
            // 0100000 (octal) is the POSIX regular-file type mask expected here.
            archive_entry_set_filetype(entry, UInt32(0o100000))
            archive_entry_set_perm(entry, 0o644)

            guard archive_write_header(archive, entry) == ARCHIVE_OK else {
                throw ComicArchiveError.archiveFailure("Could not write CBZ entry \(name).")
            }

            let written = data.withUnsafeBytes { raw -> Int in
                Int(archive_write_data(archive, raw.baseAddress, raw.count))
            }
            guard written >= 0 else {
                throw ComicArchiveError.archiveFailure("Could not write CBZ page \(name).")
            }
        }
    }
}
