import Foundation

struct CharacterLibraryService {
    static func profiles(from comics: [ComicBook]) -> [CharacterProfile] {
        var buckets: [String: (String, CharacterUniverse, [UUID])] = [:]
        for comic in comics {
            for hit in matches(in: comic.title) {
                var entry = buckets[hit.key] ?? (hit.name, hit.universe, [])
                if !entry.2.contains(comic.id) { entry.2.append(comic.id) }
                buckets[hit.key] = entry
            }
        }
        return buckets.map { key, value in
            CharacterProfile(id: key, name: value.0, universe: value.1, comicIDs: value.2)
        }.sorted {
            if $0.comicIDs.count == $1.comicIDs.count { return $0.name < $1.name }
            return $0.comicIDs.count > $1.comicIDs.count
        }
    }

    private static func matches(in title: String) -> [(key: String, name: String, universe: CharacterUniverse)] {
        let t = title.lowercased()
        let catalog: [(String, String, String, CharacterUniverse)] = [
            ("nightwing", "nightwing", "Nightwing", .dc),
            ("batman", "batman", "Batman", .dc),
            ("superman", "superman", "Superman", .dc),
            ("the-flash", "flash", "The Flash", .dc),
            ("green-lantern", "green lantern", "Green Lantern", .dc),
            ("wonder-woman", "wonder woman", "Wonder Woman", .dc),
            ("justice-league", "justice league", "Justice League", .dc),
            ("teen-titans", "teen titans", "Teen Titans", .dc),
            ("spider-man", "spider-man", "Spider-Man", .marvel),
            ("spider-man", "spiderman", "Spider-Man", .marvel),
            ("daredevil", "daredevil", "Daredevil", .marvel),
            ("wolverine", "wolverine", "Wolverine", .marvel),
            ("thor", "thor", "Thor", .marvel),
            ("captain-america", "captain america", "Captain America", .marvel),
            ("iron-man", "iron man", "Iron Man", .marvel),
            ("hulk", "hulk", "Hulk", .marvel),
            ("x-men", "x-men", "X-Men", .marvel),
            ("avengers", "avengers", "Avengers", .marvel),
            ("fantastic-four", "fantastic four", "Fantastic Four", .marvel)
        ]
        var seen = Set<String>()
        return catalog.compactMap { item in
            guard t.contains(item.1), !seen.contains(item.0) else { return nil }
            seen.insert(item.0)
            return (item.0, item.2, item.3)
        }
    }
}
