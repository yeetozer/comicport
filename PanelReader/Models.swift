import Foundation

enum ComicType: String, Codable, Sendable {
    case pdf
    case cbz
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case reading = "Reading"
    case toRead = "To Read"
    case completed = "Completed"

    var id: String { rawValue }
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

struct ComicBook: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var storedFileName: String
    var type: ComicType
    var pageCount: Int
    var currentPage: Int
    var addedAt: Date
    var thumbnailFileName: String?
    var rightToLeft: Bool
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
        rightToLeft: Bool = false,
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
        self.rightToLeft = rightToLeft
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
        return min(1, Double(currentPage + 1) / Double(pageCount))
    }

    var progressPercent: Int { Int((progress * 100).rounded()) }

    private enum CodingKeys: String, CodingKey {
        case id, title, storedFileName, type, pageCount, currentPage, addedAt, thumbnailFileName, rightToLeft
        case readingStatus, favorite, rating, lastOpenedAt, lastReadAt
        case sourceIdentity, isInLibrary, fileAvailable, isArchived
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
        thumbnailFileName = try c.decodeIfPresent(String.self, forKey: .thumbnailFileName)
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
