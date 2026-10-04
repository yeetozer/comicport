import Foundation

struct ComicRecommendationSignal: Sendable {
    let title: String
    let tasteWeight: Double
}

struct ComicRecommendationOccasion: Hashable, Sendable {
    let eventID: String
    let title: String
    let date: Date
    let daysAway: Int
    let keywords: [String]
    let broadTheme: Bool

    static func upcoming(
        from now: Date = .now,
        withinDays: Int = 30,
        calendar: Calendar = .current
    ) -> ComicRecommendationOccasion? {
        let start = calendar.startOfDay(for: now)

        // Check several upcoming events instead of only the first one. This prevents a
        // generic community day from hiding a nearby Batman/Spider-Man/etc. occasion.
        let candidates: [ComicRecommendationOccasion] = ComicCalendarService
            .upcoming(from: now, count: 8, calendar: calendar)
            .compactMap { eventDate, event in
                let day = calendar.startOfDay(for: eventDate)
                let days = max(0, calendar.dateComponents([.day], from: start, to: day).day ?? 0)
                guard days <= withinDays else { return nil }

                let config = occasionConfig(eventID: event.id, title: event.title)
                return ComicRecommendationOccasion(
                    eventID: event.id,
                    title: event.title,
                    date: day,
                    daysAway: days,
                    keywords: config.keywords,
                    broadTheme: config.broad
                )
            }

        // Specific character/creator occasions beat generic comic-reading days.
        return candidates.sorted {
            if $0.broadTheme != $1.broadTheme { return !$0.broadTheme }
            return $0.daysAway < $1.daysAway
        }.first
    }

    private static func occasionConfig(
        eventID: String,
        title: String
    ) -> (keywords: [String], broad: Bool) {
        let text = (eventID + " " + title)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        if text.contains("superman") {
            return (["superman", "clark kent", "lois lane", "krypton", "lex luthor"], false)
        }
        if text.contains("x-men") || text.contains("x men") {
            return (["x-men", "x men", "wolverine", "cyclops", "storm", "magneto", "mutant"], false)
        }
        if text.contains("spider-man") || text.contains("spider man") {
            return (["spider-man", "spider man", "peter parker", "miles morales", "venom", "green goblin"], false)
        }
        if text.contains("batman") {
            return (["batman", "bruce wayne", "gotham", "nightwing", "robin", "joker", "batgirl"], false)
        }
        if text.contains("wonder woman") {
            return (["wonder woman", "diana", "themyscira", "amazon"], false)
        }
        if text.contains("jack kirby") {
            return (["jack kirby", "fantastic four", "thor", "captain america", "new gods"], false)
        }
        if text.contains("stan lee") {
            return (["stan lee", "spider-man", "x-men", "fantastic four", "hulk", "iron man", "thor"], false)
        }

        return ([], true)
    }
}

struct ComicRecommendation: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let publisher: String
    let year: Int?
    let reason: String
    let score: Double
    let occasionTitle: String?
    let occasionDate: Date?
    let daysUntilOccasion: Int?
}

enum ComicRecommendationEngine {
    static func build(
        signals: [ComicRecommendationSignal],
        catalog: [LocalComicRecord],
        occasion: ComicRecommendationOccasion? = nil,
        limit: Int = 48
    ) -> [ComicRecommendation] {
        let curated = catalog.filter { record in
            let source = (record.sourceNote ?? "").lowercased()
            return source.contains("curated") || source.contains("starter")
        }
        let candidates = curated.isEmpty ? catalog : curated
        guard !candidates.isEmpty else { return [] }

        let normalizedCatalog: [(record: LocalComicRecord, names: [String])] = candidates.map { record in
            let names = ([record.title] + record.aliases)
                .map(normalize)
                .filter { !$0.isEmpty }
            return (record, names)
        }

        var ownedRecordIDs = Set<String>()
        var ownedTitles = Set<String>()
        var characterTaste: [String: Double] = [:]
        var tagTaste: [String: Double] = [:]
        var creatorTaste: [String: Double] = [:]
        var publisherTaste: [String: Double] = [:]

        for signal in signals {
            let signalTitle = normalize(signal.title)
            guard !signalTitle.isEmpty else { continue }
            ownedTitles.insert(signalTitle)

            guard let match = bestMatch(signalTitle: signalTitle, catalog: normalizedCatalog) else { continue }
            ownedRecordIDs.insert(match.id)
            let weight = max(0.5, signal.tasteWeight)

            for character in match.characters {
                characterTaste[normalize(character), default: 0] += weight
            }
            for tag in match.tags {
                tagTaste[normalize(tag), default: 0] += weight
            }
            for creator in match.creators {
                creatorTaste[normalize(creator), default: 0] += weight
            }
            publisherTaste[normalize(match.publisher), default: 0] += weight
        }

        // Brand-new libraries still receive a sensible rotating starter list.
        let hasTaste = !characterTaste.isEmpty || !tagTaste.isEmpty || !publisherTaste.isEmpty

        var recommendations: [ComicRecommendation] = []
        recommendations.reserveCapacity(candidates.count)

        for item in normalizedCatalog {
            let record = item.record
            guard !ownedRecordIDs.contains(record.id) else { continue }
            guard !item.names.contains(where: { name in
                ownedTitles.contains(name) || ownedTitles.contains(where: { $0.contains(name) || name.contains($0) })
            }) else { continue }

            var score = 0.0
            var bestCharacter: (String, Double)?
            var bestTag: (String, Double)?
            var bestCreator: (String, Double)?

            for character in record.characters {
                let key = normalize(character)
                let value = characterTaste[key, default: 0]
                score += value * 2.25
                if value > (bestCharacter?.1 ?? 0) { bestCharacter = (character, value) }
            }

            for tag in record.tags {
                let key = normalize(tag)
                let value = tagTaste[key, default: 0]
                score += value * 1.35
                if value > (bestTag?.1 ?? 0) { bestTag = (tag, value) }
            }

            for creator in record.creators {
                let key = normalize(creator)
                let value = creatorTaste[key, default: 0]
                score += value * 0.72
                if value > (bestCreator?.1 ?? 0) { bestCreator = (creator, value) }
            }

            let publisherScore = publisherTaste[normalize(record.publisher), default: 0]
            score += publisherScore * 0.34

            if !hasTaste {
                // Prefer the richer hand-curated records when there is no history yet.
                score = Double(record.characters.count) * 0.3 + Double(record.tags.count) * 0.22
            }

            let occasionRelevance = occasion.map { relevance(of: record, to: $0) } ?? 0
            if let occasion {
                if occasion.broadTheme {
                    score += max(2.0, 12.0 - Double(occasion.daysAway))
                } else if occasionRelevance > 0 {
                    // During the approach window, relevant comics must clearly beat
                    // unrelated taste matches. Personal taste still orders the relevant set.
                    score += 240.0 + occasionRelevance * 24.0 + max(0, 10.0 - Double(occasion.daysAway)) * 3.0
                } else {
                    score -= 38.0
                }
            }

            let reason: String
            if let occasion, occasion.broadTheme || occasionRelevance > 0 {
                reason = occasion.daysAway == 0
                    ? "\(occasion.title) bugün olduğu için bunu öneriyorum"
                    : "\(occasion.title) yaklaştığından bunu öneriyorum • \(occasion.daysAway) gün kaldı"
            } else if let bestCharacter, bestCharacter.1 > 0 {
                reason = "\(bestCharacter.0) ilgine göre"
            } else if let bestTag, bestTag.1 > 0 {
                reason = "\(bestTag.0) tarzını sevdiğin için"
            } else if let bestCreator, bestCreator.1 > 0 {
                reason = "\(bestCreator.0) ilgine göre"
            } else if publisherScore > 0 {
                reason = "\(displayPublisher(record.publisher)) okumalarına göre"
            } else {
                reason = "ComicPort'un offline seçkilerinden"
            }

            recommendations.append(
                ComicRecommendation(
                    id: record.id,
                    title: record.title,
                    publisher: displayPublisher(record.publisher),
                    year: record.year,
                    reason: reason,
                    score: score,
                    occasionTitle: occasionRelevance > 0 || occasion?.broadTheme == true ? occasion?.title : nil,
                    occasionDate: occasionRelevance > 0 || occasion?.broadTheme == true ? occasion?.date : nil,
                    daysUntilOccasion: occasionRelevance > 0 || occasion?.broadTheme == true ? occasion?.daysAway : nil
                )
            )
        }

        return Array(
            recommendations
                .sorted {
                    if abs($0.score - $1.score) > 0.01 { return $0.score > $1.score }
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                .prefix(limit)
        )
    }

    private static func relevance(of record: LocalComicRecord, to occasion: ComicRecommendationOccasion) -> Double {
        guard !occasion.broadTheme, !occasion.keywords.isEmpty else { return occasion.broadTheme ? 1 : 0 }

        let title = normalize(record.title)
        let aliases = record.aliases.map(normalize)
        let characters = record.characters.map(normalize)
        let tags = record.tags.map(normalize)
        let creators = record.creators.map(normalize)
        let description = normalize(record.description)

        var score = 0.0
        for keyword in occasion.keywords {
            let key = normalize(keyword)
            guard !key.isEmpty else { continue }

            if title.contains(key) { score += 7.0 }
            if aliases.contains(where: { $0.contains(key) || key.contains($0) }) { score += 5.5 }
            if characters.contains(where: { $0.contains(key) || key.contains($0) }) { score += 6.0 }
            if creators.contains(where: { $0.contains(key) || key.contains($0) }) { score += 4.5 }
            if tags.contains(where: { $0.contains(key) || key.contains($0) }) { score += 2.5 }
            if description.contains(key) { score += 1.5 }
        }
        return score
    }

    private static func bestMatch(
        signalTitle: String,
        catalog: [(record: LocalComicRecord, names: [String])]
    ) -> LocalComicRecord? {
        var bestRecord: LocalComicRecord?
        var bestScore = 0.0
        let signalTokens = Set(signalTitle.split(separator: " ").map(String.init))

        for item in catalog {
            for name in item.names {
                var score = 0.0
                if signalTitle == name {
                    score = 100
                } else if signalTitle.contains(name) || name.contains(signalTitle) {
                    score = 92
                } else {
                    let tokens = Set(name.split(separator: " ").map(String.init))
                    let union = signalTokens.union(tokens)
                    if !union.isEmpty {
                        score = Double(signalTokens.intersection(tokens).count) / Double(union.count) * 85
                    }
                }

                if score > bestScore {
                    bestScore = score
                    bestRecord = item.record
                }
            }
        }
        return bestScore >= 57 ? bestRecord : nil
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .replacingOccurrences(of: #"\((?:19|20)\d{2}\)"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"#\s*\d+(?:\.\d+)?"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\b(?:issue|chapter|ch|vol|volume)\.?\s*#?\s*\d+(?:\.\d+)?\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\b(omnibus|deluxe|edition|hardcover|paperback|hc|tpb|complete|collection|absolute|digital|scan)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func displayPublisher(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("dc") { return "DC Comics" }
        if lower.contains("marvel") { return "Marvel" }
        if lower.contains("image") { return "Image Comics" }
        if lower.contains("dark horse") { return "Dark Horse" }
        return raw
    }
}
