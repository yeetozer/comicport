import SwiftUI

private struct JournalBookRoute: Identifiable, Hashable {
    let id: UUID
}

struct CompletionJournalEditor: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.panelAccentColor) private var accentColor

    let bookID: UUID
    let completedAt: Date

    @State private var rating = 0
    @State private var note = ""
    @State private var wouldReread = false
    @State private var favoritePanelID: UUID?

    private var book: ComicBook? { store.books.first { $0.id == bookID } }
    private var bookPanels: [SavedPanel] { store.savedPanels.filter { $0.bookID == bookID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 14) {
                        if let book {
                            CachedCoverImage(
                                url: store.coverURL(for: book),
                                comicType: book.type,
                                maxPixelSize: 480
                            )
                            .frame(width: 92, height: 136)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Reading complete")
                                .font(.caption.bold())
                                .foregroundStyle(accentColor)
                            Text(book?.title ?? "Comic")
                                .font(.title2.bold())
                                .lineLimit(3)
                            Text(completedAt.formatted(date: .long, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Your rating").font(.headline)
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    rating = rating == value ? 0 : value
                                } label: {
                                    Image(systemName: value <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(value <= rating ? Color.yellow : Color.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Your reading note").font(.headline)
                        TextEditor(text: $note)
                            .frame(minHeight: 130)
                            .padding(10)
                            .scrollContentBackground(.hidden)
                            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
                        Text("Spoilers, favorite scenes, thoughts or anything you want to remember.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Read again someday", isOn: $wouldReread)
                        .tint(accentColor)

                    if !bookPanels.isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Favorite panel from this reading").font(.headline)
                            Picker("Favorite panel", selection: $favoritePanelID) {
                                Text("None").tag(Optional<UUID>.none)
                                ForEach(bookPanels) { panel in
                                    Text("Sayfa \(panel.page + 1)").tag(Optional(panel.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Reading Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") {
                        store.dismissCompletionJournalPrompt(bookID: bookID)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        store.saveReadingJournalEntry(
                            bookID: bookID,
                            completedAt: completedAt,
                            rating: rating,
                            note: note,
                            wouldReread: wouldReread,
                            favoritePanelID: favoritePanelID
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                rating = book?.rating ?? 0
            }
        }
        .interactiveDismissDisabled()
    }
}

struct ReadingJournalView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var search = ""
    @State private var selectedEntry: ReadingJournalEntry?
    @State private var activeBook: JournalBookRoute?

    private var filteredEntries: [ReadingJournalEntry] {
        let entries = store.readingJournalEntries.sorted { $0.completedAt > $1.completedAt }
        guard !search.isEmpty else { return entries }
        return entries.filter {
            store.bookTitle(for: $0.bookID).localizedCaseInsensitiveContains(search) ||
            $0.note.localizedCaseInsensitiveContains(search)
        }
    }

    private var summary: ReadingJournalSummary {
        ReadingJournalSummary.make(from: store.readingJournalEntries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if store.readingJournalEntries.isEmpty {
                        ContentUnavailableView(
                            "Your reading journal is empty",
                            systemImage: "book.closed.fill",
                            description: Text("Finish a comic to save your rating and thoughts here.")
                        )
                        .padding(.top, 45)
                    } else if filteredEntries.isEmpty {
                        ContentUnavailableView.search(text: search)
                            .padding(.top, 45)
                    } else {
                        LazyVStack(spacing: 11) {
                            ForEach(filteredEntries) { entry in
                                journalRow(entry)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Reading Journal")
            .searchable(text: $search, prompt: "Search comics or notes")
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry)
                    .environmentObject(store)
            }
            .navigationDestination(item: $activeBook) { route in
                BookDetailView(bookID: route.id)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your reading journal")
                        .font(.largeTitle.bold())
                    Text("Keep more than a count of finished comics. Remember what you thought about them, years later.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(accentColor)
            }

            HStack(spacing: 10) {
                stat("\(summary.totalEntries)", "entries")
                stat(summary.averageRating > 0 ? String(format: "%.1f ★", summary.averageRating) : "—", "ortalama")
                stat("\(summary.rereadCount)", "read again")
                stat("\(summary.notesCount)", "not")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.16), .white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 11))
    }

    private func journalRow(_ entry: ReadingJournalEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(alignment: .top, spacing: 13) {
                if let book = store.books.first(where: { $0.id == entry.bookID }) {
                    CachedCoverImage(
                        url: store.coverURL(for: book),
                        comicType: book.type,
                        maxPixelSize: 360
                    )
                    .frame(width: 62, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                } else {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(.white.opacity(0.05))
                        .frame(width: 62, height: 92)
                        .overlay(Image(systemName: "book.closed").foregroundStyle(.secondary))
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(store.bookTitle(for: entry.bookID))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Spacer()
                        Text(entry.completedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if entry.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { value in
                                Image(systemName: value <= entry.rating ? "star.fill" : "star")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    }

                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if entry.wouldReread {
                        Label("Read again", systemImage: "arrow.clockwise")
                            .font(.caption2.bold())
                            .foregroundStyle(accentColor)
                    }
                }
            }
            .padding(12)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
    }
}

private struct JournalEntryDetailView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let entry: ReadingJournalEntry

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(store.bookTitle(for: entry.bookID))
                        .font(.title2.bold())

                    Text(entry.completedAt.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if entry.rating > 0 {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { value in
                                Image(systemName: value <= entry.rating ? "star.fill" : "star")
                            }
                        }
                        .foregroundStyle(.yellow)
                    }

                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.body)
                            .textSelection(.enabled)
                    }

                    if entry.wouldReread {
                        Label("You want to read this again", systemImage: "arrow.clockwise.circle.fill")
                    }

                    if let panelID = entry.favoritePanelID,
                       let panel = store.savedPanels.first(where: { $0.id == panelID }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Favorite panel").font(.headline)
                            Text("My Panels • Sayfa \(panel.page + 1)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        store.deleteReadingJournalEntry(entry.id)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}
