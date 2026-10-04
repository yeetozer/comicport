import SwiftUI
import UIKit
import ImageIO

private enum CBZBackgroundLoadResult: Sendable {
    case success([URL])
    case failure(String)
}

private final class ComicPageImageCache: @unchecked Sendable {
    static let shared = ComicPageImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        #if targetEnvironment(macCatalyst)
        cache.countLimit = 42
        cache.totalCostLimit = 384 * 1024 * 1024
        #else
        cache.countLimit = 20
        cache.totalCostLimit = 128 * 1024 * 1024
        #endif
    }

    func cached(_ key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, key: String) {
        let cost = max(1, Int(image.size.width * image.size.height * 4))
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    static func downsample(url: URL, maxPixel: Int = 3600) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }
        let thumbOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions) else { return nil }
        return UIImage(cgImage: cg)
    }


    static func preload(urls: [URL]) {
        for url in urls {
            let key = url.path
            if shared.cached(key) != nil { continue }
            guard let image = downsample(url: url, maxPixel: 3000) else { continue }
            shared.insert(image, key: key)
        }
    }
}

struct CBZComicReader: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    let settings: ReaderSettings
    @Binding var controlsVisible: Bool
    @State private var pages: [URL] = []
    @State private var page = 0
    @State private var error: String?

    var body: some View {
        GeometryReader { geo in
            let doublePage: Bool = {
                switch settings.pageLayout {
                case .single:
                    return false
                case .double:
                    return true
                case .automatic:
                    return geo.size.width > geo.size.height
                }
            }()
            ZStack {
                Color.black
                if let error {
                    ContentUnavailableView("Could not open CBZ", systemImage: "exclamationmark.triangle", description: Text(error)).foregroundStyle(.white)
                } else if pages.isEmpty {
                    ProgressView().tint(.white).task(id: book.storedFileName) { await load() }
                } else {
                    comicPages(doublePage: doublePage)
                        .onChange(of: page) { _, newValue in
                            store.updateProgress(
                                id: book.id,
                                page: newValue
                            )
                            prefetch(around: newValue)
                        }
                        .onChange(of: doublePage) { _, isDouble in
                            let normalized = isDouble
                                ? page - (page % 2)
                                : page
                            if normalized != page {
                                page = normalized
                            }
                        }
                        .onChange(of: book.currentPage) { _, requested in
                            guard !pages.isEmpty else { return }

                            let clamped = min(
                                max(0, requested),
                                pages.count - 1
                            )
                            let normalized = doublePage
                                ? clamped - (clamped % 2)
                                : clamped

                            if page != normalized {
                                page = normalized
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func comicPages(doublePage: Bool) -> some View {
        #if targetEnvironment(macCatalyst)
        // SwiftUI's page-style TabView is backed by a UICollectionView.
        // On Mac Catalyst, changing Single/Two Page layouts while that
        // collection is self-sizing can enter UpdateCoalescingCollectionView's
        // recursive-layout protection. Render the current spread directly on
        // Mac so the reader has no UICollectionView in its page path.
        let displayPage = normalizedPage(
            page,
            doublePage: doublePage
        )

        spread(
            start: displayPage,
            doublePage: doublePage
        )
        .contentShape(Rectangle())
        .onTapGesture {
            controlsVisible.toggle()
        }
        #else
        TabView(selection: $page) {
            ForEach(
                spreadStarts(doublePage: doublePage),
                id: \.self
            ) { start in
                spread(
                    start: start,
                    doublePage: doublePage
                )
                .tag(start)
                .onTapGesture {
                    controlsVisible.toggle()
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .environment(
            \.layoutDirection,
            book.rightToLeft ? .rightToLeft : .leftToRight
        )
        #endif
    }

    private func normalizedPage(
        _ requested: Int,
        doublePage: Bool
    ) -> Int {
        guard !pages.isEmpty else { return 0 }

        let clamped = min(
            max(0, requested),
            pages.count - 1
        )

        if doublePage {
            return clamped - (clamped % 2)
        }

        return clamped
    }

    @ViewBuilder
    private func spread(start: Int, doublePage: Bool) -> some View {
        HStack(spacing: settings.pageGap.points) {
            let pair = pagePair(start: start, doublePage: doublePage)
            ForEach(pair, id: \.self) { idx in
                ZoomableImage(url: pages[idx])
            }
        }
    }

    private func pagePair(
        start: Int,
        doublePage: Bool
    ) -> [Int] {
        guard !pages.isEmpty else { return [] }

        let safeStart = min(
            max(0, start),
            pages.count - 1
        )

        guard doublePage,
              safeStart + 1 < pages.count else {
            return [safeStart]
        }

        return book.rightToLeft
            ? [safeStart + 1, safeStart]
            : [safeStart, safeStart + 1]
    }

    private func spreadStarts(doublePage: Bool) -> [Int] {
        guard doublePage else { return Array(pages.indices) }
        return Array(stride(from: 0, to: pages.count, by: 2))
    }

    private func prefetch(around index: Int) {
        guard !pages.isEmpty else { return }
        #if targetEnvironment(macCatalyst)
        let candidates = [
            index - 2,
            index - 1,
            index + 1,
            index + 2,
            index + 3
        ]
        #else
        let candidates = [
            index - 1,
            index + 1,
            index + 2
        ]
        #endif

        let indices = candidates
            .filter { pages.indices.contains($0) }
        let urls = indices.map { pages[$0] }
        guard !urls.isEmpty else { return }
        Task.detached(priority: .utility) {
            ComicPageImageCache.preload(urls: urls)
        }
    }

    @MainActor
    private func load() async {
        error = nil
        pages = []

        let url = store.fileURL(for: book)
        let result = await Task.detached(priority: .userInitiated) {
            do {
                return CBZBackgroundLoadResult.success(try CBZService.extractImages(from: url))
            } catch {
                return CBZBackgroundLoadResult.failure(error.localizedDescription)
            }
        }.value

        guard !Task.isCancelled else { return }
        switch result {
        case .success(let loadedPages):
            guard !loadedPages.isEmpty else {
                error = "The CBZ contains no supported page images."
                return
            }
            pages = loadedPages
            let requested = max(
                book.currentPage,
                settings.skipInitialPages
            )
            let initial = min(
                requested,
                max(0, loadedPages.count - 1)
            )
            page = initial
            if initial != book.currentPage { store.updateProgress(id: book.id, page: initial) }
            prefetch(around: initial)
        case .failure(let message):
            error = message
        }
    }
}

private struct ZoomableImage: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.delegate = context.coordinator
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 5
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.backgroundColor = .black
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tag = 100
        scroll.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        ])
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        guard let imageView = scroll.viewWithTag(100) as? UIImageView else { return }
        context.coordinator.load(url: url, into: imageView)
    }

    static func dismantleUIView(_ uiView: UIScrollView, coordinator: Coordinator) {
        coordinator.loadTask?.cancel()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate {
        var loadTask: Task<Void, Never>?
        var representedPath: String?

        func load(url: URL, into imageView: UIImageView) {
            guard representedPath != url.path else { return }
            representedPath = url.path
            loadTask?.cancel()
            imageView.image = nil

            let key = url.path
            if let cached = ComicPageImageCache.shared.cached(key) {
                imageView.image = cached
                return
            }

            loadTask = Task { @MainActor in
                let image = await Task.detached(priority: .userInitiated) {
                    ComicPageImageCache.downsample(url: url)
                }.value
                guard !Task.isCancelled, representedPath == url.path else { return }
                if let image {
                    ComicPageImageCache.shared.insert(image, key: key)
                    imageView.image = image
                }
            }
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { scrollView.viewWithTag(100) }
        @objc func doubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scroll = recognizer.view as? UIScrollView else { return }
            if scroll.zoomScale > 1 { scroll.setZoomScale(1, animated: true) }
            else {
                let point = recognizer.location(in: scroll.viewWithTag(100))
                let size = CGSize(width: scroll.bounds.width / 2.5, height: scroll.bounds.height / 2.5)
                scroll.zoom(to: CGRect(x: point.x - size.width/2, y: point.y - size.height/2, width: size.width, height: size.height), animated: true)
            }
        }
    }
}
