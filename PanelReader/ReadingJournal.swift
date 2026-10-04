import Foundation

struct ReadingJournalEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let bookID: UUID
    var completedAt: Date
    var rating: Int
    var note: String
    var wouldReread: Bool
    var favoritePanelID: UUID?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        bookID: UUID,
        completedAt: Date = .now,
        rating: Int = 0,
        note: String = "",
        wouldReread: Bool = false,
        favoritePanelID: UUID? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.bookID = bookID
        self.completedAt = completedAt
        self.rating = max(0, min(5, rating))
        self.note = note
        self.wouldReread = wouldReread
        self.favoritePanelID = favoritePanelID
        self.updatedAt = updatedAt
    }
}

struct ReadingJournalSummary: Sendable {
    let totalEntries: Int
    let averageRating: Double
    let rereadCount: Int
    let notesCount: Int

    static func make(from entries: [ReadingJournalEntry]) -> ReadingJournalSummary {
        let ratings = entries.map(\.rating).filter { $0 > 0 }
        let average = ratings.isEmpty ? 0 : Double(ratings.reduce(0, +)) / Double(ratings.count)
        return ReadingJournalSummary(
            totalEntries: entries.count,
            averageRating: average,
            rereadCount: entries.filter(\.wouldReread).count,
            notesCount: entries.filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        )
    }
}
