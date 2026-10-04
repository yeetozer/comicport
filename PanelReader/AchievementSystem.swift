import Foundation
import SwiftUI

enum AchievementTier: String, Codable, CaseIterable, Identifiable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case legendary = "Legendary"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .bronze: return "medal"
        case .silver: return "medal.fill"
        case .gold: return "trophy"
        case .platinum: return "trophy.fill"
        case .legendary: return "sparkles"
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case reading = "Reading"
    case time = "Time"
    case streak = "Streak"
    case goals = "Goals"
    case collection = "Collection"
    case omnibus = "Omnibus"
    case character = "Characters"
    case team = "Teams"
    case special = "Special"
    case hidden = "Hidden"

    var id: String { rawValue }
}

enum AchievementMetric: Codable, Hashable {
    case totalPages
    case totalSeconds
    case completedBooks
    case libraryBooks
    case favorites
    case ratedBooks
    case currentStreak
    case goalDays
    case maxDayPages
    case omnibusCompleted
    case characterCompleted(String)
    case teamCompleted(String)
    case maxCompletedInSeries
    case completedStoryArcs
    case annotatedPages
    case savedPanels
}

struct AchievementDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let category: AchievementCategory
    let tier: AchievementTier
    let xp: Int
    let target: Double
    let metric: AchievementMetric
    let hidden: Bool
}

struct AchievementProfile: Codable, Sendable {
    var unlockedIDs: Set<String> = []
    var unlockedAt: [String: Date] = [:]
    var hasBootstrapped: Bool = false
}

struct AchievementSnapshot {
    let totalPages: Int
    let totalSeconds: TimeInterval
    let completedBooks: Int
    let libraryBooks: Int
    let favorites: Int
    let ratedBooks: Int
    let currentStreak: Int
    let goalDays: Int
    let maxDayPages: Int
    let omnibusCompleted: Int
    let characterCompleted: [String: Int]
    let teamCompleted: [String: Int]
    let maxCompletedInSeries: Int
    let completedStoryArcs: Int
    let annotatedPages: Int
    let savedPanels: Int

    func value(for metric: AchievementMetric) -> Double {
        switch metric {
        case .totalPages: return Double(totalPages)
        case .totalSeconds: return totalSeconds
        case .completedBooks: return Double(completedBooks)
        case .libraryBooks: return Double(libraryBooks)
        case .favorites: return Double(favorites)
        case .ratedBooks: return Double(ratedBooks)
        case .currentStreak: return Double(currentStreak)
        case .goalDays: return Double(goalDays)
        case .maxDayPages: return Double(maxDayPages)
        case .omnibusCompleted: return Double(omnibusCompleted)
        case .characterCompleted(let name): return Double(characterCompleted[name, default: 0])
        case .teamCompleted(let name): return Double(teamCompleted[name, default: 0])
        case .maxCompletedInSeries: return Double(maxCompletedInSeries)
        case .completedStoryArcs: return Double(completedStoryArcs)
        case .annotatedPages: return Double(annotatedPages)
        case .savedPanels: return Double(savedPanels)
        }
    }
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = {
        var items: [AchievementDefinition] = []

        func addSeries(prefix: String, titles: [String], details: [String], category: AchievementCategory, metric: AchievementMetric, targets: [Double], xps: [Int]) {
            let tiers: [AchievementTier] = [.bronze, .silver, .gold, .platinum, .legendary]
            for i in targets.indices {
                items.append(AchievementDefinition(
                    id: "\(prefix).\(i+1)",
                    title: titles[min(i, titles.count - 1)],
                    detail: details[min(i, details.count - 1)],
                    category: category,
                    tier: tiers[min(i, tiers.count - 1)],
                    xp: xps[min(i, xps.count - 1)],
                    target: targets[i],
                    metric: metric,
                    hidden: false
                ))
            }
        }

        addSeries(prefix: "pages", titles: ["First Pages", "Page Hunter", "Page Master", "Page Legend", "Ink Never Ends"], details: ["Read 100 pages.", "Read 1,000 pages.", "Read 5,000 pages.", "Read 10,000 pages.", "Read 50,000 pages."], category: .reading, metric: .totalPages, targets: [100,1000,5000,10000,50000], xps: [50,150,300,500,1500])
        addSeries(prefix: "time", titles: ["First Hour", "Bookworm", "Long Reader", "Veteran Reader", "Time Traveler"], details: ["Read for 1 hour.", "Read for 10 hours.", "Read for 50 hours.", "Read for 100 hours.", "Read for 500 hours."], category: .time, metric: .totalSeconds, targets: [3600,36000,180000,360000,1800000], xps: [50,150,350,700,1800])
        addSeries(prefix: "completed", titles: ["The Beginning", "Shelf Finisher", "Collection Reader", "Century Club", "Library Legend"], details: ["Finish your first comic.", "Finish 10 comics.", "Finish 25 comics.", "Finish 100 comics.", "Finish 500 comics."], category: .reading, metric: .completedBooks, targets: [1,10,25,100,500], xps: [100,200,350,900,2500])
        addSeries(prefix: "library", titles: ["Small Library", "Shelves Filling Up", "Collector", "Archivist", "Librarian"], details: ["Keep 10 comics in your library.", "Keep 25 comics in your library.", "Keep 50 comics in your library.", "Keep 250 comics in your library.", "Keep 1,000 comics in your library."], category: .collection, metric: .libraryBooks, targets: [10,25,50,250,1000], xps: [75,125,250,700,2000])
        addSeries(prefix: "favorite", titles: ["First Favorite", "Taste Maker", "Curator", "Golden Shelf", "Heart of the Library"], details: ["Favorite 1 comic.", "Favorite 10 comics.", "Favorite 25 comics.", "Favorite 50 comics.", "Favorite 100 comics."], category: .collection, metric: .favorites, targets: [1,10,25,50,100], xps: [50,100,200,400,800])
        addSeries(prefix: "ratings", titles: ["First Review", "Critic", "Seasoned Critic", "Panel Judge", "Master Critic"], details: ["Rate 1 comic.", "Rate 10 comics.", "Rate 25 comics.", "Rate 100 comics.", "Rate 250 comics."], category: .collection, metric: .ratedBooks, targets: [1,10,25,100,250], xps: [50,100,200,500,1000])
        addSeries(prefix: "streak", titles: ["Three Days", "Serial Reader", "Two Weeks", "One Month", "Unstoppable"], details: ["Read 3 days in a row.", "Read 7 days in a row.", "Read 14 days in a row.", "Read 30 days in a row.", "Read 100 days in a row."], category: .streak, metric: .currentStreak, targets: [3,7,14,30,100], xps: [75,150,300,600,1800])
        addSeries(prefix: "goals", titles: ["On Target", "Hat Trick", "Perfect Week", "Goal Machine", "Perfect Month"], details: ["Complete your reading goal once.", "Complete it 3 days.", "Complete it 7 days.", "Complete it 20 days.", "Complete it 30 days."], category: .goals, metric: .goalDays, targets: [1,3,7,20,30], xps: [50,100,200,450,800])
        addSeries(prefix: "daypages", titles: ["Hundred Page Day", "Marathon", "Heavy Reading", "Ultra Marathon", "Impossible Day"], details: ["Read 100 pages in one day.", "Read 250 pages in one day.", "Read 500 pages in one day.", "Read 750 pages in one day.", "Read 1,000 pages in one day."], category: .special, metric: .maxDayPages, targets: [100,250,500,750,1000], xps: [100,250,600,1000,1800])
        addSeries(prefix: "omnibus", titles: ["Omnibus Finisher", "Brick Slayer", "Omnibus Hunter", "Shelf Breaker", "Omnibus Legend"], details: ["Finish 1 500+ page comic.", "Finish 5 500+ page comics.", "Finish 10 500+ page comics.", "Finish 25 500+ page comics.", "Finish 50 500+ page comics."], category: .omnibus, metric: .omnibusCompleted, targets: [1,5,10,25,50], xps: [150,350,650,1200,2400])
        addSeries(prefix: "series", titles: ["Series Starter", "Series Regular", "Series Expert", "Series Master", "Series Legend"], details: ["Finish 3 comics from one series.", "Finish 10 comics from one series.", "Finish 25 comics from one series.", "Finish 50 comics from one series.", "Finish 100 comics from one series."], category: .collection, metric: .maxCompletedInSeries, targets: [3,10,25,50,100], xps: [100,250,500,900,1800])
        addSeries(prefix: "notes", titles: ["First Note", "Margin Thinker", "Annotation Habit", "Research Desk", "Master Annotator"], details: ["Annotate 1 page.", "Annotate 10 pages.", "Annotate 25 pages.", "Annotate 100 pages.", "Annotate 250 pages."], category: .collection, metric: .annotatedPages, targets: [1,10,25,100,250], xps: [50,125,250,600,1200])
        addSeries(prefix: "panels", titles: ["First Panel", "Panel Collector", "Gallery Builder", "Panel Curator", "Panel Archivist"], details: ["Save 1 favorite panel.", "Save 10 favorite panels.", "Save 25 favorite panels.", "Save 50 favorite panels.", "Save 100 favorite panels."], category: .collection, metric: .savedPanels, targets: [1,10,25,50,100], xps: [50,150,300,600,1200])

        let characters: [(String, String)] = [
            ("Batman", "Gotham Reader"), ("Nightwing", "Flying Grayson"), ("Superman", "Man of Tomorrow"),
            ("Wonder Woman", "Amazon Reader"), ("Flash", "Speed Force"), ("Green Lantern", "No Fear"),
            ("Aquaman", "King of Atlantis"), ("Harley Quinn", "Chaos Reader"), ("Joker", "Agent of Chaos"),
            ("Robin", "Boy Wonder"), ("Spider-Man", "Friendly Neighborhood Reader"), ("Daredevil", "Man Without Fear"),
            ("Wolverine", "The Best There Is"), ("Thor", "Worthy"), ("Hulk", "Smash Reader"),
            ("Iron Man", "Armored Reader"), ("Captain America", "First Avenger"), ("Black Panther", "Wakanda Reader"),
            ("Deadpool", "Merc with a Bookmark"), ("Doctor Strange", "Sorcerer Reader")
        ]
        let charTargets: [Double] = [1, 5, 10, 25, 50, 100]
        let charTiers: [AchievementTier] = [.bronze, .bronze, .silver, .gold, .platinum, .legendary]
        let charXP = [75, 200, 400, 750, 1500, 3000]
        for (character, flavor) in characters {
            let safe = slug(character)
            for i in charTargets.indices {
                let target = Int(charTargets[i])
                let title: String
                switch i {
                case 0: title = flavor
                case 1: title = "\(character) Fan"
                case 2: title = "\(character) Expert"
                case 3: title = "\(character) Superfan"
                case 4: title = "\(character) Master"
                default: title = "\(character) Legend"
                }
                items.append(AchievementDefinition(id: "character.\(safe).\(i+1)", title: title, detail: "Finish \(target) comics featuring \(character).", category: .character, tier: charTiers[i], xp: charXP[i], target: charTargets[i], metric: .characterCompleted(character), hidden: false))
            }
        }

        let teams = ["Justice League", "Avengers", "X-Men", "Fantastic Four", "Teen Titans", "Bat-Family", "Guardians of the Galaxy", "Suicide Squad", "Justice Society", "Defenders"]
        let teamTargets: [Double] = [1,5,10,25,50]
        let teamXP = [100,250,500,900,1800]
        let teamTiers: [AchievementTier] = [.bronze,.silver,.gold,.platinum,.legendary]
        for team in teams {
            let safe = slug(team)
            for i in teamTargets.indices {
                let target = Int(teamTargets[i])
                items.append(AchievementDefinition(id: "team.\(safe).\(i+1)", title: i == 0 ? "Meet the \(team)" : "\(team) \(["Reader","Regular","Veteran","Elite","Legend"][i])", detail: "Finish \(target) comics associated with \(team).", category: .team, tier: teamTiers[i], xp: teamXP[i], target: teamTargets[i], metric: .teamCompleted(team), hidden: false))
            }
        }

        // A small hidden set. The requirements are deliberately not shown in the UI.
        let hidden: [(String,String,AchievementMetric,Double,Int)] = [
            ("hidden.midnight", "One More Page…", .maxDayPages, 300, 400),
            ("hidden.massive", "Shelf Crusher", .omnibusCompleted, 20, 1000),
            ("hidden.legend", "Living Library", .totalPages, 25000, 1200),
            ("hidden.century", "Century of Stories", .completedBooks, 100, 1200),
            ("hidden.streak", "Unbroken", .currentStreak, 60, 1200),
            ("hidden.favorites", "Heart Collector", .favorites, 75, 800)
        ]
        for (id,title,metric,target,xp) in hidden {
            items.append(AchievementDefinition(id: id, title: title, detail: "Secret requirement discovered.", category: .hidden, tier: .legendary, xp: xp, target: target, metric: metric, hidden: true))
        }

        return items
    }()

    static func slug(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

extension AchievementProfile {
    var totalXP: Int {
        AchievementCatalog.all.filter { unlockedIDs.contains($0.id) }.reduce(0) { $0 + $1.xp }
    }

    var level: Int {
        max(1, Int(sqrt(Double(totalXP) / 175.0)) + 1)
    }

    var xpIntoLevel: Int {
        let previous = Int(pow(Double(max(0, level - 1)), 2) * 175.0)
        return max(0, totalXP - previous)
    }

    var xpForNextLevel: Int {
        let previous = Int(pow(Double(max(0, level - 1)), 2) * 175.0)
        let next = Int(pow(Double(level), 2) * 175.0)
        return max(1, next - previous)
    }
}
