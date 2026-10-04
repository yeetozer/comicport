import Foundation

enum ComicMetadataAuthority: String, Codable, Hashable, Sendable {
    case verified = "Verified"
    case inferred = "Inferred"
}

struct ComicInfoMetadata: Codable, Hashable, Sendable {
    var title: String?
    var series: String?
    var number: String?
    var volume: Int?
    var count: Int?
    var year: Int?
    var month: Int?
    var day: Int?
    var summary: String?
    var publisher: String?
    var imprint: String?
    var writers: [String] = []
    var pencillers: [String] = []
    var inkers: [String] = []
    var colorists: [String] = []
    var letterers: [String] = []
    var coverArtists: [String] = []
    var editors: [String] = []
    var characters: [String] = []
    var teams: [String] = []
    var locations: [String] = []
    var genres: [String] = []
    var tags: [String] = []
    var storyArc: String?
    var seriesGroup: String?
    var languageISO: String?
    var format: String?
    var manga: String?
    var ageRating: String?
    var pageCount: Int?

    var creators: [String] {
        unique(writers + pencillers + inkers + colorists + letterers + coverArtists + editors)
    }

    var isRightToLeft: Bool {
        let value = (manga ?? "").lowercased()
        return value.contains("righttoleft") || value.contains("right-to-left")
    }

    var hasMeaningfulMetadata: Bool {
        title != nil || series != nil || number != nil || publisher != nil ||
        !creators.isEmpty || !characters.isEmpty || summary != nil
    }

    func displayTitle(fallback: String) -> String {
        let cleanSeries = series?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNumber = number?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let cleanSeries, !cleanSeries.isEmpty, let cleanNumber, !cleanNumber.isEmpty {
            if let cleanTitle, !cleanTitle.isEmpty,
               cleanTitle.caseInsensitiveCompare(cleanSeries) != .orderedSame {
                return "\(cleanSeries) #\(cleanNumber) — \(cleanTitle)"
            }
            return "\(cleanSeries) #\(cleanNumber)"
        }

        if let cleanTitle, !cleanTitle.isEmpty { return cleanTitle }
        if let cleanSeries, !cleanSeries.isEmpty { return cleanSeries }
        return fallback
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter {
            let key = $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, seen.insert(key).inserted else { return false }
            return true
        }
    }
}

enum ComicInfoService {
    static func metadata(from archiveURL: URL) -> ComicInfoMetadata? {
        guard let data = try? ComicArchiveService.comicInfoData(from: archiveURL),
              !data.isEmpty else { return nil }
        return ComicInfoXMLParser.parse(data: data)
    }
}

private final class ComicInfoXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var buffer = ""
    private var values: [String: String] = [:]

    static func parse(data: Data) -> ComicInfoMetadata? {
        let delegate = ComicInfoXMLParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else { return nil }
        return delegate.makeMetadata()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        buffer = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty {
            values[elementName] = value
        }
        currentElement = ""
        buffer = ""
    }

    private func makeMetadata() -> ComicInfoMetadata? {
        func string(_ key: String) -> String? {
            guard let value = values[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            return value
        }

        func integer(_ key: String) -> Int? {
            guard let value = string(key) else { return nil }
            return Int(value)
        }

        func list(_ key: String) -> [String] {
            guard let value = string(key) else { return [] }
            return value
                .components(separatedBy: CharacterSet(charactersIn: ",;"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        let metadata = ComicInfoMetadata(
            title: string("Title"),
            series: string("Series"),
            number: string("Number"),
            volume: integer("Volume"),
            count: integer("Count"),
            year: integer("Year"),
            month: integer("Month"),
            day: integer("Day"),
            summary: string("Summary"),
            publisher: string("Publisher"),
            imprint: string("Imprint"),
            writers: list("Writer"),
            pencillers: list("Penciller"),
            inkers: list("Inker"),
            colorists: list("Colorist"),
            letterers: list("Letterer"),
            coverArtists: list("CoverArtist"),
            editors: list("Editor"),
            characters: list("Characters"),
            teams: list("Teams"),
            locations: list("Locations"),
            genres: list("Genre"),
            tags: list("Tags"),
            storyArc: string("StoryArc"),
            seriesGroup: string("SeriesGroup"),
            languageISO: string("LanguageISO"),
            format: string("Format"),
            manga: string("Manga"),
            ageRating: string("AgeRating"),
            pageCount: integer("PageCount")
        )
        return metadata.hasMeaningfulMetadata ? metadata : nil
    }
}
