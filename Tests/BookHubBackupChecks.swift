import Foundation

@main struct BookHubBackupChecks {
    static func main() throws {
        var state = BookHubState()
        state.goals.enabled = true
        let oldID = UUID(), newID = UUID()
        state.collections = [BookHubCollection(name: "Raf", bookIDs: [oldID])]
        state.completions = [BookHubCompletion(bookID: oldID, date: Date(timeIntervalSince1970: 1000))]
        state.reachedDailyGoals = ["2026-10-08"]
        state.reachedAnnualGoals = [2026]
        let payload = PanelBackupPayload(schemaVersion: 4, createdAt: .now, appVersion: "test", books: [], analytics: ReadingAnalytics(), achievementProfile: AchievementProfile(), readerSettingsByBook: [:], defaultReaderSettings: ReaderSettings(), storyArcs: [], autoOpenNextIssue: false, textNotes: [], savedPanels: [], readingJournal: [], smartCollections: [], bookHub: state, pencilDrawings: [], panelImages: [], bookInfoFiles: [], accentThemeRawValue: "test")
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(PanelBackupPayload.self, from: data)
        precondition(decoded.bookHub?.collections == state.collections && decoded.bookHub?.reachedAnnualGoals == [2026])
        var legacy = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        legacy.removeValue(forKey: "bookHub"); legacy["schemaVersion"] = 3
        for schema in [1, 2, 3] {
            legacy["schemaVersion"] = schema
            if schema < 3 { legacy.removeValue(forKey: "smartCollections"); legacy.removeValue(forKey: "readingJournal") }
            let older = try JSONDecoder().decode(PanelBackupPayload.self, from: JSONSerialization.data(withJSONObject: legacy))
            precondition(older.bookHub == nil)
        }
        let first = BookHubState().merging(state, bookIDMap: [oldID: newID])
        let twice = first.merging(state, bookIDMap: [oldID: newID])
        precondition(twice.collections.count == 1 && twice.collections[0].bookIDs == [newID])
        precondition(twice.completions.count == 1 && twice.completions[0].bookID == newID)
        precondition(twice.reachedDailyGoals == state.reachedDailyGoals)
        print("PASS: production schema-4 Book Hub backup, schema-3 compatibility, remapped collection/completion IDs, idempotent restore")
    }
}
