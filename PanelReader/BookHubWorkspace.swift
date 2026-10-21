import SwiftUI
import UniformTypeIdentifiers

struct BookHubGoalsView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var daily = 20
    @State private var annual = 12
    @State private var enabled = false
    @State private var saved = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Okuma hedeflerin") {
                    Toggle("Kitap hedeflerini etkinleştir", isOn: $enabled)
                    Stepper("Günlük hedef: \(daily) dakika", value: $daily, in: 1...240)
                    Stepper("Yıllık hedef: \(annual) kitap", value: $annual, in: 1...1000)
                    Button("Hedefleri kaydet") { store.setBookHubGoals(dailyMinutes: daily, annualBooks: annual, enabled: enabled); saved = true }
                    if saved { Text("Hedeflerin kaydedildi.").foregroundStyle(.secondary) }
                }.listRowBackground(BookHubPalette.surface)
                Section("İlerlemen") {
                    BookHubGoalCard()
                    Text("Süre, kitap okuyucusunu kapattığında güncellenir. Yıllık hedef aynı kitabı bir yılda bir kez sayar. Eski kitapların tamamlanma tarihi bilinmiyorsa yıl hedefinde sayılmaz; okuma günlüğündeki tarihli kayıtlar dahil edilir.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Tamamlanan günlük hedef: \(store.bookHub.reachedDailyGoals.count)")
                }.listRowBackground(BookHubPalette.surface)
            }
            .bookHubSurface()
            .navigationTitle("Okuma Hedefleri")
            .onAppear { daily = store.bookHub.goals.dailyMinutes; annual = store.bookHub.goals.annualBooks; enabled = store.bookHub.goals.enabled }
            .onChange(of: daily) { _, _ in saved = false }
            .onChange(of: annual) { _, _ in saved = false }
            .onChange(of: enabled) { _, _ in saved = false }
        }
    }
}

struct BookHubGoalCard: View {
    @EnvironmentObject var store: LibraryStore
    var body: some View {
        let goals = store.bookHub.goals
        let progress = store.bookHubGoalProgress
        VStack(alignment: .leading, spacing: 12) {
            Text("Okuma hedeflerin").font(.headline)
            if goals.enabled {
                Text("Bugün \(Int(progress.todaySeconds / 60)) / \(goals.dailyMinutes) dakika")
                ProgressView(value: min(1, progress.todaySeconds / Double(max(1, goals.dailyMinutes) * 60)))
                Text("\(String(progress.year)): \(progress.completedThisYear) / \(goals.annualBooks) kitap")
                ProgressView(value: min(1, Double(progress.completedThisYear) / Double(max(1, goals.annualBooks))))
            } else { Text("Kendine günlük dakika ve yıllık kitap hedefi belirle.").foregroundStyle(.secondary) }
        }.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.brown.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct BookHubTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws { text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(text.utf8)) }
}

struct BookHubQuotesView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var query = ""
    @State private var author = ""
    @State private var selectedBook: UUID?
    @State private var kind = 0
    @State private var export = false
    @State private var exportDocument = BookHubTextDocument(text: "")
    @State private var message: String?
    @State private var editing: BookHubExcerpt?
    @State private var activeBook: BookHubBookRoute?

    private func filtered(_ entries: [BookHubExcerpt]) -> [BookHubExcerpt] {
        let words = BookLibraryQuery.fold(query).split(whereSeparator: \.isWhitespace)
        return entries.filter { entry in
            let content = BookLibraryQuery.fold(([entry.title, entry.text] + entry.authors).joined(separator: " "))
            return (selectedBook == nil || selectedBook == entry.bookID) && (author.isEmpty || entry.authors.contains(author)) &&
                (kind == 0 || (kind == 1 ? entry.isHighlight : !entry.isHighlight)) && words.allSatisfy { content.contains($0) }
        }
    }
    var body: some View {
        let all = store.bookHubExcerpts
        let entries = filtered(all)
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    TextField("Alıntı, kitap veya yazar ara…", text: $query).textFieldStyle(.roundedBorder)
                    Button("Dışa aktar") { exportDocument = BookHubTextDocument(text: BookHubExcerpt.markdown(entries)); export = true }.disabled(entries.isEmpty)
                }.padding(.horizontal)
                HStack {
                    Picker("Kitap", selection: $selectedBook) {
                        Text("Tüm kitaplar").tag(Optional<UUID>.none)
                        ForEach(store.books.filter { $0.contentKind == .book }.sorted { $0.title < $1.title }) { Text($0.title).tag(Optional($0.id)) }
                    }
                    Picker("Yazar", selection: $author) {
                        Text("Tüm yazarlar").tag("")
                        ForEach(Array(Set(all.flatMap(\.authors))).sorted(), id: \.self) { Text($0).tag($0) }
                    }
                    Picker("İçerik", selection: $kind) { Text("Tümü").tag(0); Text("Alıntılar").tag(1); Text("Notlar").tag(2) }.pickerStyle(.segmented)
                }.padding(.horizontal)
                Text("\(entries.count) alıntı / not").font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                if entries.isEmpty {
                    ContentUnavailableView(all.isEmpty ? "Defterin henüz boş" : "Eşleşen alıntı veya not yok", systemImage: "quote.bubble", description: Text("EPUB okuyucusunda metin işaretle veya bir kitap sayfasına not ekle. Arşivlenen kitapların notları da burada korunur."))
                } else {
                    List(entries) { entry in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(entry.text).textSelection(.enabled)
                            Text("\(entry.title) · \(entry.locationLabel)").font(.caption.bold())
                            if !entry.authors.isEmpty { Text(entry.authors.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary) }
                            HStack {
                                Button("Kitapta aç") {
                                    if let error = store.readerLaunchError(for: entry.bookID) { message = error }
                                    else { store.setBookHubExcerptPosition(bookID: entry.bookID, page: entry.page); activeBook = BookHubBookRoute(id: entry.bookID) }
                                }
                                if !entry.isHighlight { Button("Notu düzenle") { editing = entry } }
                            }.buttonStyle(.bordered)
                        }.padding(.vertical, 8).listRowBackground(BookHubPalette.surface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .bookHubSurface()
            .navigationTitle("Alıntı Defteri")
            .fileExporter(isPresented: $export, document: exportDocument, contentType: .plainText, defaultFilename: "Book-Hub-Alintilar.md") { result in
                if case .failure(let error) = result { message = error.localizedDescription }
            }
            .alert("Alıntı Defteri", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("Tamam") { message = nil } } message: { Text(message ?? "") }
            .sheet(item: $editing) { entry in BookHubNoteEditor(entry: entry) }
            .fullScreenCover(item: $activeBook) { route in ReadingSessionHostView(initialBookID: route.id).environmentObject(store) }
        }
    }
}

private struct BookHubBookRoute: Identifiable { let id: UUID }
private struct BookHubNoteEditor: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let entry: BookHubExcerpt
    @State private var text = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(entry.title) · \(entry.locationLabel)").font(.headline)
            TextEditor(text: $text).scrollContentBackground(.hidden).background(BookHubPalette.surface).frame(minHeight: 240)
            HStack { Button("Vazgeç") { dismiss() }; Spacer(); Button("Kaydet") { store.saveTextNote(bookID: entry.bookID, page: entry.page, text: text); dismiss() } }
        }.padding().frame(minWidth: 450, minHeight: 340).bookHubSurface().onAppear { text = entry.text }
    }
}

struct BookHubShelvesView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var editing: BookHubCollection?
    @State private var removal: BookHubCollection?
    var body: some View {
        let books = store.books.filter { $0.contentKind == .book }
        let progress = store.bookHubGoalProgress
        let annotated = Set(store.bookHubExcerpts.map(\.bookID))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Kitapların, kendi raflarında.")
                        .font(.system(.title3, design: .serif)).foregroundStyle(.secondary)
                    Text("Akıllı raflar").font(.system(.title2, design: .serif, weight: .semibold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 18)], spacing: 18) {
                        ForEach(BookHubSmartShelf.allCases) { shelf in
                            let matches = shelf.books(from: books, completedIDs: progress.completedBookIDs, annotatedIDs: annotated)
                            NavigationLink {
                                BookHubShelfBooksView(title: shelf.rawValue, bookIDs: Set(matches.map(\.id)))
                            } label: { BookHubShelfPanel(title: shelf.rawValue, icon: "books.vertical", books: matches) }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("Uzun süredir açmadıklarım: okunuyor durumunda olup 30 gündür açılmayan kitaplar.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Text("Kişisel koleksiyonlar").font(.system(.title2, design: .serif, weight: .semibold))
                        Spacer()
                        Button("Yeni koleksiyon", systemImage: "plus") { editing = BookHubCollection(name: "") }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 18)], spacing: 18) {
                        ForEach(store.bookHub.collections) { collection in
                            let available = books.filter { collection.bookIDs.contains($0.id) && $0.isInLibrary && !$0.isArchived }
                            VStack(alignment: .leading, spacing: 10) {
                                NavigationLink {
                                    BookHubShelfBooksView(title: collection.name, bookIDs: collection.bookIDs)
                                } label: { BookHubShelfPanel(title: collection.name, icon: "books.vertical", books: available) }
                                .buttonStyle(.plain)
                                HStack {
                                    Button("Düzenle") { editing = collection }
                                    Spacer()
                                    Button("Koleksiyonu kaldır") { removal = collection }
                                }.font(.caption).buttonStyle(.bordered)
                            }
                        }
                    }
                    if store.bookHub.collections.isEmpty {
                        ContentUnavailableView("İlk kişisel rafını oluştur", systemImage: "books.vertical", description: Text("Klasikler, fantastik veya sevdiğin başka bir başlık altında kitaplarını bir araya getir."))
                    }
                }.padding(24)
            }
            .bookHubSurface()
            .navigationTitle("Kitap Raflarım")
            .sheet(item: $editing) { collection in BookHubCollectionEditor(collection: collection) }
            .alert("Koleksiyon kaldırılsın mı?", isPresented: Binding(get: { removal != nil }, set: { if !$0 { removal = nil } })) {
                Button("Vazgeç", role: .cancel) { removal = nil }
                Button("Kaldır", role: .destructive) { if let collection = removal { store.removeBookHubCollection(collection.id) }; removal = nil }
            } message: { Text("Kitaplar ve okuma kayıtları korunur. Koleksiyonu yeniden oluşturabilirsin.") }
        }
    }
}

private struct BookHubShelfBooksView: View {
    @EnvironmentObject var store: LibraryStore
    let title: String
    let bookIDs: Set<UUID>
    var body: some View {
        let books = store.books.filter { bookIDs.contains($0.id) && $0.contentKind == .book && $0.isInLibrary && !$0.isArchived }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 24)], alignment: .leading, spacing: 28) {
                ForEach(books) { book in
                    NavigationLink { BookDetailView(bookID: book.id) } label: {
                        VStack(alignment: .leading, spacing: 9) {
                            CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, revision: book.coverRevision, maxPixelSize: 360)
                                .frame(height: 210).frame(maxWidth: .infinity)
                                .shadow(color: .black.opacity(0.4), radius: 8, y: 6)
                            Rectangle().fill(Color(red: 0.42, green: 0.27, blue: 0.14)).frame(height: 7)
                            Text(book.title).font(.system(.callout, design: .serif, weight: .semibold)).lineLimit(2)
                            Text((book.bookMetadata?.authors ?? []).joined(separator: ", ")).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            Text(book.readingStatus.label(forBooks: true)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(24)
            if books.isEmpty { ContentUnavailableView("Raf henüz boş", systemImage: "books.vertical", description: Text("Kitap ekledikçe bu raf güncellenir.")) }
        }.bookHubSurface().navigationTitle(title)
    }
}

private struct BookHubBookRow: View {
    let book: ComicBook
    var body: some View {
        NavigationLink { BookDetailView(bookID: book.id) } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                Text((book.bookMetadata?.authors ?? []).joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                Text(book.readingStatus.label(forBooks: true)).font(.caption)
            }
        }
    }
}

private struct BookHubCollectionEditor: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let collection: BookHubCollection
    @State private var name = ""
    @State private var query = ""
    @State private var selected: Set<UUID> = []
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Koleksiyon adı", text: $name).textFieldStyle(.roundedBorder).padding(.horizontal)
                TextField("Kitap ara…", text: $query).textFieldStyle(.roundedBorder).padding(.horizontal)
                Text("\(selected.count) kitap seçildi").font(.caption)
                let filter = BookLibraryQuery(query)
                List(store.books.filter { $0.contentKind == .book && $0.isInLibrary && !$0.isArchived && filter.matches($0) }.sorted { $0.title < $1.title }) { book in
                    Toggle(book.title, isOn: Binding(get: { selected.contains(book.id) }, set: { if $0 { selected.insert(book.id) } else { selected.remove(book.id) } })).listRowBackground(BookHubPalette.surface)
                }
            }
            .bookHubSurface()
            .navigationTitle("Koleksiyon düzenle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Kaydet") { store.saveBookHubCollection(id: collection.id, name: name, bookIDs: selected); dismiss() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .onAppear { name = collection.name; selected = collection.bookIDs }
        }.frame(minWidth: 500, minHeight: 500)
    }
}

struct BookHubMaintenanceView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var missingCovers: Set<UUID> = []
    @State private var missingFiles: Set<UUID> = []
    @State private var duplicates: [[ComicBook]] = []
    @State private var scanning = true
    @State private var scanCount = 0
    private var books: [ComicBook] { store.books.filter { $0.contentKind == .book && !$0.isArchived && ($0.isInLibrary || !$0.fileAvailable) } }
    private var revision: Int {
        var hash = Hasher()
        for book in books { hash.combine(book.id); hash.combine(book.coverRevision); hash.combine(book.title); hash.combine(book.bookMetadata); hash.combine(book.fileAvailable) }
        hash.combine(scanCount)
        return hash.finalize()
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Adayları incele, kitap ayrıntısından kapak ve bilgileri düzenle. Aynı ISBN farklı dosya biçimlerinde bulunabilir; yinelenen adaylar otomatik silinmez.").font(.callout).foregroundStyle(.secondary)
                    Button("Yeniden tara", systemImage: "arrow.clockwise") { scanCount += 1 }.disabled(scanning)
                    if scanning { ProgressView("Kapaklar ve dosyalar kontrol ediliyor…") }
                }.listRowBackground(BookHubPalette.surface)
                Section("Kapak eksik · \(missingCovers.count)") {
                    ForEach(books.filter { missingCovers.contains($0.id) }) { book in BookHubBookRow(book: book) }
                    if missingCovers.isEmpty && !scanning { Text("Eksik kapak yok.") }
                }.listRowBackground(BookHubPalette.surface)
                Section("Dosya bulunamadı · \(missingFiles.count)") {
                    ForEach(books.filter { missingFiles.contains($0.id) }) { book in BookHubBookRow(book: book) }
                    if missingFiles.isEmpty && !scanning { Text("Kitap dosyaları erişilebilir.") }
                }.listRowBackground(BookHubPalette.surface)
                ForEach(BookMetadataReviewField.allCases) { field in
                    let matches = books.filter { field.needsReview($0) }
                    Section("\(field.rawValue) · \(matches.count)") {
                        NavigationLink("Kitapları incele") { BookHubShelfBooksView(title: field.rawValue, bookIDs: Set(matches.map(\.id))) }
                    }.listRowBackground(BookHubPalette.surface)
                }.listRowBackground(BookHubPalette.surface)
                Section("Yinelenen adaylar · \(duplicates.count) grup") {
                    ForEach(Array(duplicates.enumerated()), id: \.offset) { index, group in
                        NavigationLink("\(group[0].title) · \(group.count) kayıt") { BookHubShelfBooksView(title: "Yinelenen adaylar", bookIDs: Set(group.map(\.id))) }
                    }.listRowBackground(BookHubPalette.surface)
                    if duplicates.isEmpty && !scanning { Text("Yinelenen aday bulunmadı.") }
                }.listRowBackground(BookHubPalette.surface)
            }.bookHubSurface()
            .navigationTitle("Kitap Bakımı")
            .task(id: revision) {
                scanning = true
                let snapshot = books
                let covers = store.coversURL
                let files = store.booksURL
                let result = await Task.detached(priority: .utility) {
                    var missingCovers: Set<UUID> = []
                    var missingFiles: Set<UUID> = []
                    let fm = FileManager.default
                    for book in snapshot {
                        if let name = book.thumbnailFileName, fm.fileExists(atPath: covers.appendingPathComponent(name).path) {} else { missingCovers.insert(book.id) }
                        if !fm.fileExists(atPath: files.appendingPathComponent(book.storedFileName).path) { missingFiles.insert(book.id) }
                    }
                    return (missingCovers, missingFiles, BookHubMaintenance.duplicateGroups(in: snapshot))
                }.value
                guard !Task.isCancelled else { return }
                missingCovers = result.0; missingFiles = result.1; duplicates = result.2; scanning = false
            }
        }
    }
}

/// A shared surface for Book Hub navigation, forms and sheets.
/// Apply to the content inside NavigationStack so system scroll backgrounds cannot cover it.
enum BookHubPalette {
    static let canvas = Color(red: 0.145, green: 0.095, blue: 0.060)
    static let surface = Color(red: 0.225, green: 0.150, blue: 0.095)
}

private struct BookHubSurfaceModifier: ViewModifier {
    let enabled: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if enabled {
            content
                .scrollContentBackground(.hidden)
                .background(BookHubPalette.canvas.ignoresSafeArea())
                .toolbarBackground(BookHubPalette.canvas, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .presentationBackground(BookHubPalette.canvas)
        } else {
            content
        }
    }
}

extension View {
    func bookHubSurface(when enabled: Bool = true) -> some View {
        modifier(BookHubSurfaceModifier(enabled: enabled))
    }
}
