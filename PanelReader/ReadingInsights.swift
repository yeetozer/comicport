import Foundation

struct YearReadingSummary {
    let year: Int
    let pages: Int
    let seconds: TimeInterval
    let sessions: Int
    let completedBooks: Int
    let achievements: Int
    let longestSession: TimeInterval
    let busiestMonthName: String
    let topCharacter: String
    let topSeries: String
    let topPublisher: String
    let activeDays: Int
    let longestStreak: Int

    var shareText: String {
        """
        PANEL WRAPPED \(year)
        📖 \(pages) pages
        ⏱ \(Int(seconds / 3600)) hours
        📚 \(completedBooks) completed comics
        🔥 \(longestStreak)-day best streak
        🦸 \(topCharacter)
        📚 Top series: \(topSeries)
        🏆 \(achievements) achievements
        """
    }
}

@MainActor
enum ReadingInsightsService {
    static func yearSummary(store: LibraryStore, year: Int, calendar: Calendar = .current) -> YearReadingSummary {
        let sessions = store.analytics.history.filter { calendar.component(.year, from: $0.date) == year }
        let pages = sessions.reduce(0) { $0 + max(0, $1.pagesRead) }
        let seconds = sessions.reduce(0.0) { $0 + max(0, $1.seconds) }
        let longestSession = sessions.map(\.seconds).max() ?? 0

        let completed = store.books.filter {
            $0.readingStatus == .completed &&
            ($0.lastReadAt.map { calendar.component(.year, from: $0) == year } ?? false)
        }.count

        let achievements = store.achievementProfile.unlockedAt.values.filter {
            calendar.component(.year, from: $0) == year
        }.count

        let monthGroups = Dictionary(grouping: sessions) { calendar.component(.month, from: $0.date) }
        let busiestMonth = monthGroups.max { lhs, rhs in
            lhs.value.reduce(0) { $0 + $1.pagesRead } < rhs.value.reduce(0) { $0 + $1.pagesRead }
        }?.key
        let monthName: String = {
            guard let busiestMonth,
                  let date = calendar.date(from: DateComponents(year: year, month: busiestMonth, day: 1)) else { return "—" }
            return date.formatted(.dateTime.month(.wide))
        }()

        let activeDayKeys = store.analytics.daily.compactMap { key, stat -> String? in
            guard stat.pages > 0, let date = dayDate(key),
                  calendar.component(.year, from: date) == year else { return nil }
            return key
        }

        return YearReadingSummary(
            year: year,
            pages: pages,
            seconds: seconds,
            sessions: sessions.count,
            completedBooks: completed,
            achievements: achievements,
            longestSession: longestSession,
            busiestMonthName: monthName,
            topCharacter: topCharacter(store: store, sessions: sessions),
            topSeries: topSeries(store: store, sessions: sessions),
            topPublisher: topPublisher(store: store, sessions: sessions),
            activeDays: Set(activeDayKeys).count,
            longestStreak: longestStreak(store: store, year: year, calendar: calendar)
        )
    }

    static func currentStreak(store: LibraryStore, calendar: Calendar = .current) -> Int {
        let active = activeDays(store: store, calendar: calendar)
        var cursor = calendar.startOfDay(for: .now)
        if !active.contains(cursor), let previous = calendar.date(byAdding: .day, value: -1, to: cursor), active.contains(previous) {
            cursor = previous
        }
        var count = 0
        while active.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    static func longestStreak(store: LibraryStore, year: Int? = nil, calendar: Calendar = .current) -> Int {
        let dates = activeDays(store: store, calendar: calendar)
            .filter { year == nil || calendar.component(.year, from: $0) == year }
            .sorted()
        guard !dates.isEmpty else { return 0 }

        var best = 1
        var run = 1
        for index in 1..<dates.count {
            let gap = calendar.dateComponents([.day], from: dates[index - 1], to: dates[index]).day ?? 0
            if gap == 1 { run += 1 } else if gap > 1 { run = 1 }
            best = max(best, run)
        }
        return best
    }

    static func last7Days(store: LibraryStore, calendar: Calendar = .current) -> [(Date, DailyReadingStat)] {
        (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) else { return nil }
            return (date, store.analytics.daily[dayKey(date)] ?? DailyReadingStat())
        }
    }

    static func daySessions(store: LibraryStore, date: Date, calendar: Calendar = .current) -> [ReadingHistoryEntry] {
        store.analytics.history.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private static func activeDays(store: LibraryStore, calendar: Calendar) -> Set<Date> {
        Set(store.analytics.daily.compactMap { key, stat in
            guard stat.pages > 0, let date = dayDate(key) else { return nil }
            return calendar.startOfDay(for: date)
        })
    }

    private static func topCharacter(store: LibraryStore, sessions: [ReadingHistoryEntry]) -> String {
        let profiles = CharacterLibraryService.profiles(from: store.books)
        var pageByBook: [UUID: Int] = [:]
        for session in sessions { pageByBook[session.bookID, default: 0] += session.pagesRead }

        let result = profiles.map { profile -> (String, Int) in
            let total = profile.comicIDs.reduce(0) { $0 + pageByBook[$1, default: 0] }
            return (profile.name, total)
        }.max { $0.1 < $1.1 }
        return (result?.1 ?? 0) > 0 ? result!.0 : "—"
    }

    private static func topSeries(store: LibraryStore, sessions: [ReadingHistoryEntry]) -> String {
        let bookByID = Dictionary(uniqueKeysWithValues: store.books.map { ($0.id, $0) })
        var pageBySeries: [String: Int] = [:]
        for session in sessions {
            guard let book = bookByID[session.bookID] else { continue }
            let series = SeriesService.parse(book.title).seriesTitle
            pageBySeries[series, default: 0] += session.pagesRead
        }
        return pageBySeries.max { $0.value < $1.value }?.key ?? "—"
    }

    private static func topPublisher(store: LibraryStore, sessions: [ReadingHistoryEntry]) -> String {
        let bookByID = Dictionary(uniqueKeysWithValues: store.books.map { ($0.id, $0) })
        var counts: [String: Int] = [:]
        for session in sessions {
            guard let book = bookByID[session.bookID] else { continue }
            let raw = LocalComicDatabase.bestMatch(title: book.title)?.record.publisher ?? "Other"
            let low = raw.lowercased()
            let publisher: String
            if low.contains("dc") { publisher = "DC Comics" }
            else if low.contains("marvel") { publisher = "Marvel" }
            else if low.contains("image") { publisher = "Image Comics" }
            else if low.contains("dark horse") { publisher = "Dark Horse" }
            else { publisher = raw }
            counts[publisher, default: 0] += session.pagesRead
        }
        return counts.max { $0.value < $1.value }?.key ?? "—"
    }

    private static func dayKey(_ date: Date) -> String {
        PanelDayKey.string(date)
    }

    private static func dayDate(_ key: String) -> Date? {
        PanelDayKey.date(key)
    }
}
