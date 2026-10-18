import Foundation

private final class ParsedSeriesInfoBox: NSObject {
    let value: ParsedComicSeriesInfo
    init(_ value: ParsedComicSeriesInfo) { self.value = value }
}


enum ComicEdition: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case standard = "Standard"
    case omnibus = "Omnibus"
    case deluxe = "Deluxe"
    case absolute = "Absolute"
    case complete = "Complete"
    case collection = "Collection"

    var id: String { rawValue }
}

struct ParsedComicSeriesInfo: Hashable, Sendable {
    var seriesTitle: String
    var issueNumber: Double?
    var volume: Int?
    var year: Int?
    var edition: ComicEdition
}

struct ComicSeries: Identifiable, Hashable {
    var id: String
    var title: String
    var bookIDs: [UUID]
    var editions: Set<ComicEdition>
}

struct StoryArc: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var bookIDs: [UUID]
    var createdAt: Date = .now
}


struct SeriesMissingIssue: Identifiable, Hashable, Sendable {
    let seriesID: String
    let seriesTitle: String
    let volume: Int?
    let issueNumber: Int

    var id: String { "\(seriesID)|\(volume ?? 0)|\(issueNumber)" }
}

struct SeriesDuplicateIssue: Identifiable, Hashable, Sendable {
    let seriesID: String
    let seriesTitle: String
    let volume: Int?
    let issueNumber: Double
    let bookIDs: [UUID]

    var id: String { "\(seriesID)|\(volume ?? 0)|\(issueNumber)" }
}

struct RelatedReadingBook: Sendable {
    let id: UUID
    let title: String
}

struct RelatedReadingSuggestion: Identifiable, Hashable, Sendable {
    let bookID: UUID
    let title: String
    let score: Double
    let reason: String

    var id: UUID { bookID }
}

enum ReadingOrder2Service {
    static func relatedSuggestions(
        seriesTitles: [String],
        candidates: [RelatedReadingBook],
        limit: Int = 8
    ) -> [RelatedReadingSuggestion] {
        let sourceMatches = seriesTitles.compactMap { LocalComicDatabase.bestMatch(title: $0)?.record }
        guard !sourceMatches.isEmpty else { return [] }

        let sourceCharacters = Set(sourceMatches.flatMap(\.characters).map(normalize))
        let sourceTags = Set(sourceMatches.flatMap(\.tags).map(normalize))
        let sourceCreators = Set(sourceMatches.flatMap(\.creators).map(normalize))
        let sourcePublishers = Set(sourceMatches.map { normalize($0.publisher) })

        var output: [RelatedReadingSuggestion] = []
        for candidate in candidates {
            guard let record = LocalComicDatabase.bestMatch(title: candidate.title)?.record else { continue }

            let characters = Set(record.characters.map(normalize))
            let tags = Set(record.tags.map(normalize))
            let creators = Set(record.creators.map(normalize))

            let sharedCharacters = sourceCharacters.intersection(characters)
            let sharedTags = sourceTags.intersection(tags)
            let sharedCreators = sourceCreators.intersection(creators)
            let samePublisher = sourcePublishers.contains(normalize(record.publisher))

            var score = Double(sharedCharacters.count) * 5.0
            score += Double(sharedTags.count) * 2.0
            score += Double(sharedCreators.count) * 1.4
            if samePublisher { score += 0.6 }
            guard score >= 2.5 else { continue }

            let reason: String
            if let character = sharedCharacters.sorted().first {
                reason = "Ortak karakter: \(display(character))"
            } else if let tag = sharedTags.sorted().first {
                reason = "Ortak tema: \(display(tag))"
            } else if let creator = sharedCreators.sorted().first {
                reason = "Shared creator: \(display(creator))"
            } else {
                reason = "Related publishing universe"
            }

            output.append(
                RelatedReadingSuggestion(
                    bookID: candidate.id,
                    title: candidate.title,
                    score: score,
                    reason: reason
                )
            )
        }

        return Array(
            output.sorted {
                if abs($0.score - $1.score) > 0.01 { return $0.score > $1.score }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }.prefix(limit)
        )
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func display(_ value: String) -> String {
        value.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}

enum SeriesService {
    private static let parseCache: NSCache<NSString, ParsedSeriesInfoBox> = {
        let cache = NSCache<NSString, ParsedSeriesInfoBox>()
        cache.countLimit = 4000
        return cache
    }()

    static func parse(_ title: String) -> ParsedComicSeriesInfo {
        let cacheKey = title as NSString
        if let cached = parseCache.object(forKey: cacheKey) {
            return cached.value
        }

        var working = title
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: ".", with: " ")

        let lower = working.lowercased()
        let edition: ComicEdition
        if lower.contains("omnibus") { edition = .omnibus }
        else if lower.contains("absolute") { edition = .absolute }
        else if lower.contains("deluxe") { edition = .deluxe }
        else if lower.contains("complete") { edition = .complete }
        else if lower.contains("collection") || lower.contains("tpb") { edition = .collection }
        else { edition = .standard }

        let year = firstIntMatch(in: working, pattern: #"\(((?:19|20)\d{2})\)"#)
            ?? firstIntMatch(in: working, pattern: #"\b((?:19|20)\d{2})\b"#)

        let volume = firstIntMatch(in: working, pattern: #"(?i)\bvol(?:ume)?\.?\s*(\d{1,3})\b"#)

        var issue: Double?
        if let value = firstStringMatch(in: working, pattern: #"(?i)#\s*(\d+(?:\.\d+)?)"#) {
            issue = Double(value)
        } else if let value = firstStringMatch(in: working, pattern: #"(?i)\b(?:issue|chapter|ch)\.?\s*#?\s*(\d+(?:\.\d+)?)\b"#) {
            issue = Double(value)
        }

        // Remove metadata-like parts to derive a stable series name.
        let removalPatterns = [
            #"\((?:19|20)\d{2}\)"#,
            #"(?i)#\s*\d+(?:\.\d+)?"#,
            #"(?i)\b(?:issue|chapter|ch)\.?\s*#?\s*\d+(?:\.\d+)?\b"#,
            #"(?i)\bvol(?:ume)?\.?\s*\d{1,3}\b"#,
            #"(?i)\b(omnibus|absolute|deluxe|complete|collection|edition|hardcover|paperback|hc|tpb)\b"#,
            #"(?i)\b(?:digital|web|scan)\b"#
        ]
        for pattern in removalPatterns {
            working = working.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }

        working = working
            .replacingOccurrences(of: #"[\[\]\(\)\{\}_\-–—]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        if working.isEmpty {
            working = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let result = ParsedComicSeriesInfo(
            seriesTitle: working,
            issueNumber: issue,
            volume: volume,
            year: year,
            edition: edition
        )
        parseCache.setObject(ParsedSeriesInfoBox(result), forKey: cacheKey)
        return result
    }

    static func series(from books: [ComicBook]) -> [ComicSeries] {
        var buckets: [String: (title: String, books: [ComicBook], editions: Set<ComicEdition>)] = [:]

        for book in books {
            let info = parse(book.title)
            let key = normalizedKey(info.seriesTitle)
            guard !key.isEmpty else { continue }

            var bucket = buckets[key] ?? (info.seriesTitle, [], [])
            bucket.books.append(book)
            bucket.editions.insert(info.edition)
            buckets[key] = bucket
        }

        return buckets.map { key, bucket in
            let sorted = bucket.books.sorted(by: readingOrder)
            return ComicSeries(id: key, title: bucket.title, bookIDs: sorted.map(\.id), editions: bucket.editions)
        }
        .sorted { lhs, rhs in
            if lhs.bookIDs.count == rhs.bookIDs.count {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return lhs.bookIDs.count > rhs.bookIDs.count
        }
    }

    static func books(in series: ComicSeries, from books: [ComicBook]) -> [ComicBook] {
        let ids = Set(series.bookIDs)
        return books.filter { ids.contains($0.id) }.sorted(by: readingOrder)
    }

    static func series(containing bookID: UUID, in books: [ComicBook]) -> ComicSeries? {
        guard let current = books.first(where: { $0.id == bookID }) else { return nil }
        let parsed = parse(current.title)
        let key = normalizedKey(parsed.seriesTitle)
        guard !key.isEmpty else { return nil }

        let matching = books.filter { normalizedKey(parse($0.title).seriesTitle) == key }
            .sorted(by: readingOrder)
        guard !matching.isEmpty else { return nil }

        return ComicSeries(
            id: key,
            title: parsed.seriesTitle,
            bookIDs: matching.map(\.id),
            editions: Set(matching.map { parse($0.title).edition })
        )
    }

    static func nextIssue(after bookID: UUID, in books: [ComicBook]) -> ComicBook? {
        guard let series = series(containing: bookID, in: books) else { return nil }
        let ordered = self.books(in: series, from: books)
        guard let index = ordered.firstIndex(where: { $0.id == bookID }),
              ordered.indices.contains(index + 1) else { return nil }
        return ordered[index + 1]
    }

    static func previousIssue(before bookID: UUID, in books: [ComicBook]) -> ComicBook? {
        guard let series = series(containing: bookID, in: books) else { return nil }
        let ordered = self.books(in: series, from: books)
        guard let index = ordered.firstIndex(where: { $0.id == bookID }), index > 0 else { return nil }
        return ordered[index - 1]
    }

    static func missingIssues(in series: ComicSeries, from books: [ComicBook]) -> [SeriesMissingIssue] {
        let seriesBooks = self.books(in: series, from: books)
        var byVolume: [Int: Set<Int>] = [:]

        for book in seriesBooks {
            let parsed = parse(book.title)
            guard parsed.edition == .standard,
                  let value = parsed.issueNumber,
                  value.rounded() == value else { continue }
            byVolume[parsed.volume ?? 0, default: []].insert(Int(value))
        }

        var missing: [SeriesMissingIssue] = []
        for (volumeKey, values) in byVolume {
            guard let low = values.min(), let high = values.max(),
                  high > low, high - low <= 80 else { continue }
            for issue in low...high where !values.contains(issue) {
                missing.append(
                    SeriesMissingIssue(
                        seriesID: series.id,
                        seriesTitle: series.title,
                        volume: volumeKey == 0 ? nil : volumeKey,
                        issueNumber: issue
                    )
                )
            }
        }

        return missing.sorted {
            if ($0.volume ?? 0) != ($1.volume ?? 0) { return ($0.volume ?? 0) < ($1.volume ?? 0) }
            return $0.issueNumber < $1.issueNumber
        }
    }

    static func duplicateIssueNumbers(in series: ComicSeries, from books: [ComicBook]) -> [SeriesDuplicateIssue] {
        let seriesBooks = self.books(in: series, from: books)
        var buckets: [String: (volume: Int?, issue: Double, ids: [UUID])] = [:]

        for book in seriesBooks {
            let parsed = parse(book.title)
            guard parsed.edition == .standard, let issue = parsed.issueNumber else { continue }
            let key = "\(parsed.volume ?? 0)|\(issue)"
            var bucket = buckets[key] ?? (parsed.volume, issue, [])
            bucket.ids.append(book.id)
            buckets[key] = bucket
        }

        return buckets.values.compactMap { bucket in
            guard bucket.ids.count > 1 else { return nil }
            return SeriesDuplicateIssue(
                seriesID: series.id,
                seriesTitle: series.title,
                volume: bucket.volume,
                issueNumber: bucket.issue,
                bookIDs: bucket.ids
            )
        }
        .sorted { $0.issueNumber < $1.issueNumber }
    }

    static func allMissingIssues(in books: [ComicBook]) -> [SeriesMissingIssue] {
        series(from: books).flatMap { missingIssues(in: $0, from: books) }
    }

    static func allDuplicateIssues(in books: [ComicBook]) -> [SeriesDuplicateIssue] {
        series(from: books).flatMap { duplicateIssueNumbers(in: $0, from: books) }
    }

    static func maxCompletedIssuesInOneSeries(books: [ComicBook]) -> Int {
        series(from: books).map { series in
            self.books(in: series, from: books).filter { $0.readingStatus == .completed }.count
        }.max() ?? 0
    }

    private static func readingOrder(_ lhs: ComicBook, _ rhs: ComicBook) -> Bool {
        let a = parse(lhs.title)
        let b = parse(rhs.title)

        let av = a.volume ?? 0
        let bv = b.volume ?? 0
        if av != bv { return av < bv }

        switch (a.issueNumber, b.issueNumber) {
        case let (x?, y?) where x != y: return x < y
        case (_?, nil): return true
        case (nil, _?): return false
        default:
            if lhs.addedAt != rhs.addedAt { return lhs.addedAt < rhs.addedAt }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private static func normalizedKey(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func firstIntMatch(in text: String, pattern: String) -> Int? {
        guard let result = firstStringMatch(in: text, pattern: pattern) else { return nil }
        let digits = result.filter(\.isNumber)
        return Int(digits)
    }

    private static func firstStringMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
