import Foundation
import PDFKit
import CryptoKit
import SwiftUI
import UIKit

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var books: [ComicBook] = []
    @Published private(set) var analytics = ReadingAnalytics()
    @Published var importError: String?
    @Published private(set) var importInProgressCount: Int = 0
    @Published private(set) var achievementProfile = AchievementProfile()
    @Published private(set) var currentAchievementBanner: AchievementDefinition?
    @Published private(set) var readerSettingsByBook: [String: ReaderSettings] = [:]
    @Published private(set) var defaultReaderSettings = ReaderSettings()
    @Published private(set) var storyArcs: [StoryArc] = []
    @Published var autoOpenNextIssue: Bool = false
    @Published private(set) var readerIsActive: Bool = false
    @Published private(set) var textNotes: [PageTextNote] = []
    @Published private(set) var savedPanels: [SavedPanel] = []
    @Published private(set) var annotationRevision: Int = 0
    @Published private(set) var smartSearchProgress: SmartSearchProgress?
    @Published private(set) var smartSearchLastError: String?
    @Published private(set) var smartSearchRevision: Int = 0
    @Published private(set) var smartSearchCacheReady: Bool = false
    @Published private(set) var guidedPanelModeEnabled: Bool = false
    @Published private(set) var readingJournalEntries: [ReadingJournalEntry] = []
    @Published private(set) var isBootstrapped: Bool = false
    @Published private(set) var bootstrapMessage: String = "ComicPort hazırlanıyor…"
    @Published private(set) var pendingQuickAction: PanelQuickAction?

    // Stage 18 — desktop organization / local sources / folder-based sync.
    @Published private(set) var smartCollections: [ComicPortSmartCollection] = []
    @Published private(set) var sourceFolders: [ComicPortSourceFolder] = []
    @Published private(set) var sourceScanInProgress: Bool = false
    @Published private(set) var syncLocation: ComicPortSyncLocation?
    @Published private(set) var syncStatusMessage: String = "Sync folder not configured"
    @Published private(set) var syncLastRun: Date?
    @Published private(set) var sourceNotice: String?
    @Published private(set) var lastSessionSummary: ComicPortReadingSessionSummary?

    private struct ActiveSession {
        let startedAt: Date
        let startPage: Int
        var lastPage: Int
        var pagesRead: Int
    }

    private let fm = FileManager.default
    private let metadataName = "library.json"
    private let analyticsName = "analytics.json"
    private let achievementsName = "achievements.json"
    private let readerSettingsName = "reader_settings.json"
    private let defaultReaderSettingsName = "reader_defaults.json"
    private let storyArcsName = "story_arcs.json"
    private let autoNextKey = "PanelReader.autoOpenNextIssue"
    private let textNotesName = "page_text_notes.json"
    private let savedPanelsName = "saved_panels.json"
    private let guidedPanelModeKey = "PanelReader.guidedPanelModeEnabled"
    private let readingJournalName = "reading_journal.json"

    private let smartCollectionsDefaultsKey = "ComicPort.stage18.smartCollections"
    private let sourceFoldersDefaultsKey = "ComicPort.stage18.sourceFolders"
    private let syncLocationDefaultsKey = "ComicPort.stage18.syncLocation"
    private let syncFileName = "ComicPort-Sync-v1.json"

    private let metadataWriter = VersionedMetadataWriter()
    private var metadataGeneration: UInt64 = 0
    private var persistenceFailure: Error?
    private var pendingLibrarySave: Task<Void, Never>?
    private var pendingSyncExport: Task<Void, Never>?
    private var pendingExternalImportURLs: [URL] = []
    private var achievementBannerQueue: [AchievementDefinition] = []
    private var activeSessions: [UUID: ActiveSession] = [:]
    private var pencilAnnotationPageKeys: Set<String> = []
    private var smartSearchIndexes: [UUID: OCRBookIndex] = [:]
    private var smartSearchTask: Task<Void, Never>?
    private var smartSearchKnownIndexIDs: Set<UUID> = []
    private var recommendationCacheKey: Int?
    private var recommendationCache: [ComicRecommendation] = []
    private var bootstrapStarted = false

    private let documentsOverride: URL?

    init(documentsURL: URL? = nil) {
        self.documentsOverride = documentsURL
        // Keep App initialization intentionally tiny. Disk enumeration, JSON decoding and
        // hundreds of file-existence checks are performed by bootstrap() after the first frame.
        guidedPanelModeEnabled = UserDefaults.standard.bool(forKey: guidedPanelModeKey)
        autoOpenNextIssue = UserDefaults.standard.bool(forKey: autoNextKey)

        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: smartCollectionsDefaultsKey),
           let decoded = try? JSONDecoder().decode(
                [ComicPortSmartCollection].self,
                from: data
           ) {
            smartCollections = decoded
        }

        if let data = defaults.data(forKey: sourceFoldersDefaultsKey),
           let decoded = try? JSONDecoder().decode(
                [ComicPortSourceFolder].self,
                from: data
           ) {
            sourceFolders = decoded
        }

        if let data = defaults.data(forKey: syncLocationDefaultsKey),
           let decoded = try? JSONDecoder().decode(
                ComicPortSyncLocation.self,
                from: data
           ) {
            syncLocation = decoded
            syncStatusMessage = "Ready • \(decoded.displayName)"
        }
    }

    var documentsURL: URL { documentsOverride ?? fm.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    var booksURL: URL { documentsURL.appendingPathComponent("Books", isDirectory: true) }
    var coversURL: URL { documentsURL.appendingPathComponent("Covers", isDirectory: true) }
    var notesURL: URL { documentsURL.appendingPathComponent("Notes", isDirectory: true) }
    var infoCacheURL: URL { documentsURL.appendingPathComponent("BookInfo", isDirectory: true) }
    var panelsURL: URL { documentsURL.appendingPathComponent("MyPanels", isDirectory: true) }
    var smartSearchURL: URL { documentsURL.appendingPathComponent("SearchIndex", isDirectory: true) }
    var guidedPanelsURL: URL { documentsURL.appendingPathComponent("GuidedPanels", isDirectory: true) }
    private var metadataURL: URL { documentsURL.appendingPathComponent(metadataName) }
    private var analyticsURL: URL { documentsURL.appendingPathComponent(analyticsName) }
    private var achievementsURL: URL { documentsURL.appendingPathComponent(achievementsName) }
    private var readerSettingsURL: URL { documentsURL.appendingPathComponent(readerSettingsName) }
    private var defaultReaderSettingsURL: URL { documentsURL.appendingPathComponent(defaultReaderSettingsName) }
    private var storyArcsURL: URL { documentsURL.appendingPathComponent(storyArcsName) }
    private var textNotesURL: URL { documentsURL.appendingPathComponent(textNotesName) }
    private var savedPanelsURL: URL { documentsURL.appendingPathComponent(savedPanelsName) }
    private var readingJournalURL: URL { documentsURL.appendingPathComponent(readingJournalName) }

    func bootstrap() async {
        guard !isBootstrapped, !bootstrapStarted else { return }
        bootstrapStarted = true
        bootstrapMessage = "Kütüphane yükleniyor…"

        let paths = LibraryBootstrapPaths(
            documents: documentsURL,
            books: booksURL,
            covers: coversURL,
            notes: notesURL,
            info: infoCacheURL,
            panels: panelsURL,
            search: smartSearchURL,
            guided: guidedPanelsURL,
            metadata: metadataURL,
            analytics: analyticsURL,
            achievements: achievementsURL,
            readerSettings: readerSettingsURL,
            defaultReaderSettings: defaultReaderSettingsURL,
            storyArcs: storyArcsURL,
            textNotes: textNotesURL,
            savedPanels: savedPanelsURL,
            readingJournal: readingJournalURL
        )

        let loaded = await Task.detached(priority: .userInitiated) {
            LibraryBootstrapLoader.load(paths: paths)
        }.value

        guard !Task.isCancelled else {
            bootstrapStarted = false
            return
        }

        // Assign all persisted state before revealing the dashboard, avoiding a cascade
        // of partial-state redraws while launch data arrives.
        books = loaded.books
        analytics = loaded.analytics
        achievementProfile = loaded.achievementProfile
        readerSettingsByBook = loaded.readerSettingsByBook
        defaultReaderSettings = loaded.defaultReaderSettings
        storyArcs = loaded.storyArcs
        textNotes = loaded.textNotes
        savedPanels = loaded.savedPanels
        readingJournalEntries = loaded.readingJournal
        pencilAnnotationPageKeys = loaded.pencilAnnotationPageKeys
        smartSearchKnownIndexIDs = loaded.smartSearchKnownIndexIDs

        bootstrapMessage = "Ana ekran hazırlanıyor…"
        if loaded.libraryMetadataChanged {
            scheduleLibrarySave()
        }

        isBootstrapped = true
        bootstrapStarted = false

        if pendingQuickAction == nil, let shortcutAction = PanelShortcutBridge.consumePending() {
            pendingQuickAction = shortcutAction
        }

        // Finder / Open With may launch ComicPort before bootstrap has finished.
        // Queue those file URLs and only enter the normal import pipeline after
        // the persisted library and its directories are ready.
        if !pendingExternalImportURLs.isEmpty {
            let queued = pendingExternalImportURLs
            pendingExternalImportURLs.removeAll(keepingCapacity: false)
            queued.forEach(importFile)
        }

        // Stage 18 work happens after first paint. Neither source enumeration nor
        // folder sync is allowed to extend launch time.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(850))
            guard let self, self.isBootstrapped, !self.readerIsActive else { return }
            if self.syncLocation != nil {
                await self.performComicPortSync(importRemoteFirst: true)
            }
            await self.scanAllSourceFolders()
        }

        // Achievement re-evaluation used to run synchronously inside init() and could
        // load the 950-record local catalog before the first frame. Existing profiles
        // are already persisted; a one-time legacy bootstrap is deferred until after UI.
        if !achievementProfile.hasBootstrapped {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.2))
                guard let self, self.isBootstrapped, !self.readerIsActive else { return }
                self.bootstrapAchievementsIfNeeded()
            }
        }
    }

    func handleIncomingURL(_ url: URL) {
        if url.isFileURL {
            let ext = url.pathExtension.lowercased()
            guard ext == "pdf" ||
                    ComicArchiveFormat.supportedExtensions.contains(ext) else {
                importError = "ComicPort cannot open this file type."
                return
            }

            if isBootstrapped {
                importFile(url)
            } else if !pendingExternalImportURLs.contains(url) {
                pendingExternalImportURLs.append(url)
            }
            return
        }

        handleDeepLink(url)
    }

    func handleDeepLink(_ url: URL) {
        guard let action = PanelQuickAction(url: url) else { return }
        pendingQuickAction = action
    }

    func setPendingQuickAction(_ action: PanelQuickAction) {
        pendingQuickAction = action
    }

    func clearPendingQuickAction() {
        pendingQuickAction = nil
    }

    var annotationPageCount: Int {
        let textKeys = Set(textNotes.map { "\($0.bookID.uuidString)-\($0.page)" })
        return textKeys.union(pencilAnnotationPageKeys).count
    }

    var todayStat: DailyReadingStat { analytics.daily[Self.dayKey(.now)] ?? DailyReadingStat() }
    var todayGoalProgress: Double {
        guard analytics.dailyGoalPages > 0 else { return 0 }
        return min(1, Double(todayStat.pages) / Double(analytics.dailyGoalPages))
    }

    var libraryBooks: [ComicBook] { books.filter { $0.isInLibrary && !$0.isArchived } }
    var archivedBooks: [ComicBook] { books.filter { $0.isArchived } }
    var removedBooks: [ComicBook] { books.filter { !$0.isInLibrary && !$0.isArchived } }
    var savedDataBooks: [ComicBook] { books.filter { $0.isArchived || !$0.isInLibrary || !$0.fileAvailable } }


    var recommendationTasteKey: Int {
        var hasher = Hasher()
        hasher.combine(PanelDayKey.string(.now))
        hasher.combine(ComicRecommendationOccasion.upcoming()?.eventID ?? "normal")
        for book in libraryBooks {
            hasher.combine(book.id)
            hasher.combine(book.title)
            hasher.combine(book.favorite)
            hasher.combine(book.rating)
            hasher.combine(book.readingStatus.rawValue)
            hasher.combine(min(book.currentPage / 10, 1000))
        }
        return hasher.finalize()
    }

    func comicRecommendations(forceRefresh: Bool = false) async -> [ComicRecommendation] {
        let key = recommendationTasteKey
        if !forceRefresh,
           recommendationCacheKey == key,
           !recommendationCache.isEmpty {
            return recommendationCache
        }

        let signals = libraryBooks.map { book -> ComicRecommendationSignal in
            var weight = 1.0
            if book.favorite { weight += 5.0 }
            weight += Double(max(0, min(5, book.rating))) * 1.15
            if book.readingStatus == .completed { weight += 2.0 }
            else if book.readingStatus == .reading { weight += 1.0 }
            weight += min(2.0, book.progress * 2.0)
            return ComicRecommendationSignal(title: book.title, tasteWeight: weight)
        }
        let occasion = ComicRecommendationOccasion.upcoming()
        let catalog = await Task.detached(priority: .utility) {
            LocalComicDatabase.records
        }.value

        let built = await Task.detached(priority: .utility) {
            ComicRecommendationEngine.build(
                signals: signals,
                catalog: catalog,
                occasion: occasion
            )
        }.value
        guard !Task.isCancelled else { return [] }

        recommendationCacheKey = key
        recommendationCache = built
        return built
    }

    var recentlyAdded: [ComicBook] { Array(libraryBooks.sorted { $0.addedAt > $1.addedAt }.prefix(12)) }
    var recentlyRead: [ComicBook] { Array(libraryBooks.filter { $0.lastReadAt != nil }.sorted { ($0.lastReadAt ?? .distantPast) > ($1.lastReadAt ?? .distantPast) }.prefix(12)) }

    func books(with status: ReadingStatus) -> [ComicBook] {
        libraryBooks.filter { $0.readingStatus == status }.sorted { ($0.lastReadAt ?? $0.addedAt) > ($1.lastReadAt ?? $1.addedAt) }
    }

    func fileURL(for book: ComicBook) -> URL { booksURL.appendingPathComponent(book.storedFileName) }

    func coverURL(for book: ComicBook) -> URL? {
        guard let name = book.thumbnailFileName else { return nil }
        return coversURL.appendingPathComponent(name)
    }


    func regenerateCover(for bookID: UUID) async -> Bool {
        guard let index = books.firstIndex(where: { $0.id == bookID }) else { return false }
        let book = books[index]
        let url = fileURL(for: book)
        guard fm.fileExists(atPath: url.path), book.pageCount > 0 else { return false }

        let settings = readerSettings(for: book.id)
        guard let data = await ReaderPageSnapshotService.loadSnapshot(
            fileURL: url,
            type: book.type,
            page: 0,
            settings: settings,
            maxPixel: 1050
        ) else { return false }

        let fileName = "\(book.id.uuidString).jpg"
        let target = coversURL.appendingPathComponent(fileName)
        do {
            try await Task.detached(priority: .utility) {
                try data.write(to: target, options: .atomic)
            }.value
            if let old = books[index].thumbnailFileName, old != fileName {
                try? fm.removeItem(at: coversURL.appendingPathComponent(old))
            }
            books[index].thumbnailFileName = fileName
            save()
            return true
        } catch {
            importError = "Kapak onarılamadı: \(error.localizedDescription)"
            return false
        }
    }

    func performSafeCacheCleanup() async -> Int64 {
        let validBookIDs = Set(books.map(\.id))
        let validCBZStems = Set(
            books.filter { $0.type == .cbz && $0.fileAvailable }
                .map { URL(fileURLWithPath: $0.storedFileName).deletingPathExtension().lastPathComponent }
        )
        let guided = guidedPanelsURL
        let search = smartSearchURL
        let covers = coversURL
        let cbzRoot = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PanelReaderArchives", isDirectory: true)

        let freed = await Task.detached(priority: .utility) { () -> Int64 in
            let fm = FileManager.default
            var freed: Int64 = 0

            func fileBytes(_ url: URL) -> Int64 {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    return Int64(size)
                }
                if let enumerator = fm.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.fileSizeKey],
                    options: [.skipsHiddenFiles]
                ) {
                    var total: Int64 = 0
                    for case let child as URL in enumerator {
                        total += Int64((try? child.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                    }
                    return total
                }
                return 0
            }

            if let files = try? fm.contentsOfDirectory(at: guided, includingPropertiesForKeys: nil) {
                for url in files where url.pathExtension.lowercased() == "json" {
                    let prefix = url.deletingPathExtension().lastPathComponent.split(separator: "-").first.map(String.init) ?? ""
                    if UUID(uuidString: prefix).map({ !validBookIDs.contains($0) }) ?? true {
                        freed += fileBytes(url)
                        try? fm.removeItem(at: url)
                    }
                }
            }

            if let files = try? fm.contentsOfDirectory(at: search, includingPropertiesForKeys: nil) {
                for url in files where url.pathExtension.lowercased() == "json" {
                    let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent)
                    if id.map({ !validBookIDs.contains($0) }) ?? true {
                        freed += fileBytes(url)
                        try? fm.removeItem(at: url)
                    }
                }
            }

            if let files = try? fm.contentsOfDirectory(at: covers, includingPropertiesForKeys: nil) {
                for url in files {
                    let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent)
                    if id.map({ !validBookIDs.contains($0) }) ?? false {
                        freed += fileBytes(url)
                        try? fm.removeItem(at: url)
                    }
                }
            }

            if let folders = try? fm.contentsOfDirectory(
                at: cbzRoot,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                for folder in folders where !validCBZStems.contains(folder.lastPathComponent) {
                    freed += fileBytes(folder)
                    try? fm.removeItem(at: folder)
                }
            }

            return freed
        }.value

        loadSmartSearchFileList()
        smartSearchRevision &+= 1
        return freed
    }

    private final class PreparedComicImport: @unchecked Sendable {
        let temporaryID: UUID
        let sourceExtension: String
        let targetURL: URL
        let fallbackTitle: String
        let resolvedTitle: String
        let pageCount: Int
        let coverData: Data?
        let comicInfo: ComicInfoMetadata?
        let rightToLeft: Bool

        init(
            temporaryID: UUID,
            sourceExtension: String,
            targetURL: URL,
            fallbackTitle: String,
            resolvedTitle: String,
            pageCount: Int,
            coverData: Data?,
            comicInfo: ComicInfoMetadata?,
            rightToLeft: Bool
        ) {
            self.temporaryID = temporaryID
            self.sourceExtension = sourceExtension
            self.targetURL = targetURL
            self.fallbackTitle = fallbackTitle
            self.resolvedTitle = resolvedTitle
            self.pageCount = pageCount
            self.coverData = coverData
            self.comicInfo = comicInfo
            self.rightToLeft = rightToLeft
        }
    }

    func importFile(_ source: URL) {
        let ext = source.pathExtension.lowercased()
        guard ext == "pdf" || ComicArchiveFormat.supportedExtensions.contains(ext) else {
            importError = "Supported formats: PDF, CBZ, CBR/RAR5, CB7/7z, CBT/TAR and ZIP."
            return
        }

        importInProgressCount += 1
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.importInProgressCount = max(0, self.importInProgressCount - 1) }

            let gotAccess = source.startAccessingSecurityScopedResource()
            defer { if gotAccess { source.stopAccessingSecurityScopedResource() } }

            let booksDirectory = self.booksURL
            let coversDirectory = self.coversURL

            do {
                let prepared = try await Task.detached(priority: .userInitiated) {
                    let fm = FileManager.default
                    let id = UUID()
                    let targetName = "\(id.uuidString).\(ext)"
                    let target = booksDirectory.appendingPathComponent(targetName)
                    try? fm.removeItem(at: target)
                    try fm.copyItem(at: source, to: target)

                    do {
                        let fallbackTitle = source.deletingPathExtension().lastPathComponent
                        var count = 0
                        var coverData: Data?
                        var comicInfo: ComicInfoMetadata?

                        if ext == "pdf" {
                            let doc = PDFDocument(url: target)
                            count = doc?.pageCount ?? 0
                            if let page = doc?.page(at: 0) {
                                coverData = page.thumbnail(
                                    of: CGSize(width: 700, height: 1050),
                                    for: .mediaBox
                                ).jpegData(compressionQuality: 0.88)
                            }
                        } else {
                            comicInfo = ComicInfoService.metadata(from: target)
                            let pages = try CBZService.extractImages(from: target)
                            count = pages.count
                            if let first = pages.first,
                               let data = try? Data(contentsOf: first),
                               let image = UIImage(data: data) {
                                coverData = image.jpegData(compressionQuality: 0.88)
                            }
                        }

                        guard count > 0 else {
                            throw ComicArchiveError.noReadablePages
                        }

                        return PreparedComicImport(
                            temporaryID: id,
                            sourceExtension: ext,
                            targetURL: target,
                            fallbackTitle: fallbackTitle,
                            resolvedTitle: comicInfo?.displayTitle(fallback: fallbackTitle) ?? fallbackTitle,
                            pageCount: count,
                            coverData: coverData,
                            comicInfo: comicInfo,
                            rightToLeft: comicInfo?.isRightToLeft ?? false
                        )
                    } catch {
                        try? fm.removeItem(at: target)
                        throw error
                    }
                }.value

                try self.finishPreparedImport(prepared, coversDirectory: coversDirectory)
            } catch {
                self.importError = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func finishPreparedImport(_ prepared: PreparedComicImport, coversDirectory: URL) throws {
        let id = prepared.temporaryID
        let ext = prepared.sourceExtension
        let type: ComicType = ext == "pdf" ? .pdf : .cbz
        let identity = Self.sourceIdentity(
            title: prepared.resolvedTitle,
            type: type,
            pageCount: prepared.pageCount
        )
        let fallbackIdentity = Self.sourceIdentity(
            title: prepared.fallbackTitle,
            type: type,
            pageCount: prepared.pageCount
        )

        var generatedCoverName: String?
        if let data = prepared.coverData {
            let name = "\(id.uuidString).jpg"
            try data.write(to: coversDirectory.appendingPathComponent(name), options: .atomic)
            generatedCoverName = name
        }

        func identityMatches(_ book: ComicBook) -> Bool {
            let existing = book.sourceIdentity.isEmpty
                ? Self.sourceIdentity(title: book.title, type: book.type, pageCount: book.pageCount)
                : book.sourceIdentity
            return existing == identity || existing == fallbackIdentity
        }

        if let existingIndex = books.firstIndex(where: {
            (!$0.fileAvailable || !$0.isInLibrary) && identityMatches($0)
        }) {
            let preservedID = books[existingIndex].id
            let oldFile = fileURL(for: books[existingIndex])
            let relinkedName = "\(preservedID.uuidString).\(ext)"
            let relinkedURL = booksURL.appendingPathComponent(relinkedName)

            if oldFile != relinkedURL { try? fm.removeItem(at: oldFile) }
            if prepared.targetURL != relinkedURL {
                try? fm.removeItem(at: relinkedURL)
                try fm.moveItem(at: prepared.targetURL, to: relinkedURL)
            }

            if let oldCover = coverURL(for: books[existingIndex]) {
                try? fm.removeItem(at: oldCover)
            }
            books[existingIndex].thumbnailFileName = nil

            if let generatedCoverName {
                let generatedCover = coversURL.appendingPathComponent(generatedCoverName)
                let preservedCoverName = "\(preservedID.uuidString).jpg"
                let preservedCover = coversURL.appendingPathComponent(preservedCoverName)
                try? fm.removeItem(at: preservedCover)
                if fm.fileExists(atPath: generatedCover.path) {
                    try fm.moveItem(at: generatedCover, to: preservedCover)
                    books[existingIndex].thumbnailFileName = preservedCoverName
                }
            }

            books[existingIndex].title = prepared.resolvedTitle
            books[existingIndex].storedFileName = relinkedName
            books[existingIndex].type = type
            books[existingIndex].pageCount = prepared.pageCount
            books[existingIndex].sourceIdentity = identity
            books[existingIndex].rightToLeft = prepared.rightToLeft || books[existingIndex].rightToLeft
            books[existingIndex].isInLibrary = true
            books[existingIndex].fileAvailable = true
            books[existingIndex].isArchived = false

            if let metadata = prepared.comicInfo {
                saveImportedComicInfo(metadata, book: books[existingIndex])
            }
            save()
            evaluateAchievements()

        } else if books.contains(where: {
            $0.fileAvailable && $0.isInLibrary && identityMatches($0)
        }) {
            try? fm.removeItem(at: prepared.targetURL)
            if let generatedCoverName {
                try? fm.removeItem(at: coversURL.appendingPathComponent(generatedCoverName))
            }
            importError = "This comic is already in your library."

        } else {
            let targetName = prepared.targetURL.lastPathComponent
            let book = ComicBook(
                id: id,
                title: prepared.resolvedTitle,
                storedFileName: targetName,
                type: type,
                pageCount: prepared.pageCount,
                thumbnailFileName: generatedCoverName,
                rightToLeft: prepared.rightToLeft,
                sourceIdentity: identity
            )
            books.insert(book, at: 0)
            if let metadata = prepared.comicInfo {
                saveImportedComicInfo(metadata, book: book)
            }
            save()
            evaluateAchievements()
        }
    }

    private func saveImportedComicInfo(_ metadata: ComicInfoMetadata, book: ComicBook) {
        let localMatch = LocalComicDatabase.bestMatch(
            title: [book.title, metadata.series ?? "", metadata.title ?? ""].joined(separator: " "),
            OCRText: ""
        )
        let summary = metadata.summary
            ?? localMatch?.record.description
            ?? "Metadata imported from ComicInfo.xml."

        let info = OfflineComicInfo(
            displayTitle: metadata.displayTitle(fallback: book.title),
            series: metadata.series,
            issue: metadata.number,
            year: metadata.year.map(String.init),
            creators: metadata.creators.isEmpty ? (localMatch?.record.creators ?? []) : metadata.creators,
            publisher: metadata.publisher ?? localMatch?.record.publisher,
            pageCount: book.pageCount,
            fileType: fileURL(for: book).pathExtension.uppercased(),
            embeddedAuthor: nil,
            embeddedSubject: nil,
            detectedText: "",
            summary: summary,
            confidenceNote: "Verified metadata was read from ComicInfo.xml inside this comic archive. Everything was processed locally on this device.",
            databaseMatch: localMatch?.record,
            databaseConfidence: localMatch?.confidence,
            metadataAuthority: .verified,
            comicInfoPresent: true,
            volume: metadata.volume,
            imprint: metadata.imprint,
            characters: metadata.characters,
            genres: metadata.genres,
            languageISO: metadata.languageISO,
            storyArc: metadata.storyArc,
            format: metadata.format
        )
        saveOfflineInfo(info, bookID: book.id)
    }

    func setReaderActive(_ active: Bool) {
        if readerIsActive != active {
            readerIsActive = active
        }
    }

    func setGuidedPanelModeEnabled(_ enabled: Bool) {
        guard guidedPanelModeEnabled != enabled else { return }
        guidedPanelModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: guidedPanelModeKey)
    }


    /// Repairs stale metadata before launching the reader. Returns nil when ready.
    func readerLaunchError(for id: UUID) -> String? {
        guard let index = books.firstIndex(where: { $0.id == id }) else {
            return "This comic is no longer in the library."
        }

        let url = fileURL(for: books[index])
        let exists = fm.fileExists(atPath: url.path)

        if exists && !books[index].fileAvailable {
            books[index].fileAvailable = true
            save()
        }

        guard exists else {
            books[index].fileAvailable = false
            books[index].isInLibrary = false
            save()
            return "The comic file is not on this device. Re-import the same comic file and ComicPort will reconnect its saved data."
        }

        guard books[index].pageCount > 0 else {
            return "This file contains no readable comic pages."
        }

        return nil
    }

    /// Begin a reread without retaining the completed flag or creating reading history.
    func restartComic(id: UUID) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        activeSessions.removeValue(forKey: id)
        books[index].currentPage = 0
        books[index].readingStatus = .toRead
        books[index].lastReadAt = nil
        save()
    }

    func updateProgress(id: UUID, page: Int) {
        guard let i = books.firstIndex(where: { $0.id == id }) else { return }
        let clamped = max(0, min(page, max(0, books[i].pageCount - 1)))
        if clamped != books[i].currentPage {
            registerPageChange(id: id, page: clamped)
        }
        books[i].currentPage = clamped
        books[i].lastReadAt = .now
        if books[i].readingStatus == .toRead && clamped > 0 { books[i].readingStatus = .reading }
        if books[i].pageCount > 0 && clamped >= books[i].pageCount - 1 { books[i].readingStatus = .completed }
        scheduleLibrarySave()
    }

    func beginReading(id: UUID) {
        guard let i = books.firstIndex(where: { $0.id == id }), books[i].fileAvailable else { return }
        books[i].lastOpenedAt = .now
        books[i].lastReadAt = .now
        if books[i].readingStatus == .toRead && books[i].currentPage > 0 { books[i].readingStatus = .reading }
        activeSessions[id] = ActiveSession(startedAt: .now, startPage: books[i].currentPage, lastPage: books[i].currentPage, pagesRead: 0)
        UserDefaults.standard.set(id.uuidString, forKey: "ComicPort.lastReaderBookID")
        scheduleLibrarySave()
    }

    func endReading(id: UUID) {
        guard let session = activeSessions.removeValue(forKey: id), let book = books.first(where: { $0.id == id }) else { return }
        let seconds = max(1, Date().timeIntervalSince(session.startedAt))
        let entry = ReadingHistoryEntry(bookID: id, startPage: session.startPage, endPage: book.currentPage, pagesRead: session.pagesRead, seconds: seconds)
        analytics.history.insert(entry, at: 0)

        let key = Self.dayKey(.now)
        var day = analytics.daily[key] ?? DailyReadingStat()
        day.pages += session.pagesRead
        day.seconds += seconds
        analytics.daily[key] = day
        lastSessionSummary = ComicPortReadingSessionSummary(
            bookID: id,
            title: book.title,
            pagesRead: session.pagesRead,
            seconds: seconds
        )
        flushPendingLibrarySave()
        saveAnalytics()
        evaluateAchievements()
    }

    private func registerPageChange(id: UUID, page: Int) {
        guard var session = activeSessions[id], page != session.lastPage else { return }
        session.pagesRead += 1
        session.lastPage = page
        activeSessions[id] = session
    }

    func setStatus(id: UUID, status: ReadingStatus) {
        guard let i = books.firstIndex(where: { $0.id == id }) else { return }
        books[i].readingStatus = status
        save()
        evaluateAchievements()
    }

    func toggleFavorite(id: UUID) {
        guard let i = books.firstIndex(where: { $0.id == id }) else { return }
        books[i].favorite.toggle()
        save()
        evaluateAchievements()
    }

    func setRating(id: UUID, rating: Int) {
        guard let i = books.firstIndex(where: { $0.id == id }) else { return }
        books[i].rating = max(0, min(5, rating))
        save()
        evaluateAchievements()
    }

    func setDailyGoal(_ pages: Int) {
        analytics.dailyGoalPages = max(1, min(9999, pages))
        saveAnalytics()
        evaluateAchievements()
    }

    func toggleReadingDirection(id: UUID) {
        guard let i = books.firstIndex(where: { $0.id == id }) else { return }
        books[i].rightToLeft.toggle()
        save()
    }

    func noteURL(bookID: UUID, page: Int) -> URL {
        notesURL.appendingPathComponent("\(bookID.uuidString)-\(page).drawing")
    }

    func loadNote(bookID: UUID, page: Int) -> Data? {
        try? Data(contentsOf: noteURL(bookID: bookID, page: page))
    }

    func offlineInfoURL(bookID: UUID) -> URL {
        infoCacheURL.appendingPathComponent("\(bookID.uuidString).json")
    }

    func loadOfflineInfo(bookID: UUID) -> OfflineComicInfo? {
        guard let data = try? Data(contentsOf: offlineInfoURL(bookID: bookID)) else { return nil }
        return try? JSONDecoder().decode(OfflineComicInfo.self, from: data)
    }

    func saveOfflineInfo(_ info: OfflineComicInfo, bookID: UUID) {
        do {
            let data = try JSONEncoder().encode(info)
            try data.write(to: offlineInfoURL(bookID: bookID), options: .atomic)
        } catch {
            importError = "Could not save offline book info: \(error.localizedDescription)"
        }
    }

    func saveNote(_ data: Data, bookID: UUID, page: Int) {
        let url = noteURL(bookID: bookID, page: page)
        let wasNew = !fm.fileExists(atPath: url.path)
        do {
            try data.write(to: url, options: .atomic)
            pencilAnnotationPageKeys.insert("\(bookID.uuidString)-\(page)")
            annotationRevision &+= 1
            if wasNew { evaluateAchievements() }
        } catch {
            importError = "Could not save Pencil note: \(error.localizedDescription)"
        }
    }

    func deletePencilNote(bookID: UUID, page: Int) {
        try? fm.removeItem(at: noteURL(bookID: bookID, page: page))
        pencilAnnotationPageKeys.remove("\(bookID.uuidString)-\(page)")
        annotationRevision &+= 1
    }

    func textNote(bookID: UUID, page: Int) -> PageTextNote? {
        textNotes.first { $0.bookID == bookID && $0.page == page }
    }

    func saveTextNote(bookID: UUID, page: Int, text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            textNotes.removeAll { $0.bookID == bookID && $0.page == page }
        } else if let index = textNotes.firstIndex(where: { $0.bookID == bookID && $0.page == page }) {
            textNotes[index].text = cleaned
            textNotes[index].updatedAt = .now
        } else {
            textNotes.append(PageTextNote(bookID: bookID, page: page, text: cleaned))
        }
        saveTextNotes()
        annotationRevision &+= 1
        evaluateAchievements()
    }

    func deleteTextNote(bookID: UUID, page: Int) {
        textNotes.removeAll { $0.bookID == bookID && $0.page == page }
        saveTextNotes()
        annotationRevision &+= 1
    }

    func panelURL(for panel: SavedPanel) -> URL {
        panelsURL.appendingPathComponent(panel.imageFileName)
    }

    @discardableResult
    func savePanel(_ jpegData: Data, bookID: UUID, page: Int) -> SavedPanel? {
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let url = panelsURL.appendingPathComponent(fileName)
        do {
            try jpegData.write(to: url, options: .atomic)
            let panel = SavedPanel(id: id, bookID: bookID, page: page, imageFileName: fileName)
            savedPanels.insert(panel, at: 0)
            saveSavedPanels()
            evaluateAchievements()
            return panel
        } catch {
            importError = "Could not save panel: \(error.localizedDescription)"
            return nil
        }
    }

    func deletePanel(_ panel: SavedPanel) {
        try? fm.removeItem(at: panelURL(for: panel))
        savedPanels.removeAll { $0.id == panel.id }
        saveSavedPanels()
    }

    func annotationPages() -> [AnnotationPageSummary] {
        var map: [String: AnnotationPageSummary] = [:]

        for note in textNotes {
            let key = "\(note.bookID.uuidString)-\(note.page)"
            map[key] = AnnotationPageSummary(
                bookID: note.bookID,
                page: note.page,
                hasPencilDrawing: map[key]?.hasPencilDrawing ?? false,
                textNote: note.text
            )
        }

        for key in pencilAnnotationPageKeys {
            guard let split = key.lastIndex(of: "-"),
                  let id = UUID(uuidString: String(key[..<split])),
                  let page = Int(key[key.index(after: split)...]) else { continue }
            map[key] = AnnotationPageSummary(
                bookID: id,
                page: page,
                hasPencilDrawing: true,
                textNote: map[key]?.textNote
            )
        }

        return map.values.sorted {
            let leftTitle = bookTitle(for: $0.bookID)
            let rightTitle = bookTitle(for: $1.bookID)
            if leftTitle == rightTitle { return $0.page < $1.page }
            return leftTitle.localizedCaseInsensitiveCompare(rightTitle) == .orderedAscending
        }
    }

    private func rebuildPencilAnnotationIndex() {
        guard let urls = try? fm.contentsOfDirectory(at: notesURL, includingPropertiesForKeys: nil) else {
            pencilAnnotationPageKeys = []
            return
        }

        pencilAnnotationPageKeys = Set(urls.compactMap { url -> String? in
            guard url.pathExtension == "drawing" else { return nil }
            return url.deletingPathExtension().lastPathComponent
        })
    }

    private func loadTextNotes() {
        guard let data = try? Data(contentsOf: textNotesURL),
              let decoded = try? JSONDecoder().decode([PageTextNote].self, from: data) else { return }
        textNotes = decoded
    }

    private func saveTextNotes() {
        persistInBackground(textNotes, to: textNotesURL, errorPrefix: "Could not save text notes")
    }

    private func loadSavedPanels() {
        guard let data = try? Data(contentsOf: savedPanelsURL),
              let decoded = try? JSONDecoder().decode([SavedPanel].self, from: data) else { return }
        savedPanels = decoded.filter { fm.fileExists(atPath: panelsURL.appendingPathComponent($0.imageFileName).path) }
    }

    private func saveSavedPanels() {
        persistInBackground(savedPanels, to: savedPanelsURL, errorPrefix: "Could not save My Panels")
    }


    func shouldOfferCompletionJournal(for bookID: UUID, now: Date = .now) -> Bool {
        if let recent = readingJournalEntries
            .filter({ $0.bookID == bookID })
            .map(\.completedAt)
            .max(),
           now.timeIntervalSince(recent) < 12 * 60 * 60 {
            return false
        }

        let key = "PanelReader.journalDismissed.\(bookID.uuidString)"
        if let dismissed = UserDefaults.standard.object(forKey: key) as? Date,
           now.timeIntervalSince(dismissed) < 12 * 60 * 60 {
            return false
        }
        return true
    }

    func dismissCompletionJournalPrompt(bookID: UUID) {
        UserDefaults.standard.set(Date.now, forKey: "PanelReader.journalDismissed.\(bookID.uuidString)")
    }

    func saveReadingJournalEntry(
        bookID: UUID,
        completedAt: Date,
        rating: Int,
        note: String,
        wouldReread: Bool,
        favoritePanelID: UUID?
    ) {
        let entry = ReadingJournalEntry(
            bookID: bookID,
            completedAt: completedAt,
            rating: rating,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            wouldReread: wouldReread,
            favoritePanelID: favoritePanelID
        )
        readingJournalEntries.insert(entry, at: 0)

        if rating > 0, let index = books.firstIndex(where: { $0.id == bookID }) {
            books[index].rating = max(1, min(5, rating))
            scheduleLibrarySave()
        }

        UserDefaults.standard.removeObject(forKey: "PanelReader.journalDismissed.\(bookID.uuidString)")
        saveReadingJournal()
        evaluateAchievements()
    }

    func deleteReadingJournalEntry(_ id: UUID) {
        readingJournalEntries.removeAll { $0.id == id }
        saveReadingJournal()
    }

    private func loadReadingJournal() {
        guard let data = try? Data(contentsOf: readingJournalURL),
              let decoded = try? JSONDecoder().decode([ReadingJournalEntry].self, from: data) else { return }
        readingJournalEntries = decoded
    }

    private func saveReadingJournal() {
        persistInBackground(readingJournalEntries, to: readingJournalURL, errorPrefix: "Could not save Reading Journal")
    }

    func archive(_ book: ComicBook) {
        guard let i = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[i].isArchived = true
        books[i].isInLibrary = true
        save()
    }

    func unarchive(_ book: ComicBook) {
        guard let i = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[i].isArchived = false
        books[i].isInLibrary = true
        save()
    }

    func removeFromLibrary(_ book: ComicBook) {
        guard let i = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[i].isInLibrary = false
        books[i].isArchived = false
        save()
    }

    func restoreToLibrary(_ book: ComicBook) {
        guard let i = books.firstIndex(where: { $0.id == book.id }) else { return }
        guard books[i].fileAvailable && fm.fileExists(atPath: fileURL(for: books[i]).path) else {
            importError = "The original comic file is not on this device. Import the same comic again and ComicPort will reconnect its saved data."
            return
        }
        books[i].isInLibrary = true
        books[i].isArchived = false
        save()
    }

    func deleteFileKeepingData(_ book: ComicBook) {
        guard let i = books.firstIndex(where: { $0.id == book.id }) else { return }
        let url = fileURL(for: books[i])
        CBZService.cleanTemporaryExtraction(for: url)
        try? fm.removeItem(at: url)
        books[i].fileAvailable = false
        books[i].isInLibrary = false
        books[i].isArchived = false
        save()
    }

    func installOptimizedCopy(_ result: StorageOptimizationResult, for bookID: UUID) throws {
        guard let i = books.firstIndex(where: { $0.id == bookID }) else {
            throw StorageOptimizerError.fileMissing
        }
        guard result.pageCount == books[i].pageCount, result.optimizedBytes > 0 else {
            StorageOptimizer.discard(result)
            throw StorageOptimizerError.outputInvalid
        }

        let originalURL = fileURL(for: books[i])
        let oldType = books[i].type
        let oldName = books[i].storedFileName
        let newExtension = result.outputType.rawValue
        let newName = "\(bookID.uuidString).\(newExtension)"
        let newURL = booksURL.appendingPathComponent(newName)
        let backupURL = booksURL.appendingPathComponent("\(bookID.uuidString).panel-original-backup")

        CBZService.cleanTemporaryExtraction(for: originalURL)
        try? fm.removeItem(at: backupURL)

        do {
            if fm.fileExists(atPath: originalURL.path) {
                try fm.moveItem(at: originalURL, to: backupURL)
            }
            if newURL != originalURL, fm.fileExists(atPath: newURL.path) {
                try fm.removeItem(at: newURL)
            }
            try fm.moveItem(at: result.temporaryURL, to: newURL)

            let installedBytes = Int64((try? newURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            guard installedBytes > 0 else { throw StorageOptimizerError.outputInvalid }

            books[i].storedFileName = newName
            books[i].type = result.outputType
            books[i].fileAvailable = true
            // sourceIdentity deliberately stays unchanged so re-importing the original comic
            // can still reconnect to this comic's permanent stats and notes.
            save()
            try? fm.removeItem(at: backupURL)
        } catch {
            try? fm.removeItem(at: newURL)
            if fm.fileExists(atPath: backupURL.path) {
                try? fm.moveItem(at: backupURL, to: originalURL)
            }
            books[i].storedFileName = oldName
            books[i].type = oldType
            books[i].fileAvailable = fm.fileExists(atPath: originalURL.path)
            save()
            StorageOptimizer.discard(result)
            throw error
        }
    }

    func permanentlyDelete(_ book: ComicBook) {
        let url = fileURL(for: book)
        CBZService.cleanTemporaryExtraction(for: url)
        try? fm.removeItem(at: url)
        if let cover = coverURL(for: book) { try? fm.removeItem(at: cover) }
        if let notes = try? fm.contentsOfDirectory(at: notesURL, includingPropertiesForKeys: nil) {
            for note in notes where note.lastPathComponent.hasPrefix(book.id.uuidString) { try? fm.removeItem(at: note) }
        }
        textNotes.removeAll { $0.bookID == book.id }
        pencilAnnotationPageKeys = Set(pencilAnnotationPageKeys.filter { !$0.hasPrefix(book.id.uuidString + "-") })
        saveTextNotes()
        let panelsForBook = savedPanels.filter { $0.bookID == book.id }
        for panel in panelsForBook { try? fm.removeItem(at: panelURL(for: panel)) }
        savedPanels.removeAll { $0.bookID == book.id }
        saveSavedPanels()
        readingJournalEntries.removeAll { $0.bookID == book.id }
        saveReadingJournal()
        UserDefaults.standard.removeObject(forKey: "PanelReader.journalDismissed.\(book.id.uuidString)")
        annotationRevision &+= 1
        deleteSmartSearchIndex(for: book.id)
        deleteGuidedPanelCache(for: book.id)
        try? fm.removeItem(at: offlineInfoURL(bookID: book.id))
        books.removeAll { $0.id == book.id }
        readerSettingsByBook.removeValue(forKey: book.id.uuidString)
        saveReaderSettings()
        analytics.history.removeAll { $0.bookID == book.id }
        rebuildDailyAnalyticsFromHistory()
        save()
        saveAnalytics()
    }

    private func deleteGuidedPanelCache(for bookID: UUID) {
        guard let urls = try? fm.contentsOfDirectory(
            at: guidedPanelsURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return }

        for url in urls where url.lastPathComponent.hasPrefix(bookID.uuidString + "-") {
            try? fm.removeItem(at: url)
        }
    }

    private func rebuildDailyAnalyticsFromHistory() {
        var rebuilt: [String: DailyReadingStat] = [:]
        for entry in analytics.history {
            let key = Self.dayKey(entry.date)
            var day = rebuilt[key] ?? DailyReadingStat()
            day.pages += entry.pagesRead
            day.seconds += entry.seconds
            rebuilt[key] = day
        }
        analytics.daily = rebuilt
    }

    func bookTitle(for id: UUID) -> String { books.first(where: { $0.id == id })?.title ?? "Unknown comic" }

    private func ensureDirectories() {
        try? fm.createDirectory(at: booksURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: coversURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: notesURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: infoCacheURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: panelsURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: smartSearchURL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: guidedPanelsURL, withIntermediateDirectories: true)
    }

    private func load() {
        guard let data = try? Data(contentsOf: metadataURL), let decoded = try? JSONDecoder().decode([ComicBook].self, from: data) else { return }
        books = decoded
        var changed = false
        for i in books.indices {
            if books[i].sourceIdentity.isEmpty {
                books[i].sourceIdentity = Self.sourceIdentity(title: books[i].title, type: books[i].type, pageCount: books[i].pageCount)
                changed = true
            }
            let localFileExists = fm.fileExists(atPath: fileURL(for: books[i]).path)
            if books[i].fileAvailable && !localFileExists {
                books[i].fileAvailable = false
                books[i].isInLibrary = false
                changed = true
            } else if !books[i].fileAvailable && localFileExists {
                books[i].fileAvailable = true
                changed = true
            }
        }
        if changed { save() }
    }

    // MARK: - Lightweight persistence

    /// Page turns can happen rapidly. Writing library.json for every page makes the
    /// reader and the dashboard behind it stutter, so metadata writes are coalesced.
    private func scheduleLibrarySave() {
        pendingLibrarySave?.cancel()
        pendingLibrarySave = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled, let self else { return }

            self.save()

            guard !Task.isCancelled else { return }
            self.pendingLibrarySave = nil
            self.scheduleComicPortSyncExport()
        }
    }

    private func flushPendingLibrarySave() {
        pendingLibrarySave?.cancel()
        pendingLibrarySave = nil
        save()
    }

    private func loadAnalytics() {
        guard let data = try? Data(contentsOf: analyticsURL), let decoded = try? JSONDecoder().decode(ReadingAnalytics.self, from: data) else { return }
        analytics = decoded
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(books)
            metadataGeneration += 1
            try metadataWriter.write(data, to: metadataURL, generation: metadataGeneration)
            persistenceFailure = nil
            scheduleComicPortSyncExport()
        } catch {
            persistenceFailure = error
            importError = "Could not save library: \(error.localizedDescription)"
        }
    }

    private func persistInBackground<T: Encodable & Sendable>(
        _ snapshot: T,
        to url: URL,
        errorPrefix: String
    ) {
        do {
            try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
        } catch {
            persistenceFailure = error
            importError = "\(errorPrefix): \(error.localizedDescription)"
        }
    }

    private func saveAnalytics() {
        persistInBackground(
            analytics,
            to: analyticsURL,
            errorPrefix: "Could not save reading statistics"
        )
        scheduleComicPortSyncExport()
    }


    // MARK: - Stage 18 Smart Collections

    func createSmartCollection(
        name: String,
        titleContains: String,
        minimumRating: Int,
        statusRawValue: String,
        favoritesOnly: Bool,
        format: ComicPortSmartFormat,
        mangaOnly: Bool
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let rule = ComicPortSmartRule(
            titleContains: titleContains
                .trimmingCharacters(in: .whitespacesAndNewlines),
            minimumRating: max(0, min(5, minimumRating)),
            statusRawValue: statusRawValue,
            favoritesOnly: favoritesOnly,
            format: format,
            mangaOnly: mangaOnly
        )

        smartCollections.append(
            ComicPortSmartCollection(
                name: cleanName,
                rule: rule
            )
        )
        persistSmartCollections()
    }

    func deleteSmartCollection(_ id: UUID) {
        smartCollections.removeAll { $0.id == id }
        persistSmartCollections()
    }

    func books(for collection: ComicPortSmartCollection) -> [ComicBook] {
        libraryBooks
            .filter { collection.rule.matches($0) }
            .sorted {
                ($0.lastReadAt ?? $0.addedAt) >
                ($1.lastReadAt ?? $1.addedAt)
            }
    }

    func books(for builtIn: ComicPortBuiltInCollection) -> [ComicBook] {
        builtIn.books(from: books)
    }

    private func persistSmartCollections() {
        guard let data = try? JSONEncoder().encode(smartCollections) else {
            return
        }
        UserDefaults.standard.set(data, forKey: smartCollectionsDefaultsKey)
    }

    // MARK: - Stage 18 Local Sources

    func addSourceFolder(_ folder: URL) {
        #if targetEnvironment(macCatalyst)
        let access = folder.startAccessingSecurityScopedResource()
        defer {
            if access {
                folder.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let bookmark = try folder.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let standardizedPath = folder.standardizedFileURL.path
            if let index = sourceFolders.firstIndex(
                where: { $0.originalPath == standardizedPath }
            ) {
                sourceFolders[index].bookmarkData = bookmark
                sourceFolders[index].displayName = folder.lastPathComponent
            } else {
                sourceFolders.append(
                    ComicPortSourceFolder(
                        displayName: folder.lastPathComponent,
                        originalPath: standardizedPath,
                        bookmarkData: bookmark
                    )
                )
            }

            persistSourceFolders()
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let source = self.sourceFolders.first(
                    where: { $0.originalPath == standardizedPath }
                ) {
                    await self.scanSourceFolder(source.id)
                }
            }
        } catch {
            importError = "Could not remember source folder: \(error.localizedDescription)"
        }
        #else
        importError = "Source folders are currently optimized for ComicPort Mac."
        #endif
    }

    func removeSourceFolder(_ id: UUID) {
        sourceFolders.removeAll { $0.id == id }
        persistSourceFolders()
    }

    func clearSourceSeenHistory(_ id: UUID) {
        guard let index = sourceFolders.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }
        sourceFolders[index].seenFingerprints = []
        persistSourceFolders()
    }

    func scanAllSourceFolders() async {
        guard !sourceFolders.isEmpty, !sourceScanInProgress else { return }

        sourceScanInProgress = true
        defer { sourceScanInProgress = false }

        // Copy IDs: individual scans may update @Published sourceFolders.
        let ids = sourceFolders.map(\.id)
        for id in ids {
            guard !Task.isCancelled else { return }
            await scanSourceFolder(id)
        }
    }

    func scanSourceFolder(_ id: UUID) async {
        #if targetEnvironment(macCatalyst)
        guard let index = sourceFolders.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        let source = sourceFolders[index]
        var stale = false

        do {
            let folder = try URL(
                resolvingBookmarkData: source.bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )

            let access = folder.startAccessingSecurityScopedResource()
            defer {
                if access {
                    folder.stopAccessingSecurityScopedResource()
                }
            }

            if stale,
               let renewed = try? folder.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
               ),
               let freshIndex = sourceFolders.firstIndex(
                    where: { $0.id == id }
               ) {
                sourceFolders[freshIndex].bookmarkData = renewed
            }

            let known = Set(source.seenFingerprints)
            let scanResult = await Task.detached(priority: .utility) {
                ComicPortSourceScanner.scan(
                    folder: folder,
                    excludingFingerprints: known
                )
            }.value

            guard !Task.isCancelled else { return }

            var importedCount = 0
            for item in scanResult.newItems {
                guard !Task.isCancelled else { break }
                importFile(item.url)
                importedCount += 1
            }

            if let freshIndex = sourceFolders.firstIndex(
                where: { $0.id == id }
            ) {
                var combined = Set(
                    sourceFolders[freshIndex].seenFingerprints
                )
                combined.formUnion(scanResult.allFingerprints)

                // Keep preferences compact even for huge NAS / archive folders.
                if combined.count > 12_000 {
                    combined = Set(
                        Array(combined.sorted()).suffix(12_000)
                    )
                }

                sourceFolders[freshIndex].seenFingerprints =
                    Array(combined)
                sourceFolders[freshIndex].lastScannedAt = .now
                sourceFolders[freshIndex].lastFoundCount =
                    scanResult.totalSupportedFiles
                sourceFolders[freshIndex].lastImportedCount =
                    importedCount
                sourceFolders[freshIndex].lastError = nil
                if importedCount > 0 {
                    sourceNotice = importedCount == 1
                        ? "1 new comic imported from \(source.displayName)."
                        : "\(importedCount) new comics imported from \(source.displayName)."
                }
                persistSourceFolders()
            }
        } catch {
            if let freshIndex = sourceFolders.firstIndex(
                where: { $0.id == id }
            ) {
                sourceFolders[freshIndex].lastScannedAt = .now
                sourceFolders[freshIndex].lastError =
                    error.localizedDescription
                persistSourceFolders()
            }
        }
        #endif
    }

    private func persistSourceFolders() {
        guard let data = try? JSONEncoder().encode(sourceFolders) else {
            return
        }
        UserDefaults.standard.set(data, forKey: sourceFoldersDefaultsKey)
    }

    // MARK: - Stage 18 ComicPort Sync Folder

    func setComicPortSyncFolder(_ folder: URL) {
        #if targetEnvironment(macCatalyst)
        let access = folder.startAccessingSecurityScopedResource()
        defer {
            if access {
                folder.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let bookmark = try folder.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            syncLocation = ComicPortSyncLocation(
                displayName: folder.lastPathComponent,
                originalPath: folder.standardizedFileURL.path,
                bookmarkData: bookmark
            )
            persistSyncLocation()
            syncStatusMessage = "Ready • \(folder.lastPathComponent)"

            Task { @MainActor [weak self] in
                await self?.performComicPortSync(importRemoteFirst: true)
            }
        } catch {
            syncStatusMessage =
                "Could not configure sync: \(error.localizedDescription)"
        }
        #else
        syncStatusMessage = "Sync Folder is currently optimized for ComicPort Mac."
        #endif
    }

    func clearComicPortSyncFolder() {
        pendingSyncExport?.cancel()
        pendingSyncExport = nil
        syncLocation = nil
        syncLastRun = nil
        syncStatusMessage = "Sync folder not configured"
        UserDefaults.standard.removeObject(
            forKey: syncLocationDefaultsKey
        )
    }

    func syncComicPortNow() {
        Task { @MainActor [weak self] in
            await self?.performComicPortSync(importRemoteFirst: true)
        }
    }

    private func persistSyncLocation() {
        guard let syncLocation,
              let data = try? JSONEncoder().encode(syncLocation) else {
            return
        }
        UserDefaults.standard.set(
            data,
            forKey: syncLocationDefaultsKey
        )
    }

    private func scheduleComicPortSyncExport() {
        guard syncLocation != nil, isBootstrapped else { return }

        pendingSyncExport?.cancel()
        pendingSyncExport = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled, let self else { return }
            await self.performComicPortSync(importRemoteFirst: false)
            self.pendingSyncExport = nil
        }
    }

    private func performComicPortSync(
        importRemoteFirst: Bool
    ) async {
        #if targetEnvironment(macCatalyst)
        guard let location = syncLocation else {
            syncStatusMessage = "Sync folder not configured"
            return
        }

        var stale = false

        do {
            let folder = try URL(
                resolvingBookmarkData: location.bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )

            let access = folder.startAccessingSecurityScopedResource()
            defer {
                if access {
                    folder.stopAccessingSecurityScopedResource()
                }
            }

            if stale,
               let renewed = try? folder.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
               ) {
                syncLocation = ComicPortSyncLocation(
                    id: location.id,
                    displayName: folder.lastPathComponent,
                    originalPath: folder.standardizedFileURL.path,
                    bookmarkData: renewed
                )
                persistSyncLocation()
            }

            let fileURL = folder.appendingPathComponent(syncFileName)

            if importRemoteFirst,
               fm.fileExists(atPath: fileURL.path),
               let data = try? Data(contentsOf: fileURL),
               let remote = try? JSONDecoder().decode(
                    ComicPortSyncSnapshot.self,
                    from: data
               ) {
                mergeComicPortSyncSnapshot(remote)
            }

            let snapshot = makeComicPortSyncSnapshot()
            let data = try JSONEncoder().encode(snapshot)

            try await Task.detached(priority: .utility) {
                try data.write(to: fileURL, options: .atomic)
            }.value

            guard !Task.isCancelled else { return }
            syncLastRun = .now
            syncStatusMessage = importRemoteFirst
                ? "Synced • \(location.displayName)"
                : "Auto-saved • \(location.displayName)"
        } catch {
            syncStatusMessage =
                "Sync failed: \(error.localizedDescription)"
        }
        #endif
    }

    private func makeComicPortSyncSnapshot() -> ComicPortSyncSnapshot {
        let bookStates = books
            .filter { !$0.sourceIdentity.isEmpty }
            .map {
                ComicPortSyncBookState(
                    sourceIdentity: $0.sourceIdentity,
                    title: $0.title,
                    currentPage: $0.currentPage,
                    pageCount: $0.pageCount,
                    readingStatus: $0.readingStatus,
                    favorite: $0.favorite,
                    rating: $0.rating,
                    lastReadAt: $0.lastReadAt
                )
            }

        let identityByBookID = Dictionary(
            uniqueKeysWithValues: books.map {
                ($0.id, $0.sourceIdentity)
            }
        )

        let historyStates = analytics.history.compactMap { entry
            -> ComicPortSyncHistoryState? in
            guard let identity = identityByBookID[entry.bookID],
                  !identity.isEmpty else {
                return nil
            }

            return ComicPortSyncHistoryState(
                id: entry.id,
                sourceIdentity: identity,
                date: entry.date,
                startPage: entry.startPage,
                endPage: entry.endPage,
                pagesRead: entry.pagesRead,
                seconds: entry.seconds
            )
        }

        return ComicPortSyncSnapshot(
            generatedAt: .now,
            books: bookStates,
            dailyGoalPages: analytics.dailyGoalPages,
            history: historyStates
        )
    }

    private func mergeComicPortSyncSnapshot(
        _ remote: ComicPortSyncSnapshot
    ) {
        var changedLibrary = false

        for state in remote.books {
            guard let index = books.firstIndex(
                where: { $0.sourceIdentity == state.sourceIdentity }
            ) else {
                continue
            }

            let local = books[index]
            let remoteReadIsNewer =
                (state.lastReadAt ?? .distantPast) >
                (local.lastReadAt ?? .distantPast)

            if remoteReadIsNewer {
                books[index].currentPage = min(
                    max(0, state.currentPage),
                    max(0, books[index].pageCount - 1)
                )
                books[index].readingStatus = state.readingStatus
                books[index].lastReadAt = state.lastReadAt
                changedLibrary = true
            } else if state.currentPage > books[index].currentPage {
                books[index].currentPage = min(
                    state.currentPage,
                    max(0, books[index].pageCount - 1)
                )
                changedLibrary = true
            }

            if state.readingStatus == .completed,
               books[index].readingStatus != .completed {
                books[index].readingStatus = .completed
                changedLibrary = true
            }

            if state.favorite && !books[index].favorite {
                books[index].favorite = true
                changedLibrary = true
            }

            if state.rating > books[index].rating {
                books[index].rating = min(5, state.rating)
                changedLibrary = true
            }
        }

        analytics.dailyGoalPages = max(
            analytics.dailyGoalPages,
            max(1, remote.dailyGoalPages)
        )

        let bookIDByIdentity = Dictionary(
            uniqueKeysWithValues: books.compactMap { book
                -> (String, UUID)? in
                guard !book.sourceIdentity.isEmpty else { return nil }
                return (book.sourceIdentity, book.id)
            }
        )

        var historyByID = Dictionary(
            uniqueKeysWithValues: analytics.history.map {
                ($0.id, $0)
            }
        )

        for item in remote.history {
            guard historyByID[item.id] == nil,
                  let bookID = bookIDByIdentity[item.sourceIdentity] else {
                continue
            }

            historyByID[item.id] = ReadingHistoryEntry(
                id: item.id,
                bookID: bookID,
                date: item.date,
                startPage: item.startPage,
                endPage: item.endPage,
                pagesRead: item.pagesRead,
                seconds: item.seconds
            )
        }

        let mergedHistory = historyByID.values.sorted {
            $0.date < $1.date
        }

        if mergedHistory != analytics.history {
            analytics.history = mergedHistory
            rebuildDailyAnalyticsFromHistory()
            saveAnalytics()
        }

        if changedLibrary {
            save()
        }
    }


    // MARK: - Series & reading orders

    func series(for bookID: UUID) -> ComicSeries? {
        SeriesService.series(containing: bookID, in: libraryBooks)
    }

    func nextIssue(after bookID: UUID) -> ComicBook? {
        SeriesService.nextIssue(after: bookID, in: libraryBooks)
    }

    func previousIssue(before bookID: UUID) -> ComicBook? {
        SeriesService.previousIssue(before: bookID, in: libraryBooks)
    }

    func setAutoOpenNextIssue(_ enabled: Bool) {
        autoOpenNextIssue = enabled
        UserDefaults.standard.set(enabled, forKey: autoNextKey)
    }

    func createStoryArc(name: String, bookIDs: [UUID]) {
        storyArcs.append(StoryArc(name: name, bookIDs: bookIDs))
        saveStoryArcs()
        evaluateAchievements()
    }

    func deleteStoryArc(_ id: UUID) {
        storyArcs.removeAll { $0.id == id }
        saveStoryArcs()
    }

    func moveStoryArcBooks(arcID: UUID, from source: IndexSet, to destination: Int) {
        guard let index = storyArcs.firstIndex(where: { $0.id == arcID }) else { return }
        storyArcs[index].bookIDs.move(fromOffsets: source, toOffset: destination)
        saveStoryArcs()
    }

    func storyArcProgress(_ arc: StoryArc) -> Int {
        guard !arc.bookIDs.isEmpty else { return 0 }
        let completedIDs = Set(books.lazy.filter { $0.readingStatus == .completed }.map(\.id))
        let completed = arc.bookIDs.reduce(0) { $0 + (completedIDs.contains($1) ? 1 : 0) }
        return Int((Double(completed) / Double(arc.bookIDs.count) * 100).rounded())
    }

    private func loadStoryArcs() {
        guard let data = try? Data(contentsOf: storyArcsURL),
              let decoded = try? JSONDecoder().decode([StoryArc].self, from: data) else { return }
        storyArcs = decoded
    }

    private func saveStoryArcs() {
        persistInBackground(storyArcs, to: storyArcsURL, errorPrefix: "Could not save reading orders")
    }

    // MARK: - Reader settings

    func readerSettings(for bookID: UUID) -> ReaderSettings {
        readerSettingsByBook[bookID.uuidString] ?? defaultReaderSettings
    }

    /// Updates the live reader preview and keeps the value in memory.
    /// The settings screen exposes an explicit Save button for persistence.
    func updateReaderSettings(bookID: UUID, _ change: (inout ReaderSettings) -> Void) {
        var value = readerSettings(for: bookID)
        change(&value)
        readerSettingsByBook[bookID.uuidString] = value
    }

    func persistReaderSettings(bookID: UUID) {
        // Ensure this book owns a concrete copy, even if it was using the defaults.
        if readerSettingsByBook[bookID.uuidString] == nil {
            readerSettingsByBook[bookID.uuidString] = defaultReaderSettings
        }
        saveReaderSettings()
    }

    func restoreReaderSettings(_ settings: ReaderSettings, for bookID: UUID) {
        readerSettingsByBook[bookID.uuidString] = settings
    }

    func useCurrentReaderSettingsAsDefault(bookID: UUID) {
        defaultReaderSettings = readerSettings(for: bookID)
        saveDefaultReaderSettings()
    }

    private func loadReaderSettings() {
        guard let data = try? Data(contentsOf: readerSettingsURL),
              let decoded = try? JSONDecoder().decode([String: ReaderSettings].self, from: data) else { return }
        readerSettingsByBook = decoded
    }

    private func saveReaderSettings() {
        persistInBackground(readerSettingsByBook, to: readerSettingsURL, errorPrefix: "Could not save reader settings")
    }

    private func loadDefaultReaderSettings() {
        guard let data = try? Data(contentsOf: defaultReaderSettingsURL),
              let decoded = try? JSONDecoder().decode(ReaderSettings.self, from: data) else { return }
        defaultReaderSettings = decoded
    }

    private func saveDefaultReaderSettings() {
        persistInBackground(defaultReaderSettings, to: defaultReaderSettingsURL, errorPrefix: "Could not save default reader settings")
    }


    // MARK: - Achievements

    func achievementProgress(for achievement: AchievementDefinition) -> Double {
        achievementSnapshot().value(for: achievement.metric)
    }

    private func loadAchievements() {
        guard let data = try? Data(contentsOf: achievementsURL),
              let decoded = try? JSONDecoder().decode(AchievementProfile.self, from: data) else { return }
        achievementProfile = decoded
    }

    private func saveAchievements() {
        persistInBackground(achievementProfile, to: achievementsURL, errorPrefix: "Could not save achievements")
    }

    private func bootstrapAchievementsIfNeeded() {
        guard !achievementProfile.hasBootstrapped else {
            evaluateAchievements()
            return
        }
        let snapshot = achievementSnapshot()
        for achievement in AchievementCatalog.all where snapshot.value(for: achievement.metric) >= achievement.target {
            achievementProfile.unlockedIDs.insert(achievement.id)
            achievementProfile.unlockedAt[achievement.id] = .now
        }
        achievementProfile.hasBootstrapped = true
        saveAchievements()
    }

    func evaluateAchievements() {
        let snapshot = achievementSnapshot()
        var newlyUnlocked: [AchievementDefinition] = []
        for achievement in AchievementCatalog.all where !achievementProfile.unlockedIDs.contains(achievement.id) {
            if snapshot.value(for: achievement.metric) >= achievement.target {
                achievementProfile.unlockedIDs.insert(achievement.id)
                achievementProfile.unlockedAt[achievement.id] = .now
                newlyUnlocked.append(achievement)
            }
        }
        guard !newlyUnlocked.isEmpty else { return }
        saveAchievements()
        achievementBannerQueue.append(contentsOf: newlyUnlocked)
        presentNextAchievementBannerIfNeeded()
    }

    private func presentNextAchievementBannerIfNeeded() {
        guard currentAchievementBanner == nil, !achievementBannerQueue.isEmpty else { return }
        currentAchievementBanner = achievementBannerQueue.removeFirst()
        let displaySeconds = 3.2
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(displaySeconds))
            guard let self else { return }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                self.currentAchievementBanner = nil
            }
            try? await Task.sleep(for: .milliseconds(180))
            self.presentNextAchievementBannerIfNeeded()
        }
    }

    private func achievementSnapshot() -> AchievementSnapshot {
        let totalPages = analytics.history.reduce(0) { $0 + max(0, $1.pagesRead) }
        let totalSeconds = analytics.history.reduce(0.0) { $0 + max(0, $1.seconds) }
        let completed = books.filter { $0.readingStatus == .completed }
        let favoriteCount = books.filter { $0.favorite }.count
        let ratedCount = books.filter { $0.rating > 0 }.count
        let goalDays = analytics.daily.values.filter { $0.pages >= analytics.dailyGoalPages }.count
        let maxDayPages = analytics.daily.values.map(\.pages).max() ?? 0
        let streak = currentReadingStreak()
        let omnibus = completed.filter { $0.pageCount >= 500 }.count

        var characters: [String: Int] = [:]
        var teams: [String: Int] = [:]
        let characterNames = ["Batman","Nightwing","Superman","Wonder Woman","Flash","Green Lantern","Aquaman","Harley Quinn","Joker","Robin","Spider-Man","Daredevil","Wolverine","Thor","Hulk","Iron Man","Captain America","Black Panther","Deadpool","Doctor Strange"]
        let teamNames = ["Justice League","Avengers","X-Men","Fantastic Four","Teen Titans","Bat-Family","Guardians of the Galaxy","Suicide Squad","Justice Society","Defenders"]

        for book in completed {
            let match = LocalComicDatabase.bestMatch(title: book.title)
            let detectedCharacters = Set((match?.record.characters ?? []) + characterNames.filter { Self.normalizedContains(book.title, $0) })
            for name in characterNames where detectedCharacters.contains(where: { Self.normalizedContains($0, name) || Self.normalizedContains(name, $0) }) {
                characters[name, default: 0] += 1
            }

            var searchable = book.title
            if let record = match?.record {
                searchable += " " + record.title + " " + record.tags.joined(separator: " ") + " " + record.description + " " + record.characters.joined(separator: " ")
            }
            for team in teamNames where Self.normalizedContains(searchable, team) {
                teams[team, default: 0] += 1
            }
            let batFamily = ["Batman","Nightwing","Robin","Batgirl","Red Hood","Red Robin","Oracle","Catwoman"]
            if detectedCharacters.contains(where: { character in batFamily.contains(where: { Self.normalizedContains(character, $0) }) }) {
                teams["Bat-Family", default: 0] += 1
            }
        }

        return AchievementSnapshot(
            totalPages: totalPages,
            totalSeconds: totalSeconds,
            completedBooks: completed.count,
            libraryBooks: libraryBooks.count,
            favorites: favoriteCount,
            ratedBooks: ratedCount,
            currentStreak: streak,
            goalDays: goalDays,
            maxDayPages: maxDayPages,
            omnibusCompleted: omnibus,
            characterCompleted: characters,
            teamCompleted: teams,
            maxCompletedInSeries: SeriesService.maxCompletedIssuesInOneSeries(books: books),
            completedStoryArcs: storyArcs.filter { storyArcProgress($0) == 100 }.count,
            annotatedPages: annotationPageCount,
            savedPanels: savedPanels.count
        )
    }

    private func currentReadingStreak() -> Int {
        let calendar = Calendar.current
        let activeDays = Set(analytics.daily.compactMap { key, value -> Date? in
            guard value.pages > 0 else { return nil }
            return PanelDayKey.date(key, calendar: calendar)
        }.map { calendar.startOfDay(for: $0) })

        var cursor = calendar.startOfDay(for: .now)
        if !activeDays.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), activeDays.contains(yesterday) {
            cursor = yesterday
        }
        var count = 0
        while activeDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    private static func normalizedContains(_ haystack: String, _ needle: String) -> Bool {
        func norm(_ value: String) -> String {
            value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let h = norm(haystack)
        let n = norm(needle)
        return !n.isEmpty && (h == n || h.contains(n))
    }

    private static func sourceIdentity(title: String, type: ComicType, pageCount: Int) -> String {
        let folded = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let normalized = folded
            .replacingOccurrences(of: "[^a-zA-Z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .lowercased()
        return "\(normalized)|\(type.rawValue)|\(pageCount)"
    }

    private static func dayKey(_ date: Date) -> String {
        PanelDayKey.string(date, calendar: .current)
    }
}



// MARK: - Offline Smart Search

extension LibraryStore {
    var smartSearchIndexedBookCount: Int {
        smartSearchCacheReady ? smartSearchIndexes.count : smartSearchKnownIndexIDs.count
    }

    var smartSearchIndexedPageCount: Int {
        smartSearchIndexes.values.reduce(0) { $0 + $1.searchablePageCount }
    }

    func smartSearchIsIndexed(_ bookID: UUID) -> Bool {
        if smartSearchCacheReady {
            return smartSearchIndexes[bookID] != nil
        }
        return smartSearchKnownIndexIDs.contains(bookID)
    }

    func smartSearch(query: String) -> [SmartSearchHit] {
        SmartSearchDiskService.search(
            query: query,
            books: books.map { SmartSearchBookRecord(id: $0.id, title: $0.title) },
            indexes: smartSearchIndexes
        )
    }

    func smartSearchAsync(query: String) async -> [SmartSearchHit] {
        let bookRecords = books.map { SmartSearchBookRecord(id: $0.id, title: $0.title) }
        let indexSnapshot = smartSearchIndexes
        return await Task.detached(priority: .userInitiated) {
            SmartSearchDiskService.search(
                query: query,
                books: bookRecords,
                indexes: indexSnapshot
            )
        }.value
    }

    func loadSmartSearchCacheIfNeeded() async {
        guard !smartSearchCacheReady else { return }

        let expected: [UUID: (sourceIdentity: String, pageCount: Int)] = Dictionary(
            uniqueKeysWithValues: books.map {
                (
                    $0.id,
                    (
                        sourceIdentity: $0.sourceIdentity.isEmpty
                            ? Self.sourceIdentity(title: $0.title, type: $0.type, pageCount: $0.pageCount)
                            : $0.sourceIdentity,
                        pageCount: $0.pageCount
                    )
                )
            }
        )
        let directory = smartSearchURL

        let loaded = await Task.detached(priority: .utility) {
            SmartSearchDiskService.loadIndexes(directory: directory, expected: expected)
        }.value

        guard !Task.isCancelled else { return }
        smartSearchIndexes = loaded
        smartSearchKnownIndexIDs = Set(loaded.keys)
        smartSearchCacheReady = true
        smartSearchRevision &+= 1
    }

    func startSmartSearchIndexing(forceAll: Bool = false, only bookID: UUID? = nil) {
        smartSearchTask?.cancel()
        smartSearchLastError = nil

        smartSearchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.loadSmartSearchCacheIfNeeded()
            guard !Task.isCancelled else { return }

            let available = self.books.filter {
                $0.fileAvailable && (bookID == nil || $0.id == bookID)
            }

            let candidates: [ComicBook]
            if forceAll {
                candidates = available
            } else {
                candidates = available.filter { self.smartSearchIndexes[$0.id] == nil }
            }

            guard !candidates.isEmpty else {
                self.smartSearchProgress = nil
                self.smartSearchLastError = nil
                self.smartSearchTask = nil
                return
            }

            for (offset, book) in candidates.enumerated() {
                if Task.isCancelled { break }

                let sourceIdentity = book.sourceIdentity.isEmpty
                    ? Self.sourceIdentity(title: book.title, type: book.type, pageCount: book.pageCount)
                    : book.sourceIdentity

                let descriptor = SmartSearchBookDescriptor(
                    id: book.id,
                    title: book.title,
                    sourceIdentity: sourceIdentity,
                    fileURL: self.fileURL(for: book),
                    type: book.type,
                    pageCount: book.pageCount
                )

                var finishedIndex: OCRBookIndex?

                do {
                    for try await event in OfflineOCRIndexer.stream(descriptor: descriptor) {
                        if Task.isCancelled { throw CancellationError() }

                        switch event {
                        case .progress(let page, let total):
                            self.smartSearchProgress = SmartSearchProgress(
                                bookID: book.id,
                                bookTitle: book.title,
                                bookNumber: offset + 1,
                                totalBooks: candidates.count,
                                page: page,
                                totalPages: total
                            )

                        case .finished(let index):
                            finishedIndex = index
                        }
                    }

                    guard let index = finishedIndex else { continue }
                    let target = self.smartSearchIndexURL(bookID: book.id)

                    try await Task.detached(priority: .utility) {
                        try SmartSearchDiskService.save(index, to: target)
                    }.value

                    self.smartSearchIndexes[book.id] = index
                    self.smartSearchKnownIndexIDs.insert(book.id)
                    self.smartSearchRevision &+= 1
                } catch is CancellationError {
                    break
                } catch {
                    self.smartSearchLastError = "\(book.title): \(error.localizedDescription)"
                    // Continue with the next comic rather than abandoning the entire library.
                }
            }

            self.smartSearchProgress = nil
            self.smartSearchTask = nil
        }
    }

    func cancelSmartSearchIndexing() {
        smartSearchTask?.cancel()
        smartSearchTask = nil
        smartSearchProgress = nil
    }

    func clearAllSmartSearchIndexes() {
        cancelSmartSearchIndexing()
        let directory = smartSearchURL

        if let urls = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for url in urls where url.pathExtension.lowercased() == "json" {
                try? fm.removeItem(at: url)
            }
        }

        smartSearchIndexes.removeAll()
        smartSearchKnownIndexIDs.removeAll()
        smartSearchCacheReady = true
        smartSearchLastError = nil
        smartSearchRevision &+= 1
    }

    func deleteSmartSearchIndex(for bookID: UUID) {
        try? fm.removeItem(at: smartSearchIndexURL(bookID: bookID))
        smartSearchIndexes.removeValue(forKey: bookID)
        smartSearchKnownIndexIDs.remove(bookID)
        smartSearchRevision &+= 1
    }

    private func smartSearchIndexURL(bookID: UUID) -> URL {
        smartSearchURL.appendingPathComponent("\(bookID.uuidString).json")
    }

    private func loadSmartSearchFileList() {
        guard let urls = try? fm.contentsOfDirectory(
            at: smartSearchURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            smartSearchKnownIndexIDs = []
            return
        }

        smartSearchKnownIndexIDs = Set(
            urls.compactMap { url in
                guard url.pathExtension.lowercased() == "json" else { return nil }
                return UUID(uuidString: url.deletingPathExtension().lastPathComponent)
            }
        )
    }
}

// MARK: - Panel Backup

extension LibraryStore {
    func makeBackupData(accentTheme: PanelAccentTheme) async throws -> Data {
        flushPendingLibrarySave()
        if let failure = persistenceFailure { throw failure }

        let noteDirectory = notesURL
        let panelDirectory = panelsURL
        let infoDirectory = infoCacheURL
        let panelMetadata = savedPanels

        let assets = try await Task.detached(priority: .utility) {
            let fm = FileManager.default

            var drawings: [BackupPencilDrawing] = []
            do {
                let urls = try fm.contentsOfDirectory(at: noteDirectory, includingPropertiesForKeys: nil)
                for url in urls where url.pathExtension == "drawing" {
                    let base = url.deletingPathExtension().lastPathComponent
                    guard let split = base.lastIndex(of: "-"),
                          let id = UUID(uuidString: String(base[..<split])),
                          let page = Int(base[base.index(after: split)...]) else {
                        throw BackupSafety.error("Unrecognized drawing asset: \(url.lastPathComponent)")
                    }
                    let data = try Data(contentsOf: url)
                    drawings.append(BackupPencilDrawing(bookID: id, page: page, data: data))
                }
            }

            var panelImages: [BackupPanelImage] = []
            for panel in panelMetadata {
                let url = try BackupSafety.assetURL(panel.imageFileName, in: panelDirectory)
                do {
                    let data = try Data(contentsOf: url)
                    panelImages.append(BackupPanelImage(panelID: panel.id, data: data))
                }
            }

            var infoFiles: [BackupBookInfo] = []
            do {
                let urls = try fm.contentsOfDirectory(at: infoDirectory, includingPropertiesForKeys: nil)
                for url in urls where url.pathExtension.lowercased() == "json" {
                    let stem = url.deletingPathExtension().lastPathComponent
                    guard let id = UUID(uuidString: stem) else { throw BackupSafety.error("Unrecognized book info asset") }
                    let data = try Data(contentsOf: url)
                    infoFiles.append(BackupBookInfo(bookID: id, data: data))
                }
            }

            return (drawings, panelImages, infoFiles)
        }.value

        let payload = PanelBackupPayload(
            schemaVersion: PanelBackupPayload.currentSchemaVersion,
            createdAt: .now,
            appVersion: "2.1 Stage 19 Mac v0.6 RC1",
            books: books,
            analytics: analytics,
            achievementProfile: achievementProfile,
            readerSettingsByBook: readerSettingsByBook,
            defaultReaderSettings: defaultReaderSettings,
            storyArcs: storyArcs,
            autoOpenNextIssue: autoOpenNextIssue,
            textNotes: textNotes,
            savedPanels: savedPanels,
            readingJournal: readingJournalEntries,
            smartCollections: smartCollections,
            pencilDrawings: assets.0,
            panelImages: assets.1,
            bookInfoFiles: assets.2,
            accentThemeRawValue: accentTheme.rawValue
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(payload)
    }

    func restoreBackupData(_ data: Data) throws -> PanelBackupRestoreResult {

        let decoder = JSONDecoder()
        let payload = try decoder.decode(PanelBackupPayload.self, from: data)
        guard payload.schemaVersion <= PanelBackupPayload.currentSchemaVersion else {
            throw NSError(
                domain: "PanelReader.Backup",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "This backup was created by a newer ComicPort backup format."]
            )
        }

        try BackupSafety.validate(payload)
        for directory in [booksURL, coversURL, notesURL, panelsURL, infoCacheURL] {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        flushPendingLibrarySave()
        for book in books + payload.books {
            _ = try BackupSafety.assetURL(book.storedFileName, in: booksURL)
            if let name = book.thumbnailFileName { _ = try BackupSafety.assetURL(name, in: coversURL) }
        }
        for panel in payload.savedPanels {
            _ = try BackupSafety.assetURL(panel.imageFileName, in: panelsURL)
        }
        if let failure = persistenceFailure { throw failure }

        var idMap: [UUID: UUID] = [:]
        var mergedBooks = books

        func identity(_ book: ComicBook) -> String {
            if !book.sourceIdentity.isEmpty { return book.sourceIdentity }
            return Self.sourceIdentity(title: book.title, type: book.type, pageCount: book.pageCount)
        }

        for incoming in payload.books {
            let incomingIdentity = identity(incoming)

            if let currentIndex = mergedBooks.firstIndex(where: {
                $0.id == incoming.id || identity($0) == incomingIdentity
            }) {
                let current = mergedBooks[currentIndex]
                idMap[incoming.id] = current.id

                let localURL = booksURL.appendingPathComponent(current.storedFileName)
                let localExists = fm.fileExists(atPath: localURL.path)

                let localPageCount = localExists ? max(1, current.pageCount) : max(1, incoming.pageCount)
                let restored = ComicBook(
                    id: current.id,
                    title: incoming.title,
                    storedFileName: localExists ? current.storedFileName : incoming.storedFileName,
                    type: localExists ? current.type : incoming.type,
                    pageCount: localPageCount,
                    currentPage: min(incoming.currentPage, max(0, localPageCount - 1)),
                    addedAt: min(current.addedAt, incoming.addedAt),
                    thumbnailFileName: localExists ? current.thumbnailFileName : incoming.thumbnailFileName,
                    rightToLeft: incoming.rightToLeft,
                    readingStatus: incoming.readingStatus,
                    favorite: incoming.favorite || current.favorite,
                    rating: incoming.rating > 0 ? incoming.rating : current.rating,
                    lastOpenedAt: maxOptionalDate(current.lastOpenedAt, incoming.lastOpenedAt),
                    lastReadAt: maxOptionalDate(current.lastReadAt, incoming.lastReadAt),
                    sourceIdentity: incomingIdentity,
                    isInLibrary: localExists ? current.isInLibrary : false,
                    fileAvailable: localExists,
                    isArchived: localExists ? incoming.isArchived : false
                )
                mergedBooks[currentIndex] = restored
            } else {
                idMap[incoming.id] = incoming.id
                let possibleURL = booksURL.appendingPathComponent(incoming.storedFileName)
                let exists = fm.fileExists(atPath: possibleURL.path)

                mergedBooks.append(
                    ComicBook(
                        id: incoming.id,
                        title: incoming.title,
                        storedFileName: incoming.storedFileName,
                        type: incoming.type,
                        pageCount: incoming.pageCount,
                        currentPage: min(incoming.currentPage, max(0, incoming.pageCount - 1)),
                        addedAt: incoming.addedAt,
                        thumbnailFileName: incoming.thumbnailFileName,
                        rightToLeft: incoming.rightToLeft,
                        readingStatus: incoming.readingStatus,
                        favorite: incoming.favorite,
                        rating: incoming.rating,
                        lastOpenedAt: incoming.lastOpenedAt,
                        lastReadAt: incoming.lastReadAt,
                        sourceIdentity: incomingIdentity,
                        isInLibrary: exists ? incoming.isInLibrary : false,
                        fileAvailable: exists,
                        isArchived: exists ? incoming.isArchived : false
                    )
                )
            }
        }

        // Stage every asset before changing live metadata or files.
        let staging = documentsURL.appendingPathComponent("Restore-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        var staged: [(URL, URL)] = []
        func stage(_ bytes: Data, target: URL) throws {
            let source = staging.appendingPathComponent(UUID().uuidString)
            try bytes.write(to: source, options: .atomic)
            staged.append((source, target))
        }
        for drawing in payload.pencilDrawings {
            try stage(drawing.data, target: noteURL(bookID: idMap[drawing.bookID]!, page: drawing.page))
        }
        for image in payload.panelImages {
            let panel = payload.savedPanels.first { $0.id == image.panelID }!
            try stage(image.data, target: BackupSafety.assetURL(panel.imageFileName, in: panelsURL))
        }
        for info in payload.bookInfoFiles {
            try stage(info.data, target: offlineInfoURL(bookID: idMap[info.bookID]!))
        }
        // Preserve overwritten assets so a failed asset commit can roll back.
        var previous: [(URL, Data?)] = []
        do {
            for (source, target) in staged {
                let old = fm.fileExists(atPath: target.path) ? try Data(contentsOf: target) : nil
                previous.append((target, old))
                try Data(contentsOf: source).write(to: target, options: .atomic)
            }
        } catch {
            var rollbackFailed = false
            for (target, old) in previous.reversed() {
                do {
                    if let old { try old.write(to: target, options: .atomic) }
                    else if fm.fileExists(atPath: target.path) { try fm.removeItem(at: target) }
                } catch { rollbackFailed = true }
            }
            throw BackupSafety.error("Restore asset commit failed: \(error.localizedDescription). \(rollbackFailed ? "Some assets could not be rolled back." : "No metadata was changed.")")
        }
        books = mergedBooks

        // Reading history is merged by history-entry UUID so restoring the same backup twice does not double-count.
        var historyByID = Dictionary(uniqueKeysWithValues: analytics.history.map { ($0.id, $0) })
        for entry in payload.analytics.history {
            let mappedID = idMap[entry.bookID] ?? entry.bookID
            historyByID[entry.id] = ReadingHistoryEntry(
                id: entry.id,
                bookID: mappedID,
                date: entry.date,
                startPage: entry.startPage,
                endPage: entry.endPage,
                pagesRead: entry.pagesRead,
                seconds: entry.seconds
            )
        }

        analytics.dailyGoalPages = payload.analytics.dailyGoalPages
        analytics.history = historyByID.values.sorted { $0.date < $1.date }
        analytics.daily = rebuildDailyStats(from: analytics.history)

        // Never take achievements away during a merge restore.
        achievementProfile.unlockedIDs.formUnion(payload.achievementProfile.unlockedIDs)
        for (id, date) in payload.achievementProfile.unlockedAt {
            if let current = achievementProfile.unlockedAt[id] {
                achievementProfile.unlockedAt[id] = min(current, date)
            } else {
                achievementProfile.unlockedAt[id] = date
            }
        }
        achievementProfile.hasBootstrapped = achievementProfile.hasBootstrapped || payload.achievementProfile.hasBootstrapped

        // Reader settings remap backup book IDs to any matching local book IDs.
        for (oldKey, value) in payload.readerSettingsByBook {
            if let oldID = UUID(uuidString: oldKey) {
                let newID = idMap[oldID] ?? oldID
                readerSettingsByBook[newID.uuidString] = value
            }
        }
        defaultReaderSettings = payload.defaultReaderSettings

        // Story arcs are merged by arc ID, with book IDs remapped.
        var arcsByID = Dictionary(uniqueKeysWithValues: storyArcs.map { ($0.id, $0) })
        for arc in payload.storyArcs {
            let mapped = StoryArc(
                id: arc.id,
                name: arc.name,
                bookIDs: arc.bookIDs.map { idMap[$0] ?? $0 },
                createdAt: arc.createdAt
            )
            arcsByID[arc.id] = mapped
        }
        storyArcs = arcsByID.values.sorted { $0.createdAt < $1.createdAt }

        // Text notes use page identity so backup values replace the same page note.
        var textByPage = Dictionary(uniqueKeysWithValues: textNotes.map {
            ("\($0.bookID.uuidString)-\($0.page)", $0)
        })
        for note in payload.textNotes {
            let mappedID = idMap[note.bookID] ?? note.bookID
            let mapped = PageTextNote(
                id: note.id,
                bookID: mappedID,
                page: note.page,
                text: note.text,
                updatedAt: note.updatedAt
            )
            textByPage["\(mappedID.uuidString)-\(note.page)"] = mapped
        }
        textNotes = textByPage.values.sorted { $0.updatedAt < $1.updatedAt }

        // Reading Journal was added in backup schema 2. Older backups simply
        // have no journal field and remain fully restorable.
        var journalByID = Dictionary(uniqueKeysWithValues: readingJournalEntries.map { ($0.id, $0) })
        for entry in payload.readingJournal ?? [] {
            let mappedID = idMap[entry.bookID] ?? entry.bookID
            journalByID[entry.id] = ReadingJournalEntry(
                id: entry.id,
                bookID: mappedID,
                completedAt: entry.completedAt,
                rating: entry.rating,
                note: entry.note,
                wouldReread: entry.wouldReread,
                favoritePanelID: entry.favoritePanelID,
                updatedAt: entry.updatedAt
            )
        }
        readingJournalEntries = journalByID.values.sorted { $0.completedAt > $1.completedAt }

        // My Panels metadata/images.
        var panelsByID = Dictionary(uniqueKeysWithValues: savedPanels.map { ($0.id, $0) })
        for panel in payload.savedPanels {
            let mappedID = idMap[panel.bookID] ?? panel.bookID
            panelsByID[panel.id] = SavedPanel(
                id: panel.id,
                bookID: mappedID,
                page: panel.page,
                imageFileName: panel.imageFileName,
                createdAt: panel.createdAt
            )
        }
        savedPanels = panelsByID.values.sorted { $0.createdAt > $1.createdAt }

        autoOpenNextIssue = payload.autoOpenNextIssue
        UserDefaults.standard.set(autoOpenNextIssue, forKey: autoNextKey)

        // Schema 3: rule-based Smart Collections are portable.
        // Security-scoped Source/Sync folder bookmarks are intentionally not.
        if let incomingCollections = payload.smartCollections {
            var byID = Dictionary(
                uniqueKeysWithValues: smartCollections.map { ($0.id, $0) }
            )
            for collection in incomingCollections {
                byID[collection.id] = collection
            }
            smartCollections = byID.values.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) ==
                    .orderedAscending
            }
            persistSmartCollections()
        }

        rebuildPencilAnnotationIndex()
        annotationRevision &+= 1

        persistenceFailure = nil
        save()
        saveAnalytics()
        saveAchievements()
        saveReaderSettings()
        saveDefaultReaderSettings()
        saveStoryArcs()
        saveTextNotes()
        saveSavedPanels()
        saveReadingJournal()
        evaluateAchievements()

        if let failure = persistenceFailure {
            throw BackupSafety.error("Restore was applied in memory, but saving failed; restore is incomplete: \(failure.localizedDescription)")
        }
        return PanelBackupRestoreResult(
            accentTheme: PanelAccentTheme(rawValue: payload.accentThemeRawValue),
            importedBooks: payload.books.count,
            historyEntries: payload.analytics.history.count,
            notes: annotationPageCount,
            panels: payload.savedPanels.count
        )
    }

    private func rebuildDailyStats(from history: [ReadingHistoryEntry]) -> [String: DailyReadingStat] {
        var daily: [String: DailyReadingStat] = [:]
        for entry in history {
            let key = Self.dayKey(entry.date)
            var stat = daily[key] ?? DailyReadingStat()
            stat.pages += max(0, entry.pagesRead)
            stat.seconds += max(0, entry.seconds)
            daily[key] = stat
        }
        return daily
    }

    private func maxOptionalDate(_ lhs: Date?, _ rhs: Date?) -> Date? {
        switch (lhs, rhs) {
        case let (a?, b?): return max(a, b)
        case let (a?, nil): return a
        case let (nil, b?): return b
        case (nil, nil): return nil
        }
    }
}



// MARK: - Stage 20.4 Power Tools

extension LibraryStore {
    func clearSourceNotice() { sourceNotice = nil }
    func clearSessionSummary() { lastSessionSummary = nil }

    func setCover(bookID: UUID, page: Int) async -> Bool {
        guard let index = books.firstIndex(where: { $0.id == bookID }) else { return false }
        let book = books[index]
        guard let data = await ReaderPageSnapshotService.loadSnapshot(
            fileURL: fileURL(for: book),
            type: book.type,
            page: page,
            settings: readerSettings(for: book.id),
            maxPixel: 1200
        ) else { return false }

        let name = "\(book.id.uuidString).jpg"
        let target = coversURL.appendingPathComponent(name)
        do {
            try await Task.detached(priority: .utility) {
                try data.write(to: target, options: .atomic)
            }.value
            books[index].thumbnailFileName = name
            save()
            return true
        } catch {
            importError = "Cover could not be changed: \(error.localizedDescription)"
            return false
        }
    }

    func saveEditedMetadata(
        bookID: UUID,
        title: String,
        series: String,
        issue: String,
        year: String,
        publisher: String,
        creators: String,
        summary: String,
        writeComicInfo: Bool
    ) async -> String {
        guard let index = books.firstIndex(where: { $0.id == bookID }) else {
            return "Book not found."
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanTitle.isEmpty { books[index].title = cleanTitle }

        let creatorList = creators
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let previous = loadOfflineInfo(bookID: bookID)
        let info = OfflineComicInfo(
            analyzedAt: .now,
            displayTitle: cleanTitle.isEmpty ? books[index].title : cleanTitle,
            series: series.nilIfBlank,
            issue: issue.nilIfBlank,
            year: year.nilIfBlank,
            creators: creatorList,
            publisher: publisher.nilIfBlank,
            pageCount: books[index].pageCount,
            fileType: fileURL(for: books[index]).pathExtension.uppercased(),
            embeddedAuthor: previous?.embeddedAuthor,
            embeddedSubject: previous?.embeddedSubject,
            detectedText: previous?.detectedText ?? "",
            summary: summary.nilIfBlank ?? previous?.summary ?? "",
            confidenceNote: "Edited locally by the ComicPort user.",
            databaseMatch: previous?.databaseMatch,
            databaseConfidence: previous?.databaseConfidence,
            metadataAuthority: .verified,
            comicInfoPresent: writeComicInfo || previous?.comicInfoPresent == true,
            volume: previous?.volume,
            imprint: previous?.imprint,
            characters: previous?.characters,
            genres: previous?.genres,
            languageISO: previous?.languageISO,
            storyArc: previous?.storyArc,
            format: previous?.format
        )
        saveOfflineInfo(info, bookID: bookID)
        books[index].sourceIdentity = Self.sourceIdentity(
            title: books[index].title,
            type: books[index].type,
            pageCount: books[index].pageCount
        )
        save()

        guard writeComicInfo, books[index].type == .cbz, books[index].fileAvailable else {
            return "Metadata saved locally."
        }

        let source = fileURL(for: books[index])
        let temp = documentsURL
            .appendingPathComponent("ComicPortMetadata-\(UUID().uuidString).cbz")
        let xml = ComicRepairService.metadataXML(
            title: info.displayTitle,
            series: series,
            issue: issue,
            year: year,
            publisher: publisher,
            creators: creators,
            summary: info.summary,
            pageCount: books[index].pageCount
        )

        do {
            try await Task.detached(priority: .userInitiated) {
                try ComicRepairService.rewriteArchiveWithComicInfo(
                    source: source,
                    output: temp,
                    xml: xml
                )
            }.value

            let newName = "\(bookID.uuidString).cbz"
            let finalURL = booksURL.appendingPathComponent(newName)
            try? fm.removeItem(at: finalURL)
            try fm.moveItem(at: temp, to: finalURL)
            if source != finalURL { try? fm.removeItem(at: source) }
            books[index].storedFileName = newName
            books[index].type = .cbz
            CBZService.cleanTemporaryExtraction(for: source)
            save()
            return "Metadata saved and ComicInfo.xml written to a normalized CBZ."
        } catch {
            try? fm.removeItem(at: temp)
            return "Metadata saved locally, but ComicInfo.xml write-back failed: \(error.localizedDescription)"
        }
    }

    func createCleanCBZ(
        bookID: UUID,
        removeBlankPages: Bool,
        topCrop: Double,
        bottomCrop: Double
    ) async -> String {
        guard let book = books.first(where: { $0.id == bookID }),
              book.type == .pdf else { return "Select a PDF comic first." }
        let source = fileURL(for: book)
        let output = documentsURL.appendingPathComponent(
            "ComicPort-Clean-\(UUID().uuidString).cbz"
        )
        do {
            try await Task.detached(priority: .userInitiated) {
                try ComicRepairService.convertPDFToCBZ(
                    source: source,
                    output: output,
                    title: book.title,
                    removeBlankPages: removeBlankPages,
                    topCrop: topCrop,
                    bottomCrop: bottomCrop
                )
            }.value
            importFile(output)
            return "Clean CBZ created and queued for import. The original PDF was not changed."
        } catch {
            return "Cleaner failed: \(error.localizedDescription)"
        }
    }

    func repairArchive(bookID: UUID) async -> String {
        guard let book = books.first(where: { $0.id == bookID }),
              book.type == .cbz else { return "Select an archive comic first." }
        let source = fileURL(for: book)
        let output = documentsURL.appendingPathComponent(
            "ComicPort-Repaired-\(UUID().uuidString).cbz"
        )
        do {
            try await Task.detached(priority: .userInitiated) {
                try ComicRepairService.repairArchiveToCBZ(
                    source: source,
                    output: output,
                    title: book.title
                )
            }.value
            importFile(output)
            return "Repaired CBZ created with natural page order and queued for import. Original file was not changed."
        } catch {
            return "Repair failed: \(error.localizedDescription)"
        }
    }

    func exactDuplicateGroups() async -> [ComicPortDuplicateGroup] {
        let candidates = libraryBooks
            .filter(\.fileAvailable)
            .map { ($0.id, $0.title, fileURL(for: $0)) }

        return await Task.detached(priority: .utility) {
            var buckets: [String: [(UUID, String)]] = [:]
            for (id, title, url) in candidates {
                guard !Task.isCancelled,
                      let fingerprint = ComicPortFileFingerprint.sha256(url) else { continue }
                buckets[fingerprint, default: []].append((id, title))
            }
            return buckets.compactMap { fingerprint, values in
                guard values.count > 1 else { return nil }
                return ComicPortDuplicateGroup(
                    fingerprint: fingerprint,
                    bookIDs: values.map(\.0),
                    titles: values.map(\.1)
                )
            }
            .sorted { $0.titles.first ?? "" < $1.titles.first ?? "" }
        }.value
    }

    func storageBySeries() async -> [ComicPortSeriesStorage] {
        let items = libraryBooks.map { book in
            (book, fileURL(for: book))
        }
        return await Task.detached(priority: .utility) {
            var buckets: [String: (display: String, bytes: Int64, count: Int)] = [:]
            for (book, url) in items {
                let info = SeriesService.parse(book.title)
                let key = info.seriesTitle.lowercased()
                let bytes = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                var bucket = buckets[key] ?? (info.seriesTitle, 0, 0)
                bucket.bytes += bytes
                bucket.count += 1
                buckets[key] = bucket
            }
            return buckets.values.map {
                ComicPortSeriesStorage(
                    series: $0.display,
                    bytes: $0.bytes,
                    comicCount: $0.count
                )
            }
            .sorted { $0.bytes > $1.bytes }
        }.value
    }

    func backupHealthReport() -> ComicPortBackupHealth {
        ComicPortBackupHealth(
            libraryRecords: books.count,
            missingFiles: books.filter { !$0.fileAvailable }.count,
            readingSessions: analytics.history.count,
            pencilNotes: pencilAnnotationPageKeys.count,
            textNotes: textNotes.count,
            savedPanels: savedPanels.count,
            smartCollections: smartCollections.count
        )
    }
}

struct ComicPortReadingSessionSummary: Identifiable, Equatable, Sendable {
    let id = UUID()
    let bookID: UUID
    let title: String
    let pagesRead: Int
    let seconds: TimeInterval
}

struct ComicPortDuplicateGroup: Identifiable, Sendable {
    var id: String { fingerprint }
    let fingerprint: String
    let bookIDs: [UUID]
    let titles: [String]
}

struct ComicPortSeriesStorage: Identifiable, Sendable {
    var id: String { series.lowercased() }
    let series: String
    let bytes: Int64
    let comicCount: Int
}

struct ComicPortBackupHealth: Sendable {
    let libraryRecords: Int
    let missingFiles: Int
    let readingSessions: Int
    let pencilNotes: Int
    let textNotes: Int
    let savedPanels: Int
    let smartCollections: Int

    var isHealthy: Bool { libraryRecords > 0 && missingFiles == 0 }
}

private enum ComicPortFileFingerprint {
    static func sha256(_ url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            guard let data = try? handle.read(
                upToCount: 1024 * 1024
            ),
            !data.isEmpty else {
                break
            }
            hasher.update(data: data)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    var nilIfBlank: String? {
        let clean = trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? nil : clean
    }
}

// MARK: - Stage 18 Models

enum ComicPortSmartFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case any = "Any"
    case pdf = "PDF"
    case archive = "Archive"

    var id: String { rawValue }
}

struct ComicPortSmartRule: Codable, Hashable, Sendable {
    var titleContains: String = ""
    var minimumRating: Int = 0
    var statusRawValue: String = "Any"
    var favoritesOnly: Bool = false
    var format: ComicPortSmartFormat = .any
    var mangaOnly: Bool = false

    func matches(_ book: ComicBook) -> Bool {
        if !titleContains.isEmpty,
           !book.title.localizedCaseInsensitiveContains(
                titleContains
           ) {
            return false
        }

        if minimumRating > 0,
           book.rating < minimumRating {
            return false
        }

        if statusRawValue != "Any",
           book.readingStatus.rawValue != statusRawValue {
            return false
        }

        if favoritesOnly,
           !book.favorite {
            return false
        }

        switch format {
        case .any:
            break
        case .pdf:
            if book.type != .pdf { return false }
        case .archive:
            if book.type != .cbz { return false }
        }

        if mangaOnly,
           !book.rightToLeft {
            return false
        }

        return true
    }
}

struct ComicPortSmartCollection: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var rule: ComicPortSmartRule

    init(
        id: UUID = UUID(),
        name: String,
        rule: ComicPortSmartRule
    ) {
        self.id = id
        self.name = name
        self.rule = rule
    }
}

enum ComicPortBuiltInCollection: String, CaseIterable, Identifiable, Sendable {
    case unread = "Unread"
    case inProgress = "In Progress"
    case completed = "Completed"
    case favorites = "Favorites"
    case highlyRated = "4–5 Stars"
    case manga = "Manga / RTL"
    case recent = "Added in Last 30 Days"
    case longReads = "Long Reads"
    case pdf = "PDF"
    case archives = "Archives"
    case missing = "Missing Files"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .unread: return "circle"
        case .inProgress: return "book.pages"
        case .completed: return "checkmark.circle.fill"
        case .favorites: return "heart.fill"
        case .highlyRated: return "star.fill"
        case .manga: return "arrow.left"
        case .recent: return "calendar.badge.plus"
        case .longReads: return "books.vertical.fill"
        case .pdf: return "doc.richtext"
        case .archives: return "archivebox"
        case .missing: return "externaldrive.badge.exclamationmark"
        }
    }

    func books(from allBooks: [ComicBook]) -> [ComicBook] {
        let library = allBooks.filter {
            $0.isInLibrary && !$0.isArchived
        }

        let result: [ComicBook]
        switch self {
        case .unread:
            result = library.filter {
                $0.readingStatus == .toRead &&
                $0.currentPage == 0
            }
        case .inProgress:
            result = library.filter {
                $0.readingStatus == .reading
            }
        case .completed:
            result = library.filter {
                $0.readingStatus == .completed
            }
        case .favorites:
            result = library.filter(\.favorite)
        case .highlyRated:
            result = library.filter { $0.rating >= 4 }
        case .manga:
            result = library.filter(\.rightToLeft)
        case .recent:
            let cutoff = Calendar.current.date(
                byAdding: .day,
                value: -30,
                to: .now
            ) ?? .distantPast
            result = library.filter { $0.addedAt >= cutoff }
        case .longReads:
            result = library.filter { $0.pageCount >= 150 }
        case .pdf:
            result = library.filter { $0.type == .pdf }
        case .archives:
            result = library.filter { $0.type == .cbz }
        case .missing:
            result = allBooks.filter {
                !$0.fileAvailable
            }
        }

        return result.sorted {
            ($0.lastReadAt ?? $0.addedAt) >
            ($1.lastReadAt ?? $1.addedAt)
        }
    }
}

struct ComicPortSourceFolder: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var displayName: String
    var originalPath: String
    var bookmarkData: Data
    var seenFingerprints: [String]
    var lastScannedAt: Date?
    var lastFoundCount: Int
    var lastImportedCount: Int
    var lastError: String?

    init(
        id: UUID = UUID(),
        displayName: String,
        originalPath: String,
        bookmarkData: Data,
        seenFingerprints: [String] = [],
        lastScannedAt: Date? = nil,
        lastFoundCount: Int = 0,
        lastImportedCount: Int = 0,
        lastError: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.originalPath = originalPath
        self.bookmarkData = bookmarkData
        self.seenFingerprints = seenFingerprints
        self.lastScannedAt = lastScannedAt
        self.lastFoundCount = lastFoundCount
        self.lastImportedCount = lastImportedCount
        self.lastError = lastError
    }
}

private struct ComicPortSourceScanResult: Sendable {
    let newItems: [ComicPortSourceScanItem]
    let allFingerprints: [String]
    let totalSupportedFiles: Int
}

private struct ComicPortSourceScanItem: @unchecked Sendable {
    let url: URL
    let fingerprint: String
}

private enum ComicPortSourceScanner {
    static func scan(
        folder: URL,
        excludingFingerprints known: Set<String>
    ) -> ComicPortSourceScanResult {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey
        ]

        guard let enumerator = fm.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [
                .skipsHiddenFiles,
                .skipsPackageDescendants
            ]
        ) else {
            return ComicPortSourceScanResult(
                newItems: [],
                allFingerprints: [],
                totalSupportedFiles: 0
            )
        }

        var newItems: [ComicPortSourceScanItem] = []
        var all: [String] = []
        var total = 0

        for case let url as URL in enumerator {
            if Task.isCancelled { break }

            let ext = url.pathExtension.lowercased()
            guard ext == "pdf" ||
                    ComicArchiveFormat.supportedExtensions.contains(ext) else {
                continue
            }

            let values = try? url.resourceValues(
                forKeys: Set(keys)
            )
            guard values?.isRegularFile != false else {
                continue
            }

            total += 1

            let size = values?.fileSize ?? 0
            let modified =
                values?.contentModificationDate?
                    .timeIntervalSince1970 ?? 0

            let fingerprint = [
                url.standardizedFileURL.path,
                String(size),
                String(Int64(modified))
            ].joined(separator: "|")

            all.append(fingerprint)

            if !known.contains(fingerprint) {
                newItems.append(
                    ComicPortSourceScanItem(
                        url: url,
                        fingerprint: fingerprint
                    )
                )
            }
        }

        return ComicPortSourceScanResult(
            newItems: newItems,
            allFingerprints: all,
            totalSupportedFiles: total
        )
    }
}

struct ComicPortSyncLocation: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var displayName: String
    var originalPath: String
    var bookmarkData: Data

    init(
        id: UUID = UUID(),
        displayName: String,
        originalPath: String,
        bookmarkData: Data
    ) {
        self.id = id
        self.displayName = displayName
        self.originalPath = originalPath
        self.bookmarkData = bookmarkData
    }
}

private struct ComicPortSyncBookState: Codable, Hashable, Sendable {
    let sourceIdentity: String
    let title: String
    let currentPage: Int
    let pageCount: Int
    let readingStatus: ReadingStatus
    let favorite: Bool
    let rating: Int
    let lastReadAt: Date?
}

private struct ComicPortSyncHistoryState: Codable, Hashable, Sendable {
    let id: UUID
    let sourceIdentity: String
    let date: Date
    let startPage: Int
    let endPage: Int
    let pagesRead: Int
    let seconds: TimeInterval
}

private struct ComicPortSyncSnapshot: Codable, Hashable, Sendable {
    let schemaVersion: Int
    let generatedAt: Date
    let books: [ComicPortSyncBookState]
    let dailyGoalPages: Int
    let history: [ComicPortSyncHistoryState]

    init(
        schemaVersion: Int = 1,
        generatedAt: Date,
        books: [ComicPortSyncBookState],
        dailyGoalPages: Int,
        history: [ComicPortSyncHistoryState]
    ) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.books = books
        self.dailyGoalPages = dailyGoalPages
        self.history = history
    }
}


// A single synchronous serial writer is intentional: flush returns only after disk completion.
// Generations also protect against delayed callers submitting an older snapshot.
final class VersionedMetadataWriter: @unchecked Sendable {
    private let queue = DispatchQueue(label: "ComicPort.metadata")
    private var latest: UInt64 = 0
    func write(_ data: Data, to url: URL, generation: UInt64) throws {
        try queue.sync {
            guard generation > latest else { return }
            latest = generation
            try data.write(to: url, options: .atomic)
        }
    }
}

enum BackupSafety {
    static func error(_ message: String) -> NSError {
        NSError(domain: "ComicPort.Backup", code: 10, userInfo: [NSLocalizedDescriptionKey: message])
    }

    static func assetURL(_ name: String, in directory: URL) throws -> URL {
        guard !name.isEmpty, name != ".", name != "..",
              !name.contains("/"), !name.contains("\\"), !name.contains(":"),
              !name.unicodeScalars.contains(where: { $0.value == 0 }) else {
            throw error("Unsafe backup filename: \(name)")
        }
        let root = directory.standardizedFileURL.resolvingSymlinksInPath()
        let target = root.appendingPathComponent(name).standardizedFileURL.resolvingSymlinksInPath()
        guard target.deletingLastPathComponent() == root else {
            throw error("Backup asset escapes its storage directory.")
        }
        return target
    }

    static func validate(_ payload: PanelBackupPayload) throws {
        func require(_ value: Bool, _ message: String) throws {
            if !value { throw error("Invalid backup: \(message)") }
        }
        func unique<T: Hashable>(_ values: [T], _ label: String) throws {
            try require(Set(values).count == values.count, "duplicate \(label).")
        }
        try require((1...PanelBackupPayload.currentSchemaVersion).contains(payload.schemaVersion), "unsupported schema.")
        try unique(payload.books.map(\.id), "book IDs")
        try unique(payload.savedPanels.map(\.id), "panel IDs")
        try unique(payload.panelImages.map(\.panelID), "panel image IDs")
        try unique(payload.analytics.history.map(\.id), "history IDs")
        try unique(payload.bookInfoFiles.map(\.bookID), "book info IDs")
        let books = Dictionary(uniqueKeysWithValues: payload.books.map { ($0.id, $0) })
        let root = URL(fileURLWithPath: "/backup-validation", isDirectory: true)
        func page(_ id: UUID, _ page: Int) throws {
            guard let book = books[id], page >= 0, page < book.pageCount else {
                throw error("Invalid backup: unknown book or out-of-range page.")
            }
        }
        for book in payload.books {
            _ = try assetURL(book.storedFileName, in: root)
            if let name = book.thumbnailFileName { _ = try assetURL(name, in: root) }
            try require(book.pageCount > 0 && book.currentPage >= 0 && book.currentPage < book.pageCount, "invalid reading progress.")
            try require((0...5).contains(book.rating), "rating must be between 0 and 5.")
        }
        for panel in payload.savedPanels {
            try page(panel.bookID, panel.page)
            _ = try assetURL(panel.imageFileName, in: root)
        }
        try unique(payload.savedPanels.map(\.imageFileName), "panel filenames")
        let panelIDs = Set(payload.savedPanels.map(\.id))
        try require(Set(payload.panelImages.map(\.panelID)) == panelIDs, "missing or unreferenced panel images.")
        for note in payload.textNotes { try page(note.bookID, note.page) }
        for drawing in payload.pencilDrawings { try page(drawing.bookID, drawing.page) }
        for info in payload.bookInfoFiles { try require(books[info.bookID] != nil, "unknown book info reference.") }
        for arc in payload.storyArcs {
            try require(arc.bookIDs.allSatisfy { books[$0] != nil }, "unknown story arc book.")
        }
        for key in payload.readerSettingsByBook.keys {
            try require(UUID(uuidString: key).flatMap { books[$0] } != nil, "unknown reader settings book.")
        }
        for entry in payload.analytics.history {
            try page(entry.bookID, entry.startPage)
            try page(entry.bookID, entry.endPage)
            try require(entry.pagesRead >= 0 && entry.seconds.isFinite && entry.seconds >= 0, "invalid history values.")
        }
        try require(payload.analytics.dailyGoalPages > 0, "invalid reading goal.")
        for entry in payload.readingJournal ?? [] {
            try require(books[entry.bookID] != nil && (0...5).contains(entry.rating), "invalid journal reference or rating.")
            if let id = entry.favoritePanelID { try require(panelIDs.contains(id), "unknown favorite panel.") }
        }
    }
}
