import Foundation

@main struct BookHubPerformanceChecks {
    static func main() throws {
        for count in [1_000, 10_000] {
            let library = (0..<count).map { index -> ComicBook in
                var book = ComicBook(title: String(format: "Test Kitap %04d", index), storedFileName: "fixture.pdf", type: .pdf, pageCount: 4, currentPage: index % 4, contentKind: .book, readingStatus: [.toRead, .reading, .completed][index % 3], favorite: index.isMultiple(of: 10))
                book.bookMetadata = BookBibliography(authors: [index.isMultiple(of: 5) ? "Çağrı Yılmaz" : "Yazar \(index % 50)"], publisher: "Test Yayınevi \(index % 20)", isbn: "9780306406157", language: "tr", publicationYear: String(1980 + index % 45))
                book.thumbnailFileName = "fixture.jpg"
                return book
            }
            let data = try JSONEncoder().encode(library)
            func measure(_ name: String, _ operation: () throws -> Void) rethrows {
                var samples: [Double] = []
                for _ in 0..<3 {
                    let start = Date()
                    try operation()
                    samples.append(Date().timeIntervalSince(start) * 1000)
                }
                samples.sort()
                print("\(count) records | \(name) | median \(String(format: "%.1f", samples[1])) ms | max \(String(format: "%.1f", samples.last!)) ms")
            }
            try measure("JSON decode") {
                let decoded = try JSONDecoder().decode([ComicBook].self, from: data)
                precondition(decoded.count == count && decoded.last?.bookMetadata?.language == "tr")
            }
            measure("multi-term search") {
                let query = BookLibraryQuery("kitap 0999")
                precondition(library.filter(query.matches).count == 1)
            }
            measure("Turkish author search") {
                let query = BookLibraryQuery("cagri yilmaz")
                precondition(library.filter(query.matches).count == count / 5)
            }
            measure("author sort") {
                let sorted = BookLibrarySort.author.sorted(library)
                precondition(sorted.count == count && sorted.first?.bookMetadata?.authors.first == "Çağrı Yılmaz")
            }
            measure("author + publisher shelves") {
                precondition(!BookShelfGroup.groups(in: library, byAuthors: true).isEmpty)
                precondition(BookShelfGroup.groups(in: library, byAuthors: false).count == 20)
            }
            measure("bounded dashboard queue") {
                precondition(BookHubReadingQueue.books(from: library).count == 8)
            }
            if count == 1_000, CommandLine.arguments.count > 1 {
                let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
                try data.write(to: root.appendingPathComponent("library.json"), options: .atomic)
            }
        }
        print("PASS: production-model performance workload and result checks")
    }
}
