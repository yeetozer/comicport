import SwiftUI

struct SeriesLibraryView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var query = ""
    @State private var cachedSeries: [ComicSeries] = []

    private var signature: String {
        store.libraryBooks.map { "\($0.id)|\($0.title)|\($0.readingStatus.rawValue)" }.joined(separator: ";")
    }

    private var filtered: [ComicSeries] {
        guard !query.isEmpty else { return cachedSeries }
        return cachedSeries.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        query.isEmpty ? "No series detected yet" : "No matching series",
                        systemImage: "books.vertical",
                        description: Text("Files such as Nightwing #1, #2 and #3 are grouped automatically.")
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 18)], spacing: 18) {
                        ForEach(filtered) { series in
                            NavigationLink {
                                SeriesDetailView(series: series)
                            } label: {
                                SeriesCard(series: series)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Series")
            .searchable(text: $query, prompt: "Search series")
            .task(id: signature) {
                cachedSeries = SeriesService.series(from: store.libraryBooks)
            }
        }
    }
}

private struct SeriesCard: View {
    @EnvironmentObject var store: LibraryStore
    let series: ComicSeries

    private var books: [ComicBook] {
        SeriesService.books(in: series, from: store.libraryBooks)
    }

    private var completed: Int { books.filter { $0.readingStatus == .completed }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                if let book = books.first {
                    CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, maxPixelSize: 620)
                } else {
                    Rectangle().fill(.quaternary)
                }

                LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .center, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ComicDisplayTitle.series(series.title))
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text("\(ComicDisplayTitle.issues(books.count)) • \(completed) completed")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                }
                .padding(14)
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            ProgressView(value: books.isEmpty ? 0 : Double(completed) / Double(books.count))
        }
    }
}

struct SeriesDetailView: View {
    @EnvironmentObject var store: LibraryStore
    let series: ComicSeries

    private var books: [ComicBook] {
        SeriesService.books(in: series, from: store.libraryBooks)
    }

    private var completed: Int { books.filter { $0.readingStatus == .completed }.count }
    private var nextUnread: ComicBook? { books.first { $0.readingStatus != .completed && $0.fileAvailable } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ComicDisplayTitle.series(series.title)).font(.largeTitle.bold())
                        Text("\(ComicDisplayTitle.issues(books.count)) • \(completed) completed • \(max(0, books.count - completed)) remaining")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let nextUnread {
                        NavigationLink {
                            BookDetailView(bookID: nextUnread.id)
                        } label: {
                            Label("Continue Series", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                ProgressView(value: books.isEmpty ? 0 : Double(completed) / Double(books.count))

                SeriesReadingOrder2Card(series: series)

                if !series.editions.isEmpty {
                    HStack {
                        ForEach(Array(series.editions).sorted { $0.rawValue < $1.rawValue }) { edition in
                            Text(edition.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                }

                LazyVStack(spacing: 10) {
                    ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                        NavigationLink {
                            BookDetailView(bookID: book.id)
                        } label: {
                            HStack(spacing: 14) {
                                CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, maxPixelSize: 300)
                                    .frame(width: 68, height: 102)
                                    .clipShape(RoundedRectangle(cornerRadius: 9))

                                VStack(alignment: .leading, spacing: 5) {
                                    let parsed = SeriesService.parse(book.title)
                                    Text(parsed.issueNumber.map { "Issue #\(formatIssue($0))" } ?? "Part \(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    Text(book.displayTitle)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    HStack {
                                        Text("\(book.displayProgressPercent)%")
                                        if let volume = parsed.volume { Text("• Vol. \(volume)") }
                                        if parsed.edition != .standard { Text("• \(parsed.edition.rawValue)") }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    ProgressView(value: book.displayProgress)
                                }
                                Spacer()
                                Image(systemName: book.readingStatus == .completed ? "checkmark.circle.fill" : "chevron.right")
                                    .foregroundStyle(book.readingStatus == .completed ? .green : .secondary)
                            }
                            .padding(10)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(ComicDisplayTitle.series(series.title))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StoryArcLibraryView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var showCreator = false

    var body: some View {
        NavigationStack {
            Group {
                if store.storyArcs.isEmpty {
                    ContentUnavailableView(
                        "No reading orders yet",
                        systemImage: "point.3.connected.trianglepath.dotted",
                        description: Text("Create a Story Arc to put comics from different series into one reading order.")
                    )
                } else {
                    List {
                        ForEach(store.storyArcs) { arc in
                            NavigationLink {
                                StoryArcDetailView(arcID: arc.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(arc.name).font(.headline)
                                    Text("\(arc.bookIDs.count) comics • \(store.storyArcProgress(arc))% complete")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets { store.deleteStoryArc(store.storyArcs[index].id) }
                        }
                    }
                }
            }
            .navigationTitle("Reading Orders")
            .toolbar {
                Button { showCreator = true } label: { Label("New", systemImage: "plus") }
            }
            .sheet(isPresented: $showCreator) {
                StoryArcCreatorView()
                    .environmentObject(store)
            }
        }
    }
}

private struct StoryArcCreatorView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selection = Set<UUID>()

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("e.g. Night of the Owls", text: $name)
                }
                Section("Choose comics in reading order") {
                    ForEach(store.libraryBooks) { book in
                        Button {
                            if selection.contains(book.id) { selection.remove(book.id) }
                            else { selection.insert(book.id) }
                        } label: {
                            HStack {
                                Image(systemName: selection.contains(book.id) ? "checkmark.circle.fill" : "circle")
                                Text(book.displayTitle).foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Story Arc")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let ordered = store.libraryBooks.filter { selection.contains($0.id) }.map(\.id)
                        store.createStoryArc(name: name.isEmpty ? "Reading Order" : name, bookIDs: ordered)
                        dismiss()
                    }
                    .disabled(selection.isEmpty)
                }
            }
        }
    }
}

struct StoryArcDetailView: View {
    @EnvironmentObject var store: LibraryStore
    let arcID: UUID

    private var arc: StoryArc? { store.storyArcs.first { $0.id == arcID } }

    var body: some View {
        Group {
            if let arc {
                List {
                    Section {
                        HStack {
                            Text("\(store.storyArcProgress(arc))% complete")
                            Spacer()
                            ProgressView(value: Double(store.storyArcProgress(arc)) / 100.0)
                                .frame(width: 180)
                        }
                    }

                    Section("Reading order") {
                        ForEach(Array(arc.bookIDs.enumerated()), id: \.element) { index, id in
                            if let book = store.books.first(where: { $0.id == id }) {
                                NavigationLink {
                                    BookDetailView(bookID: book.id)
                                } label: {
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .frame(width: 28, height: 28)
                                            .background(.quaternary, in: Circle())
                                        VStack(alignment: .leading) {
                                            Text(book.displayTitle)
                                            Text("\(book.displayProgressPercent)% read")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if book.readingStatus == .completed {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }
                        .onMove { source, destination in
                            store.moveStoryArcBooks(arcID: arc.id, from: source, to: destination)
                        }
                    }
                }
                .navigationTitle(arc.name)
                .toolbar { EditButton() }
            } else {
                ContentUnavailableView("Reading order not found", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

private func formatIssue(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(value)
}
