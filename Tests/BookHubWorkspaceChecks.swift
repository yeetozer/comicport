import Foundation

@main struct BookHubWorkspaceChecks {
    static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 3 * 3600)!
        let now = Date(timeIntervalSince1970: 1791493200)
        var book = ComicBook(title: "Çağrı", storedFileName: "a.epub", type: .epub, pageCount: 2, contentKind: .book, bookMetadata: BookBibliography(authors: ["Çağrı Yılmaz"]))
        let comic = ComicBook(title: "Comic", storedFileName: "c.pdf", type: .pdf, pageCount: 4)
        let history = [ReadingHistoryEntry(bookID: book.id, date: now, startPage: 0, endPage: 1, pagesRead: 0, seconds: 1200), ReadingHistoryEntry(bookID: comic.id, date: now, startPage: 0, endPage: 1, pagesRead: 1, seconds: 9999), ReadingHistoryEntry(bookID: book.id, date: now.addingTimeInterval(-86400), startPage: 0, endPage: 1, pagesRead: 0, seconds: 600)]
        let completions = [BookHubCompletion(bookID: book.id, date: now), BookHubCompletion(bookID: book.id, date: now.addingTimeInterval(-86400)), BookHubCompletion(bookID: comic.id, date: now)]
        let progress = BookHubGoalProgress(books: [book, comic], history: history, completions: completions, now: now, calendar: calendar)
        precondition(progress.todaySeconds == 1200 && progress.completedThisYear == 1)
        var state = BookHubState(); state.goals.enabled = true; state.completions = completions
        state.collections = [BookHubCollection(name: "Koleksiyon", bookIDs: [book.id])]
        state.reachedDailyGoals = ["2026-10-08"]
        let decoded = try JSONDecoder().decode(BookHubState.self, from: JSONEncoder().encode(state))
        precondition(decoded.collections == state.collections && decoded.reachedDailyGoals == state.reachedDailyGoals)
        precondition(BookHubSmartShelf.unstarted.books(from: [book, comic], completedIDs: [], annotatedIDs: []).count == 1)
        book.readingStatus = .reading; book.lastReadAt = now.addingTimeInterval(-31 * 86400)
        precondition(BookHubSmartShelf.paused.books(from: [book], completedIDs: [], annotatedIDs: [], now: now).count == 1)
        book.isArchived = true
        precondition(BookHubSmartShelf.paused.books(from: [book], completedIDs: [], annotatedIDs: [], now: now).isEmpty)
        book.isArchived = false
        var duplicate = book; duplicate.title = "Cagri"
        duplicate.bookMetadata?.authors = ["Cagri Yilmaz"]
        precondition(BookHubMaintenance.duplicateGroups(in: [book, duplicate, comic]).count == 1)
        duplicate.bookMetadata?.authors = []
        precondition(BookHubMaintenance.duplicateGroups(in: [book, duplicate]).isEmpty)
        book.readingStatus = .completed
        duplicate.readingStatus = .completed; duplicate.bookMetadata?.authors = ["Cagri Yilmaz"]
        let milestones = BookHubMilestones(books: [book, duplicate, comic], collections: [BookHubCollection(name: "Bitti", bookIDs: [book.id]), BookHubCollection(name: "Boş"), BookHubCollection(name: "Eksik", bookIDs: [UUID()])])
        precondition(milestones.completedAuthors == 1 && milestones.completedCollections == 1)
        let excerpt = BookHubExcerpt(id: "x", bookID: book.id, title: "Kitap", authors: ["Yazar"], page: 1, isChapter: true, text: "birinci\nikinci", isHighlight: true)
        let markdown = BookHubExcerpt.markdown([excerpt])
        precondition(markdown.contains("Bölüm 2") && markdown.contains("> birinci\n> ikinci"))
        print("PASS: Book Hub scope, local-day minutes, annual unique books, state persistence, archive-safe shelves, Turkish duplicate matching")
    }
}
