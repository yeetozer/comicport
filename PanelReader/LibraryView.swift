import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct LibraryView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if targetEnvironment(macCatalyst)
    @State private var dropTargeted = false
    #endif

    var body: some View {
        ZStack(alignment: .top) {
            if store.isBootstrapped {
                #if DEBUG
                if let route = ProcessInfo.processInfo.environment["SCREENSHOT_ROUTE"] {
                    ScreenshotRootView(route: route)
                } else {
                    DashboardShellView().transition(.opacity)
                }
                #else
                DashboardShellView().transition(.opacity)
                #endif

                if let achievement = store.currentAchievementBanner {
                    AchievementBanner(achievement: achievement)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            } else {
                PanelReaderLaunchView(message: store.bootstrapMessage)
            }
        }
        .background(Color(red: 0.025, green: 0.035, blue: 0.05).ignoresSafeArea())
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.20),
            value: store.isBootstrapped
        )
        .animation(
            reduceMotion
                ? nil
                : .spring(response: 0.42, dampingFraction: 0.88),
            value: store.currentAchievementBanner?.id
        )
        .task {
            await store.bootstrap()
        }
        .onOpenURL { url in
            store.handleIncomingURL(url)
        }
        .dropDestination(for: URL.self) { urls, _ in
            let comics = urls.filter { url in
                url.pathExtension.lowercased() == "pdf" || ComicArchiveFormat.supports(url)
            }
            comics.forEach(store.importFile)
            return !comics.isEmpty
        } isTargeted: { targeted in
            #if targetEnvironment(macCatalyst)
            dropTargeted = targeted
            #endif
        }
        #if targetEnvironment(macCatalyst)
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, dash: [9, 6]))
                    .padding(14)
                    .overlay {
                        Label("Drop comics into ComicPort", systemImage: "square.and.arrow.down")
                            .font(.title3.bold())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .allowsHitTesting(false)
            }
        }
        #endif
    }
}

private struct PanelReaderLaunchView: View {
    @Environment(\.panelAccentColor) private var accentColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let message: String

    @State private var pagesOpen = false
    @State private var titleVisible = false
    @State private var glow = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accentColor.opacity(glow ? 0.12 : 0.03))
                    .frame(width: 142, height: 142)
                    .blur(radius: 14)
                    .scaleEffect(glow ? 1.06 : 0.82)

                RoundedRectangle(cornerRadius: 15)
                    .fill(accentColor.opacity(0.10))
                    .frame(width: 62, height: 78)
                    .rotationEffect(.degrees(pagesOpen ? -9 : 0), anchor: .bottomTrailing)
                    .offset(x: pagesOpen ? -16 : 0, y: 1)

                RoundedRectangle(cornerRadius: 15)
                    .fill(accentColor.opacity(0.16))
                    .frame(width: 62, height: 78)
                    .rotationEffect(.degrees(pagesOpen ? 9 : 0), anchor: .bottomLeading)
                    .offset(x: pagesOpen ? 16 : 0, y: 1)

                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(accentColor.opacity(0.15))
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 92, height: 92)
                .scaleEffect(pagesOpen ? 1 : 0.72)
                .rotationEffect(.degrees(pagesOpen ? 0 : -5))
            }
            .frame(width: 150, height: 128)

            VStack(spacing: 3) {
                Text("COMIC")
                Text("PORT")
            }
            .font(.title.bold())
            .italic()
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 7)

            ProgressView()
                .controlSize(.regular)
                .tint(accentColor)
                .padding(.top, 4)
                .opacity(titleVisible ? 1 : 0.25)

            Text(ComicPortRelease.copy(message))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.dark)
        .onAppear {
            if reduceMotion {
                pagesOpen = true
                titleVisible = true
                glow = false
            } else {
                withAnimation(
                    .spring(response: 0.48, dampingFraction: 0.76)
                ) {
                    pagesOpen = true
                }
                withAnimation(
                    .easeOut(duration: 0.32).delay(0.14)
                ) {
                    titleVisible = true
                }
                withAnimation(
                    .easeInOut(duration: 0.75)
                        .repeatForever(autoreverses: true)
                        .delay(0.20)
                ) {
                    glow = true
                }
            }
        }
    }
}



private struct DailyGoalBanner: View {
    @EnvironmentObject var store: LibraryStore

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: store.todayGoalProgress)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(store.todayStat.pages)")
                    .font(.title3.bold())
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text("Today's reading goal").font(.headline)
                Text("\(store.todayStat.pages) of \(store.analytics.dailyGoalPages) pages")
                    .foregroundStyle(.secondary)
                Text(formatDuration(store.todayStat.seconds))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
}

private struct ShelfSection: View {
    let title: String
    let icon: String
    let books: [ComicBook]

    var body: some View {
        if !books.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon)
                    .font(.title2.bold())
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(books) { book in
                            NavigationLink(value: book.id) { BookCard(book: book, width: 155) }
                                .buttonStyle(.plain)
                                .bookContextMenu(book)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

private struct SearchGrid: View {
    let books: [ComicBook]
    private let columns = [GridItem(.adaptive(minimum: 155, maximum: 210), spacing: 18)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(books) { book in
                    NavigationLink(value: book.id) { BookCard(book: book, width: nil) }
                        .buttonStyle(.plain)
                        .bookContextMenu(book)
                }
            }
            .padding()
        }
    }
}

private struct BookCard: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    let width: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(.quaternary)
                    if let url = store.coverURL(for: book), let image = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        Image(systemName: book.type == .pdf ? "doc.richtext" : "photo.on.rectangle.angled")
                            .font(.system(size: 42)).foregroundStyle(.secondary)
                    }
                }
                .aspectRatio(2/3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 4, y: 2)

                if book.favorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.55), in: Circle())
                        .padding(8)
                }
            }

            Text(book.title).font(.headline).lineLimit(2)
            HStack {
                Text("\(book.progressPercent)%")
                Spacer()
                Label(book.readingStatus.rawValue, systemImage: book.readingStatus.systemImage)
                    .labelStyle(.iconOnly)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ProgressView(value: book.progress)

            if book.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { value in
                        Image(systemName: value <= book.rating ? "star.fill" : "star")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .frame(width: width)
    }
}

private struct BookContextModifier: ViewModifier {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    @State private var confirmFileDelete = false
    @State private var confirmPermanentDelete = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button { store.toggleFavorite(id: book.id) } label: {
                    Label(book.favorite ? "Remove Favorite" : "Favorite", systemImage: book.favorite ? "heart.slash" : "heart")
                }

                Menu("Collection") {
                    ForEach(ReadingStatus.allCases) { status in
                        Button { store.setStatus(id: book.id, status: status) } label: {
                            Label(status.rawValue, systemImage: status.systemImage)
                        }
                    }
                }

                Menu("Rating") {
                    Button("No rating") { store.setRating(id: book.id, rating: 0) }
                    ForEach(1...5, id: \.self) { value in
                        Button(String(repeating: "★", count: value)) { store.setRating(id: book.id, rating: value) }
                    }
                }

                Divider()
                Button { store.archive(book) } label: { Label("Archive", systemImage: "archivebox") }
                Button { store.removeFromLibrary(book) } label: { Label("Remove from Library", systemImage: "books.vertical") }
                Button(role: .destructive) { confirmFileDelete = true } label: {
                    Label("Delete File, Keep Data", systemImage: "externaldrive.badge.minus")
                }
                Button(role: .destructive) { confirmPermanentDelete = true } label: {
                    Label("Delete Completely…", systemImage: "trash.slash")
                }
            }
            .confirmationDialog(
                "Delete the comic file from this device?",
                isPresented: $confirmFileDelete,
                titleVisibility: .visible
            ) {
                Button("Delete File, Keep Data", role: .destructive) { store.deleteFileKeepingData(book) }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Reading history, progress, rating, favorite status, notes and saved information will remain. Import the same comic later to reconnect them.")
            }
            .confirmationDialog(
                "Delete completely?",
                isPresented: $confirmPermanentDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) { store.permanentlyDelete(book) }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The comic file, history, reading statistics for this comic, notes, rating, favorite status, cover and offline analysis will be permanently deleted.")
            }
    }
}

private extension View {
    func bookContextMenu(_ book: ComicBook) -> some View { modifier(BookContextModifier(book: book)) }
}

private struct SavedDataView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var pendingPermanentDelete: ComicBook?

    var body: some View {
        NavigationStack {
            Group {
                if store.savedDataBooks.isEmpty {
                    ContentUnavailableView(
                        "No archived or removed comics",
                        systemImage: "archivebox",
                        description: Text("Archived books and comics whose files were removed while keeping their data will appear here.")
                    )
                } else {
                    List {
                        if !store.archivedBooks.isEmpty {
                            Section("Archived") {
                                ForEach(store.archivedBooks) { book in savedRow(book) }
                            }
                        }
                        if !store.removedBooks.isEmpty {
                            Section("Removed / Data Kept") {
                                ForEach(store.removedBooks) { book in savedRow(book) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Data")
            .confirmationDialog(
                "Delete completely?",
                isPresented: Binding(
                    get: { pendingPermanentDelete != nil },
                    set: { if !$0 { pendingPermanentDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let book = pendingPermanentDelete {
                    Button("Delete Everything", role: .destructive) {
                        store.permanentlyDelete(book)
                        pendingPermanentDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingPermanentDelete = nil }
            } message: {
                Text("This also removes the saved reading history, statistics, notes, cover and offline analysis for this comic.")
            }
        }
    }

    @ViewBuilder
    private func savedRow(_ book: ComicBook) -> some View {
        HStack(spacing: 14) {
            Group {
                if let url = store.coverURL(for: book), let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    ZStack { Rectangle().fill(.quaternary); Image(systemName: "book.closed") }
                }
            }
            .frame(width: 54, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(book.fileAvailable ? 1 : 0.55)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.headline).lineLimit(2)
                Text(book.fileAvailable ? (book.isArchived ? "Archived · file on device" : "Removed from library · file on device") : "Not on device · reading data preserved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(book.progressPercent)% read · ★ \(book.rating)/5")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                if book.isArchived {
                    Button { store.unarchive(book) } label: { Label("Return to Library", systemImage: "arrow.uturn.backward") }
                } else if book.fileAvailable {
                    Button { store.restoreToLibrary(book) } label: { Label("Return to Library", systemImage: "books.vertical.fill") }
                } else {
                    Text("Import the same comic file to reconnect")
                }
                Divider()
                Button(role: .destructive) { pendingPermanentDelete = book } label: { Label("Delete Completely…", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ReadingStatsView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var goalText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 14) {
                        StatCard(title: "Today", value: "\(store.todayStat.pages)", subtitle: "pages", icon: "book.pages")
                        StatCard(title: "Reading time", value: formatDuration(store.todayStat.seconds), subtitle: "today", icon: "timer")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily goal").font(.headline)
                        ProgressView(value: store.todayGoalProgress)
                        HStack {
                            TextField("Pages", text: $goalText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Button("Set") {
                                if let value = Int(goalText), value > 0 { store.setDailyGoal(value); goalText = "" }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Text("Current goal: \(store.analytics.dailyGoalPages) pages per day")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reading History").font(.title2.bold())
                        if store.analytics.history.isEmpty {
                            ContentUnavailableView("No reading history yet", systemImage: "clock.arrow.circlepath")
                        } else {
                            ForEach(store.analytics.history.prefix(50)) { entry in
                                HStack(spacing: 12) {
                                    Image(systemName: "book.closed.fill")
                                        .frame(width: 34, height: 34)
                                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(store.bookTitle(for: entry.bookID)).font(.headline).lineLimit(1)
                                        Text("Pages \(entry.startPage + 1)–\(entry.endPage + 1) · \(entry.pagesRead) turned · \(formatDuration(entry.seconds))")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(entry.date, style: .relative)
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
            .navigationTitle("Reading Stats")
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).minimumScaleFactor(0.7)
            Text(subtitle).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded())
    if total < 60 { return "\(total)s" }
    let minutes = total / 60
    if minutes < 60 { return "\(minutes)m" }
    return "\(minutes / 60)h \(minutes % 60)m"
}
