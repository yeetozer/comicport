import SwiftUI
import UIKit

private enum GuidedTapZone {
    case previous
    case center
    case next
}

private final class SendableGuidedImageBox: @unchecked Sendable {
    let image: UIImage?
    init(_ image: UIImage?) { self.image = image }
}

struct GuidedPanelReader: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    let book: ComicBook
    let settings: ReaderSettings
    @Binding var controlsVisible: Bool
    let onFinishedBook: () -> Void

    @State private var prepared: GuidedPanelPreparedPage?
    @State private var image: UIImage?
    @State private var panelIndex = 0
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var overview = false
    @State private var openPreviousPageAtEnd = false
    @State private var forceGeneration = 0
    @State private var prefetchTask: Task<Void, Never>?

    private var panels: [GuidedPanelRect] { prepared?.layout.panels ?? [] }

    private var focusRect: GuidedPanelRect {
        if overview { return .fullPage }
        guard panels.indices.contains(panelIndex) else { return .fullPage }
        return panels[panelIndex]
    }

    var body: some View {
        ZStack {
            Color.black

            if let image {
                GuidedPanelZoomCanvas(
                    image: image,
                    pageKey: "\(book.id.uuidString)-\(book.currentPage)",
                    focusRect: focusRect,
                    onTapZone: handleTap
                )
                .ignoresSafeArea()
            } else if let errorMessage {
                ContentUnavailableView(
                    "Guided Panel View unavailable",
                    systemImage: "rectangle.grid.2x2",
                    description: Text(errorMessage)
                )
                .foregroundStyle(.white)
            } else {
                VStack(spacing: 13) {
                    ProgressView().controlSize(.large).tint(.white)
                    Text("Detecting panels…")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Analysis runs locally on this device and is cached per page.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if image != nil {
                panelHUD
                    .padding(.bottom, controlsVisible ? 72 : 14)
                    .animation(.easeInOut(duration: 0.18), value: controlsVisible)
            }
        }
        .task(id: loadKey) {
            await loadCurrentPage(forceLayout: forceGeneration > 0)
        }
        .onDisappear {
            prefetchTask?.cancel()
        }
    }

    private var loadKey: String {
        "\(book.currentPage)|\(GuidedPanelEngine.settingsSignature(settings, rtl: book.rightToLeft))|\(forceGeneration)"
    }

    private var panelHUD: some View {
        HStack(spacing: 10) {
            Button {
                previous()
            } label: {
                Image(systemName: book.rightToLeft ? "chevron.right" : "chevron.left")
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.plain)

            Button {
                overview.toggle()
            } label: {
                Image(systemName: overview ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                    .frame(width: 32, height: 30)
            }
            .buttonStyle(.plain)

            VStack(spacing: 1) {
                Text(overview ? "Whole Page" : "Panel \(min(panelIndex + 1, max(1, panels.count))) / \(max(1, panels.count))")
                    .font(.caption.bold())
                    .monospacedDigit()
                HStack(spacing: 5) {
                    Text("Page \(book.currentPage + 1)")
                    if prepared?.layout.usedFallback == true {
                        Text("• Smart split")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(minWidth: 126)

            Button {
                redetect()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 32, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Re-detect panels")

            Button {
                next()
            } label: {
                Image(systemName: book.rightToLeft ? "chevron.left" : "chevron.right")
                    .frame(width: 34, height: 30)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(accentColor.opacity(0.32), lineWidth: 1))
    }

    private func handleTap(_ zone: GuidedTapZone) {
        switch zone {
        case .center:
            controlsVisible.toggle()
        case .previous:
            if book.rightToLeft { next() } else { previous() }
        case .next:
            if book.rightToLeft { previous() } else { next() }
        }
    }

    private func next() {
        overview = false
        guard !panels.isEmpty else { return }

        if panelIndex + 1 < panels.count {
            panelIndex += 1
            lightHaptic()
            return
        }

        if book.currentPage + 1 < book.pageCount {
            openPreviousPageAtEnd = false
            panelIndex = 0
            store.updateProgress(id: book.id, page: book.currentPage + 1)
            lightHaptic()
        } else {
            onFinishedBook()
        }
    }

    private func previous() {
        overview = false
        guard !panels.isEmpty else { return }

        if panelIndex > 0 {
            panelIndex -= 1
            lightHaptic()
            return
        }

        if book.currentPage > 0 {
            openPreviousPageAtEnd = true
            store.updateProgress(id: book.id, page: book.currentPage - 1)
            lightHaptic()
        }
    }

    @MainActor
    private func loadCurrentPage(forceLayout: Bool) async {
        loading = true
        errorMessage = nil
        prepared = nil
        image = nil
        prefetchTask?.cancel()

        let page = book.currentPage
        let sourceIdentity = book.sourceIdentity.isEmpty
            ? "\(book.title)|\(book.type.rawValue)|\(book.pageCount)"
            : book.sourceIdentity

        do {
            let result = try await GuidedPanelEngine.prepare(
                bookID: book.id,
                sourceIdentity: sourceIdentity,
                fileURL: store.fileURL(for: book),
                type: book.type,
                page: page,
                settings: settings,
                rightToLeft: book.rightToLeft,
                cacheDirectory: store.guidedPanelsURL,
                forceLayout: forceLayout
            )
            guard !Task.isCancelled else { return }

            let box = await Task.detached(priority: .userInitiated) {
                SendableGuidedImageBox(UIImage(data: result.jpegData))
            }.value
            guard !Task.isCancelled else { return }

            prepared = result
            image = box.image
            if openPreviousPageAtEnd {
                panelIndex = max(0, result.layout.panels.count - 1)
                openPreviousPageAtEnd = false
            } else {
                panelIndex = min(panelIndex, max(0, result.layout.panels.count - 1))
                if page != book.currentPage { panelIndex = 0 }
            }
            loading = false

            prefetchNextPage(after: page, sourceIdentity: sourceIdentity)
        } catch is CancellationError {
            return
        } catch {
            loading = false
            errorMessage = error.localizedDescription
        }
    }

    private func prefetchNextPage(after page: Int, sourceIdentity: String) {
        guard page + 1 < book.pageCount else { return }
        let url = store.fileURL(for: book)
        let cacheDirectory = store.guidedPanelsURL
        let settingsSnapshot = settings
        let bookID = book.id
        let type = book.type
        let rtl = book.rightToLeft

        prefetchTask = Task {
            _ = try? await GuidedPanelEngine.prepare(
                bookID: bookID,
                sourceIdentity: sourceIdentity,
                fileURL: url,
                type: type,
                page: page + 1,
                settings: settingsSnapshot,
                rightToLeft: rtl,
                cacheDirectory: cacheDirectory
            )
        }
    }

    private func redetect() {
        GuidedPanelEngine.removeCachedLayout(
            bookID: book.id,
            page: book.currentPage,
            settings: settings,
            rightToLeft: book.rightToLeft,
            cacheDirectory: store.guidedPanelsURL
        )
        panelIndex = 0
        overview = false
        forceGeneration += 1
    }

    private func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.55)
    }
}

private struct GuidedPanelZoomCanvas: UIViewRepresentable {
    let image: UIImage
    let pageKey: String
    let focusRect: GuidedPanelRect
    let onTapZone: (GuidedTapZone) -> Void

    func makeUIView(context: Context) -> UIScrollView {
        let scroll = UIScrollView()
        scroll.backgroundColor = .black
        scroll.delegate = context.coordinator
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.bouncesZoom = true
        scroll.decelerationRate = .fast

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 811
        scroll.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.singleTapped(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        scroll.addGestureRecognizer(singleTap)

        context.coordinator.scrollView = scroll
        context.coordinator.imageView = imageView
        return scroll
    }

    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.onTapZone = onTapZone
        context.coordinator.update(
            image: image,
            pageKey: pageKey,
            focusRect: focusRect,
            containerSize: scroll.bounds.size
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator(onTapZone: onTapZone) }

    @MainActor
    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        weak var imageView: UIImageView?
        var onTapZone: (GuidedTapZone) -> Void

        private var representedPageKey = ""
        private var representedFocus = GuidedPanelRect.fullPage
        private var lastContainerSize = CGSize.zero

        init(onTapZone: @escaping (GuidedTapZone) -> Void) {
            self.onTapZone = onTapZone
        }

        func update(image: UIImage, pageKey: String, focusRect: GuidedPanelRect, containerSize: CGSize) {
            guard let scrollView, let imageView else { return }

            let newPage = representedPageKey != pageKey
            let sizeChanged = abs(lastContainerSize.width - containerSize.width) > 1 || abs(lastContainerSize.height - containerSize.height) > 1
            let focusChanged = representedFocus != focusRect

            if newPage {
                representedPageKey = pageKey
                imageView.image = image
                imageView.frame = CGRect(origin: .zero, size: image.size)
                scrollView.contentSize = image.size
            }

            if newPage || sizeChanged {
                lastContainerSize = containerSize
                configureMinimumZoom()
            }

            if newPage || sizeChanged || focusChanged {
                representedFocus = focusRect
                DispatchQueue.main.async { [weak self] in
                    self?.zoomToFocus(animated: !newPage)
                }
            }
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent()
        }

        func scrollViewDidLayoutSubviews(_ scrollView: UIScrollView) {
            if scrollView.bounds.size != lastContainerSize {
                lastContainerSize = scrollView.bounds.size
                configureMinimumZoom()
                zoomToFocus(animated: false)
            }
        }

        private func configureMinimumZoom() {
            guard let scrollView, let imageView, imageView.bounds.width > 0, imageView.bounds.height > 0 else { return }
            let fit = min(
                scrollView.bounds.width / imageView.bounds.width,
                scrollView.bounds.height / imageView.bounds.height
            )
            let minimum = max(0.02, fit)
            scrollView.minimumZoomScale = minimum
            scrollView.maximumZoomScale = max(minimum * 8, 5)
            if scrollView.zoomScale < minimum || representedPageKey.isEmpty {
                scrollView.zoomScale = minimum
            }
            centerContent()
        }

        private func zoomToFocus(animated: Bool) {
            guard let scrollView, let imageView else { return }
            let imageSize = imageView.bounds.size
            guard imageSize.width > 0, imageSize.height > 0 else { return }

            if representedFocus == .fullPage {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: animated)
                return
            }

            let rect = CGRect(
                x: representedFocus.x * imageSize.width,
                y: representedFocus.y * imageSize.height,
                width: representedFocus.width * imageSize.width,
                height: representedFocus.height * imageSize.height
            )

            let padX = min(rect.width * 0.035, 28)
            let padY = min(rect.height * 0.035, 28)
            let padded = rect.insetBy(dx: -padX, dy: -padY).intersection(CGRect(origin: .zero, size: imageSize))
            guard padded.width > 2, padded.height > 2 else { return }
            scrollView.zoom(to: padded, animated: animated)
        }

        private func centerContent() {
            guard let scrollView, let imageView else { return }
            let scaledWidth = imageView.frame.width
            let scaledHeight = imageView.frame.height
            let horizontal = max(0, (scrollView.bounds.width - scaledWidth) / 2)
            let vertical = max(0, (scrollView.bounds.height - scaledHeight) / 2)
            scrollView.contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        }

        @objc func singleTapped(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView else { return }
            let point = recognizer.location(in: scrollView)
            let ratio = point.x / max(1, scrollView.bounds.width)
            if ratio < 0.23 { onTapZone(.previous) }
            else if ratio > 0.77 { onTapZone(.next) }
            else { onTapZone(.center) }
        }

        @objc func doubleTapped(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale * 1.25 {
                zoomToFocus(animated: true)
            } else {
                let point = recognizer.location(in: imageView)
                let width = max(80, scrollView.bounds.width / 3.0 / max(scrollView.zoomScale, 0.01))
                let height = max(80, scrollView.bounds.height / 3.0 / max(scrollView.zoomScale, 0.01))
                scrollView.zoom(
                    to: CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height),
                    animated: true
                )
            }
        }
    }
}
