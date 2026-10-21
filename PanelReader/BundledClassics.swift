import Foundation
import CryptoKit

struct BundledClassic: Codable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let author: String
    let year: String
    let fileName: String
    let coverFileName: String
    let chapterCount: Int
    let sourceURL: URL
    let replacesSHA256: [String]?
    let sha256: String
    let summary: String
    let rights: String
}

enum BundledClassics {
    static let resourceDirectory = Bundle.main.resourceURL?.appendingPathComponent("BundledClassics", isDirectory: true)
    static let catalog = (resourceDirectory.flatMap { try? readCatalog(at: $0) }) ?? []

    static func readCatalog(at directory: URL) throws -> [BundledClassic] {
        let data = try Data(contentsOf: directory.appendingPathComponent("catalog.json"))
        let entries = try JSONDecoder().decode([BundledClassic].self, from: data)
        guard Set(entries.map(\.id)).count == entries.count,
              entries.allSatisfy({ $0.chapterCount > 0 && safeName($0.fileName) && safeName($0.coverFileName) }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return entries
    }

    private static func safeName(_ name: String) -> Bool {
        !name.isEmpty && !name.contains("/") && !name.contains("\\") && name != "." && name != ".."
    }

    /// Runs on the bootstrap worker. Receipts live beside library.json, not in
    /// UserDefaults: removing/archiving a starter book never reinstalls it.
    static func install(in documents: URL, existing: [ComicBook], resources: URL) throws -> [ComicBook] {
        let fm = FileManager.default
        let catalog = try readCatalog(at: resources)
        let receiptURL = documents.appendingPathComponent("bundled_classics_receipts.json")
        var receipts: Set<UUID> = []
        if fm.fileExists(atPath: receiptURL.path) {
            receipts = try JSONDecoder().decode(Set<UUID>.self, from: Data(contentsOf: receiptURL))
        }
        // Correct an earlier bundled revision only while its copy remains unread
        // and byte-for-byte unchanged. Never overwrite imported or edited files.
        for entry in catalog where receipts.contains(entry.id) {
            guard let book = existing.first(where: { $0.id == entry.id }),
                  book.sourceIdentity == "bookhub-classic:\(entry.id.uuidString)",
                  book.storedFileName == "classic-\(entry.id.uuidString).epub",
                  book.currentPage == 0, book.readingStatus == .toRead, book.epubState == nil,
                  let allowed = entry.replacesSHA256, !allowed.isEmpty else { continue }
            let destination = documents.appendingPathComponent("Books/" + book.storedFileName)
            guard let data = try? Data(contentsOf: destination), allowed.contains(digest(data)) else { continue }
            let replacement = try Data(contentsOf: resources.appendingPathComponent(entry.fileName))
            guard digest(replacement) == entry.sha256 else { throw CocoaError(.fileReadCorruptFile) }
            try replacement.write(to: destination, options: .atomic)
        }
        let pending = catalog.filter { !receipts.contains($0.id) }
        guard !pending.isEmpty else { return existing }
        var books = existing
        let booksDirectory = documents.appendingPathComponent("Books", isDirectory: true)
        let coversDirectory = documents.appendingPathComponent("Covers", isDirectory: true)
        try fm.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
        try fm.createDirectory(at: coversDirectory, withIntermediateDirectories: true)
        for entry in pending {
            // Reconcile restored libraries and pre-existing manual imports without
            // replacing progress, highlights, custom covers, or archive status.
            if books.contains(where: { $0.id == entry.id || ($0.type == .epub && $0.contentKind == .book && BookLibraryQuery.fold($0.title) == BookLibraryQuery.fold(entry.title) && ($0.bookMetadata?.authors.contains(where: { BookLibraryQuery.fold($0) == BookLibraryQuery.fold(entry.author) }) ?? false)) }) {
                receipts.insert(entry.id)
                continue
            }
            let source = resources.appendingPathComponent(entry.fileName)
            let data = try Data(contentsOf: source)
            guard digest(data) == entry.sha256, data.starts(with: [0x50, 0x4b]) else { throw CocoaError(.fileReadCorruptFile) }
            let name = "classic-\(entry.id.uuidString).epub"
            let destination = booksDirectory.appendingPathComponent(name)
            if fm.fileExists(atPath: destination.path) {
                guard digest(try Data(contentsOf: destination)) == entry.sha256 else { throw CocoaError(.fileWriteFileExists) }
            } else { try data.write(to: destination, options: .atomic) }
            let coverName = "classic-\(entry.id.uuidString).png"
            let cover = coversDirectory.appendingPathComponent(coverName)
            if !fm.fileExists(atPath: cover.path) { try fm.copyItem(at: resources.appendingPathComponent(entry.coverFileName), to: cover) }
            var metadata = BookBibliography(title: entry.title, authors: [entry.author], publisher: "Book Hub Classics", language: "en", publicationYear: entry.year, summary: entry.summary)
            for field in ["title", "authors", "publisher", "language", "publicationYear", "summary"] { metadata.sources[field] = .embedded }
            let book = ComicBook(id: entry.id, title: entry.title, storedFileName: name, type: .epub, pageCount: entry.chapterCount, thumbnailFileName: coverName, contentKind: .book, bookMetadata: metadata, sourceIdentity: "bookhub-classic:\(entry.id.uuidString)")
            books.append(book)
            receipts.insert(entry.id)
        }
        // Commit records before receipts. If the process stops between writes,
        // stable IDs reconcile on the next launch without adding duplicates.
        try JSONEncoder().encode(books).write(to: documents.appendingPathComponent("library.json"), options: .atomic)
        try JSONEncoder().encode(receipts).write(to: receiptURL, options: .atomic)
        return books
    }
    private static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
}
