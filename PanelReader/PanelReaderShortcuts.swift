import Foundation
import AppIntents

enum PanelQuickAction: String, Sendable {
    case continueReading = "continue"
    case randomComic = "random"
    case smartSearch = "search"
    case journal = "journal"
    case readingGoal = "goal"
    case importComics = "import"
    case library = "library"
    case home = "home"
    case smartCollections = "collections"
    case sourcesSync = "sources"
    case settings = "settings"
    case commandPalette = "palette"

    init?(url: URL) {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "comicport" || scheme == "panelreader" else { return nil }
        let raw: String?
        if let host = url.host, !host.isEmpty {
            raw = host.lowercased()
        } else {
            raw = url.pathComponents.dropFirst().first?.lowercased()
        }
        guard let raw else { return nil }
        self.init(rawValue: raw)
    }
}

enum PanelShortcutBridge {
    private static let key = "PanelReader.pendingQuickAction"

    static func setPending(_ action: PanelQuickAction) {
        UserDefaults.standard.set(action.rawValue, forKey: key)
    }

    static func consumePending() -> PanelQuickAction? {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let action = PanelQuickAction(rawValue: raw) else { return nil }
        UserDefaults.standard.removeObject(forKey: key)
        return action
    }
}

private enum PanelShortcutData {
    static func analytics() -> ReadingAnalytics? {
        let fm = FileManager.default
        guard let documents = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let url = documents.appendingPathComponent("analytics.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ReadingAnalytics.self, from: data)
    }
}

struct ContinueReadingIntent: AppIntent {
    static var title: LocalizedStringResource = "Continue Reading in ComicPort"
    static var description = IntentDescription("Opens your most recently read comic in ComicPort.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PanelShortcutBridge.setPending(.continueReading)
        return .result(dialog: "Opening your most recently read comic.")
    }
}

struct RandomComicIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Random Comic"
    static var description = IntentDescription("Opens a random comic from the library on this device.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PanelShortcutBridge.setPending(.randomComic)
        return .result(dialog: "Choosing a random comic from your library.")
    }
}

struct OpenSmartSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "ComicPort Smart Search"
    static var description = IntentDescription("Opens ComicPort’s offline smart search.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        PanelShortcutBridge.setPending(.smartSearch)
        return .result()
    }
}

struct OpenReadingJournalIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Reading Journal"
    static var description = IntentDescription("Opens your ComicPort reading journal.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        PanelShortcutBridge.setPending(.journal)
        return .result()
    }
}

struct ShowReadingGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Today’s Reading Goal"
    static var description = IntentDescription("Shows today’s page goal and progress without opening ComicPort.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let analytics = PanelShortcutData.analytics() else {
            return .result(dialog: "No ComicPort reading statistics yet.")
        }

        let key = PanelDayKey.string(.now)
        let pages = analytics.daily[key]?.pages ?? 0
        let goal = max(1, analytics.dailyGoalPages)
        let remaining = max(0, goal - pages)

        if remaining == 0 {
            return .result(dialog: "Today’s goal is complete: \(pages) of \(goal) pages.")
        }
        return .result(dialog: "You read \(pages) of \(goal) pages today. \(remaining) pages to go.")
    }
}

struct PanelReaderAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ContinueReadingIntent(),
            phrases: ["Continue reading in \(.applicationName)"],
            shortTitle: "Continue Reading",
            systemImageName: "book.pages.fill"
        )
        AppShortcut(
            intent: RandomComicIntent(),
            phrases: ["Open a random comic in \(.applicationName)"],
            shortTitle: "Random Comic",
            systemImageName: "shuffle"
        )
        AppShortcut(
            intent: ShowReadingGoalIntent(),
            phrases: ["Show my reading goal in \(.applicationName)"],
            shortTitle: "My Reading Goal",
            systemImageName: "target"
        )
        AppShortcut(
            intent: OpenSmartSearchIntent(),
            phrases: ["Open smart search in \(.applicationName)"],
            shortTitle: "Smart Search",
            systemImageName: "text.viewfinder"
        )
    }
}
