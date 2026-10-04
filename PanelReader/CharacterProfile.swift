import Foundation

struct CharacterProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let universe: CharacterUniverse
    let comicIDs: [UUID]
}

enum CharacterUniverse: String, CaseIterable, Identifiable {
    case dc = "DC"
    case marvel = "Marvel"
    case other = "Other"
    var id: String { rawValue }
}
