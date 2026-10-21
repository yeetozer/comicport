import Foundation
struct OfflineComicInfo: Sendable { let displayTitle: String }
actor AnalysisProbe {
    static let shared = AnalysisProbe()
    var calls = 0
    var active = 0
    var maxActive = 0
    func start() { calls += 1; active += 1; maxActive = max(maxActive, active) }
    func end() { active -= 1 }
    func snapshot() -> (Int, Int) { (calls, maxActive) }
}
enum BookInfoService {
    static func analyze(book: ComicBook, fileURL: URL) async throws -> OfflineComicInfo {
        await AnalysisProbe.shared.start()
        try await Task.sleep(nanoseconds: 80_000_000)
        await AnalysisProbe.shared.end()
        return OfflineComicInfo(displayTitle: book.title)
    }
}
@main struct QueueChecks {
    static func main() async throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        try Data("fixture".utf8).write(to: url)
        let books = (0..<9).map { ComicBook(title: "Queue \($0)", storedFileName: "fixture.pdf", type: .pdf, pageCount: 4, contentKind: .book) }
        let jobs = books.prefix(8).map { book in Task { try await BookMetadataIntelligence.shared.analyze(book: book, fileURL: url) } }
        try await Task.sleep(nanoseconds: 20_000_000)
        let duplicate = Task { try await BookMetadataIntelligence.shared.analyze(book: books[0], fileURL: url, force: true) }
        do {
            _ = try await BookMetadataIntelligence.shared.analyze(book: books[8], fileURL: url)
            fatalError("Queue accepted more than its pending limit")
        } catch BookMetadataIntelligence.AnalysisError.busy { }
        for job in jobs { _ = try await job.value }
        _ = try await duplicate.value
        let first = await AnalysisProbe.shared.snapshot()
        precondition(first.0 == 8 && first.1 == 1)
        _ = try await BookMetadataIntelligence.shared.analyze(book: books[0], fileURL: url)
        let cached = await AnalysisProbe.shared.snapshot()
        precondition(cached.0 == 8)
        try Data("modified fixture with different size".utf8).write(to: url)
        _ = try await BookMetadataIntelligence.shared.analyze(book: books[0], fileURL: url)
        let modified = await AnalysisProbe.shared.snapshot()
        precondition(modified.0 == 9 && modified.1 == 1)
        print("PASS: queue limit, serial execution, duplicate coalescing, cache hit, changed-file invalidation")
    }
}
