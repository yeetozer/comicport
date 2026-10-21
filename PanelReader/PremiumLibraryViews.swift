import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PremiumLibraryHomeView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var showImporter = false
    @State private var search = ""

    private var searched: [ComicBook] {
        store.libraryBooks.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.libraryBooks.isEmpty {
                    ContentUnavailableView("Your library is empty", systemImage: "books.vertical", description: Text("Import a PDF or CBZ from Files."))
                } else if !search.isEmpty {
                    ComicGrid(books: searched)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            libraryHero
                            GoalCard()
                            if let current = store.recentlyRead.first { ContinueCard(book: current) }
                            ComicShelf(title: "Recently Added", icon: "sparkles", books: store.recentlyAdded)
                            ComicShelf(title: "Recently Read", icon: "clock.fill", books: store.recentlyRead)
                            ComicShelf(title: "Reading", icon: "book.pages", books: store.books(with: .reading))
                            ComicShelf(title: "To Read", icon: "bookmark.fill", books: store.books(with: .toRead))
                            ComicShelf(title: "Completed", icon: "checkmark.circle.fill", books: store.books(with: .completed))
                            ComicShelf(title: "Favorites", icon: "heart.fill", books: store.libraryBooks.filter { $0.favorite })
                            CharacterPreviewSection(comics: store.libraryBooks)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .comicHubSurface().navigationTitle("ComicPort")
            .searchable(text: $search, prompt: "Search library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showImporter = true } label: { Label("Import", systemImage: "plus") }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if store.books.contains(where: { $0.id == id }) { BookDetailView(bookID: id) }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: ComicArchiveFormat.allowedImportTypes, allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls): urls.forEach(store.importFile)
                case .failure(let error): store.importError = error.localizedDescription
                }
            }
            .alert("ComicPort", isPresented: Binding(get: { store.importError != nil }, set: { if !$0 { store.importError = nil } })) {
                Button("OK", role: .cancel) { store.importError = nil }
            } message: { Text(store.importError ?? "") }
        }
    }

    private var libraryHero: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Library").font(.largeTitle.bold())
                Text("\(store.libraryBooks.count) comics • \(store.books(with: .completed).count) completed")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

private struct GoalCard: View {
    @EnvironmentObject var store: LibraryStore
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 8)
                Circle().trim(from: 0, to: store.todayGoalProgress)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(store.todayStat.pages)").font(.title3.bold())
            }.frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 5) {
                Text("Today's Goal").font(.headline)
                Text("\(store.todayStat.pages) / \(store.analytics.dailyGoalPages) pages").foregroundStyle(.secondary)
                Text("Keep your streak moving.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

private struct ContinueCard: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Continue Reading", systemImage: "play.circle.fill").font(.title2.bold())
            NavigationLink(value: book.id) {
                HStack(spacing: 18) {
                    ComicCover(book: book).frame(width: 110, height: 165).clipShape(RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title).font(.title3.bold()).foregroundStyle(.primary).lineLimit(2)
                        Text("\(book.progressPercent)% read • page \(min(book.currentPage + 1, max(1, book.pageCount))) of \(book.pageCount)")
                            .foregroundStyle(.secondary)
                        ProgressView(value: book.progress).frame(maxWidth: 320)
                        Label("Resume", systemImage: "play.fill").font(.headline).foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding()
                .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }.buttonStyle(.plain)
        }.padding(.horizontal)
    }
}

private struct ComicShelf: View {
    let title: String
    let icon: String
    let books: [ComicBook]
    var body: some View {
        if !books.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon).font(.title2.bold()).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(books) { book in
                            NavigationLink(value: book.id) { PremiumBookCard(book: book, width: 155) }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }
}

private struct ComicGrid: View {
    let books: [ComicBook]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 210), spacing: 18)], spacing: 24) {
                ForEach(books) { book in
                    NavigationLink(value: book.id) { PremiumBookCard(book: book, width: nil) }.buttonStyle(.plain)
                }
            }.padding()
        }
    }
}

private struct PremiumBookCard: View {
    let book: ComicBook
    let width: CGFloat?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ComicCover(book: book).aspectRatio(2/3, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 14)).shadow(radius: 4, y: 2)
                if book.favorite { Image(systemName: "heart.fill").foregroundStyle(.white).padding(8).background(.black.opacity(0.55), in: Circle()).padding(8) }
            }
            Text(book.title).font(.headline).foregroundStyle(.primary).lineLimit(2)
            HStack { Text("\(book.progressPercent)%"); Spacer(); Image(systemName: book.readingStatus.systemImage) }
                .font(.caption).foregroundStyle(.secondary)
            ProgressView(value: book.progress)
            if book.rating > 0 {
                HStack(spacing: 2) { ForEach(1...5, id: \.self) { n in Image(systemName: n <= book.rating ? "star.fill" : "star") } }
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }.frame(width: width)
    }
}

private struct ComicCover: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(.quaternary)
            CachedCoverImage(
                url: store.coverURL(for: book),
                comicType: book.type, revision: book.coverRevision,
                maxPixelSize: 720
            )
        }
    }
}

private struct CharacterPreviewSection: View {
    let comics: [ComicBook]
    private var profiles: [CharacterProfile] { CharacterLibraryService.profiles(from: comics) }
    var body: some View {
        if !profiles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack { Label("Characters", systemImage: "person.3.fill").font(.title2.bold()); Spacer(); NavigationLink("See All") { CharacterLibraryView() } }
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(profiles.prefix(10)) { profile in
                            NavigationLink { CharacterDetailView(profile: profile) } label: {
                                CharacterMiniCard(profile: profile)
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }
}

private struct CharacterMiniCard: View {
    @EnvironmentObject var store: LibraryStore
    let profile: CharacterProfile
    private var firstBook: ComicBook? { store.books.first(where: { profile.comicIDs.contains($0.id) }) }
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let book = firstBook { ComicCover(book: book) } else { RoundedRectangle(cornerRadius: 18).fill(.quaternary) }
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name).font(.headline).foregroundStyle(.white)
                Text("\(profile.comicIDs.count) comics").font(.caption).foregroundStyle(.white.opacity(0.8))
            }.padding(12)
        }
        .frame(width: 170, height: 255)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CharacterLibraryView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var universe: CharacterUniverse? = nil
    @State private var search = ""
    private var profiles: [CharacterProfile] {
        CharacterLibraryService.profiles(from: store.profileLibraryBooks).filter {
            (universe == nil || $0.universe == universe) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack { filter("All", nil); ForEach(CharacterUniverse.allCases) { filter($0.rawValue, $0) } }.padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 18)], spacing: 18) {
                        ForEach(profiles) { profile in NavigationLink { CharacterDetailView(profile: profile) } label: { CharacterLargeCard(profile: profile) }.buttonStyle(.plain) }
                    }.padding(.horizontal)
                }.padding(.vertical)
            }
            .comicHubSurface(when: store.activeReaderProfile == .comics)
            .navigationTitle("Karakterler")
            .searchable(text: $search, prompt: "Search characters")
        }
    }
    private func filter(_ title: String, _ value: CharacterUniverse?) -> some View {
        Button { universe = value } label: { Text(title).font(.subheadline.weight(.semibold)).padding(.horizontal, 14).padding(.vertical, 8).background(universe == value ? Color.primary.opacity(0.18) : Color.secondary.opacity(0.10)).clipShape(Capsule()) }.buttonStyle(.plain)
    }
}

private struct CharacterLargeCard: View {
    @EnvironmentObject var store: LibraryStore
    let profile: CharacterProfile
    private var firstBook: ComicBook? { store.books.first(where: { profile.comicIDs.contains($0.id) }) }
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let book = firstBook { ComicCover(book: book) } else { RoundedRectangle(cornerRadius: 18).fill(.quaternary) }
            LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) { Text(profile.name).font(.title3.bold()).foregroundStyle(.white); Text("\(profile.universe.rawValue) • \(profile.comicIDs.count) comics").font(.caption).foregroundStyle(.white.opacity(0.8)) }.padding(14)
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CharacterDetailView: View {
    @EnvironmentObject var store: LibraryStore
    let profile: CharacterProfile
    private var comics: [ComicBook] { store.profileLibraryBooks.filter { profile.comicIDs.contains($0.id) } }
    private var completed: Int { comics.filter { $0.readingStatus == .completed }.count }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name).font(.largeTitle.bold())
                    Text("\(profile.universe.rawValue) • \(comics.count) comics • \(completed) completed").foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 210), spacing: 18)], spacing: 22) {
                    ForEach(comics) { book in NavigationLink(value: book.id) { PremiumBookCard(book: book, width: nil) }.buttonStyle(.plain) }
                }
            }.padding()
        }
        .comicHubSurface(when: store.activeReaderProfile == .comics)
        .navigationTitle(profile.name).navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UUID.self) { id in if store.books.contains(where: { $0.id == id }) { BookDetailView(bookID: id) } }
    }
}
