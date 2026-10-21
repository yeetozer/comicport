import SwiftUI
import UIKit
import ImageIO

struct EPUBReaderView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    @State private var publication: EPUBPublication?
    @State private var chapter = 0
    @State private var text = ""
    @State private var images: [EPUBChapterImage] = []
    @State private var links: [EPUBChapterLink] = []
    @State private var anchors: [String: Int] = [:]
    @State private var inlineImages: [Int: Data] = [:]
    @State private var pendingFragment: String?
    @State private var jump: EPUBTextJump?
    @State private var chapterLoaded = false
    @State private var showImages = false
    @State private var state = EPUBReaderState()
    @State private var selection = NSRange(location: 0, length: 0)
    @State private var error: String?
    @State private var showNotes = false
    @State private var note = ""
    @State private var showBookmarks = false
    @State private var started = false
    @State private var saveTask: Task<Void, Never>?
    @State private var chapterTask: Task<Void, Never>?

    private var book: ComicBook? { store.books.first { $0.id == bookID } }
    private var foreground: Color { state.theme == .night ? .white : .black }
    private var background: Color { state.theme == .night ? Color(white: 0.10) : (state.theme == .sepia ? Color(red: 0.97, green: 0.93, blue: 0.84) : .white) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Kapat", systemImage: "xmark") { persist(); dismiss() }.keyboardShortcut(.escape, modifiers: [])
                Text(book?.title ?? "Kitap").font(.headline).lineLimit(1)
                Spacer()
                Menu("Bölümler", systemImage: "list.bullet") {
                    ForEach(publication?.chapters ?? []) { item in Button(item.title) { go(to: item.id) } }
                }
                Menu("Bağlantılar", systemImage: "link") {
                    ForEach(Array(links.enumerated()), id: \.offset) { _, link in
                        Button((text as NSString).substring(with: NSRange(location: link.location, length: link.length))) { openLink(link.url) }
                    }
                }.disabled(links.isEmpty)
                Button("Görseller", systemImage: "photo") { showImages = true }.disabled(images.isEmpty)
                Button("Yer imleri", systemImage: "bookmark") { showBookmarks = true }
                Button(state.bookmarks.contains(chapter) ? "Yer imini kaldır" : "Yer imi ekle", systemImage: state.bookmarks.contains(chapter) ? "bookmark.fill" : "bookmark") {
                    if state.bookmarks.contains(chapter) { state.bookmarks.remove(chapter) } else { state.bookmarks.insert(chapter) }
                    persist()
                }
            }.padding()
            HStack {
                Button("Yazıyı küçült", systemImage: "textformat.size.smaller") { state.fontSize = max(14, state.fontSize - 2); persist() }
                Text("\(Int(state.fontSize)) punto").font(.caption).monospacedDigit()
                Button("Yazıyı büyüt", systemImage: "textformat.size.larger") { state.fontSize = min(36, state.fontSize + 2); persist() }
                Picker("Yazı tipi", selection: $state.fontFamily) {
                    ForEach(EPUBFontFamily.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu).onChange(of: state.fontFamily) { _, _ in persist() }
                Picker("Tema", selection: $state.theme) {
                    Text("Açık").tag(ReaderTheme.normal)
                    Text("Sepya").tag(ReaderTheme.sepia)
                    Text("Gece").tag(ReaderTheme.night)
                }.pickerStyle(.menu).onChange(of: state.theme) { _, _ in persist() }
                Menu("Sayfa düzeni", systemImage: "text.alignleft") {
                    Picker("Satır aralığı", selection: $state.lineSpacing) {
                        Text("Sık").tag(3.0); Text("Normal").tag(7.0); Text("Geniş").tag(14.0)
                    }
                    Picker("Kenar boşluğu", selection: $state.horizontalMargin) {
                        Text("Dar").tag(16.0); Text("Normal").tag(30.0); Text("Geniş").tag(60.0)
                    }
                }
                .onChange(of: state.lineSpacing) { _, _ in persist() }
                .onChange(of: state.horizontalMargin) { _, _ in persist() }
                Spacer()
                Button("İşaretle", systemImage: "highlighter") { addHighlight() }.disabled(selection.length == 0)
                Button("Notlar", systemImage: "note.text") { note = store.textNote(bookID: bookID, page: chapter)?.text ?? ""; showNotes = true }
            }.padding(.horizontal).padding(.bottom, 8)
            Divider()
            if let error {
                ContentUnavailableView("Kitap açılamadı", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if !chapterLoaded {
                ProgressView("Bölüm açılıyor…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EPUBTextView(text: text, chapter: chapter, fontSize: state.fontSize, fontFamily: state.fontFamily, theme: state.theme,
                    lineSpacing: state.lineSpacing, horizontalMargin: state.horizontalMargin, links: links, images: images, imageData: inlineImages, jump: jump, openLink: openLink, highlights: state.highlights.filter { $0.chapter == chapter }, selection: $selection, fraction: $state.scrollFraction)
                    .onChange(of: state.scrollFraction) { _, _ in
                        saveTask?.cancel()
                        saveTask = Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(500))
                            if !Task.isCancelled { persist() }
                        }
                    }
            }
            Divider()
            HStack {
                Button("Önceki bölüm", systemImage: "chevron.left") { go(to: chapter - 1) }.disabled(chapter == 0).keyboardShortcut(.leftArrow, modifiers: [])
                Spacer()
                Text("Bölüm \(chapter + 1)/\(publication?.chapters.count ?? 0)").font(.caption).monospacedDigit()
                Spacer()
                if chapter + 1 < (publication?.chapters.count ?? 0) {
                    Button("Sonraki bölüm", systemImage: "chevron.right") { go(to: chapter + 1) }.keyboardShortcut(.rightArrow, modifiers: [])
                } else {
                    Button("Kitabı tamamladım", systemImage: "checkmark.circle") { persist(); store.setStatus(id: bookID, status: .completed); dismiss() }.disabled(publication == nil)
                }
            }.padding()
        }
        .foregroundStyle(foreground).background(background)
        .task {
            guard let book else { return }
            do {
                let url = store.fileURL(for: book)
                let result = try await Task.detached(priority: .userInitiated) { try EPUBService.open(url) }.value
                guard !Task.isCancelled else { return }
                publication = result
                chapter = max(0, min(book.currentPage, result.chapters.count - 1))
                state = book.epubState ?? EPUBReaderState()
                try await loadChapter(chapter)
                guard !Task.isCancelled else { return }
                store.beginReading(id: bookID)
                started = true
                persist()
            } catch { self.error = error.localizedDescription }
        }
        .onDisappear {
            chapterTask?.cancel(); saveTask?.cancel()
            if started { persist(); store.endReading(id: bookID) }
        }
        .sheet(isPresented: $showImages) {
            VStack {
                HStack { Text("Bölüm görselleri").font(.title2.bold()); Spacer(); Button("Kapat") { showImages = false } }.padding()
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(images) { item in EPUBChapterImageView(item: item) }
                    }.padding()
                }
            }.frame(minWidth: 450, minHeight: 450)
        }
        .sheet(isPresented: $showNotes) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Bölüm \(chapter + 1) notları").font(.title2.bold())
                TextEditor(text: $note).frame(minWidth: 350, minHeight: 250)
                HStack {
                    Button("Vazgeç") { showNotes = false }
                    Spacer()
                    Button("Kaydet") { store.saveTextNote(bookID: bookID, page: chapter, text: note); showNotes = false }.buttonStyle(.borderedProminent)
                }
            }.padding()
        }
        .sheet(isPresented: $showBookmarks) {
            VStack(alignment: .leading) {
                HStack { Text("Yer imleri ve işaretler").font(.title2.bold()); Spacer(); Button("Kapat") { showBookmarks = false } }
                List {
                    ForEach(state.bookmarks.sorted(), id: \.self) { index in
                        HStack {
                            Button("Bölüm \(index + 1)") { go(to: index); showBookmarks = false }
                            Spacer()
                            Button("Kaldır") { state.bookmarks.remove(index); persist() }
                        }
                    }
                    ForEach(state.highlights) { highlight in
                        HStack {
                            Button("Bölüm \(highlight.chapter + 1): \(highlight.quote)") { go(to: highlight.chapter); showBookmarks = false }.lineLimit(2)
                            Spacer()
                            Button("Kaldır") { state.highlights.removeAll { $0.id == highlight.id }; persist() }
                        }
                    }
                    if state.bookmarks.isEmpty && state.highlights.isEmpty { Text("Henüz yer imi veya işaret yok.") }
                }
            }.padding().frame(minWidth: 450, minHeight: 350)
        }
    }

    private func loadChapter(_ index: Int) async throws {
        guard let publication, publication.chapters.indices.contains(index), let book else { return }
        let source = store.fileURL(for: book)
        let value = try await Task.detached(priority: .userInitiated) {
            let current = try EPUBService.open(source)
            guard current.chapters.indices.contains(index) else { throw EPUBError.invalidPackage }
            return try EPUBPackage.content(at: current.chapters[index].fileURL, root: current.root)
        }.value
        guard !Task.isCancelled, chapter == index else { return }
        text = value.text; images = value.images; links = value.links; anchors = value.anchors
        // Prepare bounded thumbnails off the main thread. The gallery remains available
        // for unsupported images and chapters exceeding the inline memory budget.
        let prepared = await Task.detached(priority: .utility) {
            var result: [Int: Data] = [:]
            var cost = 0
            for image in value.images {
                guard !Task.isCancelled else { break }
                guard let data = BookCoverPreparation.jpeg(at: image.fileURL),
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                      let width = properties[kCGImagePropertyPixelWidth] as? Int,
                      let height = properties[kCGImagePropertyPixelHeight] as? Int else { continue }
                let bytes = width * height * 4
                guard cost + bytes <= 32 * 1024 * 1024 else { continue }
                cost += bytes; result[image.id] = data
            }
            return result
        }.value
        guard !Task.isCancelled, chapter == index else { return }
        inlineImages = prepared
        if let fragment = pendingFragment, let location = anchors[fragment] { jump = EPUBTextJump(location: location) }
        pendingFragment = nil; chapterLoaded = true
    }
    private func go(to index: Int, fragment: String? = nil) {
        guard let publication, publication.chapters.indices.contains(index) else { return }
        if index == chapter {
            if chapterLoaded {
                if let fragment, let location = anchors[fragment] { jump = EPUBTextJump(location: location) }
            } else { pendingFragment = fragment }
            return
        }
        pendingFragment = fragment; jump = nil; inlineImages = [:]; anchors = [:]
        chapterTask?.cancel(); saveTask?.cancel()
        chapter = index; state.scrollFraction = 0; selection = NSRange(location: 0, length: 0); text = ""; images = []; links = []; chapterLoaded = false; error = nil
        persist()
        chapterTask = Task { @MainActor in
            do { try await loadChapter(index) }
            catch { if !Task.isCancelled { self.error = error.localizedDescription } }
        }
    }
    private func openLink(_ url: URL) {
        if url.isFileURL {
            if let index = publication?.chapters.firstIndex(where: { $0.fileURL.standardizedFileURL.path == url.standardizedFileURL.path }) {
                go(to: index, fragment: URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment)
            }
        } else if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url)
        }
    }
    private func persist() {
        guard started else { return }
        store.updateEPUBState(id: bookID, chapter: chapter, state: state)
    }
    private func addHighlight() {
        let source = text as NSString
        guard selection.length > 0, selection.location >= 0, NSMaxRange(selection) <= source.length else { return }
        let quote = source.substring(with: selection)
        guard !state.highlights.contains(where: { $0.chapter == chapter && $0.location == selection.location && $0.length == selection.length }) else { return }
        state.highlights.append(EPUBHighlight(chapter: chapter, location: selection.location, length: selection.length, quote: quote))
        persist()
    }
}

private struct EPUBTextJump: Equatable {
    let id = UUID()
    let location: Int
}

private struct EPUBTextView: UIViewRepresentable {
    let text: String
    let chapter: Int
    let fontSize: Double
    let fontFamily: EPUBFontFamily
    let theme: ReaderTheme
    let lineSpacing: Double
    let horizontalMargin: Double
    let links: [EPUBChapterLink]
    let images: [EPUBChapterImage]
    let imageData: [Int: Data]
    let jump: EPUBTextJump?
    let openLink: (URL) -> Void
    let highlights: [EPUBHighlight]
    @Binding var selection: NSRange
    @Binding var fraction: Double

    private var readerFont: UIFont {
        switch fontFamily {
        case .serif: return UIFont(name: "Georgia", size: fontSize) ?? .systemFont(ofSize: fontSize)
        case .sans: return .systemFont(ofSize: fontSize)
        case .mono: return .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UITextView {
        let view = EPUBNativeTextView()
        view.isEditable = false
        view.isSelectable = true
        view.spellCheckingType = .no
        view.autocorrectionType = .no
        view.delegate = context.coordinator
        view.textContainerInset = UIEdgeInsets(top: 24, left: 30, bottom: 32, right: 30)
        return view
    }
    func updateUIView(_ view: UITextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        let newChapter = coordinator.chapter != chapter || coordinator.text != text
        let needsJump = jump != nil && coordinator.jump != jump
        let width = max(100, view.bounds.width - horizontalMargin * 2)
        guard needsJump || coordinator.lineSpacing != lineSpacing || coordinator.horizontalMargin != horizontalMargin || abs(coordinator.width - width) > 1 || newChapter || coordinator.fontSize != fontSize || coordinator.fontFamily != fontFamily || coordinator.theme != theme || coordinator.highlights != highlights else { return }
        coordinator.applying = true
        let selected = view.selectedRange
        let position = view.contentOffset
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        view.textContainerInset = UIEdgeInsets(top: 24, left: horizontalMargin, bottom: 32, right: horizontalMargin)
        paragraph.paragraphSpacing = 12
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: readerFont,
            .foregroundColor: theme == .night ? UIColor.white : UIColor.black,
            .paragraphStyle: paragraph
        ])
        for link in links {
            attributed.addAttribute(.link, value: link.url, range: NSRange(location: link.location, length: link.length))
        }
        view.linkTextAttributes = [.foregroundColor: theme == .night ? UIColor.systemTeal : UIColor.systemBlue, .underlineStyle: NSUnderlineStyle.single.rawValue]
        for highlight in highlights where highlight.location >= 0 && highlight.length > 0 && highlight.location <= attributed.length && highlight.length <= attributed.length - highlight.location {
            let range = NSRange(location: highlight.location, length: highlight.length)
            if (text as NSString).substring(with: range) == highlight.quote {
                attributed.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.45), range: range)
            }
        }
        let map = EPUBDisplayMap(imageLocations: images.map(\.location))
        for item in images.reversed() {
            let attachment = NSTextAttachment()
            let image = imageData[item.id].flatMap { UIImage(data: $0) }
            attachment.image = image ?? UIImage(systemName: "photo")
            let size = image?.size ?? CGSize(width: 80, height: 80)
            let scale = min(1, width / max(1, size.width), 800 / max(1, size.height))
            attachment.bounds = CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale)
            let insertion = NSMutableAttributedString(string: "\n")
            insertion.append(NSAttributedString(attachment: attachment))
            insertion.append(NSAttributedString(string: "\n"))
            attributed.insert(insertion, at: min(attributed.length, item.location))
        }
        coordinator.map = map
        view.backgroundColor = theme == .night ? UIColor(white: 0.10, alpha: 1) : (theme == .sepia ? UIColor(red: 0.97, green: 0.93, blue: 0.84, alpha: 1) : .white)
        view.attributedText = attributed
        if !newChapter { view.selectedRange = selected; view.setContentOffset(position, animated: false) }
        coordinator.chapter = chapter; coordinator.text = text; coordinator.fontSize = fontSize; coordinator.fontFamily = fontFamily; coordinator.theme = theme; coordinator.highlights = highlights; coordinator.width = width; coordinator.lineSpacing = lineSpacing; coordinator.horizontalMargin = horizontalMargin; coordinator.jump = jump
        if let native = view as? EPUBNativeTextView {
            if newChapter { native.pendingFraction = fraction }
            if needsJump, let jump { native.pendingOffset = map.displayOffset(jump.location) }
            native.setNeedsLayout()
        }
        DispatchQueue.main.async {
            view.layoutIfNeeded()
            coordinator.applying = false
            coordinator.scrollViewDidScroll(view)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: EPUBTextView
        var chapter = -1
        var text = ""
        var fontSize: Double = 0
        var fontFamily: EPUBFontFamily = .serif
        var theme: ReaderTheme = .normal
        var highlights: [EPUBHighlight] = []
        var applying = false
        var lineSpacing: Double = 0
        var horizontalMargin: Double = 0
        var width: CGFloat = 0
        var jump: EPUBTextJump?
        var map = EPUBDisplayMap(imageLocations: [])
        init(_ parent: EPUBTextView) { self.parent = parent }
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            guard case .link(let url) = textItem.content else { return defaultAction }
            return UIAction { [weak self] _ in self?.parent.openLink(url) }
        }
        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !applying else { return }
            let range = textView.selectedRange
            let start = map.sourceOffset(range.location)
            let end = map.sourceOffset(NSMaxRange(range))
            DispatchQueue.main.async { self.parent.selection = NSRange(location: start, length: max(0, end - start)) }
        }
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !applying else { return }
            let maximum = max(0, scrollView.contentSize.height - scrollView.bounds.height)
            parent.fraction = maximum > 0 ? min(1, max(0, scrollView.contentOffset.y / maximum)) : 0
        }
    }
}

private struct EPUBChapterImageView: View {
    let item: EPUBChapterImage
    @State private var image: UIImage?
    @State private var loaded = false
    var body: some View {
        VStack(spacing: 8) {
            if let image { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 800).accessibilityLabel(item.caption.isEmpty ? "Kitap görseli" : item.caption) }
            else if loaded { Label("Bu görsel gösterilemiyor.", systemImage: "photo") }
            else { ProgressView() }
            if !item.caption.isEmpty { Text(item.caption).font(.caption) }
        }
        .task(id: item.fileURL) {
            let url = item.fileURL
            let data = await Task.detached(priority: .utility) { BookCoverPreparation.jpeg(at: url) }.value
            guard !Task.isCancelled else { return }
            image = data.flatMap { UIImage(data: $0) }; loaded = true
        }
    }
}

/// Resize attachments after UIKit assigns the final width, including window resizing.
private final class EPUBNativeTextView: UITextView {
    private var imageWidth: CGFloat = -1
    var pendingFraction: Double?
    var pendingOffset: Int?
    override func layoutSubviews() {
        let width = max(1, bounds.width - textContainerInset.left - textContainerInset.right - textContainer.lineFragmentPadding * 2)
        if abs(imageWidth - width) > 1 {
            imageWidth = width
            textStorage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textStorage.length)) { value, _, _ in
                guard let attachment = value as? NSTextAttachment, let size = attachment.image?.size else { return }
                let scale = min(1, width / max(1, size.width), 800 / max(1, size.height))
                attachment.bounds = CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale)
            }
            layoutManager.invalidateLayout(forCharacterRange: NSRange(location: 0, length: textStorage.length), actualCharacterRange: nil)
        }
        super.layoutSubviews()
        guard window != nil, bounds.width > 0, bounds.height > 0 else { return }
        if pendingFraction != nil || pendingOffset != nil {
            layoutManager.ensureLayout(for: textContainer)
            let fraction = pendingFraction
            let target = pendingOffset
            pendingFraction = nil; pendingOffset = nil
            if let fraction { setContentOffset(CGPoint(x: 0, y: max(0, contentSize.height - bounds.height) * fraction), animated: false) }
            if let target {
                let offset = min(textStorage.length, target)
                scrollRangeToVisible(NSRange(location: offset, length: offset < textStorage.length ? 1 : 0))
            }
        }
    }
}
