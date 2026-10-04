import SwiftUI
import PDFKit

private final class SendablePDFDocumentBox: @unchecked Sendable {
    let document: PDFDocument?
    init(_ document: PDFDocument?) { self.document = document }
}

struct PDFComicReader: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    let settings: ReaderSettings
    @Binding var controlsVisible: Bool

    @State private var document: PDFDocument?
    @State private var errorMessage: String?
    @State private var loading = true

    var body: some View {
        Group {
            if let document {
                LoadedPDFComicReader(
                    book: book,
                    settings: settings,
                    controlsVisible: $controlsVisible,
                    document: document
                )
            } else if let errorMessage {
                ContentUnavailableView(
                    "Could not open PDF",
                    systemImage: "doc.badge.exclamationmark",
                    description: Text(errorMessage)
                )
                .foregroundStyle(.white)
            } else {
                ZStack {
                    Color.black
                    VStack(spacing: 12) {
                        ProgressView().controlSize(.large).tint(.white)
                        Text("Preparing PDF…").foregroundStyle(.white)
                    }
                }
            }
        }
        .task(id: book.storedFileName) {
            await loadDocument()
        }
    }

    @MainActor
    private func loadDocument() async {
        loading = true
        errorMessage = nil
        document = nil
        let url = store.fileURL(for: book)

        let box = await Task.detached(priority: .userInitiated) {
            SendablePDFDocumentBox(PDFDocument(url: url))
        }.value

        guard !Task.isCancelled else { return }
        if let loaded = box.document, loaded.pageCount > 0 {
            document = loaded
        } else {
            errorMessage = "The PDF could not be read. The original file was left unchanged."
        }
        loading = false
    }
}

private struct LoadedPDFComicReader: UIViewRepresentable {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    let settings: ReaderSettings
    @Binding var controlsVisible: Bool
    let document: PDFDocument

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.backgroundColor = .black
        view.displayBox = .cropBox
        view.displayMode = .singlePageContinuous
        view.displayDirection = .horizontal
        view.displaysAsBook = false
        view.usePageViewController(true, withViewOptions: [UIPageViewController.OptionsKey.interPageSpacing: settings.pageGap.points])
        view.autoScales = true
        view.maxScaleFactor = 6
        view.document = document

        let start = min(max(book.currentPage, settings.skipInitialPages), max(0, (view.document?.pageCount ?? 1) - 1))
        if let page = view.document?.page(at: start) { view.go(to: page) }
        if start != book.currentPage { store.updateProgress(id: book.id, page: start) }

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.pageChanged(_:)), name: .PDFViewPageChanged, object: view)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)

        context.coordinator.pdfView = view
        context.coordinator.lastSettings = settings
        context.coordinator.configureDisplay(view, settings: settings)
        context.coordinator.scheduleCropForCurrentPage()
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        context.coordinator.parent = self

        let landscape = uiView.bounds.width > uiView.bounds.height
        let desired: PDFDisplayMode
        switch settings.pageLayout {
        case .single:
            desired = .singlePageContinuous
        case .double:
            desired = .twoUpContinuous
        case .automatic:
            desired = landscape
                ? .twoUpContinuous
                : .singlePageContinuous
        }
        if uiView.displayMode != desired {
            uiView.displayMode = desired
            uiView.displaysAsBook = false
        }

        if context.coordinator.lastSettings != settings {
            context.coordinator.lastSettings = settings
            context.coordinator.cropGeneration += 1
            context.coordinator.resetCropBoxes()
            uiView.usePageViewController(true, withViewOptions: [UIPageViewController.OptionsKey.interPageSpacing: settings.pageGap.points])
            context.coordinator.scheduleCropForCurrentPage(force: true)
        }

        if let current = uiView.currentPage,
           let currentIndex = uiView.document?.index(for: current),
           currentIndex != book.currentPage,
           let requested = uiView.document?.page(at: book.currentPage) {
            uiView.go(to: requested)
        }

        context.coordinator.configureDisplay(uiView, settings: settings)
    }

    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
        coordinator.cropGeneration += 1
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: LoadedPDFComicReader
        weak var pdfView: PDFView?
        var lastSettings: ReaderSettings?
        var cropGeneration = 0
        private var cropCache: [String: NormalizedCropRect] = [:]
        private var cropCacheOrder: [String] = []
        private var pending: Set<String> = []

        init(_ parent: LoadedPDFComicReader) { self.parent = parent }

        @objc func pageChanged(_ note: Notification) {
            guard let view = pdfView, let page = view.currentPage, let index = view.document?.index(for: page) else { return }
            Task { @MainActor in self.parent.store.updateProgress(id: self.parent.book.id, page: index) }
            scheduleCrop(index: index)
            // Warm nearby pages without blocking navigation.
            scheduleCrop(index: index + 1)
            #if targetEnvironment(macCatalyst)
            scheduleCrop(index: index + 2)
            #endif
        }

        @objc func tapped() {
            Task { @MainActor in self.parent.controlsVisible.toggle() }
        }

        func scheduleCropForCurrentPage(force: Bool = false) {
            guard let view = pdfView, let page = view.currentPage, let index = view.document?.index(for: page) else { return }
            scheduleCrop(index: index, force: force)
            scheduleCrop(index: index + 1, force: force)
            #if targetEnvironment(macCatalyst)
            scheduleCrop(index: index + 2, force: force)
            #endif
        }

        func scheduleCrop(index: Int, force: Bool = false) {
            guard let view = pdfView,
                  let doc = view.document,
                  index >= 0, index < doc.pageCount else { return }

            let settings = parent.settings
            let key = cacheKey(index: index, settings: settings)
            if !force, let cached = cropCache[key] {
                apply(cached, to: index, settings: settings)
                return
            }
            guard !pending.contains(key) else { return }
            pending.insert(key)

            let url = parent.store.fileURL(for: parent.book)
            let generation = cropGeneration
            let auto = settings.autoCropEnabled
            let strength = settings.cropStrength
            let manual = settings.manualCrop
            let trimFooter = settings.trimWebFooter
            let fullBleed = settings.fullBleed

            let worker = Task.detached(priority: .utility) {
                let base: NormalizedCropRect = auto
                    ? PDFAutoCropService.detectNormalizedCrop(
                        fileURL: url,
                        pageIndex: index,
                        strength: strength,
                        trimFooter: trimFooter,
                        fullBleed: fullBleed
                    )
                    : .full
                return base.applyingManual(manual)
            }

            Task { @MainActor [weak self] in
                let result = await worker.value
                guard let self, generation == self.cropGeneration else { return }
                self.pending.remove(key)
                self.cacheCrop(result, key: key)
                self.apply(result, to: index, settings: settings)
            }
        }

        func resetCropBoxes() {
            guard let doc = pdfView?.document else { return }
            cropCache.removeAll()
            cropCacheOrder.removeAll()
            pending.removeAll()
            for index in 0..<doc.pageCount {
                guard let page = doc.page(at: index) else { continue }
                page.setBounds(page.bounds(for: .mediaBox), for: .cropBox)
            }
        }

        private func apply(_ normalized: NormalizedCropRect, to index: Int, settings: ReaderSettings) {
            guard let view = pdfView,
                  let page = view.document?.page(at: index) else { return }
            let media = page.bounds(for: .mediaBox)
            page.setBounds(PDFAutoCropService.pdfRect(from: normalized, mediaBox: media), for: .cropBox)

            if view.currentPage === page {
                view.layoutDocumentView()
                configureDisplay(view, settings: settings)
            }
        }

        func configureDisplay(_ view: PDFView, settings: ReaderSettings) {
            guard let page = view.currentPage else { return }
            let gap = settings.pageGap.points
            let landscape = view.bounds.width > view.bounds.height

            switch settings.fitMode {
            case .fitPage:
                view.autoScales = true
                let fit = max(0.1, view.scaleFactorForSizeToFit)
                view.minScaleFactor = fit
                if abs(view.scaleFactor - fit) > 0.03 { view.scaleFactor = fit }
            case .fitWidth:
                view.autoScales = false
                let pageBounds = page.bounds(for: .cropBox)
                guard pageBounds.width > 0, view.bounds.width > 0 else { return }
                let available = landscape ? max(1, (view.bounds.width - gap * 2) / 2) : max(1, view.bounds.width - gap * 2)
                let factor = max(0.1, available / pageBounds.width)
                view.minScaleFactor = factor
                if abs(view.scaleFactor - factor) > 0.03 { view.scaleFactor = factor }
            }
            view.maxScaleFactor = max(6, view.minScaleFactor * 6)
        }

        private func cacheCrop(
            _ crop: NormalizedCropRect,
            key: String
        ) {
            cropCache[key] = crop
            cropCacheOrder.removeAll { $0 == key }
            cropCacheOrder.append(key)

            #if targetEnvironment(macCatalyst)
            let maximumEntries = 28
            #else
            let maximumEntries = 14
            #endif

            while cropCacheOrder.count > maximumEntries {
                let victim = cropCacheOrder.removeFirst()
                cropCache.removeValue(forKey: victim)
            }
        }

        private func cacheKey(index: Int, settings: ReaderSettings) -> String {
            "\(index)|\(settings.autoCropEnabled)|\(settings.cropStrength.rawValue)|\(settings.trimWebFooter)|\(settings.fullBleed)|\(settings.manualCrop.top)|\(settings.manualCrop.leading)|\(settings.manualCrop.bottom)|\(settings.manualCrop.trailing)"
        }
    }
}
