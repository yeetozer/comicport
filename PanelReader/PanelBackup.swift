import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct BackupPencilDrawing: Codable, Sendable {
    let bookID: UUID
    let page: Int
    let data: Data
}

struct BackupPanelImage: Codable, Sendable {
    let panelID: UUID
    let data: Data
}

struct BackupBookInfo: Codable, Sendable {
    let bookID: UUID
    let data: Data
}

struct PanelBackupPayload: Codable {
    static let currentSchemaVersion = 3

    let schemaVersion: Int
    let createdAt: Date
    let appVersion: String

    var books: [ComicBook]
    var analytics: ReadingAnalytics
    let achievementProfile: AchievementProfile
    var readerSettingsByBook: [String: ReaderSettings]
    let defaultReaderSettings: ReaderSettings
    var storyArcs: [StoryArc]
    let autoOpenNextIssue: Bool
    var textNotes: [PageTextNote]
    var savedPanels: [SavedPanel]
    var readingJournal: [ReadingJournalEntry]?

    // Schema 3. Optional so schema 1/2 backup files still decode.
    let smartCollections: [ComicPortSmartCollection]?

    var pencilDrawings: [BackupPencilDrawing]
    var panelImages: [BackupPanelImage]
    var bookInfoFiles: [BackupBookInfo]

    let accentThemeRawValue: String
}

struct PanelBackupRestoreResult {
    let skippedItems: [String]
    let accentTheme: PanelAccentTheme?
    let importedBooks: Int
    let historyEntries: Int
    let notes: Int
    let panels: Int
}

struct PanelBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
