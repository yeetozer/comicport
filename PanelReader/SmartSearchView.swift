import SwiftUI

private struct SmartSearchReaderRoute: Identifiable {
    let id: UUID
}

struct SmartSearchView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var query = ""
    @State private var results: [SmartSearchHit] = []
    @State private var activeReader: SmartSearchReaderRoute?
    @State private var unavailableMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private var indexedBooks: Int { store.smartSearchIndexedBookCount }
    private var indexedPages: Int { store.smartSearchIndexedPageCount }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    indexStatus

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                        emptySearchIntro
                    } else if results.isEmpty {
                        ContentUnavailableView(
                            "No results found",
                            systemImage: "text.magnifyingglass",
                            description: Text(
                                indexedBooks == 0
                                ? "Index your library to search page text as well as titles."
                                : "Try another word or index comics that are not searchable yet."
                            )
                        )
                        .padding(.top, 35)
                    } else {
                        resultList
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Smart Search")
            .searchable(text: $query, prompt: "Joker, Dick Grayson, replik…")
            .task {
                await store.loadSmartSearchCacheIfNeeded()
                await performSearch()
            }
            .onChange(of: query) { _, _ in
                scheduleSearch()
            }
            .onChange(of: store.smartSearchRevision) { _, _ in
                scheduleSearch(immediate: true)
            }
            .fullScreenCover(item: $activeReader) { route in
                ReadingSessionHostView(initialBookID: route.id)
                    .environmentObject(store)
                    .preferredColorScheme(.dark)
            }
            .alert("This comic is not on this device", isPresented: Binding(
                get: { unavailableMessage != nil },
                set: { if !$0 { unavailableMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) { unavailableMessage = nil }
            } message: {
                Text(unavailableMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(accentColor.opacity(0.14))
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Offline Smart Search")
                        .font(.largeTitle.bold())
                    Text("Index dialogue with on-device OCR and jump directly to a page.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Label("No internet connection or server is used.", systemImage: "iphone.gen3.radiowaves.left.and.right.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(19)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.17), .white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var indexStatus: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Search Index")
                        .font(.title2.bold())
                    Text("\(indexedBooks) comics • \(indexedPages) searchable pages")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if store.smartSearchProgress == nil {
                    Button {
                        store.startSmartSearchIndexing()
                    } label: {
                        Label(indexedBooks == 0 ? "Index Library" : "Index Missing", systemImage: "text.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)

                    Menu {
                        Button {
                            store.startSmartSearchIndexing(forceAll: true)
                        } label: {
                            Label("Reindex All", systemImage: "arrow.clockwise")
                        }

                        if indexedBooks > 0 {
                            Button(role: .destructive) {
                                store.clearAllSmartSearchIndexes()
                            } label: {
                                Label("Delete Search Index", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(role: .destructive) {
                        store.cancelSmartSearchIndexing()
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let progress = store.smartSearchProgress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(progress.bookTitle)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer()
                        Text("\(progress.bookNumber)/\(progress.totalBooks)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: progress.overallFraction)
                        .tint(accentColor)

                    HStack {
                        Text("Sayfa \(progress.page)/\(max(1, progress.totalPages))")
                        Spacer()
                        Text("%\(Int((progress.overallFraction * 100).rounded()))")
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            } else if let error = store.smartSearchLastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Indexing starts only when you ask. OCR text is stored as small JSON files on this device. Your PDF and CBZ files are not changed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
    }

    private var emptySearchIntro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Neler arayabilirsin?")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                example("Karakter", "Dick Grayson", "person.text.rectangle")
                example("Villain", "Joker", "theatermasks.fill")
                example("Replik", "I am vengeance", "quote.bubble.fill")
                example("Yer / kavram", "Gotham", "building.2.fill")
            }

            if indexedBooks == 0 {
                Label("Choose Index Library above to get started.", systemImage: "arrow.up")
                    .font(.subheadline)
                    .foregroundStyle(accentColor)
                    .padding(.top, 5)
            }
        }
    }

    private func example(_ title: String, _ value: String, _ icon: String) -> some View {
        Button {
            query = value
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .frame(width: 40, height: 40)
                    .background(accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Text(value).font(.headline).foregroundStyle(.primary)
                }
                Spacer()
            }
            .padding(12)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }

    private var resultList: some View {
        LazyVStack(spacing: 10) {
            HStack {
                Text("\(results.count) results")
                    .font(.headline)
                Spacer()
                if results.count >= 120 {
                    Text("Showing the first 120 results")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(results) { hit in
                Button {
                    open(hit)
                } label: {
                    HStack(alignment: .top, spacing: 13) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 11)
                                .fill((hit.kind == .title ? accentColor : Color.secondary).opacity(0.11))
                            Image(systemName: hit.kind == .title ? "book.closed.fill" : "text.bubble.fill")
                                .foregroundStyle(hit.kind == .title ? accentColor : .secondary)
                        }
                        .frame(width: 46, height: 46)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(hit.bookTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                if let page = hit.page {
                                    Text("• Sayfa \(page + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(accentColor)
                                }
                            }

                            Text(hit.snippet)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 12)
                    }
                    .padding(13)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func scheduleSearch(immediate: Bool = false) {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            if !immediate {
                try? await Task.sleep(for: .milliseconds(170))
            }
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    @MainActor
    private func performSearch() async {
        let captured = query
        let found = await store.smartSearchAsync(query: captured)
        guard !Task.isCancelled, captured == query else { return }
        results = found
    }

    private func open(_ hit: SmartSearchHit) {
        guard let book = store.books.first(where: { $0.id == hit.bookID }) else { return }

        guard book.fileAvailable else {
            unavailableMessage = "This result comes from a saved OCR index, but the comic is not on this device. Import it again to open this page."
            return
        }

        if let page = hit.page {
            store.updateProgress(id: hit.bookID, page: page)
        }
        activeReader = SmartSearchReaderRoute(id: hit.bookID)
    }
}

struct BookSearchIndexCard: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    let book: ComicBook

    private var isIndexed: Bool { store.smartSearchIsIndexed(book.id) }
    private var isCurrentJob: Bool { store.smartSearchProgress?.bookID == book.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Offline Smart Search", systemImage: "text.viewfinder")
                    .font(.title2.bold())

                Spacer()

                if isCurrentJob {
                    Button(role: .destructive) {
                        store.cancelSmartSearchIndexing()
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                } else if book.fileAvailable {
                    Button {
                        store.startSmartSearchIndexing(forceAll: true, only: book.id)
                    } label: {
                        Label(isIndexed ? "Reindex" : "Index for Search", systemImage: isIndexed ? "arrow.clockwise" : "text.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if isCurrentJob, let progress = store.smartSearchProgress {
                ProgressView(value: progress.totalPages > 0 ? Double(progress.page) / Double(progress.totalPages) : 0)
                    .tint(accentColor)
                Text("Reading page \(progress.page)/\(max(1, progress.totalPages)) with on-device OCR…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isIndexed {
                Label("This comic’s dialogue and text are ready to search.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            } else if book.fileAvailable {
                Text("Once indexed, search names, words and dialogue in this comic offline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("The file must be on this device to reindex it. Any existing index is preserved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .task {
            await store.loadSmartSearchCacheIfNeeded()
        }
    }
}
