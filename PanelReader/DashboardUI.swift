import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - Dashboard Navigation

enum DashboardSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case library
    case reading
    case toRead
    case completed
    case recentAdded
    case recentRead
    case favorites
    case characters
    case series
    case achievements
    case lists
    case notes
    case myPanels
    case smartSearch
    case readingOrder2
    case libraryHealth
    case libraryTools
    case smartCollections
    case sourcesSync
    case journal
    case statistics
    case wrapped
    case history
    case saved
    case settings

    case browse

    var title: String {
        switch self {
        case .home: return String(localized: "Home")
        case .library: return String(localized: "Library")
        case .reading: return String(localized: "Reading")
        case .toRead: return String(localized: "To Read")
        case .completed: return String(localized: "Completed")
        case .recentAdded: return String(localized: "Recently Added")
        case .recentRead: return String(localized: "Recently Read")
        case .favorites: return String(localized: "Favorites")
        case .characters: return String(localized: "Characters")
        case .series: return String(localized: "Series")
        case .achievements: return String(localized: "Achievements")
        case .lists: return String(localized: "Lists")
        case .notes: return String(localized: "Notes")
        case .myPanels: return String(localized: "My Panels")
        case .smartSearch: return String(localized: "Smart Search")
        case .readingOrder2: return String(localized: "Reading Order")
        case .libraryHealth: return String(localized: "Library Health")
        case .libraryTools: return String(localized: "Library Tools")
        case .smartCollections: return String(localized: "Smart Collections")
        case .sourcesSync: return String(localized: "Sources & Sync")
        case .journal: return String(localized: "Reading Journal")
        case .statistics: return String(localized: "Statistics")
        case .wrapped: return String(localized: "ComicPort Wrapped")
        case .history: return String(localized: "Reading History")
        case .saved: return String(localized: "Saved")
        case .settings: return String(localized: "Settings")
        case .browse: return String(localized: "Browse")
        }
    }

    static func restore(_ value: String) -> Self {
        if let route = Self(rawValue: value) { return route }
        let legacy: [String: Self] = [
            "Ana Sayfa": .home,
            "Kütüphanem": .library,
            "Okunuyor": .reading,
            "Okunacak": .toRead,
            "Tamamlandı": .completed,
            "Son Eklenenler": .recentAdded,
            "Son Okunanlar": .recentRead,
            "Favoriler": .favorites,
            "Karakterler": .characters,
            "Seriler": .series,
            "Başarımlar": .achievements,
            "Listelerim": .lists,
            "Notlar": .notes,
            "My Panels": .myPanels,
            "Akıllı Arama": .smartSearch,
            "Reading Order 2.0": .readingOrder2,
            "Reading Order": .readingOrder2,
            "Library Health": .libraryHealth,
            "Library Tools": .libraryTools,
            "Smart Collections": .smartCollections,
            "Sources & Sync": .sourcesSync,
            "Reading Journal": .journal,
            "İstatistikler": .statistics,
            "ComicPort Wrapped": .wrapped,
            "Okuma Geçmişi": .history,
            "Kaydedilenler": .saved,
            "Ayarlar": .settings
        ]
        return legacy[value] ?? .home
    }

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .browse: return "square.grid.2x2.fill"
        case .home: return "house.fill"
        case .library: return "books.vertical.fill"
        case .reading: return "book.pages.fill"
        case .toRead: return "bookmark.fill"
        case .completed: return "checkmark.circle.fill"
        case .recentAdded: return "plus.circle.fill"
        case .recentRead: return "clock.fill"
        case .favorites: return "heart.fill"
        case .characters: return "person.3.fill"
        case .series: return "books.vertical.circle.fill"
        case .achievements: return "trophy.fill"
        case .lists: return "list.bullet.rectangle"
        case .notes: return "pencil.and.scribble"
        case .myPanels: return "rectangle.stack.fill"
        case .smartSearch: return "text.viewfinder"
        case .readingOrder2: return "point.3.connected.trianglepath.dotted"
        case .libraryHealth: return "heart.text.clipboard.fill"
        case .libraryTools: return "wrench.and.screwdriver.fill"
        case .smartCollections: return "rectangle.3.group.fill"
        case .sourcesSync: return "externaldrive.connected.to.line.below"
        case .journal: return "book.pages.fill"
        case .statistics: return "chart.bar.fill"
        case .wrapped: return "sparkles.rectangle.stack.fill"
        case .history: return "clock.arrow.circlepath"
        case .saved: return "archivebox.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

private struct DashboardQuickReaderRoute: Identifiable {
    let id: UUID
}

struct DashboardShellView: View {
    @EnvironmentObject var store: LibraryStore
    @EnvironmentObject var theme: PanelThemeStore
    @Environment(\.panelAccentColor) private var accentColor
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selection: DashboardSection = .home
    @State private var searchText = ""
    @State private var showImporter = false
    @State private var quickReader: DashboardQuickReaderRoute?
    @State private var showCommandPalette = false
    @State private var sessionSummary: ComicPortReadingSessionSummary?
    @AppStorage("ComicPort.lastDashboardSection") private var persistedSection = DashboardSection.home.rawValue

    var body: some View {
        GeometryReader { proxy in
            let showSidebar = proxy.size.width >= 1000 && horizontalSizeClass == .regular

            ZStack(alignment: .bottom) {
                Color(red: 0.025, green: 0.035, blue: 0.05)
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    if showSidebar {
                        DashboardSidebar(selection: $selection)
                            .frame(width: ComicPortPlatform.isMac ? 246 : 220)
                    }

                    VStack(spacing: 0) {
                        if selection != .settings {
                        DashboardTopBar(
                            searchText: $searchText,
                            showImporter: $showImporter,
                            compact: !showSidebar
                        )

                        Divider().opacity(0.18)
                        }

                        DashboardContent(selection: $selection, searchText: searchText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }


            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !ComicPortPlatform.isMac || !showSidebar {
                    DashboardBottomBar(selection: $selection)
                        .padding(.horizontal, showSidebar ? 250 : 18)
                        .padding(.vertical, 8)
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: ComicArchiveFormat.allowedImportTypes,
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls): urls.forEach(store.importFile)
                case .failure(let error): store.importError = error.localizedDescription
                }
            }
            .alert("ComicPort", isPresented: Binding(
                get: { store.importError != nil },
                set: { if !$0 { store.importError = nil } }
            )) {
                Button("OK", role: .cancel) { store.importError = nil }
            } message: {
                Text(store.importError ?? "")
            }
        }
        .preferredColorScheme(.dark)
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ScreenshotSection"))) { note in
            if let route = note.object as? String {
                selection = DashboardSection.allCases.first { String(describing: $0) == route } ?? .home
                showImporter = route == "import"
            }
        }
        #endif
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ComicPortImportRequested"))) { _ in showImporter = true }
        .tint(accentColor)
        .task(id: store.pendingQuickAction?.rawValue) {
            processQuickActionIfNeeded()
        }
        .fullScreenCover(item: $quickReader) { route in
            ReadingSessionHostView(initialBookID: route.id)
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showCommandPalette) {
            ComicPortCommandPalette(
                selection: $selection,
                quickReader: $quickReader,
                showImporter: $showImporter
            )
            .environmentObject(store)
        }
        .alert(item: $sessionSummary) { summary in
            Alert(
                title: Text("Reading Session"),
                message: Text(
                    "\(summary.title)\n\(summary.pagesRead) page(s) · " +
                    "\(Int(summary.seconds / 60)) min"
                ),
                dismissButton: .default(Text("Done")) {
                    store.clearSessionSummary()
                }
            )
        }
        .overlay(alignment: .top) {
            if let notice = store.sourceNotice {
                HStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                    Text(notice).font(.callout.weight(.semibold))
                    Button { store.clearSourceNotice() } label: { Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("Dismiss notification")
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 10)
            }
        }
        .onAppear {
            selection = DashboardSection.restore(persistedSection)
            persistedSection = selection.rawValue
        }
        .onChange(of: selection) { _, newValue in
            searchText = ""
            persistedSection = newValue.rawValue
        }
        .onChange(of: store.lastSessionSummary) { _, summary in
            sessionSummary = summary
        }
    }

    private func processQuickActionIfNeeded() {
        guard let action = store.pendingQuickAction else { return }

        switch action {
        case .continueReading:
            let availableReading = store.books(with: .reading).first(where: \.fileAvailable)
            let recent = store.recentlyRead.first(where: \.fileAvailable)
            if let book = availableReading ?? recent {
                quickReader = DashboardQuickReaderRoute(id: book.id)
            } else {
                selection = .library
            }

        case .randomComic:
            let available = store.libraryBooks.filter(\.fileAvailable)
            if let book = available.randomElement() {
                quickReader = DashboardQuickReaderRoute(id: book.id)
            } else {
                selection = .library
            }

        case .smartSearch:
            selection = .smartSearch

        case .journal:
            selection = .journal

        case .readingGoal:
            selection = .home

        case .importComics:
            showImporter = true

        case .library:
            selection = .library

        case .home:
            selection = .home

        case .smartCollections:
            selection = .smartCollections

        case .sourcesSync:
            selection = .sourcesSync

        case .settings:
            selection = .settings

        case .commandPalette:
            showCommandPalette = true
        }

        store.clearPendingQuickAction()
    }
}

// MARK: - Sidebar

private struct DashboardSidebar: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @Binding var selection: DashboardSection
    #if targetEnvironment(macCatalyst)
    @State private var hoveredItem: DashboardSection?
    #endif

    private let primary: [DashboardSection] = [.home, .library, .reading, .toRead, .completed]
    private let secondary: [DashboardSection] = [.recentAdded, .recentRead, .favorites, .characters, .series, .readingOrder2, .achievements, .lists, .notes, .myPanels, .smartSearch, .libraryHealth, .libraryTools, .smartCollections]
    private let tertiary: [DashboardSection] = [.sourcesSync, .journal, .statistics, .wrapped, .history, .saved, .settings]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.18))
                    Image(systemName: "book.closed.fill")
                        .font(.title2.bold())
                        .foregroundStyle(accentColor)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: -2) {
                    Text("COMIC")
                    Text("PORT")
                }
                .font(.headline.bold())
                .italic()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            #if targetEnvironment(macCatalyst)
            List {
                desktopSection(primary)
                desktopSeparator
                desktopSection(secondary)
                desktopSeparator
                desktopSection(tertiary)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            #else
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    section(primary)
                    separator
                    section(secondary)
                    separator
                    section(tertiary)
                }
                .padding(.horizontal, 12)
            }
            #endif

            Spacer(minLength: 8)

            Button {
                selection = .settings
            } label: {
                StorageSidebarCard()
            }
            .buttonStyle(.plain)
            .help("Open storage and diagnostics")
            .padding(.horizontal, 12)
            .padding(.bottom, ComicPortPlatform.isMac ? 14 : 92)
        }
        .background {
            if ComicPortPlatform.isMac {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            } else {
                Color.black.opacity(0.48)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(.white.opacity(0.06)).frame(width: 1)
        }
    }

    private func section(_ items: [DashboardSection]) -> some View {
        VStack(spacing: 5) {
            ForEach(items) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = item }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .frame(width: 22)
                        Text(item.title)
                            .font(.subheadline.weight(selection == item ? .semibold : .regular))
                        Spacer()
                    }
                    .foregroundStyle(selection == item ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(
                        selection == item ? accentColor.opacity(0.88) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    #if targetEnvironment(macCatalyst)
    @ViewBuilder
    private func desktopSection(_ items: [DashboardSection]) -> some View {
        ForEach(items) { item in
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .frame(width: 22)
                Text(item.title)
                    .font(.subheadline.weight(selection == item ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(selection == item ? .white : .secondary)
            .padding(.horizontal, 11)
            .frame(height: 38)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        selection == item
                            ? accentColor.opacity(0.88)
                            : (hoveredItem == item ? Color.white.opacity(0.07) : Color.clear)
                    )
            )
            .onHover { hovering in
                hoveredItem = hovering ? item : (hoveredItem == item ? nil : hoveredItem)
            }
            .onTapGesture(count: 1) {
                // No selection animation on desktop: the destination changes on the
                // same click instead of waiting for an animated state transaction.
                selection = item
            }
            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private var desktopSeparator: some View {
        Divider()
            .opacity(0.14)
            .listRowInsets(EdgeInsets(top: 5, leading: 14, bottom: 5, trailing: 14))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
    #endif

    private var separator: some View {
        Divider().opacity(0.14).padding(.vertical, 5)
    }
}

// MARK: - Top Bar

private struct DashboardTopBar: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @Binding var searchText: String
    @Binding var showImporter: Bool
    let compact: Bool

    var body: some View {
        HStack(spacing: 14) {
            if compact {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed.fill").foregroundStyle(accentColor)
                    Text("COMICPORT").font(.headline.bold())
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search comics…", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear search")
                    .accessibilityLabel("Clear search")
                } else if ComicPortPlatform.isMac {
                    Text("⌘F")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(
                .white.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.055))
            )

            Spacer(minLength: 2)

            if store.importInProgressCount > 0 {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("\(store.importInProgressCount) importing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
            }

            Button {
                showImporter = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Import")
                    if ComicPortPlatform.isMac {
                        Text("⌘O")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(
                    accentColor,
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(store.importInProgressCount >= 8)
            .help("Import comics")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.18))
    }
}

// MARK: - Content Router

private struct DashboardContent: View {
    @EnvironmentObject var store: LibraryStore
    @Binding var selection: DashboardSection
    let searchText: String

    var body: some View {
        Group {
            if !searchText.isEmpty {
                DashboardBookCollectionView(
                    title: "Search Results",
                    books: store.libraryBooks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                )
            } else {
                switch selection {
                case .browse:
                    DashboardBrowseView(selection: $selection)
                case .home:
                    DashboardHomeView(selection: $selection)
                case .library:
                    DashboardBookCollectionView(title: "Library", books: store.libraryBooks)
                case .reading:
                    DashboardBookCollectionView(title: "Reading", books: store.books(with: .reading))
                case .toRead:
                    DashboardBookCollectionView(title: "To Read", books: store.books(with: .toRead))
                case .completed:
                    DashboardBookCollectionView(title: "Completed", books: store.books(with: .completed))
                case .recentAdded:
                    DashboardBookCollectionView(title: "Recently Added", books: store.recentlyAdded)
                case .recentRead:
                    DashboardBookCollectionView(title: "Recently Read", books: store.recentlyRead)
                case .favorites:
                    DashboardBookCollectionView(title: "Favorites", books: store.libraryBooks.filter { $0.favorite })
                case .characters:
                    CharacterLibraryView()
                case .series:
                    SeriesLibraryView()
                case .achievements:
                    AchievementsView()
                case .lists:
                    StoryArcLibraryView()
                case .notes:
                    NotesCenterView()
                case .myPanels:
                    MyPanelsView()
                case .smartSearch:
                    SmartSearchView()
                case .readingOrder2:
                    SmartReadingOrder2View()
                case .libraryHealth:
                    LibraryHealthView()
                case .libraryTools:
                    ComicPortLibraryToolsView()
                case .smartCollections:
                    ComicPortSmartCollectionsView()
                case .sourcesSync:
                    ComicPortSourcesSyncView()
                case .journal:
                    ReadingJournalView()
                case .statistics:
                    Stage7StatisticsView()
                case .wrapped:
                    PanelWrappedView()
                case .history:
                    DashboardHistoryView()
                case .saved:
                    DashboardSavedView()
                case .settings:
                    DashboardSettingsView()
                }
            }
        }
        .dashboardBottomClearance()
    }
}

extension View {
    /// Reserve the floating tab bar plus a 16-point breathing room for every destination.
    func dashboardBottomClearance() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: ComicPortPlatform.isMac ? 16 : 96)
        }
    }
}

// MARK: - Home Dashboard

private struct DashboardReaderRoute: Identifiable {
    let id: UUID
}

private struct DashboardHomeView: View {
    @EnvironmentObject var store: LibraryStore
    @Binding var selection: DashboardSection
    @State private var activeReader: DashboardReaderRoute?

    private var continueBooks: [ComicBook] {
        Array(store.libraryBooks.filter { $0.currentPage > 0 && $0.readingStatus != .completed }.prefix(4))
    }

    private var recentBooks: [ComicBook] {
        Array(store.recentlyAdded.prefix(6))
    }

    var body: some View {
        Group {
            if store.readerIsActive {
                Color.black
                    .ignoresSafeArea()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                if store.libraryBooks.isEmpty {
                    ContentUnavailableView {
                        Label("Your next story starts here", systemImage: "books.vertical")
                    } description: {
                        Text("Import a PDF, CBZ or CBR — free public-domain comics from the Internet Archive are a great place to start.")
                    } actions: {
                        Button("Import a Comic") { NotificationCenter.default.post(name: Notification.Name("ComicPortImportRequested"), object: nil) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                } else {
                    if store.analytics.history.contains(where: { $0.pagesRead > 0 }) || store.libraryBooks.contains(where: { $0.currentPage > 0 || $0.readingStatus == .completed }) {
                        ReadingSummaryStrip()

                    }

                if continueBooks.isEmpty {
                    DashboardPanel(title: "RECENTLY ADDED", trailing: "See All") { selection = .recentAdded } content: {
                        RecentlyAddedGrid(books: recentBooks) { activeReader = DashboardReaderRoute(id: $0.id) }
                    }
                } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        DashboardPanel(title: "CONTINUE READING", trailing: "See All") {
                            selection = .reading
                        } content: {
                            ContinueReadingRow(books: continueBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        DashboardPanel(title: "RECENTLY ADDED", trailing: "See All") {
                            selection = .recentAdded
                        } content: {
                            RecentlyAddedGrid(books: recentBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                        .frame(width: 380)
                    }

                    VStack(spacing: 16) {
                        DashboardPanel(title: "CONTINUE READING", trailing: "See All") { selection = .reading } content: {
                            ContinueReadingRow(books: continueBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                        DashboardPanel(title: "RECENTLY ADDED", trailing: "See All") { selection = .recentAdded } content: {
                            RecentlyAddedGrid(books: recentBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                    }
                }

                }
                CompactComicFactBar()
                CompactComicRecommendationBar()

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ReadingGoalDashboardCard()
                            .frame(maxWidth: .infinity)
                        ReadingCalendarCard()
                            .frame(maxWidth: .infinity)
                        PublisherCategoriesCard()
                            .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 16) {
                        ReadingGoalDashboardCard()
                        ReadingCalendarCard()
                        PublisherCategoriesCard()
                    }
                }
                }
            }
                    .padding(16)
                }
            }
        }
        .fullScreenCover(item: $activeReader) { route in
            ReadingSessionHostView(initialBookID: route.id)
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Summary Strip

private struct ReadingSummaryStrip: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var totalPagesRead = 0
    @State private var totalSeconds: TimeInterval = 0
    @State private var weekSeconds: TimeInterval = 0
    @State private var overallProgress: Double = 0

    private var refreshKey: String {
        let pageSignature = store.libraryBooks.reduce(0) { partial, book in
            partial &+ (book.currentPage &* 31) &+ book.pageCount
        }
        return "\(store.analytics.history.count)|\(store.libraryBooks.count)|\(pageSignature)"
    }

    var body: some View {
        DashboardPanel(title: "READING STATISTICS") {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    StatTile(icon: "books.vertical.fill", value: "\(store.libraryBooks.count)", label: "Comics", footnote: "in your library", tint: accentColor)
                    StatTile(icon: "book.pages.fill", value: formatNumber(totalPagesRead), label: "Pages Read", footnote: "total", tint: .green)
                    StatTile(icon: "clock.fill", value: shortDuration(totalSeconds), label: "Reading Time", footnote: "total", tint: .purple)
                    StatTile(icon: "calendar", value: shortDuration(weekSeconds), label: "This Week", footnote: "reading time", tint: .orange)
                    OverallProgressTile(progress: overallProgress)
                }
                VStack(spacing: 10) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    StatTile(icon: "books.vertical.fill", value: "\(store.libraryBooks.count)", label: "Comics", footnote: "in your library", tint: accentColor)
                    StatTile(icon: "book.pages.fill", value: formatNumber(totalPagesRead), label: "Pages Read", footnote: "total", tint: .green)
                    StatTile(icon: "clock.fill", value: shortDuration(totalSeconds), label: "Reading Time", footnote: "total", tint: .purple)
                    StatTile(icon: "calendar", value: shortDuration(weekSeconds), label: "This Week", footnote: "reading time", tint: .orange)
                }
                    OverallProgressTile(progress: overallProgress)
                }
            }
        }
        .task(id: refreshKey) {
            await refresh()
        }
    }

    @MainActor
    private func refresh() async {
        let history = store.analytics.history
        let books = store.libraryBooks

        let summary = await Task.detached(priority: .utility) {
            let pages = history.reduce(0) { $0 + $1.pagesRead }
            let seconds = history.reduce(0.0) { $0 + $1.seconds }

            let calendar = Calendar.current
            let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
            let week = history.reduce(0.0) { partial, entry in
                partial + (entry.date >= start ? entry.seconds : 0)
            }

            let total = books.reduce(0) { $0 + max(0, $1.pageCount) }
            let current = books.reduce(0) { partial, book in
                partial + Int((book.displayProgress * Double(max(0, book.pageCount))).rounded())
            }
            let progress = total == 0 ? 0 : min(1, Double(current) / Double(total))
            return (pages, seconds, week, progress)
        }.value

        guard !Task.isCancelled else { return }
        totalPagesRead = summary.0
        totalSeconds = summary.1
        weekSeconds = summary.2
        overallProgress = summary.3
    }
}
private struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let footnote: String
    let tint: Color

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 11).fill(tint.opacity(0.15))
                Image(systemName: icon).foregroundStyle(tint).font(.title3)
            }
            .frame(width: 43, height: 43)

            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStringKey(label)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text(value).font(.title3.bold()).lineLimit(1).minimumScaleFactor(0.75)
                Text(footnote).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct OverallProgressTile: View {
    @Environment(\.panelAccentColor) private var accentColor
    let progress: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(.white.opacity(0.08), lineWidth: 8)
                Circle().trim(from: 0, to: progress)
                    .stroke(progress == 0 ? Color.secondary : accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 1) {
                Text("Overall Progress").font(.caption).foregroundStyle(.secondary)
                Text("\(Int((progress * 100).rounded()))%").font(.title2.bold())
                Text("of your library").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Comic panels

private struct ContinueReadingRow: View {
    let books: [ComicBook]
    let onOpen: (ComicBook) -> Void

    var body: some View {
        if books.isEmpty {
            EmptyDashboardMessage(icon: "book.pages", text: "Start a comic to continue reading here.")
                .frame(height: 300)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(books) { book in
                        DashboardComicCard(book: book, width: 150, showProgress: true, onOpen: onOpen)
                    }
                }
            }
            .frame(minHeight: 300)
        }
    }
}

private struct RecentlyAddedGrid: View {
    let books: [ComicBook]
    let onOpen: (ComicBook) -> Void
    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 12)]

    var body: some View {
        if books.isEmpty {
            EmptyDashboardMessage(icon: "plus.circle", text: "Your imported comics appear here.")
                .frame(height: 300)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(books) { book in
                    DashboardMiniComicCard(book: book, onOpen: onOpen)
                }
            }
            .frame(minHeight: 300, alignment: .top)
        }
    }
}

private struct DashboardComicCard: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @State private var hovered = false
    @State private var showQuickPreview = false

    let book: ComicBook
    let width: CGFloat
    let showProgress: Bool
    var onOpen: ((ComicBook) -> Void)? = nil

    var body: some View {
        Group {
            if let onOpen {
                Button {
                    onOpen(book)
                } label: {
                    cardContent
                }
            } else {
                NavigationLink {
                    BookDetailView(bookID: book.id)
                } label: {
                    cardContent
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.toggleFavorite(id: book.id)
            } label: {
                Label(
                    book.favorite ? "Remove Favorite" : "Add Favorite",
                    systemImage: book.favorite ? "heart.slash" : "heart"
                )
            }

            Button {
                showQuickPreview = true
            } label: {
                Label("Quick Preview", systemImage: "eye")
            }

            Menu("Reading Status") {
                ForEach(ReadingStatus.allCases) { status in
                    Button {
                        store.setStatus(id: book.id, status: status)
                    } label: {
                        Label(status.rawValue, systemImage: status.systemImage)
                    }
                }
            }
        }
        #if targetEnvironment(macCatalyst)
        .onHover { value in
            withAnimation(.easeOut(duration: 0.12)) {
                hovered = value
            }
        }
        #endif
        .sheet(isPresented: $showQuickPreview) {
            ComicQuickPreviewView(bookID: book.id)
                .environmentObject(store)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 7) {
            DashboardCover(book: book)
                .frame(width: width, height: width * 1.48)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(book.displayTitle)
                    .truncationMode(.tail)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)

            if showProgress {
                Text("\(book.displayProgressPercent)% read")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: book.displayProgress)
                    .tint(book.displayProgress == 0 ? Color.secondary : accentColor)
                    .frame(width: width)
            }
        }
        #if targetEnvironment(macCatalyst)
        .scaleEffect(hovered ? 1.018 : 1)
        .shadow(
            color: .black.opacity(hovered ? 0.32 : 0.12),
            radius: hovered ? 12 : 4,
            y: hovered ? 6 : 2
        )
        #endif
    }
}

private struct DashboardMiniComicCard: View {
    @State private var hovered = false

    let book: ComicBook
    let onOpen: (ComicBook) -> Void

    var body: some View {
        Button {
            onOpen(book)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                DashboardCover(book: book)
                    .aspectRatio(0.67, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(book.displayTitle)
                    .truncationMode(.tail)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("\(book.displayProgressPercent)%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        #if targetEnvironment(macCatalyst)
        .scaleEffect(hovered ? 1.025 : 1)
        .onHover { value in
            withAnimation(.easeOut(duration: 0.12)) {
                hovered = value
            }
        }
        #endif
    }
}

private struct DashboardCover: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.055))
            CachedCoverImage(
                url: store.coverURL(for: book),
                comicType: book.type,
                maxPixelSize: 640
            )
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.07)))
    }
}

// MARK: - Goal Card

private struct ReadingGoalDashboardCard: View {
    @EnvironmentObject var store: LibraryStore

    var body: some View {
        DashboardPanel(title: "READING GOAL") {
            HStack(spacing: 20) {
                ZStack {
                    Circle().stroke(.white.opacity(0.08), lineWidth: 11)
                    Circle().trim(from: 0, to: store.todayGoalProgress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(store.todayStat.pages)").font(.title.bold())
                        Text("/\(store.analytics.dailyGoalPages)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(store.todayStat.pages) pages")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                    Text("Goal: \(store.analytics.dailyGoalPages) pages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(value: store.todayGoalProgress)
                        .tint(.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Reading Calendar

private struct ReadingCalendarCard: View {
    @EnvironmentObject var store: LibraryStore
    @State private var showFullCalendar = false
    @State private var calendarOpenDate = Date.now
    @State private var currentMonthEventMap: [String: [ComicCalendarEvent]] = [:]

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).year())
    }

    private var days: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: .now),
              let range = calendar.range(of: .day, in: .month, for: .now) else { return [] }
        let first = interval.start
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday + 5) % 7
        var result = Array<Date?>(repeating: nil, count: leading)
        for day in range {
            result.append(calendar.date(bySetting: .day, value: day, of: first))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    var body: some View {
        DashboardPanel(
            title: "READING CALENDAR",
            trailing: "Full Calendar",
            action: {
                calendarOpenDate = .now
                showFullCalendar = true
            }
        ) {
            VStack(spacing: 10) {
                Text(monthTitle.capitalized)
                    .font(.headline)
                HStack {
                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                        Text(day).font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                        if let date {
                            Button {
                                calendarOpenDate = date
                                showFullCalendar = true
                            } label: {
                                let key = PanelDayKey.string(date, calendar: calendar)
                                CalendarDayCell(
                                    date: date,
                                    pages: store.analytics.daily[key]?.pages ?? 0,
                                    isToday: calendar.isDateInToday(date),
                                    events: currentMonthEventMap[key] ?? []
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear.frame(height: 28)
                        }
                    }
                }


                Divider().opacity(0.12)

                if let next = ComicCalendarService.upcoming().first {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(next.1.kind.color)
                            .frame(width: 8, height: 8)
                        Text("Upcoming: \(next.1.title)")
                            .font(.caption.bold())
                            .lineLimit(1)
                        Spacer()
                        Text(next.0.formatted(.dateTime.day().month(.abbreviated)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 10) {
                    calendarLegend("Reading", color: .green)
                    calendarLegend("Special Day", color: .yellow)
                    Spacer()
                    Text("Tap the calendar to browse months and years")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .task {
            currentMonthEventMap = ComicCalendarService.eventMap(inMonthContaining: .now, calendar: calendar)
        }
        .fullScreenCover(isPresented: $showFullCalendar) {
            NavigationStack {
                ScrollView {
                    FullComicCalendarView(initialDate: calendarOpenDate)
                        .environmentObject(store)
                        .padding(18)
                }
                .navigationTitle("Reading Calendar")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            showFullCalendar = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func calendarLegend(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(LocalizedStringKey(title)).font(.caption2).foregroundStyle(.secondary)
        }
    }

}

private struct CalendarDayCell: View {
    let date: Date
    let pages: Int
    let isToday: Bool
    let events: [ComicCalendarEvent]

    var body: some View {
        CalendarDateBadge(
            date: date,
            pages: pages,
            isToday: isToday,
            events: events,
            size: 24
        )
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .center)
        .contentShape(Rectangle())
    }
}

// MARK: - Publishers

private struct PublisherCategoriesCard: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @State private var publishers: [(name: String, count: Int, icon: String)] = []

    private var refreshKey: String {
        store.libraryBooks
            .map { "\($0.id.uuidString)|\($0.title)" }
            .joined(separator: ";")
    }

    var body: some View {
        DashboardPanel(title: "CATEGORIES", trailing: "See All") {} content: {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                ForEach(Array(publishers.indices), id: \.self) { index in
                    let item = publishers[index]
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9).fill(.white.opacity(0.06))
                            Image(systemName: item.icon).foregroundStyle(accentColor)
                        }
                        .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name).font(.caption.bold()).lineLimit(1)
                            Text("\(item.count)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(9)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 11))
                }
            }
        }
        .task(id: refreshKey) {
            await rebuild()
        }
    }

    @MainActor
    private func rebuild() async {
        let titles = store.libraryBooks.map(\.title)
        let counts = await Task.detached(priority: .utility) {
            var result: [String: Int] = [:]
            for title in titles {
                let raw = LocalComicDatabase.bestMatch(title: title)?.record.publisher
                let low = raw?.lowercased() ?? ""
                let publisher: String
                if low.contains("dc") { publisher = "DC Comics" }
                else if low.contains("marvel") { publisher = "Marvel" }
                else if low.contains("image") { publisher = "Image Comics" }
                else if low.contains("dark horse") { publisher = "Dark Horse" }
                else if low.contains("boom") { publisher = "BOOM! Studios" }
                else { publisher = "Other" }
                result[publisher, default: 0] += 1
            }
            return result
        }.value
        guard !Task.isCancelled else { return }

        let order = ["DC Comics", "Marvel", "Image Comics", "Dark Horse", "BOOM! Studios", "Other"]
        publishers = order.map { name in
            (name: name, count: counts[name, default: 0], icon: publisherIcon(name))
        }
    }

    private func normalizedPublisher(_ raw: String?) -> String {
        guard let raw else { return "Other" }
        let low = raw.lowercased()
        if low.contains("dc") { return "DC Comics" }
        if low.contains("marvel") { return "Marvel" }
        if low.contains("image") { return "Image Comics" }
        if low.contains("dark horse") { return "Dark Horse" }
        if low.contains("boom") { return "BOOM! Studios" }
        return "Other"
    }

    private func publisherIcon(_ name: String) -> String {
        switch name {
        case "DC Comics": return "d.circle.fill"
        case "Marvel": return "m.square.fill"
        case "Image Comics": return "photo.stack.fill"
        case "Dark Horse": return "moon.stars.fill"
        case "BOOM! Studios": return "burst.fill"
        default: return "circle.grid.2x2.fill"
        }
    }
}
// MARK: - Reusable Panel

private struct DashboardPanel<Content: View>: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil
    @ViewBuilder let content: Content

    init(title: String, trailing: String? = nil, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                if let trailing {
                    Button(trailing) { action?() }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                }
            }
            content
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.045), Color.white.opacity(0.025)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06)))
    }
}

// MARK: - Collections

private struct DashboardBookCollectionView: View {
    let title: String
    let books: [ComicBook]

    @State private var quickFilter: LibraryQuickFilter = .all
    @AppStorage("ComicPort.Mac.LibraryCoverWidth")
    private var macCoverWidth: Double = 160

    private var cardWidth: CGFloat {
        ComicPortPlatform.isMac
            ? CGFloat(min(max(macCoverWidth, 132), 220))
            : 155
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(
                    minimum: cardWidth,
                    maximum: cardWidth + 18
                ),
                spacing: ComicPortPlatform.isMac ? 16 : 18
            )
        ]
    }

    private var supportsQuickTabs: Bool {
        title == "Library" || title == "Search Results"
    }

    private var filteredBooks: [ComicBook] {
        guard supportsQuickTabs else { return books }
        switch quickFilter {
        case .all: return books
        case .reading: return books.filter { $0.readingStatus == .reading }
        case .toRead: return books.filter { $0.readingStatus == .toRead }
        case .completed: return books.filter { $0.readingStatus == .completed }
        case .favorites: return books.filter(\.favorite)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if supportsQuickTabs {
                        Picker("Library Filter", selection: $quickFilter) {
                            ForEach(LibraryQuickFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                    }

                    if ComicPortPlatform.isMac {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.largeTitle.bold())
                                Text("\(filteredBooks.count) comics")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "rectangle.grid.3x2")
                                .foregroundStyle(.secondary)

                            Slider(
                                value: $macCoverWidth,
                                in: 132...220,
                                step: 4
                            )
                            .frame(width: 150)
                            .help("Adjust cover size")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                    }

                    if filteredBooks.isEmpty {
                        EmptyDashboardMessage(
                            icon: "books.vertical",
                            text: "No comics here yet."
                        )
                        .padding(.top, ComicPortPlatform.isMac ? 60 : 100)
                    } else {
                        LazyVGrid(
                            columns: columns,
                            alignment: .leading,
                            spacing: ComicPortPlatform.isMac ? 20 : 22
                        ) {
                            ForEach(filteredBooks) { book in
                                DashboardComicCard(
                                    book: book,
                                    width: cardWidth,
                                    showProgress: true
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(ComicPortPlatform.isMac ? "" : title)
        }
    }
}

// MARK: - Detailed Statistics

private struct DashboardStatisticsView: View {
    @EnvironmentObject var store: LibraryStore

    private var totalPages: Int { store.analytics.history.reduce(0) { $0 + $1.pagesRead } }
    private var totalSeconds: TimeInterval { store.analytics.history.reduce(0) { $0 + $1.seconds } }
    private var sessions: Int { store.analytics.history.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Statistics").font(.largeTitle.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
                    DetailStatCard(icon: "book.pages.fill", title: "Pages Read", value: formatNumber(totalPages), tint: .green)
                    DetailStatCard(icon: "clock.fill", title: "Total Time", value: shortDuration(totalSeconds), tint: .purple)
                    DetailStatCard(icon: "rectangle.stack.fill", title: "Reading Sessions", value: "\(sessions)", tint: .blue)
                    DetailStatCard(icon: "checkmark.circle.fill", title: "Completed", value: "\(store.books(with: .completed).count)", tint: .orange)
                    DetailStatCard(icon: "heart.fill", title: "Favori", value: "\(store.libraryBooks.filter { $0.favorite }.count)", tint: .pink)
                    DetailStatCard(icon: "trophy.fill", title: "Achievements", value: "\(store.achievementProfile.unlockedIDs.count) / \(AchievementCatalog.all.count)", tint: .yellow)
                }
                ReadingCalendarCard()
            }
            .padding(20)
            .padding(.bottom, 70)
        }
    }
}

private struct DetailStatCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 50, height: 50)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading) {
                Text(title).foregroundStyle(.secondary)
                Text(value).font(.title2.bold())
            }
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - History / Saved / Settings

private struct DashboardHistoryView: View {
    @EnvironmentObject var store: LibraryStore

    var body: some View {
        NavigationStack {
            List {
                if store.analytics.history.isEmpty {
                    ContentUnavailableView("No reading history yet", systemImage: "clock.arrow.circlepath")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.analytics.history) { entry in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(store.bookTitle(for: entry.bookID)).font(.headline)
                            Text("Page \(entry.startPage + 1) → \(entry.endPage + 1) • \(entry.pagesRead) pages")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("\(entry.date.formatted(date: .abbreviated, time: .shortened)) • \(shortDuration(entry.seconds))")
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 5)
                        .listRowBackground(Color.white.opacity(0.025))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Reading History")
        }
    }
}

private struct DashboardSavedView: View {
    @EnvironmentObject var store: LibraryStore

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.savedDataBooks.isEmpty {
                    EmptyDashboardMessage(icon: "archivebox", text: "No archived or offloaded comics.")
                        .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(store.savedDataBooks) { book in
                            HStack(spacing: 14) {
                                DashboardCover(book: book)
                                    .frame(width: 58, height: 86)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .opacity(book.fileAvailable ? 1 : 0.48)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(book.displayTitle).font(.headline)
                                    Text(book.fileAvailable ? (book.isArchived ? "Archived" : "Outside Library") : "Not on this device")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text("\(book.displayProgressPercent)% • \(book.readingStatus.rawValue)")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Saved")
        }
    }
}

private struct DashboardSettingsView: View {
    @EnvironmentObject var store: LibraryStore
    @EnvironmentObject var theme: PanelThemeStore
    @Environment(\.panelAccentColor) private var accentColor

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    Stepper("Daily goal: \(store.analytics.dailyGoalPages) pages", value: Binding(
                        get: { store.analytics.dailyGoalPages },
                        set: { store.setDailyGoal($0) }
                    ), in: 1...1000, step: 5)

                    Toggle("Automatically open the next issue", isOn: Binding(
                        get: { store.autoOpenNextIssue },
                        set: { store.setAutoOpenNextIssue($0) }
                    ))
                    .tint(accentColor)

                    Toggle("Use Guided Panel View by default", isOn: Binding(
                        get: { store.guidedPanelModeEnabled },
                        set: { store.setGuidedPanelModeEnabled($0) }
                    ))
                    .tint(accentColor)

                    Text("When a series is detected, the next issue can open automatically after the last page.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Appearance") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                        ForEach(PanelAccentTheme.releaseChoices) { option in
                            Button {
                                theme.accent = option
                            } label: {
                                HStack(spacing: 9) {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 20, height: 20)
                                    Text(option.rawValue)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if theme.accent == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(option.color)
                                    }
                                }
                                .padding(10)
                                .background(
                                    theme.accent == option ? option.color.opacity(0.12) : Color.secondary.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Your accent color is used for menus, buttons and progress. Achievement rarity colors stay unchanged.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Data & Privacy") {
                    NavigationLink {
                        BackupRestoreView()
                            .environmentObject(store)
                            .environmentObject(theme)
                    } label: {
                        Label("Backup & Restore", systemImage: "externaldrive.badge.icloud")
                    }


                }

                Section("Storage") {
                    Text("Storage Optimizer")
                    Text("Optimize PDF and archive storage from a comic’s detail page. The original is preserved until the new copy is verified.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Health & Diagnostics") {
                    NavigationLink {
                        ComicPortDiagnosticsView()
                            .environmentObject(store)
                    } label: {
                        Label(
                            "Diagnostics & Release Health",
                            systemImage: "stethoscope"
                        )
                    }

                    Text("Runs local-only storage and library checks. No diagnostic data is uploaded.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    LabeledContent("Platform", value: ComicPortPlatform.displayName)
                    LabeledContent("Price", value: String(localized: "Free forever"))
                    LabeledContent("Version", value: ComicPortRelease.version)

                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


private struct ComicPortDiagnosticsView: View {
    @EnvironmentObject var store: LibraryStore

    @State private var snapshot: ComicPortDiagnosticSnapshot?
    @State private var isRunning = false
    @State private var actionMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diagnostics & Release Health")
                            .font(.largeTitle.bold())

                        Text(
                            "Local checks for storage, library integrity and this device’s environment."
                        )
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task { await refresh() }
                    } label: {
                        Label(
                            "Run Checks",
                            systemImage: "arrow.clockwise"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)
                }

                if isRunning {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Checking ComicPort locally…")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                if let snapshot {
                    healthSummary(snapshot)
                    libraryCard(snapshot)
                    storageCard(snapshot)
                    integrationCard(snapshot)
                    actionsCard(snapshot)
                } else if !isRunning {
                    ContentUnavailableView(
                        "Diagnostics not run yet",
                        systemImage: "stethoscope",
                        description: Text(
                            "Run the checks to create a local ComicPort health report."
                        )
                    )
                    .frame(minHeight: 280)
                }
            }
            .padding(20)
        }
        .navigationTitle("Diagnostics")
        .task {
            if snapshot == nil {
                await refresh()
            }
        }
    }

    private func healthSummary(
        _ value: ComicPortDiagnosticSnapshot
    ) -> some View {
        HStack(spacing: 14) {
            Image(
                systemName: value.missingFiles == 0
                    ? "checkmark.seal.fill"
                    : "exclamationmark.triangle.fill"
            )
            .font(.system(size: 34))
            .foregroundStyle(
                value.missingFiles == 0 ? .green : .orange
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    value.missingFiles == 0
                        ? "Core library looks healthy"
                        : "\(value.missingFiles) missing-file record(s)"
                )
                .font(.title3.bold())

                Text(
                    "Checked \(value.checkedAt.formatted(date: .abbreviated, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("LOCAL ONLY")
                .font(.caption2.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    .green.opacity(0.10),
                    in: Capsule()
                )
        }
        .padding(18)
        .background(
            .white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func libraryCard(
        _ value: ComicPortDiagnosticSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Library", systemImage: "books.vertical.fill")
                .font(.title3.bold())

            diagnosticRows([
                ("Library comics", "\(value.libraryBooks)"),
                ("Available files", "\(value.availableFiles)"),
                ("Missing files", "\(value.missingFiles)"),
                ("Smart Collections", "\(value.smartCollections)"),
                ("Source folders", "\(value.sourceFolders)"),
                ("Reading sessions", "\(value.historyEntries)")
            ])
        }
        .comicPortDiagnosticCard()
    }

    private func storageCard(
        _ value: ComicPortDiagnosticSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                "Local Storage",
                systemImage: "internaldrive.fill"
            )
            .font(.title3.bold())

            diagnosticRows([
                ("Comic files", formatBytes(value.bookBytes)),
                ("Covers", formatBytes(value.coverBytes)),
                ("Search index", formatBytes(value.searchBytes)),
                ("Book info", formatBytes(value.infoBytes)),
                ("Notes", formatBytes(value.noteBytes)),
                ("My Panels", formatBytes(value.panelBytes)),
                ("ComicPort documents total", formatBytes(value.documentBytes))
            ])
        }
        .comicPortDiagnosticCard()
    }

    private func integrationCard(
        _ value: ComicPortDiagnosticSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                "Desktop Integration",
                systemImage: "macwindow"
            )
            .font(.title3.bold())

            diagnosticRows([
                ("Platform", ComicPortPlatform.displayName),
                ("Finder / Open With", "PDF + comic archives"),
                (
                    "Local Sources",
                    value.sourceFolders > 0
                        ? "Configured"
                        : "Optional"
                ),
                (
                    "Sync Folder",
                    value.syncConfigured
                        ? "Configured"
                        : "Optional"
                ),
                ("WidgetKit", "Paused"),
                ("ComicPort server", "Not used")
            ])
        }
        .comicPortDiagnosticCard()
    }

    private func actionsCard(
        _ value: ComicPortDiagnosticSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                "Maintenance",
                systemImage: "wrench.and.screwdriver"
            )
            .font(.title3.bold())

            HStack {
                Button {
                    Task {
                        let freed = await store.performSafeCacheCleanup()
                        actionMessage =
                            "Freed \(formatBytes(freed)) from safe caches."
                        await refresh()
                    }
                } label: {
                    Label(
                        "Clean Safe Caches",
                        systemImage: "sparkles"
                    )
                }

                Button {
                    UIPasteboard.general.string =
                        supportReport(value)
                    actionMessage =
                        "Support report copied to clipboard."
                } label: {
                    Label(
                        "Copy Support Report",
                        systemImage: "doc.on.doc"
                    )
                }

                #if targetEnvironment(macCatalyst)
                Button {
                    UIApplication.shared.open(store.booksURL)
                } label: {
                    Label(
                        "Open Library Folder",
                        systemImage: "folder"
                    )
                }
                #endif
            }

            if let actionMessage {
                Text(actionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(
                "Safe cache cleanup removes only reproducible cache data. Comic files, history, notes, ratings, favorites, Smart Collections and backups are preserved."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .comicPortDiagnosticCard()
    }

    @ViewBuilder
    private func diagnosticRows(
        _ rows: [(String, String)]
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(
                Array(rows.enumerated()),
                id: \.offset
            ) { index, row in
                HStack {
                    Text(row.0)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(row.1)
                        .font(.callout.monospacedDigit())
                }
                .padding(.vertical, 7)

                if index < rows.count - 1 {
                    Divider().opacity(0.16)
                }
            }
        }
    }

    @MainActor
    private func refresh() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        let documents = store.documentsURL
        let booksURL = store.booksURL
        let coversURL = store.coversURL
        let searchURL = store.smartSearchURL
        let infoURL = store.infoCacheURL
        let notesURL = store.notesURL
        let panelsURL = store.panelsURL

        let libraryBooks = store.libraryBooks.count
        let availableFiles = store.books.filter(\.fileAvailable).count
        let missingFiles = store.books.filter { !$0.fileAvailable }.count
        let smartCollections = store.smartCollections.count
        let sourceFolders = store.sourceFolders.count
        let historyEntries = store.analytics.history.count
        let syncConfigured = store.syncLocation != nil

        let sizes = await Task.detached(priority: .utility) {
            (
                ComicPortDiagnosticsView.folderBytes(booksURL),
                ComicPortDiagnosticsView.folderBytes(coversURL),
                ComicPortDiagnosticsView.folderBytes(searchURL),
                ComicPortDiagnosticsView.folderBytes(infoURL),
                ComicPortDiagnosticsView.folderBytes(notesURL),
                ComicPortDiagnosticsView.folderBytes(panelsURL),
                ComicPortDiagnosticsView.folderBytes(documents)
            )
        }.value

        guard !Task.isCancelled else { return }

        snapshot = ComicPortDiagnosticSnapshot(
            checkedAt: .now,
            libraryBooks: libraryBooks,
            availableFiles: availableFiles,
            missingFiles: missingFiles,
            smartCollections: smartCollections,
            sourceFolders: sourceFolders,
            historyEntries: historyEntries,
            syncConfigured: syncConfigured,
            bookBytes: sizes.0,
            coverBytes: sizes.1,
            searchBytes: sizes.2,
            infoBytes: sizes.3,
            noteBytes: sizes.4,
            panelBytes: sizes.5,
            documentBytes: sizes.6
        )
    }

    nonisolated private static func folderBytes(
        _ url: URL
    ) -> Int64 {
        let fm = FileManager.default

        if let direct = try? url.resourceValues(
            forKeys: [.fileSizeKey]
        ).fileSize,
           !url.hasDirectoryPath {
            return Int64(direct)
        }

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [
                .isRegularFileKey,
                .fileSizeKey
            ],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var result: Int64 = 0

        for case let child as URL in enumerator {
            guard !Task.isCancelled else { break }

            let values = try? child.resourceValues(
                forKeys: [
                    .isRegularFileKey,
                    .fileSizeKey
                ]
            )

            if values?.isRegularFile == true {
                result += Int64(values?.fileSize ?? 0)
            }
        }

        return result
    }

    private func formatBytes(
        _ bytes: Int64
    ) -> String {
        ByteCountFormatter.string(
            fromByteCount: bytes,
            countStyle: .file
        )
    }

    private func supportReport(
        _ value: ComicPortDiagnosticSnapshot
    ) -> String {
        """
        ComicPort Support Report
        ========================
        Version: \(ComicPortRelease.version)
        Platform: \(ComicPortPlatform.displayName)
        Checked: \(value.checkedAt.formatted())

        Library comics: \(value.libraryBooks)
        Available files: \(value.availableFiles)
        Missing files: \(value.missingFiles)
        Smart Collections: \(value.smartCollections)
        Source folders: \(value.sourceFolders)
        Reading sessions: \(value.historyEntries)
        Sync folder: \(value.syncConfigured ? "Configured" : "Not configured")

        Comic files: \(formatBytes(value.bookBytes))
        Covers: \(formatBytes(value.coverBytes))
        Search index: \(formatBytes(value.searchBytes))
        Book info: \(formatBytes(value.infoBytes))
        Notes: \(formatBytes(value.noteBytes))
        My Panels: \(formatBytes(value.panelBytes))
        Documents total: \(formatBytes(value.documentBytes))

        WidgetKit: Paused
        ComicPort server: Not used
        """
    }
}

private struct ComicPortDiagnosticSnapshot: Sendable {
    let checkedAt: Date
    let libraryBooks: Int
    let availableFiles: Int
    let missingFiles: Int
    let smartCollections: Int
    let sourceFolders: Int
    let historyEntries: Int
    let syncConfigured: Bool
    let bookBytes: Int64
    let coverBytes: Int64
    let searchBytes: Int64
    let infoBytes: Int64
    let noteBytes: Int64
    let panelBytes: Int64
    let documentBytes: Int64
}

private extension View {
    func comicPortDiagnosticCard() -> some View {
        self
            .padding(18)
            .background(
                .white.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.055))
            )
    }
}

private struct DashboardPlaceholderView: View {
    let title: String
    let icon: String
    let detail: String

    var body: some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(detail))
    }
}

private struct EmptyDashboardMessage: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 58, height: 58)
                .background(
                    .white.opacity(0.045),
                    in: RoundedRectangle(cornerRadius: 15)
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Storage

private struct StorageSidebarCard: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var libraryBytes: Int64 = 0
    @State private var totalCapacity: Int64 = 0
    @State private var availableCapacity: Int64 = 0

    private var refreshKey: String {
        let availableCount = store.books.filter(\.fileAvailable).count
        return "\(store.books.count)|\(availableCount)"
    }

    private var usedRatio: Double {
        guard totalCapacity > 0 else { return 0 }
        return min(1, Double(totalCapacity - availableCapacity) / Double(totalCapacity))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Storage").font(.subheadline.bold())
                Spacer()
                Image(systemName: "gearshape")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(.white.opacity(0.08), lineWidth: 6)
                    Circle().trim(from: 0, to: usedRatio)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("%\(Int((usedRatio * 100).rounded()))").font(.caption2.bold())
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(byteString(libraryBytes)).font(.caption.bold())
                    Text("comics").font(.caption2).foregroundStyle(.secondary)
                    Text("\(byteString(availableCapacity)) available").font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.06)))
        .task(id: refreshKey) {
            await refreshStorage()
        }
    }

    @MainActor
    private func refreshStorage() async {
        let urls = store.books.compactMap { book in
            book.fileAvailable ? store.fileURL(for: book) : nil
        }
        let documentURL = store.documentsURL

        let snapshot = await Task.detached(priority: .utility) {
            var bytes: Int64 = 0
            for url in urls {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                bytes += Int64(size)
            }
            let values = try? documentURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            return (
                bytes,
                Int64(values?.volumeTotalCapacity ?? 0),
                Int64(values?.volumeAvailableCapacity ?? 0)
            )
        }.value

        guard !Task.isCancelled else { return }
        libraryBytes = snapshot.0
        totalCapacity = snapshot.1
        availableCapacity = snapshot.2
    }
}


// MARK: - Stage 18 Smart Collections

private struct ComicPortSmartCollectionsView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var showCreate = false

    private let columns = [
        GridItem(
            .adaptive(minimum: 210, maximum: 310),
            spacing: 14
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Smart Collections")
                                .font(.largeTitle.bold())
                            Text(
                                "Dynamic shelves that update automatically as your library changes."
                            )
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            showCreate = true
                        } label: {
                            Label(
                                "New Smart Collection",
                                systemImage: "plus"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text("BUILT-IN")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: columns,
                        alignment: .leading,
                        spacing: 14
                    ) {
                        ForEach(ComicPortBuiltInCollection.allCases) {
                            collection in

                            let books = store.books(for: collection)

                            NavigationLink {
                                DashboardBookCollectionView(
                                    title: collection.rawValue,
                                    books: books
                                )
                            } label: {
                                smartCollectionCard(
                                    title: collection.rawValue,
                                    subtitle: "\(books.count) comics",
                                    icon: collection.systemImage,
                                    emphasized: false
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        Text("MY SMART COLLECTIONS")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(store.smartCollections.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }

                    if store.smartCollections.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(
                                "Create your first rule-based shelf",
                                systemImage: "wand.and.stars"
                            )
                            .font(.headline)

                            Text(
                                "Combine title, rating, reading status, favorite, PDF/archive and manga rules."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(18)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(
                            .white.opacity(0.035),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    } else {
                        LazyVGrid(
                            columns: columns,
                            alignment: .leading,
                            spacing: 14
                        ) {
                            ForEach(store.smartCollections) { collection in
                                let books = store.books(for: collection)

                                NavigationLink {
                                    DashboardBookCollectionView(
                                        title: collection.name,
                                        books: books
                                    )
                                } label: {
                                    smartCollectionCard(
                                        title: collection.name,
                                        subtitle: "\(books.count) comics",
                                        icon: "slider.horizontal.3",
                                        emphasized: true
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(
                                        "Delete Smart Collection",
                                        role: .destructive
                                    ) {
                                        store.deleteSmartCollection(
                                            collection.id
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Smart Collections")
            .sheet(isPresented: $showCreate) {
                ComicPortCreateSmartCollectionView()
                    .environmentObject(store)
            }
        }
    }

    private func smartCollectionCard(
        title: String,
        subtitle: String,
        icon: String,
        emphasized: Bool
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    emphasized ? accentColor : .secondary
                )
                .frame(width: 48, height: 48)
                .background(
                    (emphasized
                        ? accentColor.opacity(0.16)
                        : Color.white.opacity(0.05)),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            minHeight: 82,
            alignment: .leading
        )
        .background(
            .white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.055))
        )
    }
}

private struct ComicPortCreateSmartCollectionView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var titleContains = ""
    @State private var minimumRating = 0
    @State private var status = "Any"
    @State private var favoritesOnly = false
    @State private var format: ComicPortSmartFormat = .any
    @State private var mangaOnly = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Collection") {
                    TextField("Name", text: $name)
                    TextField(
                        "Title contains (optional)",
                        text: $titleContains
                    )
                }

                Section("Rules") {
                    Picker(
                        "Reading Status",
                        selection: $status
                    ) {
                        Text("Any").tag("Any")
                        ForEach(ReadingStatus.allCases) { option in
                            Text(option.rawValue)
                                .tag(option.rawValue)
                        }
                    }

                    Picker(
                        "Minimum Rating",
                        selection: $minimumRating
                    ) {
                        ForEach(0...5, id: \.self) { rating in
                            Text(
                                rating == 0
                                    ? "Any"
                                    : "\(rating)+ stars"
                            )
                            .tag(rating)
                        }
                    }

                    Picker("Format", selection: $format) {
                        ForEach(ComicPortSmartFormat.allCases) {
                            option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    Toggle(
                        "Favorites only",
                        isOn: $favoritesOnly
                    )

                    Toggle(
                        "Manga / right-to-left only",
                        isOn: $mangaOnly
                    )
                }

                Section {
                    Text(
                        "Smart Collections are filters, not duplicate files. A comic can appear in any number of collections without using extra storage."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Smart Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.createSmartCollection(
                            name: name,
                            titleContains: titleContains,
                            minimumRating: minimumRating,
                            statusRawValue: status,
                            favoritesOnly: favoritesOnly,
                            format: format,
                            mangaOnly: mangaOnly
                        )
                        dismiss()
                    }
                    .disabled(
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
        #if targetEnvironment(macCatalyst)
        .frame(
            minWidth: 560,
            idealWidth: 620,
            minHeight: 520,
            idealHeight: 600
        )
        #endif
    }
}

// MARK: - Stage 18 Sources & Sync

private struct ComicPortSourcesSyncView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var showSourceFolderPicker = false
    @State private var showSyncFolderPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Sources & Sync")
                                .font(.largeTitle.bold())

                            Text(
                                "Watch local comic folders and keep reading state in a portable sync folder."
                            )
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    sourcePanel
                    syncPanel
                    privacyPanel
                }
                .padding(20)
            }
            .navigationTitle("Sources & Sync")
        }
        .fileImporter(
            isPresented: $showSourceFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result,
               let folder = urls.first {
                store.addSourceFolder(folder)
            }
        }
        .fileImporter(
            isPresented: $showSyncFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result,
               let folder = urls.first {
                store.setComicPortSyncFolder(folder)
            }
        }
    }

    private var sourcePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    "Local Sources",
                    systemImage: "folder.badge.gearshape"
                )
                .font(.title3.bold())

                Spacer()

                if store.sourceScanInProgress {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task {
                        await store.scanAllSourceFolders()
                    }
                } label: {
                    Label(
                        "Scan",
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(
                    store.sourceFolders.isEmpty ||
                    store.sourceScanInProgress
                )

                Button {
                    showSourceFolderPicker = true
                } label: {
                    Label(
                        "Add Folder",
                        systemImage: "plus"
                    )
                }
                .buttonStyle(.borderedProminent)
            }

            Text(
                "ComicPort recursively checks these folders for new PDF/CBZ/CBR/RAR/7z/CB7/CBT/ZIP/TAR comics. Only newly detected files are queued for import."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if store.sourceFolders.isEmpty {
                sourceEmptyState
            } else {
                ForEach(store.sourceFolders) { source in
                    sourceRow(source)
                }
            }
        }
        .padding(18)
        .background(
            .white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var sourceEmptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.title2)
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 3) {
                Text("No source folders yet")
                    .font(.headline)
                Text(
                    "Add your Comics folder once; later scans only inspect new/changed file fingerprints."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func sourceRow(
        _ source: ComicPortSourceFolder
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(source.displayName)
                    .font(.headline)

                Text(source.originalPath)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text(
                        "\(source.lastFoundCount) supported"
                    )
                    Text(
                        "• \(source.lastImportedCount) new last scan"
                    )

                    if let last = source.lastScannedAt {
                        Text(
                            "• \(last.formatted(date: .abbreviated, time: .shortened))"
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let error = source.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Menu {
                Button("Scan This Folder") {
                    Task {
                        await store.scanSourceFolder(source.id)
                    }
                }

                Button("Forget Scan History") {
                    store.clearSourceSeenHistory(source.id)
                }

                Divider()

                Button(
                    "Remove Source",
                    role: .destructive
                ) {
                    store.removeSourceFolder(source.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(12)
        .background(
            .white.opacity(0.025),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }

    private var syncPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    "ComicPort Sync Folder",
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .font(.title3.bold())

                Spacer()

                Button {
                    store.syncComicPortNow()
                } label: {
                    Label(
                        "Sync Now",
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(store.syncLocation == nil)

                Button {
                    showSyncFolderPicker = true
                } label: {
                    Label(
                        store.syncLocation == nil
                            ? "Choose Folder"
                            : "Change Folder",
                        systemImage: "folder"
                    )
                }
                .buttonStyle(.borderedProminent)
            }

            if let location = store.syncLocation {
                HStack(spacing: 12) {
                    Image(systemName: "externaldrive.fill.badge.checkmark")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.displayName)
                            .font(.headline)

                        Text(store.syncStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let last = store.syncLastRun {
                            Text(
                                "Last sync: \(last.formatted(date: .abbreviated, time: .shortened))"
                            )
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    Button(
                        "Disconnect",
                        role: .destructive
                    ) {
                        store.clearComicPortSyncFolder()
                    }
                }
                .padding(12)
                .background(
                    .white.opacity(0.025),
                    in: RoundedRectangle(cornerRadius: 12)
                )
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "externaldrive")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No sync folder selected")
                            .font(.headline)

                        Text(
                            "Choose a normal folder, iCloud Drive folder or another synced folder."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Text(
                "ComicPort writes a small ComicPort-Sync-v1.json file. It syncs reading progress, status, favorites, ratings, daily goal and mapped reading history — not the comic files themselves."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            .white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(
                "Local-first by design",
                systemImage: "lock.shield.fill"
            )
            .font(.headline)
            .foregroundStyle(.green)

            Text(
                "ComicPort does not connect to a ComicPort server. Source scanning happens on this \(ComicPortPlatform.isMac ? "Mac" : "iPad"). Sync Folder uses a folder you explicitly choose; if that folder is backed by iCloud Drive or another provider, your cloud provider’s app handles the network transfer."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(
                "Performance 10: recursive folder enumeration runs off the main thread, known file fingerprints prevent repeated imports, sync is metadata-only, and automatic sync writes are debounced."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            .green.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}



private enum LibraryQuickFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case reading = "Reading"
    case toRead = "To Read"
    case completed = "Completed"
    case favorites = "Favorites"
    var id: String { rawValue }
}

private struct ComicQuickPreviewView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID

    private var book: ComicBook? { store.books.first { $0.id == bookID } }

    var body: some View {
        NavigationStack {
            Group {
                if let book {
                    HStack(alignment: .top, spacing: 22) {
                        CachedCoverImage(
                            url: store.coverURL(for: book),
                            comicType: book.type,
                            maxPixelSize: 900
                        )
                        .frame(width: 230, height: 350)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(book.displayTitle)
                    .truncationMode(.tail)
                                .font(.largeTitle.bold())

                            Label(
                                "\(book.pageCount) pages",
                                systemImage: "book.pages"
                            )

                            Label(
                                "\(book.displayProgressPercent)% read",
                                systemImage: "chart.line.uptrend.xyaxis"
                            )

                            ProgressView(value: book.displayProgress)

                            if let info = store.loadOfflineInfo(
                                bookID: book.id
                            ) {
                                if let series = info.series {
                                    LabeledContent(
                                        "Series",
                                        value: series
                                    )
                                }

                                if let issue = info.issue {
                                    LabeledContent(
                                        "Issue",
                                        value: issue
                                    )
                                }

                                if let publisher = info.publisher {
                                    LabeledContent(
                                        "Publisher",
                                        value: publisher
                                    )
                                }

                                if !info.summary.isEmpty {
                                    Text(info.summary)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(8)
                                }
                            }

                            Spacer()

                            NavigationLink {
                                BookDetailView(bookID: book.id)
                            } label: {
                                Label(
                                    "Open Details",
                                    systemImage: "info.circle"
                                )
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(
                            maxWidth: 460,
                            alignment: .leading
                        )
                    }
                    .padding(24)
                } else {
                    ContentUnavailableView(
                        "Comic unavailable",
                        systemImage: "book.closed",
                        description: Text(
                            "This comic is no longer in the library."
                        )
                    )
                }
            }
        }
        .navigationTitle("Quick Preview")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 760, minHeight: 480)
        #endif
    }
}

private struct ComicPortLibraryToolsView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var duplicates: [ComicPortDuplicateGroup] = []
    @State private var storage: [ComicPortSeriesStorage] = []
    @State private var scanning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Library Tools").font(.largeTitle.bold())
                            Text("Exact duplicate detection and storage-by-series analysis run locally.")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            Task { await refresh() }
                        } label: {
                            Label(scanning ? "Scanning…" : "Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(scanning)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Exact Duplicates", systemImage: "doc.on.doc.fill")
                            .font(.title2.bold())
                        if scanning && duplicates.isEmpty { ProgressView() }
                        else if duplicates.isEmpty {
                            Label("No byte-for-byte duplicates found", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            ForEach(duplicates) { group in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(group.bookIDs.count) identical files").font(.headline)
                                    ForEach(Array(group.titles.enumerated()), id: \.offset) { _, title in
                                        Text(LocalizedStringKey(title)).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(12)
                                .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(18)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Storage by Series", systemImage: "internaldrive.fill")
                            .font(.title2.bold())
                        ForEach(storage.prefix(40)) { row in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.series).font(.headline)
                                    Text("\(row.comicCount) comic(s)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: row.bytes, countStyle: .file))
                                    .monospacedDigit()
                            }
                            Divider().opacity(0.12)
                        }
                    }
                    .padding(18)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(20)
            }
            .task { await refresh() }
        }
    }

    @MainActor private func refresh() async {
        guard !scanning else { return }
        scanning = true
        async let d = store.exactDuplicateGroups()
        async let s = store.storageBySeries()
        duplicates = await d
        storage = await s
        scanning = false
    }
}

private struct ComicPortCommandPalette: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: DashboardSection
    @Binding var quickReader: DashboardQuickReaderRoute?
    @Binding var showImporter: Bool
    @State private var query = ""

    private var matchingBooks: [ComicBook] {
        guard !query.isEmpty else { return Array(store.recentlyRead.prefix(6)) }
        return Array(store.libraryBooks.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }.prefix(12))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "command")
                TextField("Type a command or comic title…", text: $query)
                    .textFieldStyle(.plain)
            }
            .font(.title3)
            .padding(16)

            Divider().opacity(0.16)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    paletteButton("Import Comics", "square.and.arrow.down") { showImporter = true; dismiss() }
                    paletteButton("Library", "books.vertical.fill") { selection = .library; dismiss() }
                    paletteButton("Smart Collections", "rectangle.3.group.fill") { selection = .smartCollections; dismiss() }
                    paletteButton("Library Tools", "wrench.and.screwdriver.fill") { selection = .libraryTools; dismiss() }
                    paletteButton("Sources & Sync", "externaldrive") { selection = .sourcesSync; dismiss() }
                    paletteButton("Settings", "gearshape") { selection = .settings; dismiss() }

                    Divider().opacity(0.16).padding(.vertical, 6)
                    Text(query.isEmpty ? "RECENT" : "COMICS")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(matchingBooks) { book in
                        paletteButton(book.title, "book.closed") {
                            quickReader = DashboardQuickReaderRoute(id: book.id)
                            dismiss()
                        }
                    }
                }
                .padding(12)
            }
        }
        #if targetEnvironment(macCatalyst)
        .frame(width: 620, height: 560)
        #endif
    }

    private func paletteButton(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 24)
                Text(title).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Bar

private struct DashboardBottomBar: View {
    @Environment(\.panelAccentColor) private var accentColor
    @Binding var selection: DashboardSection

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tabs: [(DashboardSection, String, String)] = [
        (.home, "Home", "house.fill"),
        (.library, "Library", "books.vertical.fill"),
        (.characters, "Characters", "person.3.fill"),
        (.browse, "Browse", "square.grid.2x2.fill"),
        (.settings, "Settings", "gearshape.fill")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.indices), id: \.self) { index in
                let tab = tabs[index]
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { selection = tab.0 }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.2).font(.system(size: 18, weight: .semibold))
                        Text(tab.1).font(.caption2)
                    }
                    .foregroundStyle(selection == tab.0 ? accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selection == tab.0 ? accentColor.opacity(0.11) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.07)))
        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }
}

// MARK: - Formatting

private func formatNumber(_ value: Int) -> String {
    value.formatted(.number.grouping(.automatic))
}

func shortDuration(_ seconds: TimeInterval) -> String {
    let totalMinutes = Int(seconds) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 { return "\(hours)h \(minutes)m" }
    return "\(minutes)m"
}

private func byteString(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}

#if DEBUG
/// CI-only routing: uses production views and real asynchronous import, never mock books.
struct ScreenshotRootView: View {
    @EnvironmentObject var store: LibraryStore
    let route: String
    @State private var ready = false
    @State private var section = DashboardSection.home
    @State private var importing = false
    private var book: ComicBook? {
        store.books.first { route.hasPrefix("pdf") ? $0.type == .pdf : $0.type != .pdf }
    }
    var body: some View {
        Group {
            if !ready { ProgressView("Preparing screenshot…") }
            else if route == "detail", let book { NavigationStack { BookDetailView(bookID: book.id) } }
            else if route == "preview", let book { ComicQuickPreviewView(bookID: book.id) }
            else if ["cbz", "cbz-hidden", "pdf", "guided", "reader-settings"].contains(route), let book {
                ReaderView(bookID: book.id)
            } else { DashboardShellView().onAppear {
                NotificationCenter.default.post(name: Notification.Name("ScreenshotSection"), object: route)
            } }
        }
        .preferredColorScheme(.dark)
        .task {
            let landscape = ProcessInfo.processInfo.environment["SCREENSHOT_ORIENTATION"] == "landscape"
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                UIDevice.current.setValue(landscape ? UIInterfaceOrientation.landscapeLeft.rawValue : UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: landscape ? .landscapeLeft : .portrait))
            }
            if route != "empty" && store.books.isEmpty {
                let folder = store.documentsURL.appendingPathComponent("ScreenshotSamples")
                for url in (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [] { store.importFile(url) }
                while store.importInProgressCount > 0 { try? await Task.sleep(for: .milliseconds(250)) }
            }
            store.setGuidedPanelModeEnabled(route == "guided")
            if let book {
                store.updateReaderSettings(bookID: book.id) { settings in
                    settings.pageLayout = .single
                    settings.fitMode = .fitWidth
                    settings.autoHideControls = false
                }
            }
            ready = true
            try? await Task.sleep(for: .seconds(8))
            let status = "route=\(route) books=\(store.books.count) error=\(store.importError ?? "none")"
            try? status.write(to: store.documentsURL.appendingPathComponent("screenshot-ready.txt"), atomically: true, encoding: .utf8)
        }
    }
}
#endif
