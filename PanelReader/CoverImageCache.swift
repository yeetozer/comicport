import SwiftUI
import UIKit
import ImageIO

enum BookCoverPreparation {
    static func jpeg(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
        return jpeg(source: source)
    }

    static func jpeg(at url: URL) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
        return jpeg(source: source)
    }

    private static func jpeg(source: CGImageSource) -> Data? {
        let options = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                       kCGImageSourceCreateThumbnailWithTransform: true,
                       kCGImageSourceThumbnailMaxPixelSize: 1200] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: 0.88)
    }
}

final class PanelCoverCache: @unchecked Sendable {
    static let shared = PanelCoverCache()
    private let cache = NSCache<NSString, UIImage>()

    private var memoryObserver: NSObjectProtocol?

    private init() {
        #if targetEnvironment(macCatalyst)
        cache.countLimit = 360
        cache.totalCostLimit = 256 * 1024 * 1024
        #else
        cache.countLimit = 180
        cache.totalCostLimit = 96 * 1024 * 1024
        #endif
        memoryObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height }
            ?? Int(image.size.width * image.scale * image.size.height * image.scale * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

struct CachedCoverImage: View {
    let url: URL?
    let comicType: ComicType
    var revision: Int = 0
    var maxPixelSize: CGFloat = 720

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: comicType == .pdf ? "doc.richtext" : "photo.on.rectangle.angled")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: cacheKey) {
            await load()
        }
    }

    private var cacheKey: String {
        guard let url else { return "missing" }
        return "\(url.path)|\(revision)|\(Int(maxPixelSize))"
    }

    @MainActor
    private func load() async {
        guard let url else {
            image = nil
            return
        }

        let key = cacheKey
        if let cached = PanelCoverCache.shared.image(for: key) {
            image = cached
            return
        }

        image = nil
        let target = maxPixelSize
        let loaded = await PanelCoverLoader.shared.image(url: url, maxPixelSize: target, key: key)

        guard !Task.isCancelled else { return }
        if let loaded {
            image = loaded
        } else {
            image = nil
        }
    }

    nonisolated fileprivate static func downsample(url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(160, Int(maxPixelSize)),
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}


// Coalesce identical requests and bound simultaneous image decoding to two workers.
actor PanelCoverLoader {
    static let shared = PanelCoverLoader()
    private let decodeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .utility
        return queue
    }()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    func image(url: URL, maxPixelSize: CGFloat, key: String) async -> UIImage? {
        if let cached = PanelCoverCache.shared.image(for: key) { return cached }
        if let existing = inFlight[key] { return await existing.value }
        let queue = decodeQueue
        let task = Task.detached(priority: .utility) {
            await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
                queue.addOperation {
                    continuation.resume(returning: CachedCoverImage.downsample(url: url, maxPixelSize: maxPixelSize))
                }
            }
        }
        inFlight[key] = task
        let image = await task.value
        if let image { PanelCoverCache.shared.insert(image, for: key) }
        inFlight[key] = nil
        return image
    }
}
