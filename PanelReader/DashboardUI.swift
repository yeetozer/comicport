import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - Dashboard Navigation

enum DashboardSection: String, CaseIterable, Identifiable, Hashable {
    case home = "Ana Sayfa"
    case bookGoals = "Okuma Hedefleri"
    case bookQuotes = "Alıntı Defteri"
    case bookShelves = "Kitap Raflarım"
    case bookMaintenance = "Kitap Bakımı"
    case library = "Kütüphanem"
    case reading = "Okunuyor"
    case toRead = "Okunacak"
    case completed = "Tamamlandı"
    case recentAdded = "Son Eklenenler"
    case recentRead = "Son Okunanlar"
    case favorites = "Favoriler"
    case characters = "Karakterler"
    case series = "Seriler"
    case achievements = "Başarımlar"
    case lists = "Listelerim"
    case notes = "Notlar"
    case myPanels = "My Panels"
    case smartSearch = "Akıllı Arama"
    case readingOrder2 = "Reading Order 2.0"
    case libraryHealth = "Library Health"
    case libraryTools = "Library Tools"
    case smartCollections = "Smart Collections"
    case sourcesSync = "Sources & Sync"
    case journal = "Reading Journal"
    case statistics = "İstatistikler"
    case wrapped = "ComicPort Wrapped"
    case history = "Okuma Geçmişi"
    case saved = "Kaydedilenler"
    case settings = "Ayarlar"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bookGoals: return "target"
        case .bookQuotes: return "quote.bubble"
        case .bookShelves: return "books.vertical"
        case .bookMaintenance: return "wrench.and.screwdriver"
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
    @AppStorage("ComicPort.ComicHub.sceneTheme") private var comicSceneTheme = ComicHubSceneTheme.city.rawValue
    @AppStorage("ComicPort.lastDashboardSection") private var persistedSection = DashboardSection.home.rawValue

    var body: some View {
        GeometryReader { proxy in
            let showSidebar = proxy.size.width >= 1000 && horizontalSizeClass == .regular

            ZStack(alignment: .bottom) {
                (store.activeReaderProfile == .books
                    ? Color(red: 0.12, green: 0.075, blue: 0.045)
                    : Color(red: 0.025, green: 0.035, blue: 0.05))
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    if showSidebar {
                        DashboardSidebar(selection: $selection)
                            .environment(\.panelAccentColor, store.activeReaderProfile == .books ? Color(red: 0.88, green: 0.65, blue: 0.36) : (store.activeReaderProfile == .comics ? ComicHubPalette.red : accentColor))
                            .frame(width: ComicPortPlatform.isMac ? 246 : 220)
                    }

                    VStack(spacing: 0) {
                        DashboardTopBar(
                            searchText: $searchText,
                            showImporter: $showImporter,
                            compact: !showSidebar
                        )
                        .environment(\.panelAccentColor, store.activeReaderProfile == .books ? Color(red: 0.88, green: 0.65, blue: 0.36) : (store.activeReaderProfile == .comics ? ComicHubPalette.red : accentColor))

                        Divider().opacity(0.18)

                        DashboardContent(
                            selection: $selection,
                            searchText: searchText
                        )
                        .environment(\.panelAccentColor, store.activeReaderProfile == .books ? Color(red: 0.88, green: 0.65, blue: 0.36) : (store.activeReaderProfile == .comics ? ComicHubPalette.red : accentColor))
                        .id(store.activeReaderProfile.rawValue)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                    }
                }

                if !ComicPortPlatform.isMac || !showSidebar {
                    DashboardBottomBar(selection: $selection)
                        .padding(.horizontal, showSidebar ? 250 : 18)
                        .padding(.bottom, 8)
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
                Button("Tamam", role: .cancel) { store.importError = nil }
            } message: {
                Text(store.importError ?? "")
            }
        }
        .id(comicSceneTheme)
        .preferredColorScheme(.dark)
        .environment(\.comicHubEnabled, store.activeReaderProfile == .comics)
        .tint(store.activeReaderProfile == .books ? Color(red: 0.88, green: 0.65, blue: 0.36) : (store.activeReaderProfile == .comics ? ComicHubPalette.red : accentColor))
        .onChange(of: store.activeReaderProfile) { _, _ in
            searchText = ""
            selection = .home
        }
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
            let book = store.books.first { $0.id == summary.bookID }
            let isBook = book?.contentKind == .book
            let duration = summary.seconds < 60 ? "\(Int(summary.seconds)) sn" : "\(Int(summary.seconds / 60)) dk"
            let detail = book?.type == .epub ? duration : (isBook ? "\(summary.pagesRead) sayfa · \(duration)" : "\(summary.pagesRead) page(s) · \(Int(summary.seconds / 60)) min")
            return Alert(
                title: Text(isBook ? "Okuma oturumu" : "Reading Session"),
                message: Text("\(summary.title)\n\(detail)"),
                dismissButton: .default(Text(isBook ? "Tamam" : "Done")) {
                    store.clearSessionSummary()
                }
            )
        }
        .overlay(alignment: .top) {
            if let notice = store.sourceNotice {
                HStack(spacing: 10) {
                    Image(systemName: "folder.badge.plus")
                    Text(notice).font(.callout.weight(.semibold))
                    Button { store.clearSourceNotice() } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .comicHubMaterial(.ultraThinMaterial, in: Capsule())
                .padding(.top, 10)
            }
        }
        .onAppear {
            if let restored = DashboardSection.allCases.first(where: { $0.rawValue == persistedSection }) {
                let bookSections: Set<DashboardSection> = [.bookGoals, .bookQuotes, .bookShelves, .bookMaintenance]
                selection = store.activeReaderProfile != .books && bookSections.contains(restored) ? .home : restored
            }
        }
        .onChange(of: selection) { _, newValue in
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
    private var secondary: [DashboardSection] {
        if store.activeReaderProfile == .books { return [.bookGoals, .bookQuotes, .bookShelves, .bookMaintenance, .achievements, .notes, .smartSearch] }
        return [.recentAdded, .recentRead, .favorites, .characters, .series, .readingOrder2, .achievements, .lists, .notes, .myPanels, .smartSearch, .libraryHealth, .libraryTools, .smartCollections]
    }
    private let tertiary: [DashboardSection] = [.sourcesSync, .journal, .statistics, .wrapped, .history, .saved, .settings]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Button {
                    let profiles = ComicPortReaderProfile.allCases
                    let current = profiles.firstIndex(of: store.activeReaderProfile) ?? 0
                    store.setReaderProfile(profiles[(current + 1) % profiles.count])
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentColor.opacity(0.18))
                        Image(systemName: store.activeReaderProfile.systemImage)
                            .font(.title2.bold())
                            .foregroundStyle(accentColor)
                    }
                    .frame(width: 40, height: 40)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sonraki okuyucu profiline geç")
                .help("Sonraki okuyucu profiline geç")

                VStack(alignment: .leading, spacing: -2) {
                    Text(store.activeReaderProfile == .books ? "BOOK" : "COMIC")
                    Text(store.activeReaderProfile == .books || store.activeReaderProfile == .comics ? "HUB" : "PORT")
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
            if store.activeReaderProfile == .books {
                Color(red: 0.16, green: 0.10, blue: 0.065)
            } else if store.activeReaderProfile == .comics {
                ComicHubPalette.canvas
            } else if ComicPortPlatform.isMac {
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
                        Text(item.rawValue)
                            .font(.subheadline.weight(selection == item ? .semibold : .regular))
                        Spacer()
                    }
                    .foregroundStyle(selection == item ? (store.activeReaderProfile == .comics ? ComicHubPalette.onAccent : Color.white) : Color.secondary)
                    .padding(.horizontal, 12)
                    .frame(height: 42)
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
                Text(item.rawValue)
                    .font(.subheadline.weight(selection == item ? .semibold : .regular))
                Spacer()
            }
            .foregroundStyle(selection == item ? (store.activeReaderProfile == .comics ? ComicHubPalette.onAccent : Color.white) : Color.secondary)
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

                TextField(
                    store.activeReaderProfile == .mix
                        ? "Tüm kitaplıkta ara…"
                        : "\(store.activeReaderProfile.rawValue) içinde ara…",
                    text: $searchText
                )
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
                } else if ComicPortPlatform.isMac {
                    Text("⌘F")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
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

            Menu {
                Picker(
                    "Reader Profile",
                    selection: Binding(
                        get: { store.activeReaderProfile },
                        set: { store.setReaderProfile($0) }
                    )
                ) {
                    ForEach(ComicPortReaderProfile.allCases) { profile in
                        Label(
                            profile.rawValue,
                            systemImage: profile.systemImage
                        )
                        .tag(profile)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: store.activeReaderProfile.systemImage
                    )

                    VStack(alignment: .leading, spacing: 0) {
                        Text(
                            store.activeReaderProfile == .mix
                                ? "Mix"
                                : store.activeReaderProfile.rawValue
                        )
                        .font(.subheadline.weight(.semibold))

                        Text(
                            store.activeReaderProfile == .mix
                                ? "All Library"
                                : "Reader Profile"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(
                    .white.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(.white.opacity(0.08))
                )
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .help("Switch Reader Profile")

            Button {
                showImporter = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("İçe Aktar")
                    if ComicPortPlatform.isMac {
                        Text("⌘O")
                            .font(.caption2.monospaced())
                            .foregroundStyle((store.activeReaderProfile == .comics ? ComicHubPalette.onAccent : Color.white).opacity(0.72))
                    }
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    accentColor,
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .foregroundStyle(store.activeReaderProfile == .comics ? ComicHubPalette.onAccent : Color.white)
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
        let query = BookLibraryQuery(searchText)
        Group {
            if !query.isEmpty {
                DashboardBookCollectionView(
                    title: "Arama Sonuçları",
                    books: store.profileLibraryBooks.filter { query.matches($0) },
                    emptyMessage: store.activeReaderProfile == .books ? "Aramana uyan kitap bulunamadı." : "Aramana uyan çizgi roman bulunamadı.",
                    showsQuickFilters: true
                )
            } else {
                switch selection {
                case .bookGoals: BookHubGoalsView()
                case .bookQuotes: BookHubQuotesView()
                case .bookShelves: BookHubShelvesView()
                case .bookMaintenance: BookHubMaintenanceView()
                case .home:
                    if store.activeReaderProfile == .books {
                        BookHubHomeView(selection: $selection)
                    } else if store.activeReaderProfile == .comics {
                        ComicHubHomeView(selection: $selection)
                    } else {
                        DashboardHomeView(selection: $selection)
                    }
                case .library:
                    DashboardBookCollectionView(title: store.activeReaderProfile == .comics ? "Kütüphanem" : (store.activeReaderProfile == .mix ? "Mix Kitaplık" : store.activeReaderProfile.rawValue), books: store.profileLibraryBooks, showsQuickFilters: true)
                case .reading:
                    DashboardBookCollectionView(title: "Okunuyor", books: store.profileBooks(with: .reading))
                case .toRead:
                    DashboardBookCollectionView(title: "Okunacak", books: store.profileBooks(with: .toRead))
                case .completed:
                    DashboardBookCollectionView(title: "Tamamlandı", books: store.profileBooks(with: .completed))
                case .recentAdded:
                    DashboardBookCollectionView(title: "Son Eklenenler", books: store.profileRecentlyAdded)
                case .recentRead:
                    DashboardBookCollectionView(title: "Son Okunanlar", books: store.profileRecentlyRead)
                case .favorites:
                    DashboardBookCollectionView(title: "Favoriler", books: store.profileLibraryBooks.filter { $0.favorite })
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
        .bookHubSurface(when: store.activeReaderProfile == .books)
        .comicHubSurface(when: store.activeReaderProfile == .comics)
        .padding(.bottom, ComicPortPlatform.isMac ? 14 : 78)
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
        Array(store.profileBooks(with: .reading).prefix(4))
    }

    private var recentBooks: [ComicBook] {
        Array(store.profileRecentlyAdded.prefix(6))
    }

    var body: some View {
        Group {
            if store.readerIsActive {
                Color.black
                    .ignoresSafeArea()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(
                        systemName: store.activeReaderProfile.systemImage
                    )
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        .white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            store.activeReaderProfile == .mix
                                ? "Mix Kitaplık"
                                : store.activeReaderProfile.rawValue
                        )
                        .font(.headline)

                        Text(store.activeReaderProfile.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(store.profileLibraryBooks.count) kitap")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(
                    .white.opacity(0.035),
                    in: RoundedRectangle(cornerRadius: 14)
                )

                ReadingSummaryStrip()

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        DashboardPanel(title: "DEVAM ETTİĞİN YERDEN", trailing: "Tümünü Gör") {
                            selection = .reading
                        } content: {
                            ContinueReadingRow(books: continueBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        DashboardPanel(title: "SON EKLENENLER", trailing: "Tümünü Gör") {
                            selection = .recentAdded
                        } content: {
                            RecentlyAddedGrid(books: recentBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                        .frame(width: 380)
                    }

                    VStack(spacing: 16) {
                        DashboardPanel(title: "DEVAM ETTİĞİN YERDEN", trailing: "Tümünü Gör") { selection = .reading } content: {
                            ContinueReadingRow(books: continueBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                        DashboardPanel(title: "SON EKLENENLER", trailing: "Tümünü Gör") { selection = .recentAdded } content: {
                            RecentlyAddedGrid(books: recentBooks) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                    }
                }

                if store.activeReaderProfile != .books {
                    CompactComicFactBar()
                    CompactComicRecommendationBar()
                }

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

// A bounded, lazy bookshelf; no metadata scans or image decoding on the UI thread.
private struct BookHubHomeView: View {
    @State private var selectedShelf: BookShelfGroup?
    @State private var selectedReview: BookMetadataReviewField?
    @EnvironmentObject var store: LibraryStore
    @Binding var selection: DashboardSection
    @State private var activeReader: DashboardReaderRoute?
    private let amber = Color(red: 0.88, green: 0.65, blue: 0.36)

    var body: some View {
        let books = store.profileLibraryBooks
        let reading = Array(books.filter { $0.readingStatus == .reading }
            .sorted { ($0.lastReadAt ?? .distantPast) > ($1.lastReadAt ?? .distantPast) }.prefix(8))
        let recent = Array(books.sorted { $0.addedAt > $1.addedAt }.prefix(12))
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("BOOK HUB", systemImage: "books.vertical.fill")
                        .font(.caption.weight(.semibold)).tracking(3).foregroundStyle(amber)
                    Text("Kütüphanene hoş geldin")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    Text("Bir kitap seç, kaldığın yerden devam et.")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 24) {
                        Label("\(books.count) kitap", systemImage: "books.vertical")
                        Label("\(books.filter { $0.readingStatus == .reading }.count) okunuyor", systemImage: "book.pages")
                        Label("\(books.filter { $0.readingStatus == .completed }.count) tamamlandı", systemImage: "checkmark.circle")
                    }
                    .font(.callout).foregroundStyle(amber).padding(.top, 8)
                }
                .padding(28).frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Color(red: 0.29, green: 0.18, blue: 0.10), Color(red: 0.17, green: 0.105, blue: 0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
                BookHubGoalCard()
                Button("Hedeflerimi düzenle") { selection = .bookGoals }
                if books.isEmpty {
                    ContentUnavailableView("İlk rafını oluştur", systemImage: "books.vertical", description: Text("İçe Aktar ile ilk kitabını rafına ekle."))
                }
                shelf("Kaldığın yerden", books: reading, section: .reading)
                shelf("Okunacak kitapların", books: BookHubReadingQueue.books(from: books), section: .toRead)
                homeBookshelves(books: books)
                authorShelves(books: books)
                shelf("Rafına yeni eklenenler", books: recent, section: .recentAdded)
                metadataShelves("Yayınevlerine göre", groups: BookShelfGroup.groups(in: books, byAuthors: false), icon: "building.2.fill")
                if !books.isEmpty { metadataReview(books: books) }
                HStack {
                    Label("Kütüphanen çevrimdışı da yanında", systemImage: "internaldrive")
                    Spacer()
                    Button("Tüm kitaplar") { selection = .library }
                }
                .font(.callout).foregroundStyle(amber).padding(18)
            }
            .padding(24)
        }
        .sheet(item: $selectedShelf) { group in
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Kapat") { selectedShelf = nil }
                }.padding()
                DashboardBookCollectionView(title: group.title, books: store.profileLibraryBooks.filter { group.bookIDs.contains($0.id) })
            }.bookHubSurface()
            #if targetEnvironment(macCatalyst)
            .frame(minWidth: 600, minHeight: 620)
            #endif
        }
        .sheet(item: $selectedReview) { field in
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Kapat") { selectedReview = nil }
                }.padding()
                DashboardBookCollectionView(title: field.rawValue, books: store.profileLibraryBooks.filter { field.needsReview($0) }, emptyMessage: "Bu alanda kontrol edilecek kitap yok.")
            }.bookHubSurface()
            #if targetEnvironment(macCatalyst)
            .frame(minWidth: 600, minHeight: 620)
            #endif
        }
        .fullScreenCover(item: $activeReader) { route in
            ReadingSessionHostView(initialBookID: route.id)
                .environmentObject(store).preferredColorScheme(.dark)
        }
    }

    private func metadataReview(books: [ComicBook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kitap bilgilerini gözden geçir").font(.system(.title2, design: .serif, weight: .semibold))
            Text("Bu alanlar isteğe bağlıdır. Bir liste açıp kitap bilgilerini düzenleyebilirsin.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(BookMetadataReviewField.allCases) { field in
                let count = books.filter { field.needsReview($0) }.count
                Button { selectedReview = field } label: {
                    HStack {
                        Text(field.rawValue)
                        Spacer()
                        Text("\(count) kitap").monospacedDigit()
                        Image(systemName: "chevron.right")
                    }.padding(12).background(amber.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }.buttonStyle(.plain).disabled(count == 0)
            }
        }.padding(20).background(.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 16))
    }

    private func homeBookshelves(books: [ComicBook]) -> some View {
        let shelves: [(String, String, [ComicBook])] = [
            ("Okunuyor", "book.pages", books.filter { $0.readingStatus == .reading }),
            ("Okunacak", "bookmark", books.filter { $0.readingStatus == .toRead }),
            ("Tamamlandı", "checkmark.circle", books.filter { $0.readingStatus == .completed }),
            ("Favoriler", "star", books.filter { $0.favorite })
        ]
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Raflarım").font(.system(.title2, design: .serif, weight: .semibold))
                Spacer()
                Button("Tüm raflar") { selection = .bookShelves }.foregroundStyle(amber)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 18)], spacing: 18) {
                ForEach(shelves, id: \.0) { item in
                    Button {
                        selectedShelf = BookShelfGroup(id: "status-" + item.0, title: item.0, bookIDs: Set(item.2.map(\.id)))
                    } label: {
                        BookHubShelfPanel(title: item.0, icon: item.1, books: item.2)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func authorShelves(books: [ComicBook]) -> some View {
        let groups = BookShelfGroup.groups(in: books, byAuthors: true)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Yazarlar").font(.system(.title2, design: .serif, weight: .semibold))
            if groups.isEmpty {
                Text("Kitaplarına yazar bilgisi eklediğinde burada görünür.").foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 26) {
                        ForEach(groups) { group in
                            Button { selectedShelf = group } label: {
                                VStack(spacing: 12) {
                                    BookHubAuthorAvatar(name: group.title, size: 88)
                                    Text(group.title).font(.system(.callout, design: .serif, weight: .semibold))
                                        .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.85)
                                        .frame(width: 134, height: 44, alignment: .top).fixedSize(horizontal: false, vertical: true)
                                    Text("\(group.bookIDs.count) kitap").font(.caption).foregroundStyle(.secondary)
                                }.frame(width: 134).padding(.vertical, 8)
                            }.buttonStyle(.plain)
                            .accessibilityLabel("\(group.title), \(group.bookIDs.count) kitap")
                        }
                    }.padding(.horizontal, 4)
                }
            }
        }.padding(22)
        .background(Color(red: 0.13, green: 0.10, blue: 0.075), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(amber.opacity(0.13)))
    }

    private func metadataShelves(_ title: String, groups: [BookShelfGroup], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(.title2, design: .serif, weight: .semibold))
            if groups.isEmpty {
                Text("Kitap bilgilerine bu alanı eklediğinde raflar burada görünür.").foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(groups) { group in
                            Button { selectedShelf = group } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(group.title, systemImage: icon).lineLimit(2)
                                    Text("\(group.bookIDs.count) kitap").font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(width: 190, alignment: .leading).padding(16)
                                .background(amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func shelf(_ title: String, books: [ComicBook], section: DashboardSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title).font(.system(.title2, design: .serif, weight: .semibold))
                Spacer()
                Button("Tümünü gör") { selection = section }.foregroundStyle(amber)
            }
            if books.isEmpty {
                Text("Bu raf henüz boş.").foregroundStyle(.secondary).padding(.vertical, 20)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 20) {
                        ForEach(books) { book in
                            DashboardComicCard(book: book, width: 150, showProgress: true) { book in
                                activeReader = DashboardReaderRoute(id: book.id)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color(red: 0.43, green: 0.27, blue: 0.14), Color(red: 0.23, green: 0.13, blue: 0.065)], startPoint: .top, endPoint: .bottom))
                .frame(height: 10).shadow(color: .black.opacity(0.3), radius: 4, y: 4)
        }
        .padding(20).background(.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 16))
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
        DashboardPanel(title: "OKUMA İSTATİSTİKLERİ") {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    StatTile(icon: "books.vertical.fill", value: "\(store.libraryBooks.count)", label: "Toplam Çizgi Roman", footnote: "koleksiyonunda", tint: accentColor)
                    StatTile(icon: "book.pages.fill", value: formatNumber(totalPagesRead), label: "Okuduğun Sayfa", footnote: "toplam", tint: .green)
                    StatTile(icon: "clock.fill", value: shortDuration(totalSeconds), label: "Okuma Süresi", footnote: "toplam", tint: .purple)
                    StatTile(icon: "calendar", value: shortDuration(weekSeconds), label: "Bu Hafta", footnote: "okuma süresi", tint: .orange)
                    OverallProgressTile(progress: overallProgress)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], spacing: 10) {
                    StatTile(icon: "books.vertical.fill", value: "\(store.libraryBooks.count)", label: "Toplam Çizgi Roman", footnote: "koleksiyonunda", tint: accentColor)
                    StatTile(icon: "book.pages.fill", value: formatNumber(totalPagesRead), label: "Okuduğun Sayfa", footnote: "toplam", tint: .green)
                    StatTile(icon: "clock.fill", value: shortDuration(totalSeconds), label: "Okuma Süresi", footnote: "toplam", tint: .purple)
                    StatTile(icon: "calendar", value: shortDuration(weekSeconds), label: "Bu Hafta", footnote: "okuma süresi", tint: .orange)
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
                partial + min(max(0, book.currentPage + 1), max(0, book.pageCount))
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
                Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
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
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 1) {
                Text("Genel İlerleme").font(.caption).foregroundStyle(.secondary)
                Text("%\(Int((progress * 100).rounded()))").font(.title2.bold())
                Text("koleksiyonunun").font(.caption2).foregroundStyle(.tertiary)
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
            EmptyDashboardMessage(icon: "book.pages", text: "Henüz devam ettiğin bir çizgi roman yok.")
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
            EmptyDashboardMessage(icon: "plus.circle", text: "Yeni eklenen çizgi roman yok.")
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
    var standsOnShelf = false

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

            Menu("Content Type") {
                ForEach(ComicPortContentKind.allCases) { kind in
                    Button {
                        store.setContentKind(
                            id: book.id,
                            kind: kind
                        )
                    } label: {
                        HStack {
                            Label(
                                kind.rawValue,
                                systemImage: kind.systemImage
                            )

                            if book.contentKind == kind {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
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

            if standsOnShelf { Color.clear.frame(height: 16) }

            Text(book.title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: width, alignment: .leading)

            if book.contentKind == .book, let authors = book.bookMetadata?.authors, !authors.isEmpty {
                Text(authors.joined(separator: ", "))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    .frame(width: width, alignment: .leading)
            }

            if showProgress {
                Text("%\(book.progressPercent) okundu")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: book.progress)
                    .tint(accentColor)
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
                Text(book.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("%\(book.progressPercent)")
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
                comicType: book.type, revision: book.coverRevision,
                maxPixelSize: CGFloat(BookHubPerformancePolicy.shelfCoverPixels)
            )
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.07)))
    }
}

// MARK: - Goal Card

private struct ReadingGoalDashboardCard: View {
    @EnvironmentObject var store: LibraryStore

    var body: some View {
        DashboardPanel(title: "OKUMA HEDEFİ") {
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
                    Text("Bugün")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(store.todayStat.pages) sayfa")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                    Text("Hedef: \(store.analytics.dailyGoalPages) sayfa")
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
            title: "OKUMA & ÇİZGİ ROMAN TAKVİMİ",
            trailing: "Tam Takvim",
            action: {
                calendarOpenDate = .now
                showFullCalendar = true
            }
        ) {
            VStack(spacing: 10) {
                Text(monthTitle.capitalized)
                    .font(.headline)
                HStack {
                    ForEach(["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"], id: \.self) { day in
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
                        Text("Yaklaşan: \(next.1.title)")
                            .font(.caption.bold())
                            .lineLimit(1)
                        Spacer()
                        Text(next.0.formatted(.dateTime.day().month(.abbreviated)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 10) {
                    calendarLegend("Okuma", color: .green)
                    calendarLegend("Özel Gün", color: .yellow)
                    Spacer()
                    Text("Takvime dokun: tüm ayları ve yılları aç")
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
                .comicHubSurface().navigationTitle("Okuma & Çizgi Roman Takvimi")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Kapat") {
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
            Text(title).font(.caption2).foregroundStyle(.secondary)
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
        DashboardPanel(title: "KATEGORİLER", trailing: "Tümünü Gör") {} content: {
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
                else { publisher = "Diğer" }
                result[publisher, default: 0] += 1
            }
            return result
        }.value
        guard !Task.isCancelled else { return }

        let order = ["DC Comics", "Marvel", "Image Comics", "Dark Horse", "BOOM! Studios", "Diğer"]
        publishers = order.map { name in
            (name: name, count: counts[name, default: 0], icon: publisherIcon(name))
        }
    }

    private func normalizedPublisher(_ raw: String?) -> String {
        guard let raw else { return "Diğer" }
        let low = raw.lowercased()
        if low.contains("dc") { return "DC Comics" }
        if low.contains("marvel") { return "Marvel" }
        if low.contains("image") { return "Image Comics" }
        if low.contains("dark horse") { return "Dark Horse" }
        if low.contains("boom") { return "BOOM! Studios" }
        return "Diğer"
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
    @EnvironmentObject var store: LibraryStore
    let title: String
    let books: [ComicBook]
    var emptyMessage: String? = nil
    var showsQuickFilters = false

    @AppStorage("ComicPort.BookHub.librarySort") private var bookSortRaw = BookLibrarySort.original.rawValue
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

    private var filteredBooks: [ComicBook] {
        let filtered = showsQuickFilters ? books.filter { quickFilter.matches($0) } : books
        guard store.activeReaderProfile == .books else { return filtered }
        return (BookLibrarySort(rawValue: bookSortRaw) ?? .original).sorted(filtered)
    }

    var body: some View {
        let displayedBooks = filteredBooks
        if store.activeReaderProfile == .comics {
            ComicHubCollectionView(title: title, books: books, showsQuickFilters: showsQuickFilters, emptyMessage: emptyMessage)
        } else {
            NavigationStack {
                GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if showsQuickFilters {
                            Picker(store.activeReaderProfile == .books ? "Okuma filtresi" : "Library Filter", selection: $quickFilter) {
                                ForEach(LibraryQuickFilter.allCases) { filter in
                                    Text(filter.label(forBooks: store.activeReaderProfile == .books)).tag(filter)
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
                                    Text("\(displayedBooks.count) \(store.activeReaderProfile == .books ? "kitap" : "çizgi roman")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: store.activeReaderProfile == .books ? "books.vertical" : "rectangle.grid.3x2")
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

                        if store.activeReaderProfile == .books {
                            HStack {
                                Text("Sıralama").foregroundStyle(.secondary)
                                Picker("Sıralama", selection: $bookSortRaw) {
                                    ForEach(BookLibrarySort.allCases) { sort in Text(sort.rawValue).tag(sort.rawValue) }
                                }.pickerStyle(.menu)
                                Spacer()
                            }.padding(.horizontal, 20)
                        }

                        if displayedBooks.isEmpty {
                            EmptyDashboardMessage(
                                icon: "books.vertical",
                                text: showsQuickFilters && quickFilter != .all ? (store.activeReaderProfile == .books ? "Seçili filtreye uyan kitap bulunamadı." : "No comics match the selected filter.") : (emptyMessage ?? (store.activeReaderProfile == .books ? "Bu bölümde henüz kitap yok." : "Bu bölümde henüz çizgi roman yok."))
                            )
                            .padding(.top, ComicPortPlatform.isMac ? 60 : 100)
                        } else if store.activeReaderProfile == .books {
                            BookHubLibraryShelfRows(books: displayedBooks, cardWidth: cardWidth,
                                                    availableWidth: geometry.size.width - 40)
                                .padding(.horizontal, 20).padding(.bottom, 20)
                        } else {
                            LazyVGrid(
                                columns: columns,
                                alignment: .leading,
                                spacing: ComicPortPlatform.isMac ? 20 : 22
                            ) {
                                ForEach(displayedBooks) { book in
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
                .bookHubSurface().comicHubSurface().navigationTitle(ComicPortPlatform.isMac ? "" : title)
                }
            }
        }
    }
}

// The row width determines shelf capacity; existing cards retain detail links,
// quick preview and status/favorite actions inside the wooden display.
private struct BookHubLibraryShelfRows: View {
    let books: [ComicBook]
    let cardWidth: CGFloat
    let availableWidth: CGFloat
    private let spacing: CGFloat = 20
    private var capacity: Int {
        max(1, Int((availableWidth - 44 + spacing) / (cardWidth + spacing)))
    }
    private var rows: [[ComicBook]] {
        stride(from: 0, to: books.count, by: capacity).map {
            Array(books[$0..<min($0 + capacity, books.count)])
        }
    }
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 22) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(row) { book in
                        DashboardComicCard(book: book, width: cardWidth,
                                           showProgress: true, standsOnShelf: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 22).padding(.top, 22).padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .top) {
                    VStack(spacing: 0) {
                        GeometryReader { geometry in
                            Image("BookHubShelfBackdrop").resizable().scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        }.frame(height: cardWidth * 1.48 + 22)
                        Rectangle()
                            .fill(LinearGradient(colors: [Color(red: 0.51, green: 0.33, blue: 0.18),
                                                         Color(red: 0.23, green: 0.13, blue: 0.065)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: 12)
                            .shadow(color: .black.opacity(0.4), radius: 4, y: 4)
                        Spacer(minLength: 0)
                    }.accessibilityHidden(true)
                }
                .background(Color(red: 0.16, green: 0.10, blue: 0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.83, green: 0.65, blue: 0.40).opacity(0.22)))
            }
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
                Text("İstatistikler").font(.largeTitle.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
                    DetailStatCard(icon: "book.pages.fill", title: "Okunan Sayfa", value: formatNumber(totalPages), tint: .green)
                    DetailStatCard(icon: "clock.fill", title: "Toplam Süre", value: shortDuration(totalSeconds), tint: .purple)
                    DetailStatCard(icon: "rectangle.stack.fill", title: "Okuma Oturumu", value: "\(sessions)", tint: .blue)
                    DetailStatCard(icon: "checkmark.circle.fill", title: "Tamamlanan", value: "\(store.books(with: .completed).count)", tint: .orange)
                    DetailStatCard(icon: "heart.fill", title: "Favori", value: "\(store.libraryBooks.filter { $0.favorite }.count)", tint: .pink)
                    DetailStatCard(icon: "trophy.fill", title: "Başarımlar", value: "\(store.achievementProfile.unlockedIDs.count) / \(AchievementCatalog.all.count)", tint: .yellow)
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
                    ContentUnavailableView("Henüz okuma geçmişi yok", systemImage: "clock.arrow.circlepath")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.analytics.history) { entry in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(store.bookTitle(for: entry.bookID)).font(.headline)
                            Text("Sayfa \(entry.startPage + 1) → \(entry.endPage + 1) • \(entry.pagesRead) sayfa")
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
            .comicHubSurface().navigationTitle("Okuma Geçmişi")
        }
    }
}

private struct DashboardSavedView: View {
    @EnvironmentObject var store: LibraryStore

    var body: some View {
        let savedBooks = store.profileFilter(store.savedDataBooks)
        NavigationStack {
            ScrollView {
                if savedBooks.isEmpty {
                    EmptyDashboardMessage(icon: "archivebox", text: store.activeReaderProfile == .books ? "Arşivlenmiş veya cihazdan kaldırılmış kitap yok." : "Arşivlenmiş veya cihazdan kaldırılmış çizgi roman yok.")
                        .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(savedBooks) { book in
                            NavigationLink {
                                BookDetailView(bookID: book.id)
                            } label: {
                            HStack(spacing: 14) {
                                DashboardCover(book: book)
                                    .frame(width: 58, height: 86)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .opacity(book.fileAvailable ? 1 : 0.48)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(book.title).font(.headline)
                                    Text(book.fileAvailable ? (book.isArchived ? "Arşivlendi" : "Kütüphane dışında") : "Cihazda değil")
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text("%\(book.progressPercent) • \(book.readingStatus.rawValue)")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .comicHubSurface().navigationTitle("Kaydedilenler")
        }
    }
}

private struct DashboardSettingsView: View {
    @EnvironmentObject var store: LibraryStore
    @EnvironmentObject var theme: PanelThemeStore
    @Environment(\.panelAccentColor) private var accentColor
    @AppStorage("ComicPort.ComicHub.sceneTheme") private var comicSceneTheme = ComicHubSceneTheme.city.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("Okuma") {
                    Stepper("Günlük hedef: \(store.analytics.dailyGoalPages) sayfa", value: Binding(
                        get: { store.analytics.dailyGoalPages },
                        set: { store.setDailyGoal($0) }
                    ), in: 1...1000, step: 5)

                    Toggle("Sonraki sayıyı otomatik aç", isOn: Binding(
                        get: { store.autoOpenNextIssue },
                        set: { store.setAutoOpenNextIssue($0) }
                    ))
                    .tint(accentColor)

                    Toggle("Guided Panel View'u varsayılan kullan", isOn: Binding(
                        get: { store.guidedPanelModeEnabled },
                        set: { store.setGuidedPanelModeEnabled($0) }
                    ))
                    .tint(accentColor)

                    Text("Bir seri algılandığında son sayfaya ulaştıktan sonra sonraki sayı otomatik açılabilir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }.comicHubRowSurface()

                if store.activeReaderProfile == .comics {
                    Section("Özel temalar") {
                        ForEach(ComicHubSceneTheme.allCases) { option in
                            Button {
                                comicSceneTheme = option.rawValue
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: option.symbol)
                                        .font(.title2).foregroundStyle(accentColor).frame(width: 36)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.title).font(.headline).foregroundStyle(.primary)
                                        Text(option.detail).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if comicSceneTheme == option.rawValue {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(accentColor)
                                    }
                                }.padding(.vertical, 8).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(option.title), \(comicSceneTheme == option.rawValue ? "seçili" : "temayı uygula")")
                        }
                        Text("Comic Hub görünümüne uygulanır. Tema sahneleri uygulama için özgün olarak hazırlanmıştır.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.comicHubRowSurface()
                }

                Section("Veri & Güvenlik") {
                    NavigationLink {
                        BackupRestoreView()
                            .environmentObject(store)
                            .environmentObject(theme)
                    } label: {
                        Label("Backup & Restore", systemImage: "externaldrive.badge.icloud")
                    }

                    LabeledContent("Okuma oturumu", value: "\(store.analytics.history.count)")
                    LabeledContent("Notlu sayfa", value: "\(store.annotationPageCount)")
                    LabeledContent("My Panels", value: "\(store.savedPanels.count)")
                    LabeledContent("Reading Journal", value: "\(store.readingJournalEntries.count)")
                    if let occasion = ComicRecommendationOccasion.upcoming() {
                        LabeledContent(
                            "Öneri modu",
                            value: occasion.daysAway == 0
                                ? occasion.title
                                : "\(occasion.title) • \(occasion.daysAway) gün"
                        )
                    } else {
                        LabeledContent("Öneri modu", value: "Kişisel")
                    }
                }.comicHubRowSurface()

                Section("Depolama") {
                    Label("Storage Optimizer", systemImage: "internaldrive")
                    Text("Çizgi roman detayından PDF/arşiv için cihaz üzerinde depolama optimizasyonu yapabilirsin. Orijinal dosya yeni kopya doğrulanmadan değiştirilmez.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }.comicHubRowSurface()

                Section("Mac Health & Diagnostics") {
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
                }.comicHubRowSurface()

                Section("Hakkında") {
                    LabeledContent("Platform", value: ComicPortPlatform.displayName)
                    LabeledContent("Codebase", value: ComicPortPlatform.sharedCodebaseMessage)
                    LabeledContent("Sürüm", value: "2.3 · Stage 21.1 · Book Hub Foundation")
                    LabeledContent("Başarım", value: "\(AchievementCatalog.all.count)")
                    LabeledContent("Yerel katalog", value: "\(LocalComicDatabase.records.count) kayıt")
                }.comicHubRowSurface()
            }
            .scrollContentBackground(.hidden)
            .comicHubSurface().navigationTitle("Ayarlar")
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
                            "Local checks for storage, library integrity and the Mac release environment."
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
        .comicHubSurface().navigationTitle("Diagnostics")
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
        Version: 2.1 · Stage 19 · Mac v0.6 RC1
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
                Text("Depolama").font(.subheadline.bold())
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
                    Text("kütüphane").font(.caption2).foregroundStyle(.secondary)
                    Text("\(byteString(availableCapacity)) boş").font(.caption2).foregroundStyle(.tertiary)
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
            .comicHubSurface().navigationTitle("Smart Collections")
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
                }.comicHubRowSurface()

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
                }.comicHubRowSurface()

                Section {
                    Text(
                        "Smart Collections are filters, not duplicate files. A comic can appear in any number of collections without using extra storage."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }.comicHubRowSurface()
            }
            .comicHubSurface().navigationTitle("New Smart Collection")
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
            .comicHubSurface().navigationTitle("Sources & Sync")
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
                            "Choose a normal folder, iCloud Drive folder or another macOS-synced folder."
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
                "ComicPort does not connect to a ComicPort server. Source scanning happens on this Mac. Sync Folder uses a folder you explicitly choose; if that folder is backed by iCloud Drive or another provider, macOS/provider software handles the network transfer."
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
                            comicType: book.type, revision: book.coverRevision,
                            maxPixelSize: 900
                        )
                        .frame(width: 230, height: 350)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(book.title)
                                .font(.largeTitle.bold())

                            Label(
                                "\(book.pageCount) pages",
                                systemImage: "book.pages"
                            )

                            Label(
                                "\(book.progressPercent)% read",
                                systemImage: "chart.line.uptrend.xyaxis"
                            )

                            ProgressView(value: book.progress)

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
        .comicHubSurface().navigationTitle("Quick Preview")
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
                                        Text(title).font(.caption).foregroundStyle(.secondary)
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
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Bar

private struct DashboardBottomBar: View {
    @Environment(\.panelAccentColor) private var accentColor
    @Binding var selection: DashboardSection

    private let tabs: [(DashboardSection, String, String)] = [
        (.home, "Ana Sayfa", "house.fill"),
        (.library, "Kütüphane", "books.vertical.fill"),
        (.characters, "Karakterler", "person.3.fill"),
        (.achievements, "Başarımlar", "trophy.fill"),
        (.settings, "Ayarlar", "gearshape.fill")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.indices), id: \.self) { index in
                let tab = tabs[index]
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = tab.0 }
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
        .comicHubMaterial(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
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
    if hours > 0 { return "\(hours)sa \(minutes)dk" }
    return "\(minutes)dk"
}

private func byteString(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}

// Shared by the home page and the collection browser; cover loading stays cached/bounded.
struct BookHubShelfPanel: View {
    @EnvironmentObject var store: LibraryStore
    let title: String
    let icon: String
    let books: [ComicBook]
    private let gold = Color(red: 0.83, green: 0.65, blue: 0.40)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(title, systemImage: icon)
                        .font(.system(.title3, design: .serif, weight: .semibold)).lineLimit(2)
                    Text("\(books.count) kitap").font(.caption).foregroundStyle(gold)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(gold)
            }.padding(20)
            ZStack(alignment: .bottom) {
                GeometryReader { geometry in
                    Image("BookHubShelfBackdrop").resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                }.accessibilityHidden(true)
                HStack(alignment: .bottom, spacing: 7) {
                    ForEach(Array(books.prefix(4))) { book in
                        CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, revision: book.coverRevision, maxPixelSize: 180)
                            .frame(width: 44, height: 68)
                            .background(.black.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .overlay(alignment: .leading) { Rectangle().fill(.white.opacity(0.15)).frame(width: 2) }
                            .shadow(color: .black.opacity(0.65), radius: 4, x: 3, y: 2)
                    }
                    if books.isEmpty {
                        Image(systemName: icon).font(.system(size: 30, weight: .ultraLight))
                            .foregroundStyle(gold.opacity(0.35)).frame(height: 68)
                    }
                    Spacer(minLength: 5)
                }.padding(.horizontal, 22).padding(.bottom, 26)

            }.frame(height: 112).clipped()
        }
        .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.82))
        .background(LinearGradient(colors: [Color(red: 0.24, green: 0.16, blue: 0.10), Color(red: 0.13, green: 0.085, blue: 0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.23)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(books.count) kitap")
    }
}

struct BookHubAuthorAvatar: View {
    let name: String
    var size: CGFloat = 88
    private let authors = ["Robert Louis Stevenson", "Arthur Conan Doyle", "Bram Stoker", "Charles Dickens", "H. G. Wells", "Jane Austen", "Lewis Carroll", "Mary Shelley", "Oscar Wilde"]
    private var portraitIndex: Int? { authors.firstIndex { BookLibraryQuery.fold($0) == BookLibraryQuery.fold(name) } }
    // The illustrated sheet is not an exact grid. Crop each portrait around its
    // own centre, inside its baked-in rim, so neighbouring portraits never leak in.
    private let portraitCenters: [CGPoint] = [
        CGPoint(x: 229, y: 206), CGPoint(x: 628, y: 204), CGPoint(x: 1020, y: 205),
        CGPoint(x: 227, y: 598), CGPoint(x: 625, y: 599), CGPoint(x: 1023, y: 600),
        CGPoint(x: 232, y: 986), CGPoint(x: 629, y: 986), CGPoint(x: 1027, y: 986)
    ]
    var body: some View {
        Group {
            if let index = portraitIndex, UIImage(named: "BookHubAuthorPortraits") != nil {
                let scale = size / 334
                let center = portraitCenters[index]
                Image("BookHubAuthorPortraits").resizable()
                    .frame(width: 1254 * scale, height: 1254 * scale)
                    .offset(x: (627 - center.x) * scale, y: (627 - center.y) * scale)
                    .frame(width: size, height: size).clipped()
            } else {
                ZStack {
                    LinearGradient(colors: [Color(red: 0.44, green: 0.32, blue: 0.21), Color(red: 0.16, green: 0.12, blue: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined())
                        .font(.system(size: size * 0.28, weight: .medium, design: .serif)).foregroundStyle(.white.opacity(0.8))
                }.frame(width: size, height: size)
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(red: 0.76, green: 0.59, blue: 0.37).opacity(0.65), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}

// MARK: - Comic Hub

enum ComicHubSceneTheme: String, CaseIterable, Identifiable {
    case city, cavern, workshop, forest, manor
    var id: String { rawValue }
    var title: String {
        switch self {
        case .city: return "Kızıl Şehir"
        case .cavern: return "Gece Mağarası"
        case .workshop: return "Kıyı Atölyesi"
        case .forest: return "Kayıp Orman"
        case .manor: return "Altın Salon"
        }
    }
    var detail: String {
        switch self {
        case .city: return "Gece silüeti · lacivert ve kızıl"
        case .cavern: return "Yeraltı komuta merkezi · kömür ve buz mavisi"
        case .workshop: return "Çizgi roman atölyesi ve boş sergileme bölmeleri · kırmızı ve altın"
        case .forest: return "Sarmaşıklar arasında unutulmuş bir uçak · yosun ve zümrüt"
        case .manor: return "Şömine, gece şehri ve gökyüzünde Comic Hub · sarı ve altın"
        }
    }
    var symbol: String {
        switch self {
        case .city: return "building.2.fill"
        case .cavern: return "mountain.2.fill"
        case .workshop: return "wrench.and.screwdriver.fill"
        case .forest: return "leaf.fill"
        case .manor: return "flame.fill"
        }
    }
    var headline: String {
        switch self {
        case .city: return "HER SAYFADA\nYENİ BİR EVREN."
        case .cavern: return "HİKÂYELERİNİN\nGİZLİ ÜSSÜ."
        case .workshop: return "YENİ FİKİRLER.\nYENİ EVRENLER."
        case .forest: return "HER HİKÂYE\nBİR KEŞİF."
        case .manor: return "ŞEHRİN IŞIKLARI.\nSENİN HİKÂYELERİN."
        }
    }
    var subtitle: String {
        switch self {
        case .city: return "Kahramanların, hikâyelerin, kendi koleksiyonun."
        case .cavern: return "Dışarıda gece. İçeride keşfedilecek evrenler."
        case .workshop: return "Ufukta okyanus. Tezgâhında bir sonraki hikâye."
        case .forest: return "Yeşilin derinliklerinde, keşfedilmeyi bekleyen evrenler."
        case .manor: return "Şöminenin sıcaklığında, bir sonraki sayfaya."
        }
    }
    var heroHeight: CGFloat {
        switch self {
        case .manor: return 500
        case .cavern: return 380
        case .forest: return 340
        case .city, .workshop: return 300
        }
    }
    // The shell observes this same key and rebuilds themed surfaces when it changes.
    static var selected: Self {
        Self(rawValue: UserDefaults.standard.string(forKey: "ComicPort.ComicHub.sceneTheme") ?? "city") ?? .city
    }
}

enum ComicHubPalette {
    private static var scene: ComicHubSceneTheme { .selected }
    static var canvas: Color {
        switch scene {
        case .city: return Color(red: 0.035, green: 0.050, blue: 0.095)
        case .cavern: return Color(red: 0.025, green: 0.040, blue: 0.050)
        case .workshop: return Color(red: 0.060, green: 0.025, blue: 0.030)
        case .forest: return Color(red: 0.025, green: 0.060, blue: 0.040)
        case .manor: return Color(red: 0.085, green: 0.060, blue: 0.025)
        }
    }
    static var surface: Color {
        switch scene {
        case .city: return Color(red: 0.075, green: 0.100, blue: 0.165)
        case .cavern: return Color(red: 0.065, green: 0.095, blue: 0.115)
        case .workshop: return Color(red: 0.135, green: 0.055, blue: 0.060)
        case .forest: return Color(red: 0.060, green: 0.125, blue: 0.080)
        case .manor: return Color(red: 0.175, green: 0.125, blue: 0.050)
        }
    }
    static var red: Color {
        switch scene {
        case .city: return Color(red: 0.96, green: 0.25, blue: 0.30)
        case .cavern: return Color(red: 0.30, green: 0.78, blue: 0.90)
        case .workshop: return Color(red: 0.82, green: 0.18, blue: 0.20)
        case .forest: return Color(red: 0.48, green: 0.82, blue: 0.37)
        case .manor: return Color(red: 1.0, green: 0.78, blue: 0.22)
        }
    }
    static var blue: Color {
        switch scene {
        case .city: return Color(red: 0.25, green: 0.57, blue: 1.0)
        case .cavern: return Color(red: 0.42, green: 0.70, blue: 0.82)
        case .workshop: return Color(red: 0.94, green: 0.73, blue: 0.32)
        case .forest: return Color(red: 0.34, green: 0.72, blue: 0.52)
        case .manor: return Color(red: 0.94, green: 0.70, blue: 0.28)
        }
    }
    static var onAccent: Color { (scene == .city || scene == .workshop) ? .white : Color(red: 0.035, green: 0.045, blue: 0.05) }
    static var cream: Color {
        switch scene {
        case .city: return Color(red: 0.97, green: 0.95, blue: 0.88)
        case .cavern: return Color(red: 0.89, green: 0.95, blue: 0.96)
        case .workshop: return Color(red: 0.98, green: 0.94, blue: 0.85)
        case .forest: return Color(red: 0.92, green: 0.97, blue: 0.85)
        case .manor: return Color(red: 1.0, green: 0.96, blue: 0.83)
        }
    }
}

private struct ComicHubThemeKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var comicHubEnabled: Bool {
        get { self[ComicHubThemeKey.self] }
        set { self[ComicHubThemeKey.self] = newValue }
    }
}

private struct ComicHubSurfaceModifier: ViewModifier {
    @Environment(\.comicHubEnabled) private var inheritedTheme
    let enabled: Bool?
    @ViewBuilder func body(content: Content) -> some View {
        if enabled ?? inheritedTheme {
            content.scrollContentBackground(.hidden)
                .background(ComicHubPalette.canvas.ignoresSafeArea())
                .toolbarBackground(ComicHubPalette.canvas, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .presentationBackground(ComicHubPalette.canvas)
        } else { content }
    }
}

extension View {
    func comicHubSurface(when enabled: Bool? = nil) -> some View {
        modifier(ComicHubSurfaceModifier(enabled: enabled))
    }
}

private struct ComicHubHomeView: View {
    @EnvironmentObject var store: LibraryStore
    @Binding var selection: DashboardSection
    @State private var activeReader: DashboardReaderRoute?
    @AppStorage("ComicPort.ComicHub.collectionLayout") private var collectionLayout = "covers"
    @State private var seriesCount = 0
    @State private var characterCount = 0
    private var books: [ComicBook] { store.profileLibraryBooks }
    private var reading: [ComicBook] { Array(store.profileBooks(with: .reading).prefix(8)) }
    private var recent: [ComicBook] { Array(store.profileRecentlyAdded.prefix(10)) }
    private var featured: ComicBook? { reading.first ?? recent.first }
    private var revision: String { books.map { "\($0.id)|\($0.title)" }.joined(separator: ";") }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                hero
                VStack(spacing: 10) {
                    CompactComicFactBar()
                    CompactComicRecommendationBar()
                }
                shelves
                comicRow(title: "MACERAYA DEVAM", subtitle: "Son kareden bir sonraki sayfaya.", books: reading, destination: .reading)
                discoveries
                comicRow(title: "RAFINA YENİ GELENLER", subtitle: "Koleksiyonundaki en yeni sayılar.", books: recent, destination: .recentAdded)
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("OKUMA RİTMİN", subtitle: "Hedeflerin ve çizgi roman takvimin.")
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            ReadingGoalDashboardCard().frame(minWidth: 280, maxWidth: .infinity)
                            ReadingCalendarCard().frame(minWidth: 300, maxWidth: .infinity)
                        }
                        VStack(spacing: 18) { ReadingGoalDashboardCard(); ReadingCalendarCard() }
                    }
                }
                HStack {
                    Label("Koleksiyonun çevrimdışı da yanında", systemImage: "internaldrive")
                    Spacer()
                    Button("Tüm çizgi romanlar", systemImage: "arrow.up.right") { selection = .library }
                }.font(.callout).foregroundStyle(.secondary).padding(.horizontal, 4)
            }.padding(24)
        }
        .background(ComicHubPalette.canvas)
        .task(id: revision) {
            let snapshot = books
            let counts = await Task.detached(priority: .utility) {
                (SeriesService.series(from: snapshot).count, CharacterLibraryService.profiles(from: snapshot).count)
            }.value
            guard !Task.isCancelled else { return }
            seriesCount = counts.0; characterCount = counts.1
        }
        .fullScreenCover(item: $activeReader) { route in
            ReadingSessionHostView(initialBookID: route.id).environmentObject(store).preferredColorScheme(.dark)
        }
    }

    private var hero: some View {
        heroText.padding(32)
            .frame(maxWidth: .infinity, minHeight: ComicHubSceneTheme.selected.heroHeight, alignment: .leading)
            .background {
                GeometryReader { geometry in
                    if ComicHubSceneTheme.selected == .manor {
                        Image("ComicHubManor").resizable().scaledToFill().accessibilityHidden(true)
                            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    } else if ComicHubSceneTheme.selected == .forest {
                        Image("ComicHubForest").resizable().scaledToFill().accessibilityHidden(true)
                            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    } else if ComicHubSceneTheme.selected == .workshop {
                        Image("ComicHubWorkshop").resizable().scaledToFill().accessibilityHidden(true)
                            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    } else if ComicHubSceneTheme.selected == .cavern {
                        Image("ComicHubCavern").resizable().scaledToFill().accessibilityHidden(true)
                            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    } else {
                        Image("ComicHubCity").resizable().scaledToFill().accessibilityHidden(true)
                            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                    }
                    LinearGradient(colors: [ComicHubPalette.canvas.opacity(0.96), ComicHubPalette.canvas.opacity(0.70), .clear], startPoint: .leading, endPoint: .trailing)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ComicHubPalette.blue.opacity(0.30)))
    }

    private var heroText: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Rectangle().fill(ComicHubPalette.red).frame(width: 24, height: 3)
                Text("COMIC HUB").font(.caption.weight(.black)).tracking(4)
            }.foregroundStyle(ComicHubPalette.cream)
            Text(ComicHubSceneTheme.selected.headline)
                .font(.system(size: 38, weight: .black, design: .rounded)).italic()
                .foregroundStyle(ComicHubPalette.cream).fixedSize(horizontal: false, vertical: true)
            Text(ComicHubSceneTheme.selected.subtitle)
                .font(.callout).foregroundStyle(.white.opacity(0.70))
            HStack(spacing: 20) {
                Label("\(books.count) çizgi roman", systemImage: "square.stack")
                Label("\(seriesCount) seri", systemImage: "rectangle.stack")
            }.font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.75))
            heroActions
        }
    }

    private var heroActions: some View {
        HStack(spacing: 12) {
            if let featured {
                Button { activeReader = DashboardReaderRoute(id: featured.id) } label: {
                    Label(featured.readingStatus == .reading ? "Okumaya devam et" : "Maceraya başla", systemImage: "play.fill")
                        .font(.callout.bold()).padding(.horizontal, 18).padding(.vertical, 12)
                        .background(ComicHubPalette.red, in: RoundedRectangle(cornerRadius: 8)).foregroundStyle(ComicHubPalette.onAccent)
                }.buttonStyle(.plain)
            }
            Button("Koleksiyonum", systemImage: "arrow.right") { selection = .library }
                .font(.callout.bold()).foregroundStyle(ComicHubPalette.cream)
        }
    }

    private var shelves: some View {
        let items: [(String, String, DashboardSection, [ComicBook], Color)] = [
            ("Okuma masam", "book.pages", .reading, books.filter { $0.readingStatus == .reading }, ComicHubPalette.red),
            ("Sıradaki sayılar", "bookmark", .toRead, books.filter { $0.readingStatus == .toRead }, ComicHubPalette.blue),
            ("Arşiv kutusu", "checkmark.seal", .completed, books.filter { $0.readingStatus == .completed }, .mint),
            ("Vitrinim", "star", .favorites, books.filter { $0.favorite }, .orange)
        ]
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("SAYI KUTULARIN", subtitle: "Okuma masan, sıradaki sayılar ve koleksiyon arşivin.")
                Spacer()
                Button("Tüm kutular", systemImage: "shippingbox") { collectionLayout = "boxes"; selection = .library }
                    .font(.caption.bold()).foregroundStyle(ComicHubPalette.blue)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
            ForEach(items, id: \.0) { item in
                Button { collectionLayout = "boxes"; selection = item.2 } label: {
                    ComicHubShelfCard(title: item.0, icon: item.1, books: item.3, tint: item.4)
                }.buttonStyle(.plain)
            }
            }
        }
    }

    private var discoveries: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("EVRENİNİ GENİŞLET", subtitle: "Koleksiyonunu farklı bir açıdan keşfet.")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    discovery(title: "Seri koleksiyonları", count: "\(seriesCount) seri", icon: "rectangle.stack.fill", tint: ComicHubPalette.blue, destination: .series).frame(minWidth: 280, maxWidth: .infinity)
                    discovery(title: "Karakter atlası", count: "\(characterCount) karakter", icon: "person.crop.square.fill", tint: ComicHubPalette.red, destination: .characters).frame(minWidth: 280, maxWidth: .infinity)
                }
                VStack(spacing: 16) {
                    discovery(title: "Seri koleksiyonları", count: "\(seriesCount) seri", icon: "rectangle.stack.fill", tint: ComicHubPalette.blue, destination: .series)
                    discovery(title: "Karakter atlası", count: "\(characterCount) karakter", icon: "person.crop.square.fill", tint: ComicHubPalette.red, destination: .characters)
                }
            }
        }
    }

    private func discovery(title: String, count: String, icon: String, tint: Color, destination: DashboardSection) -> some View {
        Button { selection = destination } label: {
            HStack(spacing: 18) {
                Image(systemName: icon).font(.system(size: 30, weight: .bold)).foregroundStyle(tint)
                    .frame(width: 68, height: 68).background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.title3.bold()).foregroundStyle(ComicHubPalette.cream)
                    Text(count).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(tint)
            }.padding(22).background(ComicHubPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.22)))
        }.buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(.title2, design: .rounded, weight: .heavy)).tracking(0.5).foregroundStyle(ComicHubPalette.cream)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func comicRow(title: String, subtitle: String, books: [ComicBook], destination: DashboardSection) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                sectionHeader(title, subtitle: subtitle)
                Spacer()
                Button("Tümünü gör", systemImage: "arrow.right") { selection = destination }
                    .font(.caption.bold()).foregroundStyle(ComicHubPalette.blue)
            }
            if books.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "book.closed").font(.title2).foregroundStyle(ComicHubPalette.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destination == .reading ? "Yeni bir macera seni bekliyor" : "İlk çizgi romanını ekle").font(.headline)
                        Text(destination == .reading ? "Koleksiyonundan bir sayı seçip okumaya başla." : "İçe Aktar ile koleksiyonunu oluşturmaya başla.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Koleksiyona git") { selection = .library }.font(.caption.bold())
                }.padding(22).background(ComicHubPalette.surface, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 22) {
                        ForEach(books) { book in
                            ComicHubIssueCard(book: book) { activeReader = DashboardReaderRoute(id: $0.id) }.frame(width: 165)
                        }
                    }.padding(18)
                }.background(ComicHubPalette.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

private struct ComicHubShelfCard: View {
    @EnvironmentObject var store: LibraryStore
    let title: String
    let icon: String
    let books: [ComicBook]
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon).foregroundStyle(tint)
                Text(title).font(.headline).foregroundStyle(ComicHubPalette.cream).lineLimit(1)
                Spacer(minLength: 2)
                Image(systemName: "arrow.up.right").font(.caption.bold()).foregroundStyle(tint)
            }
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 7).fill(ComicHubPalette.canvas)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(tint.opacity(0.25)))
                    .padding(.horizontal, 8).padding(.bottom, 12)
                HStack(alignment: .bottom, spacing: 7) {
                    ForEach(Array(books.prefix(3))) { book in
                        CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, revision: book.coverRevision, maxPixelSize: 180)
                            .frame(width: 49, height: 76).background(.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(.white.opacity(0.15)))
                    }
                    if books.isEmpty {
                        Text("Henüz sayı yok").font(.caption).foregroundStyle(.white.opacity(0.3)).frame(height: 76)
                    }
                    Spacer(minLength: 0)
                }.padding(.horizontal, 22).padding(.bottom, 43)
                VStack(alignment: .leading, spacing: 7) {
                    Rectangle().fill(tint.opacity(0.65)).frame(height: 2)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("COMIC PORT / BOX").font(.system(size: 8, weight: .heavy, design: .monospaced)).tracking(1)
                            Text("\(books.count) SAYI").font(.system(.caption, design: .monospaced, weight: .black))
                        }.foregroundStyle(ComicHubPalette.cream)
                        Spacer()
                        Capsule().fill(ComicHubPalette.canvas).frame(width: 35, height: 8)
                    }.padding(.horizontal, 14).padding(.bottom, 12)
                }
                .background(LinearGradient(colors: [ComicHubPalette.surface, ComicHubPalette.canvas], startPoint: .top, endPoint: .bottom))
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 8, bottomTrailingRadius: 8))
            }.frame(height: 130)
        }.padding(18)
        .background(ComicHubPalette.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.25)))
        .accessibilityElement(children: .ignore).accessibilityLabel("\(title), \(books.count) çizgi roman")
    }
}

private struct ComicHubRowSurfaceModifier: ViewModifier {
    @Environment(\.comicHubEnabled) private var enabled
    @ViewBuilder func body(content: Content) -> some View {
        if enabled { content.listRowBackground(ComicHubPalette.surface) }
        else { content }
    }
}
extension View {
    func comicHubRowSurface() -> some View { modifier(ComicHubRowSurfaceModifier()) }
}

private struct ComicHubCollectionView: View {
    @EnvironmentObject var store: LibraryStore
    let title: String
    let books: [ComicBook]
    let showsQuickFilters: Bool
    var emptyMessage: String?
    @State private var filter: LibraryQuickFilter = .all
    @AppStorage("ComicPort.ComicHub.collectionLayout") private var layout = "covers"
    @AppStorage("ComicPort.ComicHub.collectionSort") private var sort = "recent"
    @AppStorage("ComicPort.ComicHub.coverSize") private var coverSize = 175.0
    private var filtered: [ComicBook] {
        let matches = showsQuickFilters ? books.filter { filter.matches($0) } : books
        switch sort {
        case "title": return BookLibrarySort.title.sorted(matches)
        case "series":
            let byID = Dictionary(uniqueKeysWithValues: matches.map { ($0.id, $0) })
            return SeriesService.series(from: matches).flatMap { $0.bookIDs.compactMap { byID[$0] } }
        default: return BookLibrarySort.newest.sorted(matches)
        }
    }
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: CGFloat(coverSize), maximum: CGFloat(coverSize) + 35), spacing: 24)]
    }
    var body: some View {
        let displayed = filtered
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    header(count: displayed.count)
                    if showsQuickFilters { filters }
                    if displayed.isEmpty {
                        ContentUnavailableView("Bu kutu henüz boş", systemImage: "shippingbox", description: Text(emptyMessage ?? "Filtreni değiştir veya koleksiyonuna yeni sayılar ekle."))
                            .frame(maxWidth: .infinity).padding(.vertical, 48)
                    } else if layout == "boxes" {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 480), spacing: 20)], alignment: .leading, spacing: 20) {
                            ForEach(SeriesService.series(from: displayed)) { series in
                                issueBox(series: series, books: SeriesService.books(in: series, from: displayed))
                            }
                        }
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 26) {
                            ForEach(displayed) { book in ComicHubIssueCard(book: book) }
                        }
                    }
                }.padding(24)
            }.comicHubSurface()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(ComicPortPlatform.isMac ? "" : title)
        }
    }
    private func header(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("COMIC PORT / KOLEKSİYON").font(.caption2.weight(.heavy)).tracking(2.5).foregroundStyle(ComicHubPalette.blue)
                    Text(title).font(.system(.largeTitle, design: .rounded, weight: .black)).foregroundStyle(ComicHubPalette.cream)
                    Text("\(count) sayı · \(SeriesService.series(from: filtered).count) seri").font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: layout == "boxes" ? "shippingbox.fill" : "rectangle.stack.fill")
                    .font(.system(size: 38, weight: .light)).foregroundStyle(ComicHubPalette.blue.opacity(0.65))
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { layoutControl; Spacer(); sortControl; sizeControl }
                VStack(alignment: .leading, spacing: 14) { layoutControl; HStack { sortControl; Spacer(); sizeControl } }
            }
        }.padding(22).background(ComicHubPalette.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
    }
    private var layoutControl: some View {
        HStack(spacing: 5) {
            layoutButton("Kapak vitrini", icon: "rectangle.grid.2x2", value: "covers")
            layoutButton("Seri kutuları", icon: "shippingbox", value: "boxes")
        }.padding(4).background(ComicHubPalette.canvas, in: RoundedRectangle(cornerRadius: 10))
    }
    private func layoutButton(_ title: String, icon: String, value: String) -> some View {
        Button { layout = value } label: {
            Label(title, systemImage: icon).font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 10)
                .background(layout == value ? ComicHubPalette.blue.opacity(0.22) : .clear, in: RoundedRectangle(cornerRadius: 7))
                .foregroundStyle(layout == value ? ComicHubPalette.cream : .secondary)
        }.buttonStyle(.plain).accessibilityAddTraits(layout == value ? .isSelected : [])
    }
    private var sortControl: some View {
        Menu {
            Picker("Sıralama", selection: $sort) {
                Text("Yeni eklenenler").tag("recent")
                Text("Ada göre").tag("title")
                Text("Seri / sayı sırası").tag("series")
            }
        } label: {
            Label("Sıralama", systemImage: "arrow.up.arrow.down").font(.caption.bold())
        }.foregroundStyle(ComicHubPalette.cream)
    }
    private var sizeControl: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.expand.vertical")
            Slider(value: $coverSize, in: 145...225, step: 10).frame(width: 100).accessibilityLabel("Kapak boyutu")
        }.foregroundStyle(.secondary)
    }
    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(LibraryQuickFilter.allCases) { item in
                    Button { filter = item } label: {
                        Text(item.label(forBooks: true)).font(.caption.bold()).padding(.horizontal, 16).padding(.vertical, 10)
                            .background(filter == item ? ComicHubPalette.red : ComicHubPalette.surface, in: Capsule())
                            .foregroundStyle(filter == item ? .white : .secondary)
                    }.buttonStyle(.plain).accessibilityAddTraits(filter == item ? .isSelected : [])
                }
            }
        }
    }
    private func issueBox(series: ComicSeries, books: [ComicBook]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill").foregroundStyle(ComicHubPalette.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(series.title).font(.title3.bold()).foregroundStyle(ComicHubPalette.cream)
                    Text("\(books.count) sayı · \(books.filter { $0.readingStatus == .completed }.count) tamamlandı").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("SERİ KUTUSU").font(.caption2.monospaced().bold()).foregroundStyle(ComicHubPalette.blue).padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(ComicHubPalette.blue.opacity(0.3)))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 20) {
                    ForEach(books) { book in ComicHubIssueCard(book: book).frame(width: CGFloat(coverSize)) }
                }.padding(.vertical, 8).padding(.horizontal, 4)
            }
            Rectangle().fill(LinearGradient(colors: [ComicHubPalette.blue.opacity(0.5), ComicHubPalette.surface], startPoint: .top, endPoint: .bottom)).frame(height: 6)
        }.padding(20).background(ComicHubPalette.surface.opacity(0.4), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(ComicHubPalette.blue.opacity(0.15)))
    }
}

private struct ComicHubIssueCard: View {
    @EnvironmentObject var store: LibraryStore
    let book: ComicBook
    @State private var showQuickPreview = false
    var onOpen: ((ComicBook) -> Void)? = nil
    private var progress: Double { book.readingStatus == .completed ? 1 : max(0, min(1, book.progress)) }
    private var statusColor: Color { book.readingStatus == .completed ? .mint : (book.readingStatus == .reading ? ComicHubPalette.red : ComicHubPalette.blue) }
    private var issueLabel: String {
        let parsed = SeriesService.parse(book.title)
        guard let number = parsed.issueNumber else { return book.type.rawValue.uppercased() }
        return "#" + (number.rounded() == number ? String(Int(number)) : String(number))
    }
    var body: some View {
        Group {
            if let onOpen { Button { onOpen(book) } label: { content } }
            else { NavigationLink { BookDetailView(bookID: book.id) } label: { content } }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Hızlı önizleme", systemImage: "eye") { showQuickPreview = true }
            Button(book.favorite ? "Favorilerden çıkar" : "Favorilere ekle", systemImage: book.favorite ? "star.slash" : "star") { store.toggleFavorite(id: book.id) }
            Menu("Okuma durumu") {
                ForEach(ReadingStatus.allCases) { status in
                    Button(status.label(forBooks: true), systemImage: status.systemImage) { store.setStatus(id: book.id, status: status) }
                }
            }
            Menu("İçerik türü") {
                ForEach(ComicPortContentKind.allCases) { kind in
                    Button(kind.rawValue, systemImage: kind.systemImage) { store.setContentKind(id: book.id, kind: kind) }
                }
            }
            NavigationLink("Kapak ve bilgileri düzenle") { BookDetailView(bookID: book.id) }
        }
        .sheet(isPresented: $showQuickPreview) {
            ComicQuickPreviewView(bookID: book.id).environmentObject(store).comicHubSurface()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(book.title), \(book.readingStatus.label(forBooks: true)), yüzde \(Int(progress * 100))")
    }
    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color.black.opacity(0.35))
                CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, revision: book.coverRevision, maxPixelSize: 540)
                    .padding(5)
                Text(issueLabel).font(.caption2.monospaced().bold()).padding(.horizontal, 9).padding(.vertical, 6)
                    .background(ComicHubPalette.canvas.opacity(0.95), in: UnevenRoundedRectangle(bottomTrailingRadius: 8)).foregroundStyle(ComicHubPalette.cream)
                if book.favorite {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow).padding(9).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.10)))
            .shadow(color: .black.opacity(0.30), radius: 7, y: 5)
            Text(book.title).font(.callout.weight(.semibold)).foregroundStyle(ComicHubPalette.cream)
                .lineLimit(2).frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
            HStack {
                Circle().fill(statusColor).frame(width: 5, height: 5)
                Text(book.readingStatus.label(forBooks: true)).font(.caption2)
                Spacer(minLength: 2)
                if book.readingStatus != .toRead { Text("%\(Int(progress * 100))").font(.caption2.monospacedDigit()) }
            }.foregroundStyle(.secondary)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule().fill(statusColor).frame(width: geometry.size.width * progress)
                }
            }.frame(height: 3)
        }
    }
}

private struct ComicHubMaterialModifier<S: Shape>: ViewModifier {
    @Environment(\.comicHubEnabled) private var enabled
    let material: Material
    let shape: S
    func body(content: Content) -> some View {
        content.background {
            if enabled { shape.fill(ComicHubPalette.surface) }
            else { shape.fill(material) }
        }
    }
}
extension View {
    func comicHubMaterial<S: Shape>(_ material: Material, in shape: S) -> some View {
        modifier(ComicHubMaterialModifier(material: material, shape: shape))
    }
}
