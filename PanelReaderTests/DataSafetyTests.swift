import XCTest
@testable import PanelReader

final class DataSafetyTests: XCTestCase {
    func payload(books: [ComicBook] = [], panels: [SavedPanel] = [], images: [BackupPanelImage] = []) -> PanelBackupPayload {
        PanelBackupPayload(schemaVersion: 3, createdAt: .now, appVersion: "tests", books: books,
            analytics: ReadingAnalytics(), achievementProfile: AchievementProfile(), readerSettingsByBook: [:],
            defaultReaderSettings: ReaderSettings(), storyArcs: [], autoOpenNextIssue: false, textNotes: [],
            savedPanels: panels, readingJournal: [], smartCollections: [], pencilDrawings: [], panelImages: images,
            bookInfoFiles: [], accentThemeRawValue: "")
    }

    func testNaturalTitleOrderUsesCleanedDisplayTitles() {
        let books = ["Henry_Aldrich_012", "Henry Aldrich #5", "Henry_Aldrich_001", "Series 12", "Series 5"]
            .map { ComicBook(title: $0, storedFileName: "sample.pdf", type: .pdf, pageCount: 10) }
        XCTAssertEqual(books.sorted(by: SeriesService.titleOrder).map(\.displayTitle),
                       ["Henry Aldrich #1", "Henry Aldrich #5", "Henry Aldrich #12", "Series #5", "Series #12"])
        let series = SeriesService.series(from: Array(books.prefix(3)))
        XCTAssertEqual(SeriesService.books(in: series[0], from: books).map(\.displayTitle),
                       ["Henry Aldrich #1", "Henry Aldrich #5", "Henry Aldrich #12"])
    }

    @MainActor func testLibraryDefaultsToTitleWhileRecentlyAddedStaysByDate() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root)
        let twelve = ComicBook(title: "Henry_Aldrich_012", storedFileName: "12.pdf", type: .pdf, pageCount: 10,
                               addedAt: Date(timeIntervalSince1970: 200))
        let five = ComicBook(title: "Henry_Aldrich_005", storedFileName: "5.pdf", type: .pdf, pageCount: 10,
                             addedAt: Date(timeIntervalSince1970: 100))
        try FileManager.default.createDirectory(at: store.booksURL, withIntermediateDirectories: true)
        for book in [twelve, five] {
            try Data().write(to: store.booksURL.appendingPathComponent(book.storedFileName))
        }
        try await store.restoreBackupData(JSONEncoder().encode(payload(books: [twelve, five])))
        XCTAssertEqual(store.libraryBooks.map(\.id), [five.id, twelve.id])
        XCTAssertEqual(store.recentlyAdded.map(\.id), [twelve.id, five.id])
    }

    func testDuplicatePanelImagesThrowInsteadOfTrap() {
        let id = UUID()
        XCTAssertThrowsError(try BackupSafety.validate(payload(images: [
            BackupPanelImage(panelID: id, data: Data()), BackupPanelImage(panelID: id, data: Data())])))
    }

    func testUnsafeFilenamesRejected() {
        for name in ["../escape", "/absolute", "a/b", "a\\b", "..", "", "file:asset"] {
            XCTAssertThrowsError(try BackupSafety.assetURL(name, in: URL(fileURLWithPath: NSTemporaryDirectory())))
        }
    }

    func testOutOfRangeValuesRejected() {
        for book in [ComicBook(title: "Bad", storedFileName: "a.pdf", type: .pdf, pageCount: 2, currentPage: -1),
                     ComicBook(title: "Bad", storedFileName: "a.pdf", type: .pdf, pageCount: 2, currentPage: 2),
                     ComicBook(title: "Bad", storedFileName: "a.pdf", type: .pdf, pageCount: 2, rating: 6)] {
            XCTAssertThrowsError(try BackupSafety.validate(payload(books: [book])))
        }
    }

    func testStaleWriteCannotOverwriteNewerGeneration() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = VersionedMetadataWriter()
        try writer.write(Data("new".utf8), to: url, generation: 2)
        try writer.write(Data("old".utf8), to: url, generation: 1)
        XCTAssertEqual(try Data(contentsOf: url), Data("new".utf8))
    }

    @MainActor func testRestartClearsCompleted() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root)
        let book = ComicBook(title: "Restart", storedFileName: "restart.pdf", type: .pdf,
                             pageCount: 10, currentPage: 9, readingStatus: .completed)
        try await store.restoreBackupData(JSONEncoder().encode(payload(books: [book])))
        store.restartComic(id: book.id)
        XCTAssertEqual(store.books.first { $0.id == book.id }?.currentPage, 0)
        XCTAssertEqual(store.books.first { $0.id == book.id }?.readingStatus, .toRead)
    }
    @MainActor func testBackupRestoreRoundTrip() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = LibraryStore(documentsURL: root.appendingPathComponent("first"))
        let second = LibraryStore(documentsURL: root.appendingPathComponent("second"))
        let book = ComicBook(title: "Round trip", storedFileName: "round.pdf", type: .pdf, pageCount: 10)
        let panel = SavedPanel(id: UUID(), bookID: book.id, page: 2, imageFileName: "panel.jpg", createdAt: .now)
        let history = ReadingHistoryEntry(bookID: book.id, startPage: 0, endPage: 2, pagesRead: 2, seconds: 3)
        var analytics = ReadingAnalytics()
        analytics.history = [history]
        let original = PanelBackupPayload(schemaVersion: 3, createdAt: .now, appVersion: "test", books: [book],
            analytics: analytics, achievementProfile: AchievementProfile(), readerSettingsByBook: [book.id.uuidString: ReaderSettings()],
            defaultReaderSettings: ReaderSettings(), storyArcs: [], autoOpenNextIssue: true,
            textNotes: [PageTextNote(id: UUID(), bookID: book.id, page: 1, text: "Remember", updatedAt: .now)],
            savedPanels: [panel], readingJournal: [], smartCollections: [],
            pencilDrawings: [BackupPencilDrawing(bookID: book.id, page: 1, data: Data([1, 2]))],
            panelImages: [BackupPanelImage(panelID: panel.id, data: Data([3, 4]))], bookInfoFiles: [], accentThemeRawValue: "")
        _ = try await first.restoreBackupData(JSONEncoder().encode(original))
        let theme = try XCTUnwrap(PanelAccentTheme.allCases.first)
        let backup = try await first.makeBackupData(accentTheme: theme)
        _ = try await second.restoreBackupData(backup)
        XCTAssertEqual(second.textNotes.first?.text, "Remember")
        XCTAssertEqual(second.savedPanels.first?.id, panel.id)
        XCTAssertEqual(second.analytics.history.first?.id, history.id)
        XCTAssertNotNil(second.readerSettingsByBook[book.id.uuidString])
        XCTAssertTrue(second.autoOpenNextIssue)
        XCTAssertEqual(try Data(contentsOf: second.panelsURL.appendingPathComponent("panel.jpg")), Data([3, 4]))
    }
    private struct BackgroundOnlySnapshot: Encodable, Sendable {
        func encode(to encoder: Encoder) throws {
            if Thread.isMainThread { throw NSError(domain: "Tests.EncodedOnMain", code: 1) }
            var container = encoder.singleValueContainer()
            try container.encode("background")
        }
    }

    @MainActor func testEncodingRunsOffMainAndFlushAwaitsCompletion() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = VersionedMetadataWriter()
        writer.enqueue(BackgroundOnlySnapshot(), to: url, generation: 1)
        try await writer.flush()
        XCTAssertEqual(try JSONDecoder().decode(String.self, from: Data(contentsOf: url)), "background")
    }

    func testBackgroundWriterFlushAndStaleGeneration() async throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = VersionedMetadataWriter()
        writer.enqueue(["new"], to: url, generation: 2)
        writer.enqueue(["old"], to: url, generation: 1)
        try await writer.flush()
        XCTAssertEqual(try JSONDecoder().decode([String].self, from: Data(contentsOf: url)), ["new"])
    }

    func testFailuresArePerDestinationAndFailedGenerationCanRetry() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let bad = root.appendingPathComponent("missing/file.json")
        let good = root.appendingPathComponent("good.json")
        let writer = VersionedMetadataWriter()
        writer.enqueue([1], to: bad, generation: 1)
        writer.enqueue([2], to: good, generation: 2)
        do { try await writer.flush(); XCTFail("Another file must not clear the failure") } catch {}
        try FileManager.default.createDirectory(at: bad.deletingLastPathComponent(), withIntermediateDirectories: true)
        writer.enqueue([3], to: bad, generation: 1)
        try await writer.flush()
        XCTAssertEqual(try JSONDecoder().decode([Int].self, from: Data(contentsOf: bad)), [3])
    }

    @MainActor func testDeletedBookAndFavoritePanelRoundTrip() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root.appendingPathComponent("source"))
        let deleted = ComicBook(title: "Delete", storedFileName: "delete.pdf", type: .pdf, pageCount: 10)
        let retained = ComicBook(title: "Keep", storedFileName: "keep.pdf", type: .pdf, pageCount: 10)
        let panel = SavedPanel(id: UUID(), bookID: retained.id, page: 1, imageFileName: "favorite.jpg")
        var original = payload(books: [deleted, retained], panels: [panel], images: [BackupPanelImage(panelID: panel.id, data: Data([1]))])
        original.storyArcs = [StoryArc(name: "Arc", bookIDs: [deleted.id, retained.id])]
        original.readingJournal = [ReadingJournalEntry(bookID: retained.id, favoritePanelID: panel.id)]
        _ = try await store.restoreBackupData(JSONEncoder().encode(original))
        store.permanentlyDelete(deleted)
        store.deletePanel(panel)
        XCTAssertEqual(store.storyArcs.first?.bookIDs, [retained.id])
        XCTAssertNil(store.readingJournalEntries.first?.favoritePanelID)
        let data = try await store.makeBackupData(accentTheme: XCTUnwrap(PanelAccentTheme.allCases.first))
        let target = LibraryStore(documentsURL: root.appendingPathComponent("target"))
        let result = try await target.restoreBackupData(data)
        XCTAssertTrue(result.skippedItems.isEmpty)
        XCTAssertEqual(target.storyArcs.first?.bookIDs, [retained.id])
        XCTAssertNil(target.readingJournalEntries.first?.favoritePanelID)
    }

    @MainActor func testLegacyMissingImageAndDanglingReferencesAreReported() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root)
        let book = ComicBook(title: "Legacy", storedFileName: "legacy.pdf", type: .pdf, pageCount: 10)
        let panel = SavedPanel(id: UUID(), bookID: book.id, page: 1, imageFileName: "missing.jpg")
        var legacy = payload(books: [book], panels: [panel])
        legacy.storyArcs = [StoryArc(name: "Old arc", bookIDs: [book.id, UUID()])]
        legacy.readingJournal = [ReadingJournalEntry(bookID: book.id, favoritePanelID: UUID())]
        let report = try await store.restoreBackupData(JSONEncoder().encode(legacy))
        XCTAssertEqual(report.skippedItems.count, 3)
        XCTAssertEqual(store.savedPanels.first?.id, panel.id)
        XCTAssertEqual(store.storyArcs.first?.bookIDs, [book.id])
        XCTAssertNil(store.readingJournalEntries.first?.favoritePanelID)
        // Metadata retained without an image must itself remain exportable.
        _ = try await store.makeBackupData(accentTheme: XCTUnwrap(PanelAccentTheme.allCases.first))
    }

    @MainActor func testBackupRefusesUnsavedPanelDestinationAfterLibrarySuccess() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root)
        _ = try await store.restoreBackupData(JSONEncoder().encode(payload()))
        let destination = root.appendingPathComponent("saved_panels.json")
        try FileManager.default.removeItem(at: destination)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
        store.deletePanel(SavedPanel(bookID: UUID(), page: 0, imageFileName: "absent.jpg"))
        do {
            _ = try await store.makeBackupData(accentTheme: XCTUnwrap(PanelAccentTheme.allCases.first))
            XCTFail("Library success must not hide the panel metadata failure")
        } catch {}
    }

    @MainActor func testUnsafeAndDuplicateBackupRestoreThrows() async throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root)
        let book = ComicBook(title: "Book", storedFileName: "book.pdf", type: .pdf, pageCount: 10)
        let unsafe = ComicBook(title: "Unsafe", storedFileName: "../escape.pdf", type: .pdf, pageCount: 10)
        for invalid in [payload(books: [unsafe]), payload(books: [book, book])] {
            do { _ = try await store.restoreBackupData(JSONEncoder().encode(invalid)); XCTFail("Unsafe backup accepted") }
            catch {}
        }
        XCTAssertTrue(store.books.isEmpty)
    }

}
