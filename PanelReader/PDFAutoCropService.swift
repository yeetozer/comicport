import Foundation
import PDFKit
import UIKit
import CoreGraphics

struct NormalizedCropRect: Codable, Hashable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let full = NormalizedCropRect(x: 0, y: 0, width: 1, height: 1)

    func applyingManual(_ insets: ManualCropInsets) -> NormalizedCropRect {
        let l = max(0, min(0.25, insets.leading))
        let r = max(0, min(0.25, insets.trailing))
        let t = max(0, min(0.25, insets.top))
        let b = max(0, min(0.25, insets.bottom))
        let nx = x + width * l
        let ny = y + height * t
        let nw = width * max(0.2, 1 - l - r)
        let nh = height * max(0.2, 1 - t - b)
        return NormalizedCropRect(x: nx, y: ny, width: nw, height: nh).clamped()
    }

    func clamped() -> NormalizedCropRect {
        let nx = max(0, min(1, x))
        let ny = max(0, min(1, y))
        let nw = max(0.05, min(1 - nx, width))
        let nh = max(0.05, min(1 - ny, height))
        return NormalizedCropRect(x: nx, y: ny, width: nw, height: nh)
    }
}

private final class PDFAutoCropBox: NSObject {
    let value: NormalizedCropRect
    init(_ value: NormalizedCropRect) { self.value = value }
}

enum PDFAutoCropService {
    private static let detectionCache: NSCache<NSString, PDFAutoCropBox> = {
        let cache = NSCache<NSString, PDFAutoCropBox>()
        cache.countLimit = 1800
        return cache
    }()

    static func detectNormalizedCrop(fileURL: URL, pageIndex: Int, strength: CropStrength, trimFooter: Bool = true, fullBleed: Bool = true) -> NormalizedCropRect {
        let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let key = [
            fileURL.path,
            String(values?.fileSize ?? 0),
            String(format: "%.3f", values?.contentModificationDate?.timeIntervalSince1970 ?? 0),
            String(pageIndex),
            strength.rawValue,
            trimFooter ? "1" : "0",
            fullBleed ? "1" : "0"
        ].joined(separator: "|")

        if let cached = detectionCache.object(forKey: key as NSString) {
            return cached.value
        }

        guard let doc = PDFDocument(url: fileURL),
              let page = doc.page(at: pageIndex) else { return .full }

        let media = page.bounds(for: .mediaBox)
        guard media.width > 0, media.height > 0 else { return .full }

        let sampleWidth: CGFloat = 420
        let sampleHeight = max(180, sampleWidth * media.height / media.width)
        let image = page.thumbnail(of: CGSize(width: sampleWidth, height: sampleHeight), for: .mediaBox)
        guard let cg = image.cgImage else { return .full }
        let result = analyze(cgImage: cg, strength: strength, trimFooter: trimFooter, fullBleed: fullBleed)
        detectionCache.setObject(PDFAutoCropBox(result), forKey: key as NSString)
        return result
    }

    static func pdfRect(from normalized: NormalizedCropRect, mediaBox: CGRect) -> CGRect {
        let n = normalized.clamped()
        let x = mediaBox.minX + mediaBox.width * n.x
        // normalized y is measured from the top, PDF y from bottom.
        let y = mediaBox.minY + mediaBox.height * (1 - n.y - n.height)
        return CGRect(
            x: x,
            y: y,
            width: mediaBox.width * n.width,
            height: mediaBox.height * n.height
        ).intersection(mediaBox)
    }

    private static func analyze(
        cgImage: CGImage,
        strength: CropStrength,
        trimFooter: Bool,
        fullBleed: Bool
    ) -> NormalizedCropRect {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 20, height > 20 else { return .full }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 255, count: height * bytesPerRow)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .full }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let config: (white: Int, rowDensity: Double, colDensity: Double, padding: Double, bleed: Double)
        switch strength {
        case .light:
            config = (250, 0.018, 0.018, 0.022, 0.001)
        case .normal:
            config = (247, 0.035, 0.035, 0.010, 0.0025)
        case .maximum:
            config = (243, 0.070, 0.060, 0.002, 0.0045)
        }

        @inline(__always)
        func isContent(_ x: Int, _ y: Int) -> Bool {
            let i = y * bytesPerRow + x * bytesPerPixel
            let r = Int(pixels[i])
            let g = Int(pixels[i + 1])
            let b = Int(pixels[i + 2])
            return !(r >= config.white && g >= config.white && b >= config.white)
        }

        let step = max(1, min(width, height) / 520)
        let xs = Array(stride(from: 0, to: width, by: step))
        let ys = Array(stride(from: 0, to: height, by: step))
        guard !xs.isEmpty, !ys.isEmpty else { return .full }

        var rowActivity = [Double](repeating: 0, count: height)
        var colActivity = [Double](repeating: 0, count: width)

        for y in ys {
            var rowCount = 0
            for x in xs {
                if isContent(x, y) {
                    rowCount += 1
                    colActivity[x] += 1
                }
            }
            rowActivity[y] = Double(rowCount) / Double(xs.count)
        }

        for x in xs {
            colActivity[x] /= Double(ys.count)
        }

        let rawRows = ys.filter { rowActivity[$0] >= config.rowDensity }
        let rawCols = xs.filter { colActivity[$0] >= config.colDensity }
        guard !rawRows.isEmpty, !rawCols.isEmpty else { return .full }

        // Web-to-PDF exports often contain a large comic block plus a tiny URL/date/footer
        // block separated by a wide white band. Pick the dominant contiguous band instead
        // of blindly using the last non-white pixel.
        let rowBounds: (Int, Int)
        if trimFooter, let dominant = dominantBand(
            indices: rawRows,
            activity: rowActivity,
            dimension: height,
            step: step
        ) {
            rowBounds = dominant
        } else {
            rowBounds = (rawRows.first!, rawRows.last!)
        }

        let colBounds: (Int, Int)
        if let dominant = dominantBand(
            indices: rawCols,
            activity: colActivity,
            dimension: width,
            step: step
        ) {
            colBounds = dominant
        } else {
            colBounds = (rawCols.first!, rawCols.last!)
        }

        var minX = Double(colBounds.0) / Double(width)
        var maxX = Double(min(width, colBounds.1 + step)) / Double(width)
        var minY = Double(rowBounds.0) / Double(height)
        var maxY = Double(min(height, rowBounds.1 + step)) / Double(height)

        minX = max(0, minX - config.padding)
        maxX = min(1, maxX + config.padding)
        minY = max(0, minY - config.padding)
        maxY = min(1, maxY + config.padding)

        // Full Bleed deliberately moves a few pixels inside the detected page edge.
        // This removes the final hairline of white paper without modifying the PDF file.
        if fullBleed {
            let bx = min(config.bleed, max(0, (maxX - minX - 0.45) / 2))
            let by = min(config.bleed, max(0, (maxY - minY - 0.45) / 2))
            minX += bx
            maxX -= bx
            minY += by
            maxY -= by
        }

        let result = NormalizedCropRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        ).clamped()

        // Safety: don't accept a crop that looks like a single panel or thumbnail.
        if result.width < 0.45 || result.height < 0.45 { return .full }
        if result.width > 0.995 && result.height > 0.995 { return .full }
        return result
    }

    private static func dominantBand(
        indices: [Int],
        activity: [Double],
        dimension: Int,
        step: Int
    ) -> (Int, Int)? {
        guard let first = indices.first else { return nil }

        // Merge small gutters inside a comic page, but keep a real footer separated by
        // a large blank strip as its own group.
        let gapTolerance = max(step * 4, dimension / 70)

        var groups: [(start: Int, end: Int, score: Double)] = []
        var start = first
        var previous = first
        var densitySum = activity[first]
        var sampleCount = 1

        func finishGroup() {
            let span = max(step, previous - start + step)
            let meanDensity = densitySum / Double(max(1, sampleCount))
            // Span dominates the score; density breaks ties in favor of the comic block.
            let score = Double(span) * (0.72 + meanDensity)
            groups.append((start, previous, score))
        }

        for index in indices.dropFirst() {
            if index - previous > gapTolerance {
                finishGroup()
                start = index
                densitySum = activity[index]
                sampleCount = 1
            } else {
                densitySum += activity[index]
                sampleCount += 1
            }
            previous = index
        }
        finishGroup()

        guard let best = groups.max(by: { $0.score < $1.score }) else { return nil }

        // Ignore microscopic text-only bands such as a page-number line.
        let minimumSpan = max(step * 6, dimension / 8)
        guard best.end - best.start + step >= minimumSpan else { return nil }
        return (best.start, best.end)
    }
}
