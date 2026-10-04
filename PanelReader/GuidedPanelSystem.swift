import Foundation
import UIKit
import Vision
import ImageIO

struct GuidedPanelRect: Codable, Hashable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let fullPage = GuidedPanelRect(x: 0, y: 0, width: 1, height: 1)

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    var area: Double { width * height }

    func padded(_ amount: Double) -> GuidedPanelRect {
        let nx = max(0, x - amount)
        let ny = max(0, y - amount)
        let maxX = min(1, x + width + amount)
        let maxY = min(1, y + height + amount)
        return GuidedPanelRect(x: nx, y: ny, width: max(0.05, maxX - nx), height: max(0.05, maxY - ny))
    }
}

struct GuidedPanelPageLayout: Codable, Hashable, Sendable {
    static let schemaVersion = 1

    let schema: Int
    let bookID: UUID
    let page: Int
    let sourceIdentity: String
    let settingsSignature: String
    let detectedAt: Date
    let usedFallback: Bool
    let panels: [GuidedPanelRect]
}

struct GuidedPanelPreparedPage: Sendable {
    let jpegData: Data
    let layout: GuidedPanelPageLayout
}

private final class GuidedDataBox: NSObject {
    let data: Data
    init(_ data: Data) { self.data = data }
}

private final class GuidedLayoutBox: NSObject {
    let layout: GuidedPanelPageLayout
    init(_ layout: GuidedPanelPageLayout) { self.layout = layout }
}

private final class GuidedPanelMemoryCache: @unchecked Sendable {
    static let shared = GuidedPanelMemoryCache()

    private let imageData = NSCache<NSString, GuidedDataBox>()
    private let layouts = NSCache<NSString, GuidedLayoutBox>()

    private init() {
        imageData.countLimit = 7
        imageData.totalCostLimit = 105 * 1024 * 1024
        layouts.countLimit = 500
    }

    func data(for key: String) -> Data? {
        imageData.object(forKey: key as NSString)?.data
    }

    func setData(_ data: Data, for key: String) {
        imageData.setObject(GuidedDataBox(data), forKey: key as NSString, cost: data.count)
    }

    func layout(for key: String) -> GuidedPanelPageLayout? {
        layouts.object(forKey: key as NSString)?.layout
    }

    func setLayout(_ layout: GuidedPanelPageLayout, for key: String) {
        layouts.setObject(GuidedLayoutBox(layout), forKey: key as NSString)
    }

    func removeLayout(for key: String) {
        layouts.removeObject(forKey: key as NSString)
    }
}

enum GuidedPanelEngine {
    static func settingsSignature(_ settings: ReaderSettings, rtl: Bool) -> String {
        [
            "g11-v1",
            settings.autoCropEnabled ? "a1" : "a0",
            settings.cropStrength.rawValue,
            settings.trimWebFooter ? "f1" : "f0",
            settings.fullBleed ? "b1" : "b0",
            String(format: "%.3f", settings.manualCrop.top),
            String(format: "%.3f", settings.manualCrop.leading),
            String(format: "%.3f", settings.manualCrop.bottom),
            String(format: "%.3f", settings.manualCrop.trailing),
            rtl ? "rtl" : "ltr"
        ].joined(separator: "|")
    }

    static func prepare(
        bookID: UUID,
        sourceIdentity: String,
        fileURL: URL,
        type: ComicType,
        page: Int,
        settings: ReaderSettings,
        rightToLeft: Bool,
        cacheDirectory: URL,
        forceLayout: Bool = false
    ) async throws -> GuidedPanelPreparedPage {
        let signature = settingsSignature(settings, rtl: rightToLeft)
        let key = "\(bookID.uuidString)|\(page)|\(signature)"

        async let snapshotTask: Data? = snapshotData(
            key: key,
            fileURL: fileURL,
            type: type,
            page: page,
            settings: settings
        )

        async let layoutTask: GuidedPanelPageLayout? = existingLayout(
            key: key,
            bookID: bookID,
            page: page,
            sourceIdentity: sourceIdentity,
            signature: signature,
            cacheDirectory: cacheDirectory,
            force: forceLayout
        )

        guard let jpeg = await snapshotTask else {
            throw NSError(
                domain: "PanelReader.GuidedPanel",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The page could not be rendered for Guided Panel View."]
            )
        }

        if let cachedLayout = await layoutTask {
            return GuidedPanelPreparedPage(jpegData: jpeg, layout: cachedLayout)
        }

        let detected = await Task.detached(priority: .utility) {
            detectPanels(jpegData: jpeg, rightToLeft: rightToLeft)
        }.value

        let layout = GuidedPanelPageLayout(
            schema: GuidedPanelPageLayout.schemaVersion,
            bookID: bookID,
            page: page,
            sourceIdentity: sourceIdentity,
            settingsSignature: signature,
            detectedAt: .now,
            usedFallback: detected.fallback,
            panels: detected.panels
        )

        GuidedPanelMemoryCache.shared.setLayout(layout, for: key)

        let target = layoutURL(cacheDirectory: cacheDirectory, bookID: bookID, page: page)
        await Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(layout)
                try data.write(to: target, options: .atomic)
            } catch {
                // The layout is only a rebuildable performance cache. A failed cache write
                // should never prevent reading the comic.
            }
        }.value

        return GuidedPanelPreparedPage(jpegData: jpeg, layout: layout)
    }

    static func removeCachedLayout(
        bookID: UUID,
        page: Int,
        settings: ReaderSettings,
        rightToLeft: Bool,
        cacheDirectory: URL
    ) {
        let signature = settingsSignature(settings, rtl: rightToLeft)
        let key = "\(bookID.uuidString)|\(page)|\(signature)"
        GuidedPanelMemoryCache.shared.removeLayout(for: key)
        try? FileManager.default.removeItem(at: layoutURL(cacheDirectory: cacheDirectory, bookID: bookID, page: page))
    }

    private static func snapshotData(
        key: String,
        fileURL: URL,
        type: ComicType,
        page: Int,
        settings: ReaderSettings
    ) async -> Data? {
        if let cached = GuidedPanelMemoryCache.shared.data(for: key) {
            return cached
        }

        let data = await ReaderPageSnapshotService.loadSnapshot(
            fileURL: fileURL,
            type: type,
            page: page,
            settings: settings,
            maxPixel: 2400
        )
        if let data {
            GuidedPanelMemoryCache.shared.setData(data, for: key)
        }
        return data
    }

    private static func existingLayout(
        key: String,
        bookID: UUID,
        page: Int,
        sourceIdentity: String,
        signature: String,
        cacheDirectory: URL,
        force: Bool
    ) async -> GuidedPanelPageLayout? {
        if force { return nil }
        if let cached = GuidedPanelMemoryCache.shared.layout(for: key) {
            return cached
        }

        let url = layoutURL(cacheDirectory: cacheDirectory, bookID: bookID, page: page)
        let layout = await Task.detached(priority: .utility) { () -> GuidedPanelPageLayout? in
            guard let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode(GuidedPanelPageLayout.self, from: data),
                  decoded.schema == GuidedPanelPageLayout.schemaVersion,
                  decoded.bookID == bookID,
                  decoded.page == page,
                  decoded.sourceIdentity == sourceIdentity,
                  decoded.settingsSignature == signature,
                  !decoded.panels.isEmpty else { return nil }
            return decoded
        }.value

        if let layout {
            GuidedPanelMemoryCache.shared.setLayout(layout, for: key)
        }
        return layout
    }

    private static func layoutURL(cacheDirectory: URL, bookID: UUID, page: Int) -> URL {
        cacheDirectory.appendingPathComponent("\(bookID.uuidString)-\(page).json")
    }

    private static func detectPanels(jpegData: Data, rightToLeft: Bool) -> (panels: [GuidedPanelRect], fallback: Bool) {
        guard let source = CGImageSourceCreateWithData(jpegData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return (fallbackPanels(aspectRatio: 0.67), true)
        }

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 28
        request.minimumConfidence = 0.42
        request.minimumAspectRatio = 0.12
        request.maximumAspectRatio = 8.0
        request.minimumSize = 0.075
        request.quadratureTolerance = 32

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        let raw: [GuidedPanelRect] = (request.results ?? []).compactMap { observation in
            let box = observation.boundingBox
            let rect = GuidedPanelRect(
                x: box.minX,
                y: 1 - box.maxY,
                width: box.width,
                height: box.height
            ).padded(0.008)

            guard rect.width >= 0.10,
                  rect.height >= 0.08,
                  rect.area >= 0.028,
                  rect.area <= 0.92 else { return nil }
            return rect
        }

        let deduped = deduplicate(raw)
        let ordered = readingOrder(deduped, rightToLeft: rightToLeft)

        // Rectangle detection can mistake a page border for a single panel. In that
        // situation a predictable strip fallback is better than a useless one-panel zoom.
        if ordered.count < 2 {
            let aspect = Double(cgImage.width) / Double(max(1, cgImage.height))
            return (fallbackPanels(aspectRatio: aspect), true)
        }

        return (ordered, false)
    }

    private static func deduplicate(_ panels: [GuidedPanelRect]) -> [GuidedPanelRect] {
        let sorted = panels.sorted { $0.area > $1.area }
        var accepted: [GuidedPanelRect] = []

        for candidate in sorted {
            let duplicate = accepted.contains { existing in
                intersectionOverUnion(candidate, existing) > 0.68 ||
                containment(candidate, existing) > 0.88
            }
            if !duplicate { accepted.append(candidate) }
        }
        return accepted
    }

    private static func intersectionOverUnion(_ a: GuidedPanelRect, _ b: GuidedPanelRect) -> Double {
        let ar = a.cgRect
        let br = b.cgRect
        let intersection = ar.intersection(br)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else { return 0 }
        let inter = intersection.width * intersection.height
        let union = ar.width * ar.height + br.width * br.height - inter
        return union > 0 ? Double(inter / union) : 0
    }

    private static func containment(_ a: GuidedPanelRect, _ b: GuidedPanelRect) -> Double {
        let ar = a.cgRect
        let br = b.cgRect
        let intersection = ar.intersection(br)
        guard !intersection.isNull else { return 0 }
        let inter = Double(intersection.width * intersection.height)
        let smaller = min(a.area, b.area)
        return smaller > 0 ? inter / smaller : 0
    }

    private static func readingOrder(_ panels: [GuidedPanelRect], rightToLeft: Bool) -> [GuidedPanelRect] {
        guard panels.count > 1 else { return panels }

        // Build visual rows. Panels with strongly overlapping vertical ranges belong to
        // the same row; rows are then read top-to-bottom and horizontally by direction.
        let byTop = panels.sorted { lhs, rhs in
            if abs(lhs.y - rhs.y) < 0.035 {
                return rightToLeft ? lhs.x > rhs.x : lhs.x < rhs.x
            }
            return lhs.y < rhs.y
        }

        var rows: [[GuidedPanelRect]] = []
        for panel in byTop {
            if let index = rows.indices.last,
               rowOverlap(rows[index], panel) >= 0.28 {
                rows[index].append(panel)
            } else {
                rows.append([panel])
            }
        }

        return rows.flatMap { row in
            row.sorted { rightToLeft ? $0.x > $1.x : $0.x < $1.x }
        }
    }

    private static func rowOverlap(_ row: [GuidedPanelRect], _ panel: GuidedPanelRect) -> Double {
        guard !row.isEmpty else { return 0 }
        let rowTop = row.map(\.y).min() ?? 0
        let rowBottom = row.map { $0.y + $0.height }.max() ?? 0
        let top = max(rowTop, panel.y)
        let bottom = min(rowBottom, panel.y + panel.height)
        let overlap = max(0, bottom - top)
        let reference = min(max(0.001, rowBottom - rowTop), max(0.001, panel.height))
        return overlap / reference
    }

    private static func fallbackPanels(aspectRatio: Double) -> [GuidedPanelRect] {
        // A portrait page gets three slightly overlapping horizontal reading bands.
        // A wider page gets two. This keeps Guided View useful on borderless art pages.
        let count = aspectRatio < 0.88 ? 3 : 2
        let overlap = 0.035
        let height = 1.0 / Double(count)

        return (0..<count).map { index in
            let rawTop = Double(index) * height
            let top = max(0, rawTop - (index == 0 ? 0 : overlap))
            let bottom = min(1, rawTop + height + (index == count - 1 ? 0 : overlap))
            return GuidedPanelRect(x: 0, y: top, width: 1, height: bottom - top)
        }
    }
}
