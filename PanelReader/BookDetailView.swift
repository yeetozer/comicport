import SwiftUI
import UIKit

struct BookDetailView: View {
    @EnvironmentObject var store: LibraryStore
    let bookID: UUID
    @State private var info: OfflineComicInfo?
    @State private var analyzing = false
    @State private var analysisError: String?
    @State private var confirmFileDelete = false
    @State private var confirmPermanentDelete = false
    @State private var showReader = false
    @State private var showStorageOptimizer = false
    @State private var readerLaunchError: String?
    @State private var showMetadataEditor = false
    @State private var showCoverChooser = false
    @State private var showRepairLab = false
    @State private var showBookLookup = false

    private var book: ComicBook? { store.books.first(where: { $0.id == bookID }) }

    var body: some View {
        Group {
            if let book {
                ScrollView {
                    VStack(spacing: 24) {
                        header(book)
                        readingActions(book)
                        metadataControls(book)
                        if book.contentKind == .book {
                            bibliographyCard(book)
                            if let classic = BundledClassics.catalog.first(where: { $0.id == book.id }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Book Hub Klasikleri", systemImage: "books.vertical").font(.headline)
                                    Text("İngilizce özgün metin · Kamu malı klasik eser").font(.subheadline)
                                    Text("Book Hub için hazırlanmış metin baskısı ve kapak.").font(.caption).foregroundStyle(.secondary)
                                    Link("Kaynak baskı ve eser bilgileri", destination: classic.sourceURL)
                                }.padding().frame(maxWidth: .infinity, alignment: .leading)
                                    .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            }
                        } else {
                            seriesControls(book)
                        }
                        BookSearchIndexCard(book: book)
                        storageControls(book)
                        offlineInfoCard(book)
                    }
                    .padding()
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
                .bookHubSurface(when: book.contentKind == .book)
                .comicHubSurface(when: book.contentKind == .comic && store.activeReaderProfile == .comics)
                .navigationTitle(book.title)
                .navigationBarTitleDisplayMode(.inline)
                .task { loadCachedInfo(book) }
            } else {
                ContentUnavailableView("Book not found", systemImage: "exclamationmark.triangle")
            }
        }
        .fullScreenCover(isPresented: $showReader) {
            ReadingSessionHostView(initialBookID: bookID)
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
        .alert("Could not open comic", isPresented: Binding(
            get: { readerLaunchError != nil },
            set: { if !$0 { readerLaunchError = nil } }
        )) {
            Button("OK", role: .cancel) { readerLaunchError = nil }
        } message: {
            Text(readerLaunchError ?? "")
        }
        .sheet(isPresented: $showStorageOptimizer, onDismiss: restoreWindowTitle) {
            StorageOptimizerView(bookID: bookID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showMetadataEditor, onDismiss: {
            restoreWindowTitle()
            if let book { loadCachedInfo(book) }
        }) {
            if book?.contentKind == .book {
                BookBibliographyEditorView(bookID: bookID).environmentObject(store)
            } else {
                ComicMetadataEditorView(bookID: bookID).environmentObject(store)
            }
        }
        .sheet(isPresented: $showBookLookup, onDismiss: restoreWindowTitle) {
            BookLookupView(bookID: bookID).environmentObject(store)
        }
        .sheet(isPresented: $showCoverChooser, onDismiss: restoreWindowTitle) {
            ComicCoverChooserView(bookID: bookID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showRepairLab, onDismiss: restoreWindowTitle) {
            ComicRepairLabView(bookID: bookID)
                .environmentObject(store)
        }
        .confirmationDialog("Delete the comic file from this device?", isPresented: $confirmFileDelete, titleVisibility: .visible) {
            if let book { Button("Delete File, Keep Data", role: .destructive) { store.deleteFileKeepingData(book) } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your reading history, progress, rating, favorite status, notes and saved information stay in ComicPort.")
        }
        .confirmationDialog("Delete completely?", isPresented: $confirmPermanentDelete, titleVisibility: .visible) {
            if let book { Button("Delete Everything", role: .destructive) { store.permanentlyDelete(book) } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes the file and all saved data associated with this comic.")
        }
        .alert("Offline analysis", isPresented: Binding(get: { analysisError != nil }, set: { if !$0 { analysisError = nil } })) {
            Button("OK", role: .cancel) { analysisError = nil }
        } message: { Text(analysisError ?? "") }
    }

    @ViewBuilder private func header(_ book: ComicBook) -> some View {
        HStack(alignment: .top, spacing: 24) {
            CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, revision: book.coverRevision, maxPixelSize: 700)
            .frame(width: 190, height: 285)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 12) {
                Text(book.title).font(.largeTitle.bold())
                Label(book.contentKind == .book ? "\(book.pageCount) \(book.type == .epub ? "bölüm" : "sayfa")" : "\(book.pageCount) pages", systemImage: "book.pages")
                Label(book.contentKind == .book ? "%\(book.progressPercent) okundu · \(book.type == .epub ? "bölüm" : "sayfa") \(min(book.currentPage + 1, max(1, book.pageCount)))/\(book.pageCount)" : "\(book.progressPercent)% read · page \(min(book.currentPage + 1, max(1, book.pageCount)))/\(book.pageCount)", systemImage: "chart.line.uptrend.xyaxis")
                ProgressView(value: book.progress).frame(maxWidth: 320)
                if let date = book.lastReadAt { Label { Text(book.contentKind == .book ? "Son okuma: " : "Last read ") + Text(date, style: .relative) } icon: { Image(systemName: "clock") } }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func readingActions(_ book: ComicBook) -> some View {
        HStack {
            if book.fileAvailable {
                Button {
                    if let error = store.readerLaunchError(for: book.id) {
                        readerLaunchError = error
                    } else {
                        showReader = true
                    }
                } label: {
                    Label(book.contentKind == .book ? (book.currentPage > 0 || (book.epubState?.scrollFraction ?? 0) > 0 ? "Okumaya devam et" : "Okumaya başla") : (book.currentPage > 0 ? "Continue Reading" : "Start Reading"), systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button { store.updateProgress(id: book.id, page: 0) } label: { Label(book.contentKind == .book ? "Baştan başla" : "Start Over", systemImage: "arrow.counterclockwise") }
                    .buttonStyle(.bordered)
            } else {
                Label(book.contentKind == .book ? "Dosya bu Mac'te değil · aynı kitabı içe aktararak yeniden bağlayabilirsin" : "File is not on this Mac · import the same comic to reconnect", systemImage: "externaldrive.badge.xmark")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func metadataControls(_ book: ComicBook) -> some View {
        HStack(spacing: 16) {
            Button { store.toggleFavorite(id: book.id) } label: { Label(book.contentKind == .book ? (book.favorite ? "Favori" : "Favorilere ekle") : (book.favorite ? "Favorite" : "Add Favorite"), systemImage: book.favorite ? "heart.fill" : "heart") }
            Menu { ForEach(ReadingStatus.allCases) { status in Button(status.label(forBooks: book.contentKind == .book)) { store.setStatus(id: book.id, status: status) } } } label: { Label(book.readingStatus.label(forBooks: book.contentKind == .book), systemImage: book.readingStatus.systemImage) }
            Menu { Button(book.contentKind == .book ? "Puan yok" : "No rating") { store.setRating(id: book.id, rating: 0) }; ForEach(1...5, id: \.self) { n in Button(String(repeating: "★", count: n)) { store.setRating(id: book.id, rating: n) } } } label: { Label(book.rating == 0 ? (book.contentKind == .book ? "Puan ver" : "Rate") : "\(book.rating)/5", systemImage: "star.fill") }
            Divider().frame(height: 20)
            Button { showMetadataEditor = true } label: { Label(book.contentKind == .book ? "Kitap bilgilerini düzenle" : "Edit Metadata", systemImage: "pencil.and.list.clipboard") }
            if book.type != .epub {
                Button { showCoverChooser = true } label: { Label(book.contentKind == .book ? "Kapak seç" : "Choose Cover", systemImage: "photo.on.rectangle") }
                Button { showRepairLab = true } label: { Label(book.type == .pdf ? "Clean PDF" : "Repair CBZ", systemImage: "wand.and.stars") }
            }
            Spacer()
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder private func seriesControls(_ book: ComicBook) -> some View {
        if let series = store.series(for: book.id) {
            let ordered = SeriesService.books(in: series, from: store.libraryBooks)
            let parsed = SeriesService.parse(book.title)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Series & Reading Order", systemImage: "books.vertical.fill")
                        .font(.title2.bold())
                    Spacer()
                    Text("\(ordered.count) issues")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Series", value: series.title)
                if let issue = parsed.issueNumber {
                    LabeledContent("Issue", value: "#\(issue.rounded() == issue ? String(Int(issue)) : String(issue))")
                }
                if let volume = parsed.volume { LabeledContent("Volume", value: String(volume)) }
                if parsed.edition != .standard { LabeledContent("Edition", value: parsed.edition.rawValue) }

                HStack {
                    if let previous = store.previousIssue(before: book.id) {
                        NavigationLink {
                            BookDetailView(bookID: previous.id)
                        } label: {
                            Label("Previous Issue", systemImage: "chevron.left")
                        }
                    }

                    Spacer()

                    if let next = store.nextIssue(after: book.id) {
                        NavigationLink {
                            BookDetailView(bookID: next.id)
                        } label: {
                            Label("Next Issue", systemImage: "chevron.right")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    @ViewBuilder private func storageControls(_ book: ComicBook) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(book.contentKind == .book ? "Kütüphane ve depolama" : "Library & Storage", systemImage: "externaldrive")
                    .font(.title2.bold())
                Spacer()
                if book.fileAvailable && book.type != .epub {
                    Button { showStorageOptimizer = true } label: {
                        Label(book.contentKind == .book ? "Depolamayı optimize et" : "Optimize Storage", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            HStack {
                if book.isArchived {
                    Button { store.unarchive(book) } label: { Label(book.contentKind == .book ? "Arşivden geri al" : "Return from Archive", systemImage: "arrow.uturn.backward") }
                } else {
                    Button { store.archive(book) } label: { Label(book.contentKind == .book ? "Arşivle" : "Archive", systemImage: "archivebox") }
                }

                if book.isInLibrary {
                    Button { store.removeFromLibrary(book) } label: { Label(book.contentKind == .book ? "Kütüphaneden çıkar" : "Remove from Library", systemImage: "books.vertical") }
                } else if book.fileAvailable {
                    Button { store.restoreToLibrary(book) } label: { Label(book.contentKind == .book ? "Kütüphaneye geri al" : "Return to Library", systemImage: "books.vertical.fill") }
                }

                Spacer()
            }
            .buttonStyle(.bordered)

            HStack {
                if book.fileAvailable {
                    Button(role: .destructive) { confirmFileDelete = true } label: {
                        Label(book.contentKind == .book ? "Dosyayı sil, kayıtları koru" : "Delete File, Keep Data", systemImage: "externaldrive.badge.minus")
                    }
                }
                Button(role: .destructive) { confirmPermanentDelete = true } label: {
                    Label(book.contentKind == .book ? "Tamamen sil…" : "Delete Completely…", systemImage: "trash")
                }
                Spacer()
            }
            .buttonStyle(.bordered)

            if !book.fileAvailable {
                Text(book.contentKind == .book ? "Kitap dosyası bu Mac'te değil. Okuma geçmişi, ilerleme, puan, favoriler, notlar ve çevrimdışı bilgiler korunuyor." : "The comic file is not on this Mac. Its reading history, progress, rating, favorites, notes and offline information are still saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func bibliographyCard(_ book: ComicBook) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Kitap bilgileri", systemImage: "text.book.closed")
                .font(.title2.bold())
            Button("ISBN ile bilgi ve kapak bul", systemImage: "magnifyingglass") { showBookLookup = true }
            if let metadata = book.bookMetadata {
                bibliographyRow("Yazarlar", value: metadata.authors.isEmpty ? nil : metadata.authors.joined(separator: ", "), source: metadata.sources["authors"])
                bibliographyRow("Yayınevi", value: metadata.publisher, source: metadata.sources["publisher"])
                bibliographyRow("Yayın yılı", value: metadata.publicationYear, source: metadata.sources["publicationYear"])
                bibliographyRow("ISBN", value: metadata.isbn, source: metadata.sources["isbn"])
                bibliographyRow("Dil", value: metadata.language, source: metadata.sources["language"])
            } else {
                Text("Kitap bilgilerini düzenleyebilir veya aşağıdan yerel analiz başlatabilirsin.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func bibliographyRow(_ title: String, value: String?, source: BookMetadataSource?) -> some View {
        HStack(alignment: .top) {
            Text(title).foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
            Text(value ?? "Eklenmedi").frame(maxWidth: .infinity, alignment: .leading)
            if value != nil, let source {
                Text(source.label)
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func offlineInfoCard(_ book: ComicBook) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(book.contentKind == .book ? "Kitap analizi · Çevrimdışı" : "Book Info · Offline", systemImage: "internaldrive")
                    .font(.title2.bold())
                Spacer()
                Button { analyze(book, force: true) } label: { Label(book.contentKind == .book ? (info == nil ? "Analiz et" : "Yeniden analiz et") : (info == nil ? "Analyze" : "Analyze Again"), systemImage: "viewfinder") }
                    .buttonStyle(.borderedProminent)
                    .disabled(analyzing || !book.fileAvailable)
            }

            if analyzing {
                HStack { ProgressView(); Text(book.type == .epub ? "EPUB paketindeki kitap bilgileri okunuyor…" : (book.contentKind == .book ? "Kitap bilgileri ve ilk sayfalar bu Mac'te inceleniyor…" : "Reading metadata and scanning the first pages locally on this Mac…")).foregroundStyle(.secondary) }
            } else if let info {
                HStack {
                    LabeledContent(book.contentKind == .book ? "Bulunan başlık" : "Detected title", value: info.displayTitle)
                    if book.contentKind == .book {
                        Text(info.titleSource?.label ?? "Tahmini")
                            .font(.caption2.bold()).padding(6)
                            .background(.orange.opacity(0.16), in: Capsule())
                    } else if let authority = info.metadataAuthority {
                        Text(authority.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                authority == .verified ? Color.green.opacity(0.16) : Color.orange.opacity(0.16),
                                in: Capsule()
                            )
                    }
                }
                if info.comicInfoPresent == true {
                    Label("ComicInfo.xml metadata", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                if let series = info.series { LabeledContent("Series", value: series) }
                if let issue = info.issue { LabeledContent("Issue", value: "#\(issue)") }
                if let year = info.year { LabeledContent(book.contentKind == .book ? "Yayın yılı" : "Year", value: year) }
                if let volume = info.volume { LabeledContent("Volume", value: String(volume)) }
                if let publisher = info.publisher { LabeledContent(book.contentKind == .book ? "Yayınevi" : "Publisher", value: publisher) }
                if let imprint = info.imprint { LabeledContent("Imprint", value: imprint) }
                if let language = info.languageISO { LabeledContent(book.contentKind == .book ? "Dil" : "Language", value: language) }
                if let format = info.format { LabeledContent("Format", value: format) }
                if let storyArc = info.storyArc { LabeledContent("Story Arc", value: storyArc) }
                if !info.creators.isEmpty { LabeledContent(book.contentKind == .book ? "Yazarlar" : "Creators", value: info.creators.joined(separator: ", ")) }
                if let characters = info.characters, !characters.isEmpty {
                    LabeledContent("Characters", value: characters.joined(separator: ", "))
                }
                if let genres = info.genres, !genres.isEmpty {
                    LabeledContent("Genres", value: genres.joined(separator: ", "))
                }
                LabeledContent(book.contentKind == .book ? "Dosya" : "File", value: "\(info.fileType) · \(info.pageCount) \(book.type == .epub ? "bölüm" : (book.contentKind == .book ? "sayfa" : "pages"))")

                if let match = info.databaseMatch {
                    Divider()
                    HStack {
                        Label("Local catalog match", systemImage: "internaldrive")
                            .font(.headline)
                        Spacer()
                        if let confidence = info.databaseConfidence {
                            Text("\(confidence)% match")
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    LabeledContent("Catalog title", value: match.title)
                    LabeledContent("Publisher", value: match.publisher)
                    if let year = match.year { LabeledContent("First published", value: String(year)) }
                    if !match.creators.isEmpty { LabeledContent("Known creators", value: match.creators.joined(separator: ", ")) }
                    if !match.characters.isEmpty {
                        Text("Characters").font(.subheadline.bold())
                        Text(match.characters.joined(separator: " · ")).foregroundStyle(.secondary)
                    }
                    if !match.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(match.tags, id: \.self) { tag in Text(tag).font(.caption).padding(.horizontal, 9).padding(.vertical, 5).background(.quaternary, in: Capsule()) } }
                        }
                    }
                }

                Divider()
                Text(book.contentKind == .book ? "Yerel özet" : "Local summary").font(.headline)
                Text(info.summary).textSelection(.enabled)

                if !info.detectedText.isEmpty {
                    DisclosureGroup(book.contentKind == .book ? "Kapakta ve ilk sayfalarda bulunan metin" : "Text detected on cover / first pages") {
                        Text(info.detectedText).font(.callout.monospaced()).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                    }
                }

                Text(info.confidenceNote).font(.caption).foregroundStyle(.secondary)
            } else {
                ContentUnavailableView(book.contentKind == .book ? "Henüz analiz edilmedi" : "Not analyzed yet", systemImage: "text.viewfinder", description: Text(book.contentKind == .book ? "Analiz et düğmesine bas. Kitap bilgileri ve metinler bu cihazda incelenir; dosya internete gönderilmez." : "Tap Analyze. The comic stays on your Mac; ComicInfo.xml, OCR and local matching use no API or web service."))
            }
        }
        .padding()
        .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func loadCachedInfo(_ book: ComicBook) {
        if let cached = store.loadOfflineInfo(bookID: book.id) { info = cached }
    }

    private func restoreWindowTitle() {
        #if targetEnvironment(macCatalyst)
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.title = "ComicPort"
        }
        #endif
    }

    private func analyze(_ book: ComicBook, force: Bool) {
        if !force, let cached = store.loadOfflineInfo(bookID: book.id) { info = cached; return }
        analyzing = true
        analysisError = nil
        Task {
            do {
                let result = try await BookMetadataIntelligence.shared.analyze(book: book, fileURL: store.fileURL(for: book), force: force)
                await MainActor.run {
                    store.saveOfflineInfo(result, bookID: book.id)
                    info = store.loadOfflineInfo(bookID: book.id) ?? result
                    analyzing = false
                }
            } catch {
                await MainActor.run { analysisError = error.localizedDescription; analyzing = false }
            }
        }
    }
}


// MARK: - Stage 20.4 Library Power Tools

private struct ComicMetadataEditorView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID

    @State private var title = ""
    @State private var series = ""
    @State private var issue = ""
    @State private var year = ""
    @State private var publisher = ""
    @State private var creators = ""
    @State private var summary = ""
    @State private var writeComicInfo = true
    @State private var status: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Title", text: $title)
                    TextField("Series", text: $series)
                    TextField("Issue", text: $issue)
                    TextField("Year", text: $year)
                    TextField("Publisher", text: $publisher)
                }.comicHubRowSurface()
                Section("Creators") {
                    TextField("Comma-separated creators", text: $creators, axis: .vertical)
                }.comicHubRowSurface()
                Section("Summary") {
                    TextField("Summary", text: $summary, axis: .vertical)
                        .lineLimit(4...10)
                }.comicHubRowSurface()
                Section("ComicInfo.xml") {
                    Toggle("Write metadata into the archive", isOn: $writeComicInfo)
                    Text("For archive comics, write-back creates a normalized CBZ and preserves page images. PDF metadata remains local unless you convert it to CBZ in Repair Lab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }.comicHubRowSurface()
                if let status {
                    Section { Text(status).font(.caption).foregroundStyle(.secondary) }.comicHubRowSurface()
                }
            }
            .comicHubSurface().navigationTitle("Edit Metadata")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") {
                        saving = true
                        Task {
                            status = await store.saveEditedMetadata(
                                bookID: bookID,
                                title: title,
                                series: series,
                                issue: issue,
                                year: year,
                                publisher: publisher,
                                creators: creators,
                                summary: summary,
                                writeComicInfo: writeComicInfo
                            )
                            saving = false
                        }
                    }
                    .disabled(saving)
                }
            }
            .task { load() }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 620, idealWidth: 700, minHeight: 620)
        #endif
    }

    private func load() {
        guard let book = store.books.first(where: { $0.id == bookID }) else { return }
        let info = store.loadOfflineInfo(bookID: bookID)
        title = info?.displayTitle ?? book.title
        series = info?.series ?? SeriesService.parse(book.title).seriesTitle
        issue = info?.issue ?? ""
        year = info?.year ?? ""
        publisher = info?.publisher ?? ""
        creators = info?.creators.joined(separator: ", ") ?? ""
        summary = info?.summary ?? ""
        writeComicInfo = book.type == .cbz
    }
}

private struct ComicCoverChooserView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    @State private var page = 0
    @State private var preview: UIImage?
    @State private var loading = false
    @State private var saving = false

    private var book: ComicBook? { store.books.first { $0.id == bookID } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let preview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 480)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else if loading {
                    ProgressView().controlSize(.large)
                }

                if let book {
                    HStack {
                        Text("Page \(page + 1)").monospacedDigit()
                        Slider(
                            value: Binding(
                                get: { Double(page) },
                                set: { page = Int($0.rounded()) }
                            ),
                            in: 0...Double(max(1, book.pageCount - 1)),
                            step: 1
                        )
                        Text("\(book.pageCount)").monospacedDigit()
                    }
                }
            }
            .padding(22)
            .bookHubSurface(when: store.activeReaderProfile == .books)
            .comicHubSurface().navigationTitle("Choose Cover")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Use This Page") {
                        saving = true
                        Task {
                            if await store.setCover(bookID: bookID, page: page) { dismiss() }
                            saving = false
                        }
                    }
                    .disabled(saving || preview == nil)
                }
            }
            .task(id: page) { await loadPreview() }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 560, minHeight: 650)
        #endif
    }

    private func loadPreview() async {
        guard let book else { return }
        loading = true
        preview = nil
        let data = await ReaderPageSnapshotService.loadSnapshot(
            fileURL: store.fileURL(for: book),
            type: book.type,
            page: page,
            settings: store.readerSettings(for: book.id),
            maxPixel: 1200
        )
        if !Task.isCancelled { preview = data.flatMap(UIImage.init(data:)); loading = false }
    }
}

private struct ComicRepairLabView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID

    @State private var preview: ComicRepairPreview?
    @State private var removeBlankPages = true
    @State private var topCrop = 0.045
    @State private var bottomCrop = 0.065
    @State private var working = false
    @State private var status: String?

    private var book: ComicBook? { store.books.first { $0.id == bookID } }

    var body: some View {
        NavigationStack {
            Form {
                if let book, book.type == .pdf {
                    Section("PDF Cleaner Preview") {
                        if let preview {
                            LabeledContent("Pages", value: "\(preview.pageCount)")
                            LabeledContent("Likely blank", value: "\(preview.likelyBlankPages.count)")
                            if !preview.likelyBlankPages.isEmpty {
                                Text("Detected pages: " + preview.likelyBlankPages.prefix(24).map { String($0 + 1) }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView("Inspecting PDF locally…")
                        }
                    }.comicHubRowSurface()
                    Section("Cleanup") {
                        Toggle("Remove likely blank pages", isOn: $removeBlankPages)
                        LabeledContent("Crop top", value: "\(Int(topCrop * 100))%")
                        Slider(value: $topCrop, in: 0...0.12, step: 0.005)
                        LabeledContent("Crop bottom", value: "\(Int(bottomCrop * 100))%")
                        Slider(value: $bottomCrop, in: 0...0.14, step: 0.005)
                    }.comicHubRowSurface()
                    Section {
                        Button {
                            working = true
                            Task {
                                status = await store.createCleanCBZ(
                                    bookID: bookID,
                                    removeBlankPages: removeBlankPages,
                                    topCrop: topCrop,
                                    bottomCrop: bottomCrop
                                )
                                working = false
                            }
                        } label: {
                            Label(working ? "Converting…" : "Create Clean CBZ", systemImage: "sparkles.rectangle.stack")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(working)
                        Text("Original PDF is never rewritten. ComicPort creates a new CBZ with clean page images and ComicInfo.xml.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }.comicHubRowSurface()
                } else {
                    Section("CBZ Repair") {
                        Text("Rebuild this archive in natural page order (0001, 0002, …), preserve page images and ComicInfo.xml when available, and create a new CBZ copy.")
                            .foregroundStyle(.secondary)
                        Button {
                            working = true
                            Task {
                                status = await store.repairArchive(bookID: bookID)
                                working = false
                            }
                        } label: {
                            Label(working ? "Repairing…" : "Create Repaired CBZ", systemImage: "wrench.adjustable")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(working)
                    }.comicHubRowSurface()
                }
                if let status { Section("Result") { Text(status) }.comicHubRowSurface() }
            }
            .comicHubSurface().navigationTitle("Cleaner & Repair Lab")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { await inspectIfNeeded() }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 620, minHeight: 600)
        #endif
    }

    private func inspectIfNeeded() async {
        guard let book, book.type == .pdf else { return }
        let url = store.fileURL(for: book)
        preview = try? await Task.detached(priority: .utility) {
            try ComicRepairService.inspectPDF(url)
        }.value
        if let preview { topCrop = preview.suggestedTopCrop; bottomCrop = preview.suggestedBottomCrop }
    }
}

private struct BookBibliographyEditorView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    @State private var title = ""
    @State private var authors = ""
    @State private var publisher = ""
    @State private var year = ""
    @State private var isbn = ""
    @State private var language = ""
    @State private var summary = ""
    @State private var saving = false
    @State private var error: String?

    private var isbnInvalid: Bool {
        !isbn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && BookISBN.normalized(isbn) == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kitap") {
                    TextField("Kitap adı", text: $title)
                    TextField("Yazarlar (virgülle ayır)", text: $authors)
                    TextField("Yayınevi", text: $publisher)
                    TextField("Yayın yılı", text: $year)
                    TextField("ISBN-10 veya ISBN-13", text: $isbn)
                    if isbnInvalid {
                        Text("ISBN numarasını kontrol et. Boş bırakabilir veya geçerli bir ISBN-10/13 girebilirsin.")
                            .font(.caption).foregroundStyle(.red)
                    }
                    TextField("Dil (ör. tr, en)", text: $language)
                }.listRowBackground(BookHubPalette.surface)
                Section("Özet") {
                    TextField("Kitap özeti", text: $summary, axis: .vertical).lineLimit(4...10)
                }.listRowBackground(BookHubPalette.surface)
                Section {
                    Text("Bilgiler bu cihazda saklanır. Elle girdiğin alanlar yeniden analiz sırasında korunur.")
                        .font(.caption).foregroundStyle(.secondary)
                    if let error { Text(error).foregroundStyle(.red) }
                }.listRowBackground(BookHubPalette.surface)
            }
            .bookHubSurface()
            .comicHubSurface().navigationTitle("Kitap bilgileri")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Kaydediliyor…" : "Kaydet") {
                        saving = true
                        Task {
                            let result = await store.saveEditedMetadata(bookID: bookID, title: title, series: "", issue: "", year: year, publisher: publisher, creators: authors, summary: summary, writeComicInfo: false, isbn: isbn, language: language)
                            saving = false
                            if result == "Metadata saved locally." { dismiss() } else { error = result }
                        }
                    }
                    .disabled(saving || isbnInvalid || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task {
                guard let book = store.books.first(where: { $0.id == bookID }) else { return }
                let info = store.loadOfflineInfo(bookID: bookID)
                let metadata = book.bookMetadata
                title = metadata?.title ?? info?.displayTitle ?? book.title
                authors = (metadata?.authors ?? info?.creators ?? []).joined(separator: ", ")
                publisher = metadata?.publisher ?? info?.publisher ?? ""
                year = metadata?.publicationYear ?? info?.year ?? ""
                isbn = metadata?.isbn ?? ""
                language = metadata?.language ?? info?.languageISO ?? ""
                summary = metadata?.summary ?? info?.summary ?? ""
            }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 620, idealWidth: 700, minHeight: 620)
        #endif
    }
}
