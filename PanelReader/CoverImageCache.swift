import SwiftUI
import UIKit
import ImageIO

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
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

struct CachedCoverImage: View {
    let url: URL?
    let comicType: ComicType
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
        return "\(url.path)|\(Int(maxPixelSize))"
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

        let target = maxPixelSize
        let loaded = await Task.detached(priority: .utility) {
            Self.downsample(url: url, maxPixelSize: target)
        }.value

        guard !Task.isCancelled else { return }
        if let loaded {
            PanelCoverCache.shared.insert(loaded, for: key)
            image = loaded
        }
    }

    private static func downsample(url: URL, maxPixelSize: CGFloat) -> UIImage? {
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
