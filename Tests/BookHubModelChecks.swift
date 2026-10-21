import Foundation
@main struct ModelChecks {
    static func main() throws {
        let original = ComicBook(title: "Legacy", storedFileName: "legacy.pdf", type: .pdf, pageCount: 120, currentPage: 47, contentKind: .book, favorite: true)
        let encoded = try JSONEncoder().encode(original)
        var json = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        json.removeValue(forKey: "bookMetadata")
        json.removeValue(forKey: "coverRevision")
        let legacy = try JSONDecoder().decode(ComicBook.self, from: JSONSerialization.data(withJSONObject: json))
        precondition(legacy == original && legacy.bookMetadata == nil)
        var enriched = legacy
        enriched.bookMetadata = BookBibliography(title: "A Book", authors: ["An Author"], isbn: "9780000000002", sources: ["title": .manual])
        let restored = try JSONDecoder().decode(ComicBook.self, from: JSONEncoder().encode(enriched))
        precondition(restored == enriched && restored.currentPage == 47 && restored.favorite)
        var minimal = enriched
        minimal.bookMetadata = BookBibliography()
        let minimalRestored = try JSONDecoder().decode(ComicBook.self, from: JSONEncoder().encode(minimal))
        precondition(minimalRestored == minimal)
        precondition(BookISBN.normalized("978-0-306-40615-7") == "9780306406157")
        precondition(BookISBN.normalized("0 306 40615 2") == "0306406152")
        precondition(BookISBN.normalized("080442957x") == "080442957X")
        for invalid in ["9780306406158", "0306406153", "1234567890128", "03064061X2", "ISBN 9780306406157", "", "978-0-306-40615-7!"] {
            precondition(BookISBN.normalized(invalid) == nil)
        }
        enriched.bookMetadata?.isbn = BookISBN.normalized("978-0-306-40615-7")
        enriched.bookMetadata?.language = "tr"
        enriched.bookMetadata?.sources["isbn"] = .manual
        enriched.bookMetadata?.sources["language"] = .manual
        let bibliographicRoundTrip = try JSONDecoder().decode(ComicBook.self, from: JSONEncoder().encode(enriched))
        precondition(bibliographicRoundTrip.bookMetadata?.isbn == "9780306406157" && bibliographicRoundTrip.bookMetadata?.language == "tr")
        precondition(bibliographicRoundTrip.bookMetadata?.sources["language"] == .manual)
        var searchableBook = enriched
        searchableBook.title = "Gölgeler"
        searchableBook.bookMetadata = BookBibliography(title: "Gölgeler", authors: ["Çağrı Yılmaz"], publisher: "İş Bankası", isbn: "9780306406157", language: "tr", publicationYear: "2024")
        for query in ["golgeler", "CAGRI", "yilmaz", "iş bankası", "2024", "tr", "978-0-306-40615-7", "030640", "gölge yilmaz", "  "] {
            precondition(BookLibraryQuery(query).matches(searchableBook), "Missing match: \(query)")
        }
        precondition(!BookLibraryQuery("gölge başka").matches(searchableBook))
        precondition(BookLibraryQuery(" \n ").isEmpty)
        var searchableComic = searchableBook
        searchableComic.contentKind = .comic
        precondition(!BookLibraryQuery("yilmaz").matches(searchableComic))
        precondition(BookLibraryQuery("golgeler").matches(searchableComic))
        print("PASS: bibliography search, Turkish folding, formatted/partial ISBN, multi-term AND, whitespace and comics isolation")
        var secondBook = ComicBook(title: "Second Book", storedFileName: "second.pdf", type: .pdf, pageCount: 100, contentKind: .book)
        secondBook.bookMetadata = searchableBook.bookMetadata
        secondBook.bookMetadata?.authors = ["Çağrı Yılmaz", "Çağrı Yılmaz", "İkinci Yazar"]
        secondBook.bookMetadata?.publisher = " İş Bankası "
        let authorGroups = BookShelfGroup.groups(in: [searchableBook, secondBook, searchableComic], byAuthors: true)
        precondition(authorGroups.count == 2 && authorGroups.first?.bookIDs.count == 2)
        let publisherGroups = BookShelfGroup.groups(in: [searchableBook, secondBook, searchableComic, minimal], byAuthors: false)
        precondition(publisherGroups.count == 1 && publisherGroups[0].bookIDs.count == 2)
        precondition(BookShelfGroup.groups(in: [minimal], byAuthors: true).isEmpty)
        print("PASS: author/publisher shelves, duplicate authors, whitespace, missing metadata and comics isolation")
        var older = ComicBook(title: "Zebra", storedFileName: "old.pdf", type: .pdf, pageCount: 10, addedAt: Date(timeIntervalSince1970: 100), contentKind: .book)
        older.bookMetadata = BookBibliography(authors: ["Ada"], publicationYear: "2001")
        var newer = ComicBook(title: "Alpha", storedFileName: "new.pdf", type: .pdf, pageCount: 10, addedAt: Date(timeIntervalSince1970: 200), contentKind: .book)
        newer.bookMetadata = BookBibliography(authors: ["Zoe"], publicationYear: "2025")
        var unknown = ComicBook(title: "Beta", storedFileName: "unknown.pdf", type: .pdf, pageCount: 10, contentKind: .book)
        unknown.bookMetadata = BookBibliography(publicationYear: "unknown")
        let unsorted = [unknown, older, newer]
        precondition(BookLibrarySort.original.sorted(unsorted).map(\.id) == unsorted.map(\.id))
        precondition(BookLibrarySort.title.sorted(unsorted).map(\.id) == [newer.id, unknown.id, older.id])
        precondition(BookLibrarySort.author.sorted(unsorted).map(\.id) == [older.id, newer.id, unknown.id])
        precondition(BookLibrarySort.year.sorted(unsorted).map(\.id) == [newer.id, older.id, unknown.id])
        precondition(BookLibrarySort.newest.sorted([older, newer]).first?.id == newer.id)
        precondition(BookLibrarySort.title.sorted([]).isEmpty)
        precondition(BookLibrarySort.year.sorted(unsorted).map(\.id) == BookLibrarySort.year.sorted(unsorted.reversed()).map(\.id))
        print("PASS: title/author/year/date sorting, missing metadata, defaults and deterministic ordering")
        var incomplete = minimal
        incomplete.bookMetadata = BookBibliography(authors: ["  "], publisher: " ", isbn: "9780306406158")
        for field in BookMetadataReviewField.allCases { precondition(field.needsReview(incomplete)) }
        precondition(!BookMetadataReviewField.author.needsReview(searchableBook))
        precondition(!BookMetadataReviewField.publisher.needsReview(searchableBook))
        precondition(!BookMetadataReviewField.isbn.needsReview(searchableBook))
        precondition(!BookMetadataReviewField.isbn.needsReview(searchableComic))
        incomplete.bookMetadata?.isbn = "978-0-306-40615-7"
        precondition(!BookMetadataReviewField.isbn.needsReview(incomplete))
        print("PASS: missing metadata review, whitespace authors/publisher, ISBN checksum, formatted ISBN and comics isolation")
        older.readingStatus = .reading
        older.favorite = true
        newer.readingStatus = .completed
        unknown.readingStatus = .toRead
        let filterBooks = [older, newer, unknown]
        precondition(filterBooks.filter { LibraryQuickFilter.all.matches($0) }.count == 3)
        precondition(filterBooks.filter { LibraryQuickFilter.reading.matches($0) }.map(\.id) == [older.id])
        precondition(filterBooks.filter { LibraryQuickFilter.toRead.matches($0) }.map(\.id) == [unknown.id])
        precondition(filterBooks.filter { LibraryQuickFilter.completed.matches($0) }.map(\.id) == [newer.id])
        precondition(filterBooks.filter { LibraryQuickFilter.favorites.matches($0) }.map(\.id) == [older.id])
        let combined = BookLibrarySort.title.sorted(filterBooks.filter { BookLibraryQuery("Ada").matches($0) && LibraryQuickFilter.favorites.matches($0) })
        precondition(combined.map(\.id) == [older.id])
        precondition(LibraryQuickFilter.reading.label(forBooks: true) == "Okunuyor")
        precondition(LibraryQuickFilter.reading.label(forBooks: false) == "Reading")
        print("PASS: all reading filters, favorites, combined search/sort and Books labels")
        let backlog = (0..<12).map { ComicBook(title: "Queue \($0)", storedFileName: "queue\($0).pdf", type: .pdf, pageCount: 20, addedAt: Date(timeIntervalSince1970: Double($0)), contentKind: .book, readingStatus: .toRead) }
        precondition(BookHubReadingQueue.books(from: backlog.reversed()).map(\.title) == (0..<8).map { "Queue \($0)" })
        precondition(BookHubReadingQueue.books(from: backlog, limit: 0).isEmpty)
        precondition(BookHubReadingQueue.books(from: backlog, limit: -1).isEmpty)
        var excluded = backlog[0]
        excluded.isArchived = true
        precondition(BookHubReadingQueue.books(from: [excluded, older, newer, searchableComic]).isEmpty)
        precondition(ReadingStatus.toRead.label(forBooks: true) == "Okunacak")
        precondition(ReadingStatus.toRead.label(forBooks: false) == "To Read")
        let persistedStatus = try JSONEncoder().encode(ReadingStatus.toRead)
        precondition(String(data: persistedStatus, encoding: .utf8) == "\"To Read\"")
        print("PASS: oldest-first bounded reading queue, archive/status isolation and unchanged persisted statuses")
        precondition(AchievementCatalog.all.filter { $0.domain == .books }.count == 90)
        precondition(Set(AchievementCatalog.all.map(\.id)).count == AchievementCatalog.all.count)
        precondition(AchievementCatalog.all.first { $0.id == "completed.1" }?.domain == .comics)
        var classic = ComicBook(id: UUID(uuidString: ClassicReadingAchievements.books[0].id)!, title: "Classic", storedFileName: "classic.epub", type: .epub, pageCount: 10)
        classic.contentKind = .book
        precondition(ClassicReadingAchievements.stages(books: [classic], history: []).isEmpty)
        classic.readingStatus = .reading
        precondition(ClassicReadingAchievements.stages(books: [classic], history: [])[classic.id.uuidString] == 1)
        classic.currentPage = 4
        precondition(ClassicReadingAchievements.stages(books: [classic], history: [])[classic.id.uuidString] == 1)
        classic.currentPage = 5
        precondition(ClassicReadingAchievements.stages(books: [classic], history: [])[classic.id.uuidString] == 2)
        classic.readingStatus = .completed
        precondition(ClassicReadingAchievements.stages(books: [classic], history: [])[classic.id.uuidString] == 3)
        classic.isArchived = true
        precondition(ClassicReadingAchievements.stages(books: [classic], history: [])[classic.id.uuidString] == 3)
        let lookalike = ComicBook(title: classic.title, storedFileName: "other.epub", type: .epub, pageCount: 10, contentKind: .book, readingStatus: .completed)
        precondition(ClassicReadingAchievements.stages(books: [lookalike], history: []).isEmpty)
        classic.contentKind = .comic
        precondition(ClassicReadingAchievements.stages(books: [classic], history: []).isEmpty)
        var oldProfile = AchievementProfile()
        oldProfile.unlockedIDs = ["completed.1", "book.completed.1"]
        let profileRestored = try JSONDecoder().decode(AchievementProfile.self, from: JSONEncoder().encode(oldProfile))
        precondition(profileRestored.unlockedIDs == oldProfile.unlockedIDs && profileRestored.totalXP == 150)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = Date(timeIntervalSince1970: 86400 * 100)
        let achievementComic = ComicBook(title: "Comic", storedFileName: "comic.pdf", type: .pdf, pageCount: 100)
        let history = [
            ReadingHistoryEntry(bookID: original.id, date: today, startPage: 0, endPage: 19, pagesRead: 20, seconds: 60),
            ReadingHistoryEntry(bookID: original.id, date: today.addingTimeInterval(-86400), startPage: 0, endPage: 9, pagesRead: 10, seconds: 30),
            ReadingHistoryEntry(bookID: achievementComic.id, date: today, startPage: 0, endPage: 99, pagesRead: 100, seconds: 900),
            ReadingHistoryEntry(bookID: UUID(), date: today, startPage: 0, endPage: 999, pagesRead: 1000, seconds: 9000)
        ]
        let bookTotals = AchievementReadingTotals(books: [original, achievementComic], history: history, domain: .books, dailyGoal: 15, now: today, calendar: calendar)
        let comicTotals = AchievementReadingTotals(books: [original, achievementComic], history: history, domain: .comics, dailyGoal: 15, now: today, calendar: calendar)
        precondition(bookTotals.pages == 30 && bookTotals.seconds == 90 && bookTotals.streak == 2 && bookTotals.goalDays == 1 && bookTotals.maxDayPages == 20)
        precondition(comicTotals.pages == 100 && comicTotals.seconds == 900 && comicTotals.streak == 1)
        precondition(AchievementReadingTotals(books: [original], history: history, domain: .books, dailyGoal: 15, now: today.addingTimeInterval(86400), calendar: calendar).streak == 2)
        precondition(AchievementReadingTotals(books: [original], history: history, domain: .books, dailyGoal: 15, now: today.addingTimeInterval(86400 * 2), calendar: calendar).streak == 0)
        print("PASS: 90 unique Book Hub achievements, legacy unlock persistence, independent page/time/streak totals and unknown-record exclusion")
        var epub = ComicBook(title: "EPUB", storedFileName: "book.epub", type: .epub, pageCount: 4, currentPage: 1, contentKind: .book)
        let legacyReader = try JSONDecoder().decode(EPUBReaderState.self, from: Data("{\"scrollFraction\":0.4,\"fontSize\":22,\"theme\":\"Night\",\"bookmarks\":[1],\"highlights\":[]}".utf8))
        precondition(legacyReader.fontFamily == .serif && legacyReader.bookmarks == [1] && legacyReader.lineSpacing == 7 && legacyReader.horizontalMargin == 30)
        var layoutState = legacyReader
        layoutState.lineSpacing = 14; layoutState.horizontalMargin = 60
        let layoutRoundTrip = try JSONDecoder().decode(EPUBReaderState.self, from: JSONEncoder().encode(layoutState))
        precondition(layoutRoundTrip.lineSpacing == 14 && layoutRoundTrip.horizontalMargin == 60)
        epub.epubState = EPUBReaderState(scrollFraction: 0.5, fontSize: 24, theme: .night, bookmarks: [0, 2], highlights: [EPUBHighlight(chapter: 1, location: 0, length: 4, quote: "Test")])
        epub.epubState?.fontFamily = .mono
        let restoredEPUB = try JSONDecoder().decode(ComicBook.self, from: JSONEncoder().encode(epub))
        precondition(restoredEPUB == epub && restoredEPUB.progress == 0.375)
        epub.readingStatus = .completed
        precondition(epub.progress == 1)
        let textHistory = [ReadingHistoryEntry(bookID: epub.id, date: today, startPage: 0, endPage: 1, pagesRead: 0, seconds: 90)]
        let textTotals = AchievementReadingTotals(books: [epub], history: textHistory, domain: .books, dailyGoal: 10, now: today, calendar: calendar)
        precondition(textTotals.pages == 0 && textTotals.seconds == 90 && textTotals.streak == 1)
        print("PASS: EPUB location/settings/bookmark/highlight persistence, chapter progress, explicit completion and time-only reading streak")
        let editionJSON = Data("""
        {"title":"Example","publishers":["Online Press"],"publish_date":"September 1984","languages":[{"key":"/languages/eng"}],"covers":[-1,123],"description":{"value":"Example summary"}}
        """.utf8)
        let edition = try JSONDecoder().decode(OpenLibraryEdition.self, from: editionJSON)
        let suggestion = edition.suggestion(isbn: "9780306406157", authors: ["An Author"])
        precondition(suggestion.metadata.publicationYear == "1984" && suggestion.metadata.language == "en" && suggestion.coverID == 123)
        let manuallyBlank = BookBibliography(authors: [], publisher: "", sources: ["authors": .manual, "publisher": .manual])
        let merged = manuallyBlank.fillingMissingFields(from: suggestion.metadata)
        precondition(merged.authors.isEmpty && merged.publisher == "" && merged.publicationYear == "1984" && merged.sources["publicationYear"] == .online)
        let preserved = BookBibliography(title: "My Title", authors: ["My Author"], publisher: "My Publisher", language: "tr").fillingMissingFields(from: suggestion.metadata)
        precondition(preserved.title == "My Title" && preserved.authors == ["My Author"] && preserved.publisher == "My Publisher" && preserved.language == "tr")
        let onlineRestored = try JSONDecoder().decode(BookBibliography.self, from: JSONEncoder().encode(merged))
        precondition(onlineRestored == merged)
        print("PASS: online edition parsing, language/year normalization, cover IDs, missing-only merge, deliberate manual blanks and provenance persistence")
        let library = (0..<1000).map { index in ComicBook(title: "Book \(index)", storedFileName: "\(index).pdf", type: .pdf, pageCount: 200, contentKind: index.isMultiple(of: 2) ? .book : .comic) }
        let start = Date()
        let snapshot = try JSONEncoder().encode(library)
        let decoded = try JSONDecoder().decode([ComicBook].self, from: snapshot)
        precondition(decoded.count == 1000 && decoded.filter { $0.contentKind == .book }.count == 500)
        print("PASS: ISBN validation, language round-trip, legacy migration, bibliography round-trip, progress preservation, 1000-record decode/filter (\(Int(Date().timeIntervalSince(start) * 1000)) ms)")
    }
}
