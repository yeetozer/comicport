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

    @MainActor func testLibraryDefaultsToTitleWhileRecentlyAddedStaysByDate() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root)
        let twelve = ComicBook(title: "Henry_Aldrich_012", storedFileName: "12.pdf", type: .pdf, pageCount: 10,
                               addedAt: Date(timeIntervalSince1970: 200))
        let five = ComicBook(title: "Henry_Aldrich_005", storedFileName: "5.pdf", type: .pdf, pageCount: 10,
                             addedAt: Date(timeIntervalSince1970: 100))
        try store.restoreBackupData(JSONEncoder().encode(payload(books: [twelve, five])))
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

    @MainActor func testRestartClearsCompleted() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(documentsURL: root)
        let book = ComicBook(title: "Restart", storedFileName: "restart.pdf", type: .pdf,
                             pageCount: 10, currentPage: 9, readingStatus: .completed)
        try store.restoreBackupData(JSONEncoder().encode(payload(books: [book])))
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
        _ = try first.restoreBackupData(JSONEncoder().encode(original))
        let theme = try XCTUnwrap(PanelAccentTheme.allCases.first)
        let backup = try await first.makeBackupData(accentTheme: theme)
        _ = try second.restoreBackupData(backup)
        XCTAssertEqual(second.textNotes.first?.text, "Remember")
        XCTAssertEqual(second.savedPanels.first?.id, panel.id)
        XCTAssertEqual(second.analytics.history.first?.id, history.id)
        XCTAssertNotNil(second.readerSettingsByBook[book.id.uuidString])
        XCTAssertTrue(second.autoOpenNextIssue)
        XCTAssertEqual(try Data(contentsOf: second.panelsURL.appendingPathComponent("panel.jpg")), Data([3, 4]))
    }

}
