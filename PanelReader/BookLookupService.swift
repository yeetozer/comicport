import Foundation

struct BookLookupSuggestion: Sendable {
    let metadata: BookBibliography
    let coverID: Int?
}

enum BookLookupError: LocalizedError {
    case invalidISBN, notFound, unavailable, invalidResponse
    var errorDescription: String? {
        switch self {
        case .invalidISBN: return "Önce geçerli bir ISBN-10 veya ISBN-13 gir."
        case .notFound: return "Bu ISBN için Open Library kaydı bulunamadı."
        case .unavailable: return "Open Library şu anda yanıt vermiyor. Daha sonra tekrar deneyebilirsin."
        case .invalidResponse: return "Kitap bilgisi yanıtı okunamadı."
        }
    }
}

struct OpenLibraryEdition: Decodable {
    struct Reference: Decodable { let key: String }
    struct Description: Decodable {
        let value: String
        init(from decoder: Decoder) throws {
            if let text = try? decoder.singleValueContainer().decode(String.self) { value = text }
            else { value = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .value) }
        }
        enum CodingKeys: String, CodingKey { case value }
    }
    let title: String
    let authors: [Reference]?
    let publishers: [String]?
    let publish_date: String?
    let languages: [Reference]?
    let covers: [Int]?
    let description: Description?

    func suggestion(isbn: String, authors names: [String]) -> BookLookupSuggestion {
        let year = publish_date.flatMap { date -> String? in
            guard let range = date.range(of: "(?:18|19|20|21)[0-9]{2}", options: .regularExpression) else { return nil }
            return String(date[range])
        }
        let language = languages?.first?.key.components(separatedBy: "/").last.map { ["eng": "en", "tur": "tr", "fra": "fr", "deu": "de", "spa": "es"][$0] ?? $0 }
        var metadata = BookBibliography(title: title, authors: names, publisher: publishers?.first, isbn: isbn, language: language, publicationYear: year, summary: description?.value)
        for field in ["title", "authors", "publisher", "isbn", "language", "publicationYear", "summary"] { metadata.sources[field] = .online }
        return BookLookupSuggestion(metadata: metadata, coverID: covers?.first(where: { $0 > 0 }))
    }
}

extension BookBibliography {
    func fillingMissingFields(from suggestion: BookBibliography) -> BookBibliography {
        var result = self
        func blank(_ value: String?) -> Bool { value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true }
        for (field, value) in [("title", suggestion.title), ("publisher", suggestion.publisher), ("isbn", suggestion.isbn), ("language", suggestion.language), ("publicationYear", suggestion.publicationYear), ("summary", suggestion.summary)] {
            guard sources[field] != .manual, !blank(value) else { continue }
            let current: String?
            switch field {
            case "title": current = title
            case "publisher": current = publisher
            case "isbn": current = isbn
            case "language": current = language
            case "publicationYear": current = publicationYear
            default: current = summary
            }
            guard blank(current) else { continue }
            switch field {
            case "title": result.title = value
            case "publisher": result.publisher = value
            case "isbn": result.isbn = value.flatMap(BookISBN.normalized)
            case "language": result.language = value
            case "publicationYear": result.publicationYear = value
            default: result.summary = value
            }
            result.sources[field] = .online
        }
        if sources["authors"] != .manual && authors.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) && !suggestion.authors.isEmpty {
            result.authors = suggestion.authors
            result.sources["authors"] = .online
        }
        return result
    }
}

actor BookLookupService {
    static let shared = BookLookupService()
    private var cache: [String: (Date, BookLookupSuggestion)] = [:]
    private var inFlight: [String: Task<BookLookupSuggestion, Error>] = [:]
    private var lastSlot = Date.distantPast
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.httpMaximumConnectionsPerHost = 2
        configuration.httpAdditionalHeaders = ["User-Agent": "ComicPort/2.3 (ISBN metadata lookup)"]
        return URLSession(configuration: configuration)
    }()

    func lookup(isbn raw: String) async throws -> BookLookupSuggestion {
        guard let isbn = BookISBN.normalized(raw) else { throw BookLookupError.invalidISBN }
        if let (date, value) = cache[isbn], Date().timeIntervalSince(date) < 86400 { return value }
        if let task = inFlight[isbn] { return try await task.value }
        let task = Task { try await self.fetch(isbn: isbn) }
        inFlight[isbn] = task
        defer { inFlight[isbn] = nil }
        let result = try await task.value
        if cache.count >= 24, let oldest = cache.min(by: { $0.value.0 < $1.value.0 })?.key { cache[oldest] = nil }
        cache[isbn] = (.now, result)
        return result
    }

    func cover(id: Int) async throws -> Data {
        guard id > 0, let url = URL(string: "https://covers.openlibrary.org/b/id/\(id)-L.jpg?default=false") else { throw BookLookupError.invalidResponse }
        return try await request(url, limit: 5 * 1024 * 1024)
    }

    private func fetch(isbn: String) async throws -> BookLookupSuggestion {
        let url = URL(string: "https://openlibrary.org/isbn/\(isbn).json")!
        let data = try await request(url, limit: 1024 * 1024)
        guard let edition = try? JSONDecoder().decode(OpenLibraryEdition.self, from: data) else { throw BookLookupError.invalidResponse }
        var names: [String] = []
        struct Author: Decodable { let name: String }
        for reference in (edition.authors ?? []).prefix(5) {
            guard reference.key.range(of: "^/authors/OL[0-9]+A$", options: .regularExpression) != nil else { continue }
            let authorURL = URL(string: "https://openlibrary.org\(reference.key).json")!
            if let authorData = try? await request(authorURL, limit: 1024 * 1024), let author = try? JSONDecoder().decode(Author.self, from: authorData) { names.append(author.name) }
        }
        return edition.suggestion(isbn: isbn, authors: names)
    }

    private func request(_ url: URL, limit: Int) async throws -> Data {
        let slot = max(Date(), lastSlot.addingTimeInterval(1))
        lastSlot = slot
        let delay = slot.timeIntervalSinceNow
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw BookLookupError.invalidResponse }
        if http.statusCode == 404 { throw BookLookupError.notFound }
        guard http.statusCode == 200 else { throw BookLookupError.unavailable }
        guard data.count <= limit else { throw BookLookupError.invalidResponse }
        return data
    }
}
