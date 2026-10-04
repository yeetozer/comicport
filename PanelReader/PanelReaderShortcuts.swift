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
    static var title: LocalizedStringResource = "ComicPort'ta Okumaya Devam Et"
    static var description = IntentDescription("Son okuduğun çizgi romanı ComicPort'ta açar.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PanelShortcutBridge.setPending(.continueReading)
        return .result(dialog: "Son okuduğun çizgi roman açılıyor.")
    }
}

struct RandomComicIntent: AppIntent {
    static var title: LocalizedStringResource = "Rastgele Çizgi Roman Aç"
    static var description = IntentDescription("Cihazındaki kütüphaneden rastgele bir çizgi roman açar.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PanelShortcutBridge.setPending(.randomComic)
        return .result(dialog: "Kütüphanenden rastgele bir çizgi roman seçiyorum.")
    }
}

struct OpenSmartSearchIntent: AppIntent {
    static var title: LocalizedStringResource = "ComicPort Akıllı Arama"
    static var description = IntentDescription("ComicPort'un offline akıllı arama ekranını açar.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        PanelShortcutBridge.setPending(.smartSearch)
        return .result()
    }
}

struct OpenReadingJournalIntent: AppIntent {
    static var title: LocalizedStringResource = "Reading Journal'ı Aç"
    static var description = IntentDescription("ComicPort okuma günlüğünü açar.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        PanelShortcutBridge.setPending(.journal)
        return .result()
    }
}

struct ShowReadingGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Bugünkü Okuma Hedefimi Göster"
    static var description = IntentDescription("ComicPort'u açmadan bugünkü sayfa hedefini ve ilerlemeni gösterir.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let analytics = PanelShortcutData.analytics() else {
            return .result(dialog: "Henüz okunacak bir ComicPort istatistiği bulunamadı.")
        }

        let key = PanelDayKey.string(.now)
        let pages = analytics.daily[key]?.pages ?? 0
        let goal = max(1, analytics.dailyGoalPages)
        let remaining = max(0, goal - pages)

        if remaining == 0 {
            return .result(dialog: "Bugünkü hedefin tamamlandı: \(pages) / \(goal) sayfa.")
        }
        return .result(dialog: "Bugün \(pages) / \(goal) sayfa okudun. Hedefe \(remaining) sayfa kaldı.")
    }
}

struct PanelReaderAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ContinueReadingIntent(),
            phrases: ["\(.applicationName) ile okumaya devam et"],
            shortTitle: "Okumaya Devam",
            systemImageName: "book.pages.fill"
        )
        AppShortcut(
            intent: RandomComicIntent(),
            phrases: ["\(.applicationName) rastgele çizgi roman aç"],
            shortTitle: "Rastgele Çizgi Roman",
            systemImageName: "shuffle"
        )
        AppShortcut(
            intent: ShowReadingGoalIntent(),
            phrases: ["\(.applicationName) okuma hedefimi göster"],
            shortTitle: "Okuma Hedefim",
            systemImageName: "target"
        )
        AppShortcut(
            intent: OpenSmartSearchIntent(),
            phrases: ["\(.applicationName) akıllı aramayı aç"],
            shortTitle: "Akıllı Arama",
            systemImageName: "text.viewfinder"
        )
    }
}
