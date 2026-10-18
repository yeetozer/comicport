import SwiftUI
import PencilKit
import AVFoundation
import ImageIO
import PDFKit
import UIKit
import Vision

#if canImport(Translation)
import Translation
#endif

struct ReaderView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    var onRequestNextIssue: ((UUID) -> Void)? = nil
    @State private var controlsVisible = false
    @State private var autoNextTriggered = false
    @State private var showReaderSettings = false
    @State private var pencilMode = false
    @State private var pencilPage = -1
    @State private var pencilDrawing = PKDrawing()
    @State private var launchChecked = false
    @State private var launchError: String?
    @State private var showTextNoteEditor = false
    @State private var showPanelCapture = false
    @State private var pencilSaveTask: Task<Void, Never>?
    @State private var showCompletionJournal = false
    @State private var completionPromptTriggered = false
    @State private var showLanguageTools = false
    @State private var controlsHideTask: Task<Void, Never>?
    @State private var showThumbnailScrubber = false

    private var book: ComicBook? { store.books.first(where: { $0.id == bookID }) }

    var body: some View {
        Group {
            if let launchError {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ContentUnavailableView(
                        "Could not open comic",
                        systemImage: "exclamationmark.triangle",
                        description: Text(launchError)
                    )
                    .foregroundStyle(.white)
                }
            } else if !launchChecked {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView().controlSize(.large).tint(.white)
                        Text("Opening comic…")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Preparing the file without blocking the library.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let book {
                let readerSettings = store.readerSettings(for: book.id)

                ZStack {
                    Color.black.ignoresSafeArea()

                    Group {
                        if store.guidedPanelModeEnabled {
                            GuidedPanelReader(
                                book: book,
                                settings: readerSettings,
                                controlsVisible: $controlsVisible,
                                onFinishedBook: {
                                    handleFinishedBook(book)
                                }
                            )
                        } else if book.type == .pdf {
                            PDFComicReader(
                                book: book,
                                settings: readerSettings,
                                controlsVisible: $controlsVisible
                            )
                        } else {
                            CBZComicReader(
                                book: book,
                                settings: readerSettings,
                                controlsVisible: $controlsVisible
                            )
                        }
                    }
                    .contrast(readerSettings.enhancePreset.contrast)
                    .brightness(readerSettings.enhancePreset.brightness)
                    .saturation(readerSettings.enhancePreset.saturation)
                    .grayscale(readerSettings.enhancePreset.grayscale)

                    themeOverlay(readerSettings.theme)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    if pencilMode && !store.guidedPanelModeEnabled {
                        PencilCanvas(drawing: $pencilDrawing, onChanged: scheduleDrawingSave)
                            .background(.clear)
                            .ignoresSafeArea()
                    }
                }
                .overlay {
                    GeometryReader { geometry in
                        ZStack {
                            if controlsVisible {
                                if usesSideControls(size: geometry.size) {
                                    HStack {
                                        Spacer()
                                        readingModeSideBar(book)
                                            .padding(.trailing, 10)
                                            .padding(.vertical, 18)
                                            .transition(
                                                .move(edge: .trailing)
                                                    .combined(with: .opacity)
                                            )
                                    }
                                } else {
                                    VStack(spacing: 0) {
                                        readingModeTopBar(book)
                                            .transition(
                                                .move(edge: .top)
                                                    .combined(with: .opacity)
                                            )
                                        Spacer()
                                        readingModeBottomBar(book)
                                            .transition(
                                                .move(edge: .bottom)
                                                    .combined(with: .opacity)
                                            )
                                    }
                                }
                            }

                            ReaderKeyboardControllerHost(
                                onLeft: {
                                    keyboardMove(
                                        book,
                                        physicalDirection: -1,
                                        viewportSize: geometry.size
                                    )
                                },
                                onRight: {
                                    keyboardMove(
                                        book,
                                        physicalDirection: 1,
                                        viewportSize: geometry.size
                                    )
                                },
                                onForward: {
                                    movePage(
                                        book,
                                        readingDirection: 1,
                                        viewportSize: geometry.size
                                    )
                                },
                                onBackward: {
                                    movePage(
                                        book,
                                        readingDirection: -1,
                                        viewportSize: geometry.size
                                    )
                                },
                                onToggleLayout: {
                                    toggleQuickPageLayout(book)
                                },
                                onToggleFullscreen: {
                                    toggleCatalystFullscreen()
                                },
                                onExit: {
                                    if pencilMode { saveDrawing() }
                                    dismiss()
                                }
                            )
                            .frame(width: 1, height: 1)
                            .opacity(0.001)
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 55)
                                .onEnded { value in
                                    let horizontal = value.translation.width
                                    let vertical = value.translation.height
                                    guard abs(horizontal) > abs(vertical) * 1.35 else { return }
                                    keyboardMove(
                                        book,
                                        physicalDirection: horizontal < 0 ? 1 : -1,
                                        viewportSize: geometry.size
                                    )
                                }
                        )
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .toolbar(.hidden, for: .tabBar)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .animation(
                    readerSettings.reduceReaderMotion
                        ? nil
                        : .easeInOut(duration: 0.20),
                    value: controlsVisible
                )
                .sheet(isPresented: $showReaderSettings) {
                    ReaderSettingsView(bookID: book.id, isPDF: book.type == .pdf)
                        .environmentObject(store)
                }
                .sheet(isPresented: $showTextNoteEditor) {
                    PageTextNoteEditor(bookID: book.id, page: book.currentPage)
                        .environmentObject(store)
                }
                .sheet(isPresented: $showLanguageTools) {
                    ReaderLanguageToolsView(
                        book: book,
                        page: book.currentPage,
                        fileURL: store.fileURL(for: book),
                        targetLanguage: readerSettings.translationTarget
                    )
                }
                .sheet(isPresented: $showPanelCapture) {
                    PanelCaptureView(bookID: book.id, page: book.currentPage)
                        .environmentObject(store)
                }
                .sheet(isPresented: $showCompletionJournal, onDismiss: {
                    continueAfterCompletionJournal(book)
                }) {
                    CompletionJournalEditor(bookID: book.id, completedAt: .now)
                        .environmentObject(store)
                }
                .onAppear {
                    #if DEBUG
                    if let route = ProcessInfo.processInfo.environment["SCREENSHOT_ROUTE"] {
                        controlsVisible = route != "cbz-hidden"
                        showReaderSettings = route == "reader-settings"
                    }
                    #endif
                    let settings = store.readerSettings(for: book.id)
                    scheduleControlsAutoHide(for: book.id)
                    if book.currentPage < settings.skipInitialPages {
                        store.updateProgress(id: book.id, page: min(settings.skipInitialPages, max(0, book.pageCount - 1)))
                    }
                    store.beginReading(id: book.id)
                    pencilPage = max(book.currentPage, settings.skipInitialPages)
                }
                .onDisappear {
                    controlsHideTask?.cancel()
                    pencilSaveTask?.cancel()
                    if pencilMode { saveDrawing() }
                    store.endReading(id: book.id)
                }
                .onChange(of: controlsVisible) { _, visible in
                    if visible {
                        scheduleControlsAutoHide(for: book.id)
                    } else {
                        controlsHideTask?.cancel()
                        controlsHideTask = nil
                    }
                }
                .onChange(of: readerSettings.autoHideControls) { _, _ in
                    scheduleControlsAutoHide(for: book.id)
                }
                .onChange(of: book.currentPage) { oldValue, newValue in
                    if pencilMode, oldValue != newValue {
                        saveDrawing(page: oldValue)
                        loadDrawing(for: newValue)
                    }

                    guard !store.guidedPanelModeEnabled,
                          book.pageCount > 0,
                          oldValue < book.pageCount - 1,
                          newValue >= book.pageCount - 1 else { return }

                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(450))
                        guard !Task.isCancelled else { return }
                        handleFinishedBook(book)
                    }
                }
            } else {
                ContentUnavailableView("Book not found", systemImage: "exclamationmark.triangle")
            }
        }
        .task(id: bookID) {
            launchChecked = false
            launchError = nil
            completionPromptTriggered = false
            autoNextTriggered = false
            store.setReaderActive(true)

            if let error = store.readerLaunchError(for: bookID) {
                launchError = error
                launchChecked = true
                return
            }

            // Give SwiftUI a frame to dismiss/simplify the dashboard behind the reader
            // before PDFKit/ZIP work begins.
            await Task.yield()
            launchChecked = true
        }
        .onDisappear {
            store.setReaderActive(false)
        }
    }

    private func handleFinishedBook(_ book: ComicBook) {
        guard !completionPromptTriggered else { return }
        completionPromptTriggered = true

        if store.shouldOfferCompletionJournal(for: book.id) {
            showCompletionJournal = true
        } else {
            continueAfterCompletionJournal(book)
        }
    }

    private func continueAfterCompletionJournal(_ book: ComicBook) {
        guard !autoNextTriggered,
              store.autoOpenNextIssue,
              let next = store.nextIssue(after: book.id) else { return }
        autoNextTriggered = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            onRequestNextIssue?(next.id)
        }
    }

    private func readingModeTopBar(_ book: ComicBook) -> some View {
        let settings = store.readerSettings(for: book.id)
        let size: CGFloat = settings.largeControls ? 46 : 38

        return HStack(spacing: settings.largeControls ? 16 : 14) {
            Button {
                if pencilMode { saveDrawing() }
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: size, height: size)
            }
            .accessibilityLabel("Exit reading mode")
            .help("Back to library")

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(settings.largeControls ? .headline : .subheadline.bold())
                    .lineLimit(1)

                Text(
                    store.guidedPanelModeEnabled
                        ? "Guided Panel View"
                        : (ComicPortPlatform.isMac ? "Mac Reading Mode" : "Reading Mode")
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                quickLayoutButton(
                    book,
                    layout: .single,
                    size: size
                )
                quickLayoutButton(
                    book,
                    layout: .double,
                    size: size
                )
            }
            .padding(3)
            .background(
                .white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 9)
            )

            Button {
                if pencilMode {
                    saveDrawing()
                    pencilMode = false
                }
                store.setGuidedPanelModeEnabled(
                    !store.guidedPanelModeEnabled
                )
                controlsVisible = true
            } label: {
                Image(
                    systemName: store.guidedPanelModeEnabled
                        ? "rectangle.grid.2x2.fill"
                        : "rectangle.grid.2x2"
                )
                .frame(width: size, height: size)
            }
            .accessibilityLabel(
                store.guidedPanelModeEnabled
                    ? "Disable Guided Panel View"
                    : "Enable Guided Panel View"
            )

            Button {
                showLanguageTools = true
            } label: {
                Image(systemName: "character.bubble")
                    .frame(width: size, height: size)
            }
            .accessibilityLabel("Page Language Tools")
            .help("Page Language Tools")

            Button {
                showReaderSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: size, height: size)
            }
            .accessibilityLabel("Reader settings")
            .help("Reader Settings")

            Button {
                showTextNoteEditor = true
            } label: {
                Image(
                    systemName: store.textNote(
                        bookID: book.id,
                        page: book.currentPage
                    ) == nil
                        ? "note.text.badge.plus"
                        : "note.text"
                )
                .frame(width: size, height: size)
            }
            .accessibilityLabel("Text note")
            .help("Page Note")

            Button {
                showPanelCapture = true
            } label: {
                Image(systemName: "viewfinder.rectangular")
                    .frame(width: size, height: size)
            }
            .accessibilityLabel("Save panel")
            .help("Save this panel")

            Button {
                if pencilMode { saveDrawing() }
                pencilMode.toggle()
                if pencilMode {
                    loadDrawing(for: book.currentPage)
                }
            } label: {
                Image(
                    systemName: pencilMode
                        ? "pencil.tip.crop.circle.badge.checkmark"
                        : "pencil.tip.crop.circle"
                )
                .frame(width: size, height: size)
            }
            .accessibilityLabel(
                ComicPortPlatform.isMac
                    ? "Mouse or trackpad drawing notes"
                    : "Apple Pencil notes"
            )

            if book.type == .cbz {
                Button {
                    store.toggleReadingDirection(id: book.id)
                } label: {
                    Image(
                        systemName: book.rightToLeft
                            ? "arrow.left"
                            : "arrow.right"
                    )
                    .frame(width: size, height: size)
                }
                .accessibilityLabel(
                    book.rightToLeft
                        ? "Right to left reading"
                        : "Left to right reading"
                )
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, settings.largeControls ? 12 : 10)
        .background {
            if settings.highContrastControls {
                Color.black.opacity(0.95)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }

    private func readingModeSideBar(_ book: ComicBook) -> some View {
        let settings = store.readerSettings(for: book.id)
        let size: CGFloat = settings.largeControls ? 46 : 40

        return VStack(spacing: 7) {
            Button {
                if pencilMode { saveDrawing() }
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: size, height: size)
            }
            .help("Back to library")

            sideBarDivider

            quickLayoutButton(book, layout: .single, size: size)
            quickLayoutButton(book, layout: .double, size: size)

            sideBarDivider

            Button {
                showThumbnailScrubber.toggle()
                revealControls(bookID: book.id)
            } label: {
                Image(systemName: "rectangle.stack.badge.play")
                    .frame(width: size, height: size)
            }
            .help("Page thumbnails")

            Menu {
                ForEach(ReaderTheme.allCases) { theme in
                    Button {
                        store.updateReaderSettings(bookID: book.id) {
                            $0.theme = theme
                        }
                        store.persistReaderSettings(bookID: book.id)
                        revealControls(bookID: book.id)
                    } label: {
                        Label(theme.rawValue, systemImage: theme.systemImage)
                    }
                }
            } label: {
                Image(systemName: settings.theme.systemImage)
                    .frame(width: size, height: size)
            }
            .help("Reader background / theme")

            Button {
                showLanguageTools = true
                revealControls(bookID: book.id)
            } label: {
                Image(systemName: "character.bubble")
                    .frame(width: size, height: size)
            }
            .help("Page Language Tools")

            Button {
                showReaderSettings = true
                revealControls(bookID: book.id)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: size, height: size)
            }
            .help("Reader Settings")

            Button {
                showTextNoteEditor = true
                revealControls(bookID: book.id)
            } label: {
                Image(systemName: "note.text")
                    .frame(width: size, height: size)
            }
            .help("Page Note")

            Button {
                showPanelCapture = true
                revealControls(bookID: book.id)
            } label: {
                Image(systemName: "viewfinder.rectangular")
                    .frame(width: size, height: size)
            }
            .help("Save Panel")

            if book.type == .cbz {
                Button {
                    store.toggleReadingDirection(id: book.id)
                    revealControls(bookID: book.id)
                } label: {
                    Image(
                        systemName: book.rightToLeft
                            ? "arrow.left"
                            : "arrow.right"
                    )
                    .frame(width: size, height: size)
                }
                .help(
                    book.rightToLeft
                        ? "Right-to-left reading"
                        : "Left-to-right reading"
                )
            }

            sideBarDivider

            VStack(spacing: 2) {
                Text(
                    "\(min(book.currentPage + 1, max(1, book.pageCount)))"
                )
                .font(.headline.monospacedDigit())

                Text("/ \(max(1, book.pageCount))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 5)

            if settings.autoHideControls {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help("Controls hide after 5 seconds")
            }
        }
        .buttonStyle(.plain)
        .frame(width: size + 18)
        .padding(.vertical, 9)
        .background {
            if settings.highContrastControls {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.96))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.08))
        )
    }

    private var sideBarDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(width: 28, height: 1)
    }

    private func quickLayoutButton(
        _ book: ComicBook,
        layout: ReaderPageLayout,
        size: CGFloat
    ) -> some View {
        let selected =
            store.readerSettings(for: book.id).pageLayout == layout

        return Button {
            store.updateReaderSettings(bookID: book.id) {
                $0.pageLayout = layout
            }
            store.persistReaderSettings(bookID: book.id)
            revealControls(bookID: book.id)
        } label: {
            Image(
                systemName: layout == .single
                    ? "rectangle.portrait"
                    : "rectangle.split.2x1.fill"
            )
            .frame(width: size, height: size)
            .foregroundStyle(selected ? .primary : .secondary)
            .background(
                selected ? .white.opacity(0.12) : .clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .help(layout.rawValue)
    }

    private func toggleQuickPageLayout(_ book: ComicBook) {
        let current = store.readerSettings(for: book.id).pageLayout
        let next: ReaderPageLayout =
            current == .single ? .double : .single
        store.updateReaderSettings(bookID: book.id) {
            $0.pageLayout = next
        }
        store.persistReaderSettings(bookID: book.id)
        revealControls(bookID: book.id)
    }

    private func usesSideControls(size: CGSize) -> Bool {
        #if targetEnvironment(macCatalyst)
        let screen = UIScreen.main.bounds.size
        guard screen.width > 0, screen.height > 0 else { return false }

        return size.width >= screen.width * 0.88 &&
            size.height >= screen.height * 0.78
        #else
        return false
        #endif
    }

    private func effectiveDoublePage(
        for book: ComicBook,
        viewportSize: CGSize
    ) -> Bool {
        switch store.readerSettings(for: book.id).pageLayout {
        case .single:
            return false
        case .double:
            return true
        case .automatic:
            return viewportSize.width > viewportSize.height
        }
    }

    private func keyboardMove(
        _ book: ComicBook,
        physicalDirection: Int,
        viewportSize: CGSize
    ) {
        let readingDirection: Int
        if book.rightToLeft {
            readingDirection = -physicalDirection
        } else {
            readingDirection = physicalDirection
        }

        movePage(
            book,
            readingDirection: readingDirection,
            viewportSize: viewportSize
        )
    }

    private func movePage(
        _ book: ComicBook,
        readingDirection: Int,
        viewportSize: CGSize
    ) {
        guard !pencilMode,
              !store.guidedPanelModeEnabled,
              book.pageCount > 0 else {
            return
        }

        let step = effectiveDoublePage(
            for: book,
            viewportSize: viewportSize
        ) ? 2 : 1

        let target = min(
            max(
                0,
                book.currentPage + (readingDirection * step)
            ),
            max(0, book.pageCount - 1)
        )

        guard target != book.currentPage else { return }
        store.updateProgress(id: book.id, page: target)
        revealControls(bookID: book.id)
    }

    private func revealControls(bookID: UUID) {
        if !controlsVisible {
            controlsVisible = true
        }
        scheduleControlsAutoHide(for: bookID)
    }

    private func scheduleControlsAutoHide(for bookID: UUID) {
        controlsHideTask?.cancel()
        controlsHideTask = nil

        let settings = store.readerSettings(for: bookID)
        guard controlsVisible, settings.autoHideControls else { return }

        controlsHideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled,
                  !showReaderSettings,
                  !showTextNoteEditor,
                  !showPanelCapture,
                  !showLanguageTools else {
                return
            }
            controlsVisible = false
        }
    }

    private func readingModeBottomBar(_ book: ComicBook) -> some View {
        let settings = store.readerSettings(for: book.id)

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("1")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: { Double(book.currentPage) },
                        set: { value in
                            store.updateProgress(
                                id: book.id,
                                page: Int(value.rounded())
                            )
                        }
                    ),
                    in: 0...Double(max(1, book.pageCount - 1)),
                    step: 1
                )
                .tint(.white)

                Text("\(max(1, book.pageCount))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)

                Button {
                    showThumbnailScrubber.toggle()
                    revealControls(bookID: book.id)
                } label: {
                    Image(systemName: showThumbnailScrubber ? "rectangle.stack.fill" : "rectangle.stack")
                }
                .buttonStyle(.plain)
                .help("Thumbnail scrubber")
            }

            if showThumbnailScrubber {
                ReaderThumbnailScrubber(
                    book: book,
                    settings: settings,
                    selectedPage: book.currentPage
                ) { page in
                    store.updateProgress(id: book.id, page: page)
                    revealControls(bookID: book.id)
                }
                .frame(height: 104)
            }

            HStack {
                Text(
                    "\(min(book.currentPage + 1, max(1, book.pageCount))) / " +
                    "\(max(1, book.pageCount))"
                )
                .monospacedDigit()

                Spacer()

                if settings.enhancePreset != .off {
                    Label(
                        settings.enhancePreset.rawValue,
                        systemImage: "sparkles"
                    )
                    .foregroundStyle(.secondary)
                }

                Text("\(book.progressPercent)%")
                    .monospacedDigit()

                if book.pageCount > 0,
                   book.currentPage >= book.pageCount - 1,
                   let next = store.nextIssue(after: book.id) {
                    Button {
                        onRequestNextIssue?(next.id)
                    } label: {
                        Label("Next Issue", systemImage: "chevron.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(settings.largeControls ? .regular : .small)
                } else {
                    Text(
                        ComicPortPlatform.isMac
                            ? "Click page to hide controls"
                            : "Tap page to hide controls"
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .font(settings.largeControls ? .callout : .caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, settings.largeControls ? 12 : 10)
        .background {
            if settings.highContrastControls {
                Color.black.opacity(0.95)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }

    private func toggleCatalystFullscreen() {
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.sendAction(
            Selector(("toggleFullScreen:")),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }

    @ViewBuilder
    private func themeOverlay(_ theme: ReaderTheme) -> some View {
        switch theme {
        case .normal:
            Color.clear
        case .night:
            Color.black.opacity(0.28)
        case .sepia:
            Color(red: 0.78, green: 0.62, blue: 0.38).opacity(0.20).blendMode(.multiply)
        }
    }

    private func loadDrawing(for page: Int) {
        pencilPage = page
        if let data = store.loadNote(bookID: bookID, page: page), let drawing = try? PKDrawing(data: data) {
            pencilDrawing = drawing
        } else {
            pencilDrawing = PKDrawing()
        }
    }

    private func scheduleDrawingSave() {
        pencilSaveTask?.cancel()
        pencilSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(850))
            guard !Task.isCancelled else { return }
            saveDrawing()
        }
    }

    private func saveDrawing() {
        saveDrawing(page: pencilPage)
    }

    private func saveDrawing(page: Int) {
        guard page >= 0 else { return }
        if pencilDrawing.strokes.isEmpty {
            store.deletePencilNote(bookID: bookID, page: page)
        } else {
            store.saveNote(pencilDrawing.dataRepresentation(), bookID: bookID, page: page)
        }
    }
}

struct ReadingSessionHostView: View {
    let initialBookID: UUID
    @State private var currentBookID: UUID

    init(initialBookID: UUID) {
        self.initialBookID = initialBookID
        _currentBookID = State(initialValue: initialBookID)
    }

    var body: some View {
        ReaderView(bookID: currentBookID) { nextID in
            currentBookID = nextID
        }
        .id(currentBookID)
    }
}

private struct ReaderKeyboardControllerHost: UIViewControllerRepresentable {
    let onLeft: () -> Void
    let onRight: () -> Void
    let onForward: () -> Void
    let onBackward: () -> Void
    let onToggleLayout: () -> Void
    let onToggleFullscreen: () -> Void
    let onExit: () -> Void

    func makeUIViewController(context: Context) -> ReaderKeyboardController {
        let controller = ReaderKeyboardController()
        configure(controller)
        return controller
    }

    func updateUIViewController(
        _ uiViewController: ReaderKeyboardController,
        context: Context
    ) {
        configure(uiViewController)
        uiViewController.claimKeyboardFocus()
    }

    private func configure(_ controller: ReaderKeyboardController) {
        controller.onLeft = onLeft
        controller.onRight = onRight
        controller.onForward = onForward
        controller.onBackward = onBackward
        controller.onToggleLayout = onToggleLayout
        controller.onToggleFullscreen = onToggleFullscreen
        controller.onExit = onExit
    }
}

private final class ReaderKeyboardController: UIViewController {
    var onLeft: (() -> Void)?
    var onRight: (() -> Void)?
    var onForward: (() -> Void)?
    var onBackward: (() -> Void)?
    var onToggleLayout: (() -> Void)?
    var onToggleFullscreen: (() -> Void)?
    var onExit: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        claimKeyboardFocus()
    }

    func claimKeyboardFocus() {
        guard viewIfLoaded?.window != nil else { return }
        if !isFirstResponder {
            becomeFirstResponder()
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                input: UIKeyCommand.inputLeftArrow,
                modifierFlags: [],
                action: #selector(left)
            ),
            UIKeyCommand(
                input: UIKeyCommand.inputRightArrow,
                modifierFlags: [],
                action: #selector(right)
            ),
            UIKeyCommand(
                input: " ",
                modifierFlags: [],
                action: #selector(forward)
            ),
            UIKeyCommand(
                input: " ",
                modifierFlags: [.shift],
                action: #selector(backward)
            ),
            UIKeyCommand(
                input: "s",
                modifierFlags: [],
                action: #selector(toggleLayout)
            ),
            UIKeyCommand(
                input: "f",
                modifierFlags: [],
                action: #selector(toggleFullscreen)
            ),
            UIKeyCommand(
                input: UIKeyCommand.inputEscape,
                modifierFlags: [],
                action: #selector(exitReader)
            )
        ]
    }

    @objc private func left() { onLeft?() }
    @objc private func right() { onRight?() }
    @objc private func forward() { onForward?() }
    @objc private func backward() { onBackward?() }
    @objc private func toggleLayout() { onToggleLayout?() }
    @objc private func toggleFullscreen() { onToggleFullscreen?() }
    @objc private func exitReader() { onExit?() }
}

private struct ReaderThumbnailScrubber: View {
    let book: ComicBook
    let settings: ReaderSettings
    let selectedPage: Int
    let onSelect: (Int) -> Void

    private var pages: [Int] {
        let start = max(0, selectedPage - 5)
        let end = min(max(0, book.pageCount - 1), selectedPage + 5)
        guard start <= end else { return [] }
        return Array(start...end)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pages, id: \.self) { page in
                        ReaderThumbnailCell(
                            book: book,
                            settings: settings,
                            page: page,
                            selected: page == selectedPage
                        )
                        .id(page)
                        .onTapGesture { onSelect(page) }
                    }
                }
                .padding(.horizontal, 4)
            }
            .onChange(of: selectedPage) { _, page in
                withAnimation(.easeOut(duration: 0.14)) {
                    proxy.scrollTo(page, anchor: .center)
                }
            }
        }
    }
}

private struct ReaderThumbnailCell: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    let settings: ReaderSettings
    let page: Int
    let selected: Bool
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 7)
                .fill(.white.opacity(0.05))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            } else {
                ProgressView().controlSize(.small)
            }

            Text("\(page + 1)")
                .font(.caption2.bold().monospacedDigit())
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(.black.opacity(0.74), in: Capsule())
                .padding(4)
        }
        .frame(width: 62, height: 92)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(selected ? .white : .clear, lineWidth: 2)
        )
        .task(id: page) {
            guard image == nil else { return }
            let data = await ReaderPageSnapshotService.loadSnapshot(
                fileURL: store.fileURL(for: book),
                type: book.type,
                page: page,
                settings: settings,
                maxPixel: 260
            )
            if let data, !Task.isCancelled {
                image = UIImage(data: data)
            }
        }
    }
}

private struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let onChanged: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        #if targetEnvironment(macCatalyst)
        canvas.drawingPolicy = .anyInput
        #else
        canvas.drawingPolicy = .pencilOnly
        #endif
        canvas.delegate = context.coordinator
        canvas.tool = PKInkingTool(.pen, color: .systemRed, width: 4)
        canvas.drawing = drawing

        context.coordinator.toolPicker.setVisible(true, forFirstResponder: canvas)
        context.coordinator.toolPicker.addObserver(canvas)
        DispatchQueue.main.async { canvas.becomeFirstResponder() }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if canvas.drawing.dataRepresentation() != drawing.dataRepresentation() { canvas.drawing = drawing }
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        coordinator.toolPicker.removeObserver(uiView)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: PencilCanvas
        let toolPicker = PKToolPicker()

        init(parent: PencilCanvas) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onChanged()
        }
    }
}


// MARK: - Stage 17 Page Language Tools

private actor ReaderPageTextCache {
    static let shared = ReaderPageTextCache()

    private var values: [String: String] = [:]
    private var order: [String] = []

    func value(for key: String) -> String? {
        values[key]
    }

    func insert(_ text: String, for key: String) {
        values[key] = text
        order.removeAll { $0 == key }
        order.append(key)

        while order.count > 24 {
            let removed = order.removeFirst()
            values.removeValue(forKey: removed)
        }
    }
}

private enum ReaderPageTextService {
    static func text(
        for book: ComicBook,
        page: Int,
        fileURL: URL
    ) async -> String {
        guard page >= 0 else { return "" }

        let key = "\(book.sourceIdentity)|\(page)"
        if let cached = await ReaderPageTextCache.shared.value(for: key) {
            return cached
        }

        let text = await Task.detached(priority: .userInitiated) {
            recognize(book: book, page: page, fileURL: fileURL)
        }.value

        await ReaderPageTextCache.shared.insert(text, for: key)
        return text
    }

    private static func recognize(
        book: ComicBook,
        page: Int,
        fileURL: URL
    ) -> String {
        switch book.type {
        case .pdf:
            guard let document = PDFDocument(url: fileURL),
                  page < document.pageCount,
                  let pdfPage = document.page(at: page) else {
                return ""
            }

            if let nativeText = pdfPage.string?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               nativeText.count >= 8 {
                return nativeText
            }

            let bounds = pdfPage.bounds(for: .mediaBox)
            guard bounds.width > 0, bounds.height > 0 else {
                return ""
            }

            let maximumPixel: CGFloat = 1900
            let scale = min(
                maximumPixel / max(bounds.width, bounds.height),
                2.5
            )

            let image = pdfPage.thumbnail(
                of: CGSize(
                    width: max(1, bounds.width * scale),
                    height: max(1, bounds.height * scale)
                ),
                for: .mediaBox
            )

            guard let cgImage = image.cgImage else {
                return ""
            }

            return recognize(cgImage)

        case .cbz:
            guard let pages = try? CBZService.extractImages(from: fileURL),
                  pages.indices.contains(page),
                  let cgImage = downsample(
                    pages[page],
                    maximumPixel: 1900
                  ) else {
                return ""
            }

            return recognize(cgImage)
        }
    }

    private static func downsample(
        _ url: URL,
        maximumPixel: Int
    ) -> CGImage? {
        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithURL(
            url as CFURL,
            sourceOptions
        ) else {
            return nil
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixel,
            kCGImageSourceShouldCacheImmediately: false
        ] as CFDictionary

        return CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options
        )
    }

    private static func recognize(_ cgImage: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.007

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .filter {
                !$0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            }
            .joined(separator: "\n")
    }
}

@MainActor
private final class ReaderSpeechController {
    private let synthesizer = AVSpeechSynthesizer()

    func toggle(
        text: String,
        languageCode: String? = nil
    ) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            return
        }

        let clean = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !clean.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: clean)
        if let languageCode {
            utterance.voice = AVSpeechSynthesisVoice(
                language: languageCode
            )
        }

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

private struct ReaderLanguageToolsView: View {
    let book: ComicBook
    let page: Int
    let fileURL: URL
    let targetLanguage: ReaderTranslationLanguage

    @Environment(\.dismiss) private var dismiss
    @State private var speaker = ReaderSpeechController()
    @State private var sourceText = ""
    @State private var translatedText = ""
    @State private var isRecognizing = true
    @State private var translationError: String?
    @State private var isTranslating = false

    var body: some View {
        NavigationStack {
            Group {
                if isRecognizing {
                    VStack(spacing: 14) {
                        ProgressView()
                            .controlSize(.large)

                        Text("Reading page text locally…")
                            .font(.headline)

                        Text(
                            "Vision OCR runs on this Mac. The comic page is not uploaded."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                } else if sourceText.isEmpty {
                    ContentUnavailableView(
                        "No readable text found",
                        systemImage: "text.magnifyingglass",
                        description: Text(
                            "ComicPort could not detect enough text on page \(page + 1)."
                        )
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Page Language Tools")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        speaker.stop()
                        dismiss()
                    }
                }
            }
        }
        #if targetEnvironment(macCatalyst)
        .frame(
            minWidth: 680,
            idealWidth: 760,
            minHeight: 520,
            idealHeight: 620
        )
        #endif
        .task(id: "\(book.id.uuidString)-\(page)") {
            await recognizePage()
        }
        .onDisappear {
            speaker.stop()
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                textCard(
                    title: "Detected Text",
                    text: sourceText,
                    icon: "text.viewfinder"
                )

                HStack(spacing: 10) {
                    Button {
                        UIPasteboard.general.string = sourceText
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Button {
                        speaker.toggle(text: sourceText)
                    } label: {
                        Label(
                            "Read Aloud / Stop",
                            systemImage: "speaker.wave.2.fill"
                        )
                    }

                    Spacer()

                    #if canImport(Translation)
                    if #available(iOS 18.0, macCatalyst 26.0, *) {
                        ReaderSystemTranslateButton(
                            sourceText: sourceText,
                            targetLanguage: targetLanguage,
                            translatedText: $translatedText,
                            translationError: $translationError,
                            isTranslating: $isTranslating
                        )
                    } else {
                        translationUnavailable
                    }
                    #else
                    translationUnavailable
                    #endif
                }

                if isTranslating {
                    HStack(spacing: 9) {
                        ProgressView()
                        Text(
                            "Translating to \(targetLanguage.rawValue)…"
                        )
                        .foregroundStyle(.secondary)
                    }
                }

                if !translatedText.isEmpty {
                    textCard(
                        title: "\(targetLanguage.rawValue) Translation",
                        text: translatedText,
                        icon: "character.bubble.fill"
                    )

                    HStack {
                        Button {
                            UIPasteboard.general.string = translatedText
                        } label: {
                            Label(
                                "Copy Translation",
                                systemImage: "doc.on.doc"
                            )
                        }

                        Button {
                            speaker.toggle(
                                text: translatedText,
                                languageCode: targetLanguage.localeIdentifier
                            )
                        } label: {
                            Label(
                                "Read Translation / Stop",
                                systemImage: "speaker.wave.2"
                            )
                        }
                    }
                }

                if let translationError {
                    Label(
                        translationError,
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Label(
                    "Translation uses Apple's system Translation framework when available. A language pair can require a one-time system download before offline use.",
                    systemImage: "lock.shield"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }

    private var translationUnavailable: some View {
        Label(
            "System Translation requires Mac Catalyst 26 or newer",
            systemImage: "character.bubble"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func textCard(
        title: String,
        text: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .padding(16)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    private func recognizePage() async {
        isRecognizing = true
        translatedText = ""
        translationError = nil

        let result = await ReaderPageTextService.text(
            for: book,
            page: page,
            fileURL: fileURL
        )

        guard !Task.isCancelled else { return }

        sourceText = result.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        isRecognizing = false
    }
}

#if canImport(Translation)
@available(iOS 18.0, macCatalyst 26.0, *)
private struct ReaderSystemTranslateButton: View {
    let sourceText: String
    let targetLanguage: ReaderTranslationLanguage

    @Binding var translatedText: String
    @Binding var translationError: String?
    @Binding var isTranslating: Bool

    @State private var configuration:
        TranslationSession.Configuration?

    var body: some View {
        Button {
            translationError = nil
            isTranslating = true

            if configuration == nil {
                configuration = TranslationSession.Configuration(
                    source: nil,
                    target: Locale.Language(
                        identifier: targetLanguage.localeIdentifier
                    )
                )
            } else {
                configuration?.invalidate()
            }
        } label: {
            Label(
                "Translate to \(targetLanguage.rawValue)",
                systemImage: "character.bubble"
            )
        }
        .disabled(sourceText.isEmpty || isTranslating)
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(sourceText)
                translatedText = response.targetText
                translationError = nil
                isTranslating = false
            } catch {
                translationError = error.localizedDescription
                isTranslating = false
            }
        }
    }
}
#endif
