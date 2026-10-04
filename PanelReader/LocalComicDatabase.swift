import Foundation

struct LocalComicRecord: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var aliases: [String]
    var publisher: String
    var year: Int?
    var creators: [String]
    var characters: [String]
    var description: String
    var tags: [String]
    var sourceNote: String?
}

struct LocalComicMatch: Hashable, Sendable {
    var record: LocalComicRecord
    var confidence: Int
    var matchedAlias: String
}

private final class LocalComicMatchBox: NSObject {
    let match: LocalComicMatch?
    init(_ match: LocalComicMatch?) { self.match = match }
}

enum LocalComicDatabase {
    static let records: [LocalComicRecord] = loadBundledRecords()
    private static let titleMatchCache: NSCache<NSString, LocalComicMatchBox> = {
        let cache = NSCache<NSString, LocalComicMatchBox>()
        cache.countLimit = 1600
        return cache
    }()

    static func bestMatch(title: String, OCRText: String = "") -> LocalComicMatch? {
        let titleNorm = normalize(title)
        let ocrNorm = normalize(OCRText)
        guard !titleNorm.isEmpty else { return nil }

        if OCRText.isEmpty, let cached = titleMatchCache.object(forKey: titleNorm as NSString) {
            return cached.match
        }

        var best: LocalComicMatch?
        for record in records {
            let candidates = [record.title] + record.aliases
            for candidate in candidates {
                let candidateNorm = normalize(candidate)
                guard !candidateNorm.isEmpty else { continue }

                var score = 0
                if titleNorm == candidateNorm { score = 100 }
                else if titleNorm.contains(candidateNorm) || candidateNorm.contains(titleNorm) { score = 92 }
                else {
                    let a = Set(titleNorm.split(separator: " ").map(String.init))
                    let b = Set(candidateNorm.split(separator: " ").map(String.init))
                    let union = a.union(b)
                    let overlap = union.isEmpty ? 0 : Double(a.intersection(b).count) / Double(union.count)
                    score = Int((overlap * 85).rounded())
                }

                if !ocrNorm.isEmpty {
                    if ocrNorm.contains(normalize(record.title)) { score = max(score, 94) }
                    if record.creators.contains(where: { ocrNorm.contains(normalize($0)) }) { score += 3 }
                    if ocrNorm.contains(normalize(record.publisher)) { score += 2 }
                }
                score = min(100, score)

                if score >= 58, score > (best?.confidence ?? -1) {
                    best = LocalComicMatch(record: record, confidence: score, matchedAlias: candidate)
                }
            }
        }
        if OCRText.isEmpty {
            titleMatchCache.setObject(LocalComicMatchBox(best), forKey: titleNorm as NSString)
        }
        return best
    }

    private static func loadBundledRecords() -> [LocalComicRecord] {
        guard let url = Bundle.main.url(forResource: "LocalComicDatabase", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([LocalComicRecord].self, from: data) else {
            return []
        }
        return decoded
    }

    private static func normalize(_ raw: String) -> String {
        raw.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\b(omnibus|deluxe|edition|hardcover|paperback|hc|tpb|complete|collection|absolute)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
