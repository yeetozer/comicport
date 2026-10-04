import Foundation

struct LibraryBootstrapPaths: Sendable {
    let documents: URL
    let books: URL
    let covers: URL
    let notes: URL
    let info: URL
    let panels: URL
    let search: URL
    let guided: URL

    let metadata: URL
    let analytics: URL
    let achievements: URL
    let readerSettings: URL
    let defaultReaderSettings: URL
    let storyArcs: URL
    let textNotes: URL
    let savedPanels: URL
    let readingJournal: URL
}

final class LibraryBootstrapResult: @unchecked Sendable {
    var books: [ComicBook] = []
    var analytics = ReadingAnalytics()
    var achievementProfile = AchievementProfile()
    var readerSettingsByBook: [String: ReaderSettings] = [:]
    var defaultReaderSettings = ReaderSettings()
    var storyArcs: [StoryArc] = []
    var textNotes: [PageTextNote] = []
    var savedPanels: [SavedPanel] = []
    var readingJournal: [ReadingJournalEntry] = []
    var pencilAnnotationPageKeys: Set<String> = []
    var smartSearchKnownIndexIDs: Set<UUID> = []
    var libraryMetadataChanged = false
}

enum LibraryBootstrapLoader {
    static func load(paths: LibraryBootstrapPaths) -> LibraryBootstrapResult {
        let fm = FileManager.default
        let result = LibraryBootstrapResult()

        // Directory creation and all startup disk I/O happen away from the UI thread.
        for directory in [
            paths.books, paths.covers, paths.notes, paths.info,
            paths.panels, paths.search, paths.guided
        ] {
            try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        result.books = decode([ComicBook].self, from: paths.metadata) ?? []
        result.analytics = decode(ReadingAnalytics.self, from: paths.analytics) ?? ReadingAnalytics()
        result.achievementProfile = decode(AchievementProfile.self, from: paths.achievements) ?? AchievementProfile()
        result.readerSettingsByBook = decode([String: ReaderSettings].self, from: paths.readerSettings) ?? [:]
        result.defaultReaderSettings = decode(ReaderSettings.self, from: paths.defaultReaderSettings) ?? ReaderSettings()
        result.storyArcs = decode([StoryArc].self, from: paths.storyArcs) ?? []
        result.textNotes = decode([PageTextNote].self, from: paths.textNotes) ?? []
        result.readingJournal = decode([ReadingJournalEntry].self, from: paths.readingJournal) ?? []

        let panelMetadata = decode([SavedPanel].self, from: paths.savedPanels) ?? []
        result.savedPanels = panelMetadata.filter {
            fm.fileExists(atPath: paths.panels.appendingPathComponent($0.imageFileName).path)
        }

        if let noteFiles = try? fm.contentsOfDirectory(
            at: paths.notes,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            result.pencilAnnotationPageKeys = Set(
                noteFiles.compactMap { url in
                    guard url.pathExtension == "drawing" else { return nil }
                    return url.deletingPathExtension().lastPathComponent
                }
            )
        }

        if let searchFiles = try? fm.contentsOfDirectory(
            at: paths.search,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            result.smartSearchKnownIndexIDs = Set(
                searchFiles.compactMap { url in
                    guard url.pathExtension.lowercased() == "json" else { return nil }
                    return UUID(uuidString: url.deletingPathExtension().lastPathComponent)
                }
            )
        }

        // File availability repair used to synchronously stat every book in LibraryStore.init().
        // It is still done at launch, but now on this background bootstrap worker.
        for index in result.books.indices {
            if result.books[index].sourceIdentity.isEmpty {
                result.books[index].sourceIdentity = sourceIdentity(
                    title: result.books[index].title,
                    type: result.books[index].type,
                    pageCount: result.books[index].pageCount
                )
                result.libraryMetadataChanged = true
            }

            let fileURL = paths.books.appendingPathComponent(result.books[index].storedFileName)
            let exists = fm.fileExists(atPath: fileURL.path)
            if result.books[index].fileAvailable && !exists {
                result.books[index].fileAvailable = false
                result.books[index].isInLibrary = false
                result.libraryMetadataChanged = true
            } else if !result.books[index].fileAvailable && exists {
                result.books[index].fileAvailable = true
                result.libraryMetadataChanged = true
            }
        }

        return result
    }

    private static func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func sourceIdentity(title: String, type: ComicType, pageCount: Int) -> String {
        let normalized = title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "\(normalized)|\(type.rawValue)|\(pageCount)"
    }
}
