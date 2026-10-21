import Foundation

enum ComicType: String, Codable, Sendable {
    case pdf
    case cbz
    case epub
}

struct EPUBHighlight: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    let chapter: Int
    let location: Int
    let length: Int
    let quote: String
}

enum EPUBFontFamily: String, Codable, CaseIterable, Identifiable, Sendable {
    case serif = "Klasik", sans = "Sade", mono = "Eş aralıklı"
    var id: String { rawValue }
}

struct EPUBReaderState: Codable, Hashable, Sendable {
    var scrollFraction: Double = 0
    var fontSize: Double = 20
    var theme: ReaderTheme = .sepia
    var bookmarks: Set<Int> = []
    var highlights: [EPUBHighlight] = []
    var lineSpacing: Double = 7
    var horizontalMargin: Double = 30
    var fontFamily: EPUBFontFamily = .serif
}

extension EPUBReaderState {
    private enum CodingKeys: String, CodingKey { case scrollFraction, fontSize, theme, bookmarks, highlights, fontFamily, lineSpacing, horizontalMargin }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scrollFraction = try values.decodeIfPresent(Double.self, forKey: .scrollFraction) ?? 0
        fontSize = try values.decodeIfPresent(Double.self, forKey: .fontSize) ?? 20
        theme = try values.decodeIfPresent(ReaderTheme.self, forKey: .theme) ?? .sepia
        bookmarks = try values.decodeIfPresent(Set<Int>.self, forKey: .bookmarks) ?? []
        highlights = try values.decodeIfPresent([EPUBHighlight].self, forKey: .highlights) ?? []
        lineSpacing = min(20, max(0, try values.decodeIfPresent(Double.self, forKey: .lineSpacing) ?? 7))
        horizontalMargin = min(80, max(12, try values.decodeIfPresent(Double.self, forKey: .horizontalMargin) ?? 30))
        fontFamily = try values.decodeIfPresent(EPUBFontFamily.self, forKey: .fontFamily) ?? .serif
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case reading = "Reading"
    case toRead = "To Read"
    case completed = "Completed"

    var id: String { rawValue }
    func label(forBooks: Bool) -> String {
        guard forBooks else { return rawValue }
        switch self {
        case .reading: return "Okunuyor"
        case .toRead: return "Okunacak"
        case .completed: return "Tamamlandı"
        }
    }
    var systemImage: String {
        switch self {
        case .reading: return "book.pages"
        case .toRead: return "bookmark"
        case .completed: return "checkmark.circle"
        }
    }
}

enum ReaderTheme: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case normal = "Normal"
    case night = "Night"
    case sepia = "Sepia"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .normal: return "circle.lefthalf.filled"
        case .night: return "moon.stars"
        case .sepia: return "sun.haze"
        }
    }
}


enum ComicPortReaderProfile: String, Codable, CaseIterable, Identifiable, Sendable {
    case comics = "Comics"
    case manga = "Manga"
    case books = "Books"
    case mix = "Mix"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .comics: return "book.closed.fill"
        case .manga: return "arrow.left.and.right.text.vertical"
        case .books: return "text.book.closed.fill"
        case .mix: return "books.vertical.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .comics: return "Comics and graphic novels"
        case .manga: return "Manga and right-to-left series"
        case .books: return "Novels and books"
        case .mix: return "Everything in one library"
        }
    }
}

enum ComicPortContentKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case comic = "Comic"
    case manga = "Manga"
    case book = "Book"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .comic: return "book.closed"
        case .manga: return "arrow.left.and.right.text.vertical"
        case .book: return "text.book.closed"
        }
    }
}

struct ComicBook: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var storedFileName: String
    var type: ComicType
    var pageCount: Int
    var currentPage: Int
    var addedAt: Date
    var thumbnailFileName: String?
    var coverRevision: Int
    var contentKind: ComicPortContentKind
    var rightToLeft: Bool
    var bookMetadata: BookBibliography?
    var epubState: EPUBReaderState?
    var readingStatus: ReadingStatus
    var favorite: Bool
    var rating: Int
    var lastOpenedAt: Date?
    var lastReadAt: Date?
    var sourceIdentity: String
    var isInLibrary: Bool
    var fileAvailable: Bool
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        storedFileName: String,
        type: ComicType,
        pageCount: Int,
        currentPage: Int = 0,
        addedAt: Date = .now,
        thumbnailFileName: String? = nil,
        coverRevision: Int = 0,
        contentKind: ComicPortContentKind = .comic,
        rightToLeft: Bool = false,
        bookMetadata: BookBibliography? = nil,
        readingStatus: ReadingStatus = .toRead,
        favorite: Bool = false,
        rating: Int = 0,
        lastOpenedAt: Date? = nil,
        lastReadAt: Date? = nil,
        sourceIdentity: String = "",
        isInLibrary: Bool = true,
        fileAvailable: Bool = true,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.storedFileName = storedFileName
        self.type = type
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.addedAt = addedAt
        self.thumbnailFileName = thumbnailFileName
        self.coverRevision = coverRevision
        self.contentKind = contentKind
        self.rightToLeft = rightToLeft
        self.bookMetadata = bookMetadata
        self.epubState = nil
        self.readingStatus = readingStatus
        self.favorite = favorite
        self.rating = rating
        self.lastOpenedAt = lastOpenedAt
        self.lastReadAt = lastReadAt
        self.sourceIdentity = sourceIdentity
        self.isInLibrary = isInLibrary
        self.fileAvailable = fileAvailable
        self.isArchived = isArchived
    }

    var progress: Double {
        guard pageCount > 0 else { return 0 }
        if type == .epub {
            if readingStatus == .completed { return 1 }
            return min(1, (Double(currentPage) + (epubState?.scrollFraction ?? 0)) / Double(pageCount))
        }
        return min(1, Double(currentPage + 1) / Double(pageCount))
    }

    var progressPercent: Int { Int((progress * 100).rounded()) }

    private enum CodingKeys: String, CodingKey {
        case id, title, storedFileName, type, pageCount, currentPage, addedAt, thumbnailFileName, contentKind, rightToLeft
        case readingStatus, favorite, rating, lastOpenedAt, lastReadAt
        case sourceIdentity, isInLibrary, fileAvailable, isArchived, bookMetadata, coverRevision, epubState
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        storedFileName = try c.decode(String.self, forKey: .storedFileName)
        type = try c.decode(ComicType.self, forKey: .type)
        pageCount = try c.decode(Int.self, forKey: .pageCount)
        currentPage = try c.decode(Int.self, forKey: .currentPage)
        addedAt = try c.decode(Date.self, forKey: .addedAt)
        coverRevision = try c.decodeIfPresent(Int.self, forKey: .coverRevision) ?? 0
        thumbnailFileName = try c.decodeIfPresent(String.self, forKey: .thumbnailFileName)
        contentKind = try c.decodeIfPresent(
            ComicPortContentKind.self,
            forKey: .contentKind
        ) ?? .comic
        bookMetadata = try c.decodeIfPresent(BookBibliography.self, forKey: .bookMetadata)
        epubState = try c.decodeIfPresent(EPUBReaderState.self, forKey: .epubState)
        rightToLeft = try c.decodeIfPresent(Bool.self, forKey: .rightToLeft) ?? false
        readingStatus = try c.decodeIfPresent(ReadingStatus.self, forKey: .readingStatus) ?? (currentPage > 0 ? .reading : .toRead)
        favorite = try c.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? 0
        lastOpenedAt = try c.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
        lastReadAt = try c.decodeIfPresent(Date.self, forKey: .lastReadAt)
        sourceIdentity = try c.decodeIfPresent(String.self, forKey: .sourceIdentity) ?? ""
        isInLibrary = try c.decodeIfPresent(Bool.self, forKey: .isInLibrary) ?? true
        fileAvailable = try c.decodeIfPresent(Bool.self, forKey: .fileAvailable) ?? true
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }
}

struct DailyReadingStat: Codable, Hashable, Sendable {
    var pages: Int = 0
    var seconds: TimeInterval = 0
}

struct ReadingHistoryEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let bookID: UUID
    let date: Date
    let startPage: Int
    let endPage: Int
    let pagesRead: Int
    let seconds: TimeInterval

    init(id: UUID = UUID(), bookID: UUID, date: Date = .now, startPage: Int, endPage: Int, pagesRead: Int, seconds: TimeInterval) {
        self.id = id
        self.bookID = bookID
        self.date = date
        self.startPage = startPage
        self.endPage = endPage
        self.pagesRead = pagesRead
        self.seconds = seconds
    }
}

struct ReadingAnalytics: Codable, Sendable {
    var dailyGoalPages: Int = 50
    var daily: [String: DailyReadingStat] = [:]
    var history: [ReadingHistoryEntry] = []
}

// Optional on ComicBook so Stage 21.0.1 libraries keep their identity and progress.
// Field-level provenance prevents filename/OCR guesses being treated as verified data.
enum BookMetadataSource: String, Codable, Hashable, Sendable {
    case embedded, filename, inferred, manual, online
    var label: String {
        switch self {
        case .embedded: return "Dosyadan"
        case .filename: return "Dosya adından"
        case .inferred: return "Tahmini"
        case .manual: return "Elle girildi"
        case .online: return "Open Library"
        }
    }
}

struct BookBibliography: Codable, Hashable, Sendable {
    var title: String?
    var authors: [String] = []
    var publisher: String?
    var isbn: String?
    var language: String?
    var publicationYear: String?
    var summary: String?
    var sources: [String: BookMetadataSource] = [:]
    var analyzedAt: Date?
}

enum BookHubPerformancePolicy {
    static let metadataPageLimit = 4
    static let metadataMemoryEntries = 32
    static let metadataPendingLimit = 8
    static let shelfCoverPixels = 640
}

// Validate before persistence; formatting is accepted but never hides invalid input.
enum BookISBN {
    static func normalized(_ raw: String) -> String? {
        let value = raw.uppercased().filter { !$0.isWhitespace && $0 != "-" }
        let chars = Array(value)
        guard chars.allSatisfy({ "0123456789X".contains($0) }) else { return nil }
        if chars.count == 10 {
            var sum = 0
            for (index, char) in chars.enumerated() {
                if char == "X" {
                    guard index == 9 else { return nil }
                    sum += 10
                } else {
                    guard let digit = char.wholeNumberValue else { return nil }
                    sum += (10 - index) * digit
                }
            }
            return sum % 11 == 0 ? value : nil
        }
        if chars.count == 13, value.hasPrefix("978") || value.hasPrefix("979") {
            var sum = 0
            for (index, char) in chars.enumerated() {
                guard let digit = char.wholeNumberValue else { return nil }
                sum += digit * (index.isMultiple(of: 2) ? 1 : 3)
            }
            return sum % 10 == 0 ? value : nil
        }
        return nil
    }
}


// Prepare the query once; searching never reads files or starts metadata analysis.
struct BookLibraryQuery {
    private let terms: [String]
    private let isbnFragment: String?

    init(_ query: String) {
        let normalized = Self.fold(query)
        terms = normalized.split(whereSeparator: \.isWhitespace).map(String.init)
        let compact = normalized.filter { !$0.isWhitespace && $0 != "-" }
        isbnFragment = compact.count >= 3 && compact.allSatisfy { "0123456789x".contains($0) } ? compact : nil
    }

    var isEmpty: Bool { terms.isEmpty }

    func matches(_ book: ComicBook) -> Bool {
        if isEmpty { return true }
        var fields = [book.title]
        if book.contentKind == .book, let metadata = book.bookMetadata {
            fields += [metadata.title ?? "", metadata.publisher ?? "", metadata.publicationYear ?? "", metadata.language ?? "", metadata.isbn ?? ""]
            fields += metadata.authors
            if let isbnFragment, Self.fold(metadata.isbn ?? "").replacingOccurrences(of: "-", with: "").contains(isbnFragment) { return true }
        }
        let searchable = Self.fold(fields.joined(separator: " "))
        return terms.allSatisfy { searchable.contains($0) }
    }

    static func fold(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "ı", with: "i")
    }
}


struct BookShelfGroup: Identifiable {
    let id: String
    let title: String
    let bookIDs: Set<UUID>

    static func groups(in books: [ComicBook], byAuthors: Bool) -> [BookShelfGroup] {
        var grouped: [String: (title: String, ids: Set<UUID>)] = [:]
        for book in books where book.contentKind == .book {
            let values = byAuthors ? (book.bookMetadata?.authors ?? []) : [book.bookMetadata?.publisher ?? ""]
            for value in values {
                let title = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { continue }
                let key = title.folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
                var group = grouped[key] ?? (title, [])
                if title < group.title { group.title = title }
                group.ids.insert(book.id)
                grouped[key] = group
            }
        }
        return grouped.map { BookShelfGroup(id: $0.key, title: $0.value.title, bookIDs: $0.value.ids) }
            .sorted { $0.bookIDs.count == $1.bookIDs.count ? $0.id < $1.id : $0.bookIDs.count > $1.bookIDs.count }
    }
}


enum BookLibrarySort: String, CaseIterable, Identifiable {
    case original = "Varsayılan"
    case title = "Kitap adı"
    case author = "Yazar"
    case year = "Yayın yılı (yeni önce)"
    case newest = "Son eklenen"
    var id: String { rawValue }

    func sorted(_ books: [ComicBook]) -> [ComicBook] {
        guard self != .original else { return books }
        // Build comparison keys once per record, rather than on every comparison.
        let keyed = books.map { book in
            (book: book,
             title: Self.fold(book.title),
             author: self == .author ? Self.fold(book.bookMetadata?.authors.first ?? "") : "",
             year: self == .year ? Int((book.bookMetadata?.publicationYear ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) : nil)
        }
        return keyed.sorted { lhs, rhs in
            switch self {
            case .author:
                if lhs.author.isEmpty != rhs.author.isEmpty { return !lhs.author.isEmpty }
                if lhs.author != rhs.author { return lhs.author < rhs.author }
            case .year:
                if (lhs.year == nil) != (rhs.year == nil) { return lhs.year != nil }
                if let a = lhs.year, let b = rhs.year, a != b { return a > b }
            case .newest:
                if lhs.book.addedAt != rhs.book.addedAt { return lhs.book.addedAt > rhs.book.addedAt }
            case .original, .title: break
            }
            if lhs.title != rhs.title { return lhs.title < rhs.title }
            return lhs.book.id.uuidString < rhs.book.id.uuidString
        }.map(\.book)
    }

    private static func fold(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "ı", with: "i")
    }
}


enum BookMetadataReviewField: String, CaseIterable, Identifiable {
    case author = "Yazar bilgisi eksik"
    case publisher = "Yayınevi bilgisi eksik"
    case isbn = "ISBN eksik veya geçersiz"
    var id: String { rawValue }

    func needsReview(_ book: ComicBook) -> Bool {
        guard book.contentKind == .book else { return false }
        switch self {
        case .author:
            return !(book.bookMetadata?.authors.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false)
        case .publisher:
            return (book.bookMetadata?.publisher ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .isbn:
            return BookISBN.normalized(book.bookMetadata?.isbn ?? "") == nil
        }
    }
}

enum LibraryQuickFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case reading = "Reading"
    case toRead = "To Read"
    case completed = "Completed"
    case favorites = "Favorites"
    var id: String { rawValue }
    func label(forBooks: Bool) -> String {
        guard forBooks else { return rawValue }
        switch self {
        case .all: return "Tümü"
        case .reading: return "Okunuyor"
        case .toRead: return "Okunacak"
        case .completed: return "Tamamlandı"
        case .favorites: return "Favoriler"
        }
    }
    func matches(_ book: ComicBook) -> Bool {
        switch self {
        case .all: return true
        case .reading: return book.readingStatus == .reading
        case .toRead: return book.readingStatus == .toRead
        case .completed: return book.readingStatus == .completed
        case .favorites: return book.favorite
        }
    }
}


// A bounded preview of the reading backlog; opening the shelf never changes progress.
enum BookHubReadingQueue {
    static func books(from books: [ComicBook], limit: Int = 8) -> [ComicBook] {
        Array(books.filter { $0.contentKind == .book && $0.isInLibrary && !$0.isArchived && $0.readingStatus == .toRead }
            .sorted { lhs, rhs in
                lhs.addedAt == rhs.addedAt ? lhs.id.uuidString < rhs.id.uuidString : lhs.addedAt < rhs.addedAt
            }.prefix(max(0, limit)))
    }
}

// Book Hub planning is stored separately so old libraries and comic goals stay compatible.
struct BookHubGoals: Codable, Equatable, Sendable {
    var enabled = false
    var dailyMinutes = 20
    var annualBooks = 12
}

struct BookHubCollection: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var bookIDs: Set<UUID> = []
}

struct BookHubCompletion: Codable, Hashable, Sendable {
    let bookID: UUID
    let date: Date
}

struct BookHubState: Codable, Sendable {
    var goals = BookHubGoals()
    var collections: [BookHubCollection] = []
    var completions: [BookHubCompletion] = []
    var reachedDailyGoals: Set<String> = []
    var reachedAnnualGoals: Set<Int> = []

    func merging(_ incoming: BookHubState, bookIDMap: [UUID: UUID]) -> BookHubState {
        var result = self
        result.goals = incoming.goals
        var collections: [UUID: BookHubCollection] = [:]
        for collection in result.collections { collections[collection.id] = collection }
        for var collection in incoming.collections {
            collection.bookIDs = Set(collection.bookIDs.map { bookIDMap[$0] ?? $0 })
            collections[collection.id] = collection
        }
        result.collections = collections.values.sorted { $0.name < $1.name }
        let completions = incoming.completions.map { BookHubCompletion(bookID: bookIDMap[$0.bookID] ?? $0.bookID, date: $0.date) }
        result.completions = Array(Set(result.completions + completions)).sorted { $0.date < $1.date }
        result.reachedDailyGoals.formUnion(incoming.reachedDailyGoals)
        result.reachedAnnualGoals.formUnion(incoming.reachedAnnualGoals)
        return result
    }
}

struct BookHubGoalProgress: Sendable {
    let todaySeconds: TimeInterval
    let completedThisYear: Int
    let completedBookIDs: Set<UUID>
    let year: Int

    init(books: [ComicBook], history: [ReadingHistoryEntry], completions: [BookHubCompletion], now: Date = .now, calendar: Calendar = .current) {
        let ids = Set(books.filter { $0.contentKind == .book }.map(\.id))
        todaySeconds = history.filter { ids.contains($0.bookID) && calendar.isDate($0.date, inSameDayAs: now) }
            .reduce(0) { $0 + max(0, $1.seconds.isFinite ? $1.seconds : 0) }
        let currentYear = calendar.component(.year, from: now)
        year = currentYear
        completedBookIDs = Set(completions.filter { ids.contains($0.bookID) && calendar.component(.year, from: $0.date) == currentYear }.map(\.bookID))
        completedThisYear = completedBookIDs.count
    }
}

enum BookHubSmartShelf: String, CaseIterable, Identifiable {
    case unstarted = "Başlamadıklarım"
    case paused = "Uzun süredir açmadıklarım"
    case completedYear = "Bu yıl bitirdiklerim"
    case annotated = "Not aldığım kitaplar"
    var id: String { rawValue }

    func books(from books: [ComicBook], completedIDs: Set<UUID>, annotatedIDs: Set<UUID>, now: Date = .now) -> [ComicBook] {
        let cutoff = now.addingTimeInterval(-30 * 86400)
        return books.filter { book in
            guard book.contentKind == .book && book.isInLibrary && !book.isArchived else { return false }
            switch self {
            case .unstarted: return book.readingStatus == .toRead && book.lastOpenedAt == nil && book.currentPage == 0
            case .paused: return book.readingStatus == .reading && (book.lastReadAt ?? book.addedAt) < cutoff
            case .completedYear: return completedIDs.contains(book.id)
            case .annotated: return annotatedIDs.contains(book.id)
            }
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}

enum BookHubMaintenance {
    // Same ISBN, or same normalized title AND known author, is a review candidate, never an automatic deletion.
    static func duplicateGroups(in books: [ComicBook]) -> [[ComicBook]] {
        var groups: [String: [ComicBook]] = [:]
        for book in books where book.contentKind == .book && book.isInLibrary && !book.isArchived {
            let key: String
            if let isbn = BookISBN.normalized(book.bookMetadata?.isbn ?? "") { key = "isbn:" + isbn }
            else {
                let authors = (book.bookMetadata?.authors ?? []).map { BookLibraryQuery.fold($0.trimmingCharacters(in: .whitespacesAndNewlines)) }.filter { !$0.isEmpty }.sorted().joined(separator: "|")
                guard !authors.isEmpty else { continue }
                key = "title:" + BookLibraryQuery.fold(book.title) + ":" + authors
            }
            groups[key, default: []].append(book)
        }
        return groups.values.filter { $0.count > 1 }.map { $0.sorted { $0.title < $1.title } }
            .sorted { $0[0].title < $1[0].title }
    }
}

struct BookHubExcerpt: Identifiable, Sendable {
    let id: String
    let bookID: UUID
    let title: String
    let authors: [String]
    let page: Int
    let isChapter: Bool
    let text: String
    let isHighlight: Bool

    var locationLabel: String { "\(isChapter ? "Bölüm" : "Sayfa") \(page + 1)" }
    static func markdown(_ excerpts: [BookHubExcerpt]) -> String {
        "# Book Hub — Alıntılar ve Notlar\n\n" + excerpts.map { entry in
            "## \(entry.title.replacingOccurrences(of: "\n", with: " "))\n\n\(entry.authors.joined(separator: ", ")) · \(entry.locationLabel) · \(entry.isHighlight ? "Alıntı" : "Not")\n\n" + entry.text.components(separatedBy: .newlines).map { "> " + $0 }.joined(separator: "\n")
        }.joined(separator: "\n\n") + "\n"
    }
}

struct BookHubMilestones {
    let completedAuthors: Int
    let completedCollections: Int
    init(books: [ComicBook], collections: [BookHubCollection]) {
        let books = books.filter { $0.contentKind == .book }
        let completed = books.filter { $0.readingStatus == .completed }
        completedAuthors = Set(completed.flatMap { $0.bookMetadata?.authors ?? [] }.map { BookLibraryQuery.fold($0.trimmingCharacters(in: .whitespacesAndNewlines)) }.filter { !$0.isEmpty }).count
        let ids = Set(completed.map(\.id))
        completedCollections = collections.filter { !$0.bookIDs.isEmpty && $0.bookIDs.isSubset(of: ids) }.count
    }
}
