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
    static let currentSchemaVersion = 4

    let schemaVersion: Int
    let createdAt: Date
    let appVersion: String

    let books: [ComicBook]
    let analytics: ReadingAnalytics
    let achievementProfile: AchievementProfile
    let readerSettingsByBook: [String: ReaderSettings]
    let defaultReaderSettings: ReaderSettings
    let storyArcs: [StoryArc]
    let autoOpenNextIssue: Bool
    let textNotes: [PageTextNote]
    let savedPanels: [SavedPanel]
    let readingJournal: [ReadingJournalEntry]?

    // Schema 3. Optional so schema 1/2 backup files still decode.
    let smartCollections: [ComicPortSmartCollection]?
    let bookHub: BookHubState?

    let pencilDrawings: [BackupPencilDrawing]
    let panelImages: [BackupPanelImage]
    let bookInfoFiles: [BackupBookInfo]

    let accentThemeRawValue: String
}

struct PanelBackupRestoreResult {
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
