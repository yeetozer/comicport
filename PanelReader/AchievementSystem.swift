import Foundation

enum AchievementDomain: String, CaseIterable, Identifiable {
    case comics = "Çizgi Roman"
    case books = "Kitap"
    var id: String { rawValue }
    func includes(_ book: ComicBook) -> Bool {
        self == .books ? book.contentKind == .book : book.contentKind != .book
    }
}

struct AchievementReadingTotals {
    let pages: Int
    let seconds: TimeInterval
    let goalDays: Int
    let maxDayPages: Int
    let streak: Int

    init(books: [ComicBook], history: [ReadingHistoryEntry], domain: AchievementDomain, dailyGoal: Int, now: Date = .now, calendar: Calendar = .current) {
        let ids = Set(books.filter { domain.includes($0) }.map(\.id))
        let entries = history.filter { ids.contains($0.bookID) }
        pages = entries.reduce(0) { $0 + max(0, $1.pagesRead) }
        seconds = entries.reduce(0) { $0 + max(0, $1.seconds) }
        var daily: [Date: Int] = [:]
        var activeDays: Set<Date> = []
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            daily[day, default: 0] += max(0, entry.pagesRead)
            if entry.pagesRead > 0 || entry.seconds > 0 { activeDays.insert(day) }
        }
        goalDays = dailyGoal > 0 ? daily.values.filter { $0 >= dailyGoal }.count : 0
        maxDayPages = daily.values.max() ?? 0
        var cursor = calendar.startOfDay(for: now)
        if !activeDays.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), activeDays.contains(yesterday) { cursor = yesterday }
        var count = 0
        while activeDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        streak = count
    }
}

enum AchievementTier: String, Codable, CaseIterable, Identifiable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case legendary = "Legendary"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .bronze: return "Bronz"
        case .silver: return "Gümüş"
        case .gold: return "Altın"
        case .platinum: return "Platin"
        case .legendary: return "Efsanevi"
        }
    }
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
    var label: String {
        switch self {
        case .reading: return "Okuma"
        case .time: return "Süre"
        case .streak: return "Okuma serisi"
        case .goals: return "Hedefler"
        case .collection: return "Koleksiyon"
        case .omnibus: return "Omnibus"
        case .character: return "Karakterler"
        case .team: return "Takımlar"
        case .special: return "Özel"
        case .hidden: return "Gizli"
        }
    }
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
    case classicStage(String)
    case bookDailyGoals, bookAnnualGoals, bookAuthors, bookCollections
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
    var domain: AchievementDomain { id.hasPrefix("book.") ? .books : .comics }
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
    var classicStages: [String: Double] = [:]
    var bookDailyGoals: Int = 0
    var bookAnnualGoals: Int = 0
    var bookAuthors: Int = 0
    var bookCollections: Int = 0

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
        case .classicStage(let id): return classicStages[id, default: 0]
        case .bookDailyGoals: return Double(bookDailyGoals)
        case .bookAnnualGoals: return Double(bookAnnualGoals)
        case .bookAuthors: return Double(bookAuthors)
        case .bookCollections: return Double(bookCollections)
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

        let bookSeries: [(String, [String], AchievementMetric, [Double], String)] = [
            ("completed", ["İlk Kitabım", "Raf Bitiren", "Kitap Kurdu", "Yüz Kitap", "Kütüphane Ustası"], .completedBooks, [1, 5, 25, 100, 500], "kitap tamamla"),
            ("pages", ["İlk Sayfalar", "Sayfa Yolcusu", "Sayfa Ustası", "Uzun Yolculuk", "Bitmeyen Hikâyeler"], .totalPages, [100, 1000, 5000, 10000, 50000], "kitap sayfası oku"),
            ("time", ["İlk Okuma Saati", "Okuma Alışkanlığı", "Sessiz Saatler", "Kütüphane Mesaisi", "Okuma Ömrü"], .totalSeconds, [3600, 36000, 180000, 360000, 1800000], "saat kitap oku"),
            ("library", ["İlk Rafım", "Dolu Raflar", "Kitap Koleksiyonu", "Ev Kütüphanesi", "Büyük Kütüphane"], .libraryBooks, [1, 10, 25, 100, 500], "kitabı kütüphanende tut"),
            ("favorites", ["Sevdiğim Kitap", "Seçkin Kitaplar", "Özel Raf", "Altın Raf", "Kütüphanenin Kalbi"], .favorites, [1, 5, 25, 50, 100], "kitabı favorilerine ekle"),
            ("ratings", ["İlk Kitap Puanım", "Kitap Eleştirmeni", "Deneyimli Okur", "Edebiyat Jürisi", "Usta Eleştirmen"], .ratedBooks, [1, 5, 25, 100, 250], "kitaba puan ver"),
            ("streak", ["Üç Günlük Yolculuk", "Bir Haftalık Okur", "İki Haftalık Alışkanlık", "Bir Ay Kitap", "Durmayan Okur"], .currentStreak, [3, 7, 14, 30, 100], "gün üst üste kitap oku"),
            ("notes", ["İlk Kitap Notum", "Kenar Notları", "Düşünce Defteri", "Araştırma Rafı", "Not Ustası"], .annotatedPages, [1, 10, 25, 100, 250], "kitap sayfasına not ekle")
        ]
        for (prefix, titles, metric, targets, requirement) in bookSeries {
            let details = targets.map { target in
                "\(Int(metric == .totalSeconds ? target / 3600 : target)) \(requirement)."
            }
            addSeries(prefix: "book.\(prefix)", titles: titles, details: details, category: prefix == "time" ? .time : (prefix == "streak" ? .streak : (["completed", "pages"].contains(prefix) ? .reading : .collection)), metric: metric, targets: targets, xps: [50, 150, 300, 700, 1800])
        }
        let milestones: [(String, [String], AchievementMetric, [Double], AchievementCategory, String)] = [
            ("dailyGoals", ["Hedefe İlk Adım", "Hedef Haftası", "Hedef Alışkanlığı", "Yüz Hedef Günü", "Bir Yıl Hedef"], .bookDailyGoals, [1, 7, 30, 100, 365], .goals, "gün kitap dakika hedefini tamamla"),
            ("annualGoals", ["Yıllık Hedef", "İki Yıllık Yol", "Üç Yıllık Okur", "Beş Yıllık Alışkanlık", "On Yıllık Okur"], .bookAnnualGoals, [1, 2, 3, 5, 10], .goals, "yılda kitap hedefini tamamla"),
            ("authors", ["Yeni Sesler", "Beş Yazar", "Yazar Yolculuğu", "Edebiyat Haritası", "Elli Farklı Ses"], .bookAuthors, [2, 5, 10, 25, 50], .reading, "farklı yazardan kitap tamamla"),
            ("collections", ["İlk Koleksiyon Bitti", "Üç Raf Bitti", "Koleksiyon Okuru", "On Raf Bitti", "Raf Ustası"], .bookCollections, [1, 3, 5, 10, 25], .collection, "kişisel koleksiyonun tüm kitaplarını tamamla")
        ]
        for (prefix, titles, metric, targets, category, detail) in milestones {
            addSeries(prefix: "book.\(prefix)", titles: titles, details: targets.map { "\(Int($0)) \(detail)." }, category: category, metric: metric, targets: targets, xps: [50, 150, 300, 700, 1800])
        }
        for classic in ClassicReadingAchievements.books {
            let tiers: [AchievementTier] = [.bronze, .silver, .gold]
            for stage in 1...3 {
                items.append(AchievementDefinition(id: "book.classic.\(classic.id).\(stage)", title: classic.titles[stage - 1], detail: "\(classic.title): \(["okumaya başla", "%50 ilerlemeye ulaş", "kitabı tamamla"][stage - 1]).", category: .special, tier: tiers[stage - 1], xp: [50, 100, 200][stage - 1], target: Double(stage), metric: .classicStage(classic.id), hidden: false))
            }
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

/// Stable bundled IDs prevent unrelated books with similar titles unlocking these awards.
enum ClassicReadingAchievements {
    struct Classic { let id: String; let title: String; let titles: [String] }
    static let books: [Classic] = [
        Classic(id: "D6A31567-E495-5EF5-9E07-CB298C135ABE", title: "Pride and Prejudice", titles: ["Longbourn’a Davet", "Darcy’ye Bir Adım", "Gurur ve Önyargının Ötesinde"]),
        Classic(id: "EBC47439-3CDE-5174-8562-CBB9AD9D706B", title: "Frankenstein", titles: ["Yaratılış Kıvılcımı", "Yaratığın İzinde", "Victor’un Son Mektubu"]),
        Classic(id: "A4C8C595-5A5C-51A2-A421-AE5155289B62", title: "Dracula", titles: ["Transilvanya’ya Yolculuk", "Gecenin Kalbinde", "Şafak Vakti"]),
        Classic(id: "C2478F54-E47D-5092-A9C0-8E76163E764D", title: "The Adventures of Sherlock Holmes", titles: ["Baker Street’e Hoş Geldin", "İpuçları Birleşiyor", "Watson’ın Defteri"]),
        Classic(id: "BE91E184-0E36-54AF-8F9E-331BA68BF321", title: "Alice’s Adventures in Wonderland", titles: ["Tavşan Deliğinden İçeri", "Çılgın Çay Saati", "Harikalar Diyarından Dönüş"]),
        Classic(id: "06D0E920-140A-502B-9D0C-CFA659A4360E", title: "The Picture of Dorian Gray", titles: ["Portreye İlk Bakış", "Gölgedeki Yüz", "Portrenin Sırrı"]),
        Classic(id: "F51B3163-796F-57AB-8F62-270AED127A1A", title: "Dr. Jekyll and Mr. Hyde", titles: ["Soho’da Bir Kapı", "İki Yüzün Arasında", "Jekyll’ın İtirafı"]),
        Classic(id: "174E75B3-9DAE-52F6-AD6B-3A5C14A35F69", title: "A Christmas Carol", titles: ["Marley’nin Ziyareti", "Ruhların Rehberliğinde", "Scrooge’un Yeni Sabahı"]),
        Classic(id: "8D9CC4D3-033F-581A-A459-90D3E8294E68", title: "Treasure Island", titles: ["Harita Bulundu", "Hispaniola’da Yolculuk", "Flint’in Hazinesi"]),
        Classic(id: "96AE77D7-84D9-5735-B2E7-87DC82AD5702", title: "The Time Machine", titles: ["Zamanın Kapısı", "802.701 Yılı", "Zaman Yolcusunun Dönüşü"])
    ]
    static func stages(books: [ComicBook], history: [ReadingHistoryEntry]) -> [String: Double] {
        let known = Set(Self.books.map(\.id))
        let readIDs = Set(history.filter { $0.pagesRead > 0 || $0.seconds > 0 }.map(\.bookID))
        var values: [String: Double] = [:]
        for book in books where book.contentKind == .book {
            let id = book.id.uuidString
            guard known.contains(id) else { continue }
            let started = book.readingStatus == .reading || book.readingStatus == .completed || readIDs.contains(book.id)
            guard started else { continue }
            values[id] = book.readingStatus == .completed ? 3 : (book.progress >= 0.5 ? 2 : 1)
        }
        return values
    }
}
