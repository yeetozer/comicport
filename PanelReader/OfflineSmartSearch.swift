import Foundation
import PDFKit
import UIKit
import Vision
import ImageIO

struct OCRPageText: Codable, Hashable, Sendable {
    let page: Int
    let text: String
}

struct OCRBookIndex: Codable, Hashable, Sendable {
    static let schemaVersion = 1

    let schema: Int
    let bookID: UUID
    let title: String
    let sourceIdentity: String
    let pageCount: Int
    let indexedAt: Date
    let pages: [OCRPageText]

    var searchablePageCount: Int { pages.count }
    var recognizedCharacterCount: Int { pages.reduce(0) { $0 + $1.text.count } }
}

struct SmartSearchProgress: Hashable, Sendable {
    let bookID: UUID
    let bookTitle: String
    let bookNumber: Int
    let totalBooks: Int
    let page: Int
    let totalPages: Int

    var overallFraction: Double {
        guard totalBooks > 0 else { return 0 }
        let bookBase = Double(max(0, bookNumber - 1)) / Double(totalBooks)
        let withinBook = totalPages > 0 ? Double(page) / Double(totalPages) / Double(totalBooks) : 0
        return min(1, bookBase + withinBook)
    }
}

enum SmartSearchHitKind: String, Sendable {
    case title
    case pageText
}

struct SmartSearchHit: Identifiable, Hashable, Sendable {
    let bookID: UUID
    let bookTitle: String
    let page: Int?
    let snippet: String
    let kind: SmartSearchHitKind

    var id: String {
        "\(bookID.uuidString)-\(page ?? -1)-\(kind.rawValue)-\(snippet.hashValue)"
    }
}

struct SmartSearchBookDescriptor: Sendable {
    let id: UUID
    let title: String
    let sourceIdentity: String
    let fileURL: URL
    let type: ComicType
    let pageCount: Int
}

enum OCRIndexEvent: Sendable {
    case progress(page: Int, total: Int)
    case finished(OCRBookIndex)
}

enum OfflineOCRIndexer {
    static func stream(
        descriptor: SmartSearchBookDescriptor
    ) -> AsyncThrowingStream<OCRIndexEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached(priority: .utility) {
                do {
                    let index: OCRBookIndex
                    switch descriptor.type {
                    case .pdf:
                        index = try indexPDF(descriptor, continuation: continuation)
                    case .cbz:
                        index = try indexCBZ(descriptor, continuation: continuation)
                    }
                    try Task.checkCancellation()
                    continuation.yield(.finished(index))
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static func indexPDF(
        _ descriptor: SmartSearchBookDescriptor,
        continuation: AsyncThrowingStream<OCRIndexEvent, Error>.Continuation
    ) throws -> OCRBookIndex {
        guard let document = PDFDocument(url: descriptor.fileURL) else {
            throw NSError(
                domain: "PanelReader.OCR",
                code: 10,
                userInfo: [NSLocalizedDescriptionKey: "PDF could not be opened for OCR."]
            )
        }

        let total = document.pageCount
        var pages: [OCRPageText] = []
        pages.reserveCapacity(total)

        for pageIndex in 0..<total {
            try Task.checkCancellation()

            let text: String = autoreleasepool {
                guard let page = document.page(at: pageIndex) else { return "" }
                let bounds = page.bounds(for: .mediaBox)
                guard bounds.width > 0, bounds.height > 0 else { return "" }

                let maxPixel: CGFloat = 1700
                let scale = min(maxPixel / max(bounds.width, bounds.height), 2.3)
                let size = CGSize(
                    width: max(1, bounds.width * scale),
                    height: max(1, bounds.height * scale)
                )

                let image = page.thumbnail(of: size, for: .mediaBox)
                guard let cgImage = image.cgImage else { return "" }
                return (try? recognize(cgImage)) ?? ""
            }

            pages.append(OCRPageText(page: pageIndex, text: text))
            continuation.yield(.progress(page: pageIndex + 1, total: total))
        }

        return OCRBookIndex(
            schema: OCRBookIndex.schemaVersion,
            bookID: descriptor.id,
            title: descriptor.title,
            sourceIdentity: descriptor.sourceIdentity,
            pageCount: total,
            indexedAt: .now,
            pages: pages
        )
    }

    private static func indexCBZ(
        _ descriptor: SmartSearchBookDescriptor,
        continuation: AsyncThrowingStream<OCRIndexEvent, Error>.Continuation
    ) throws -> OCRBookIndex {
        let extracted = try CBZService.extractImages(from: descriptor.fileURL)

        let total = extracted.count
        var pages: [OCRPageText] = []
        pages.reserveCapacity(total)

        for (pageIndex, pageURL) in extracted.enumerated() {
            try Task.checkCancellation()

            let text: String = autoreleasepool {
                guard let cgImage = downsample(pageURL, maxPixel: 1700) else { return "" }
                return (try? recognize(cgImage)) ?? ""
            }

            pages.append(OCRPageText(page: pageIndex, text: text))
            continuation.yield(.progress(page: pageIndex + 1, total: total))
        }

        return OCRBookIndex(
            schema: OCRBookIndex.schemaVersion,
            bookID: descriptor.id,
            title: descriptor.title,
            sourceIdentity: descriptor.sourceIdentity,
            pageCount: total,
            indexedAt: .now,
            pages: pages
        )
    }

    private static func downsample(_ url: URL, maxPixel: Int) -> CGImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: false
        ] as CFDictionary

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }

    private static func recognize(_ cgImage: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.008

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }
}

struct SmartSearchBookRecord: Sendable {
    let id: UUID
    let title: String
}

enum SmartSearchDiskService {
    static func loadIndexes(
        directory: URL,
        expected: [UUID: (sourceIdentity: String, pageCount: Int)]
    ) -> [UUID: OCRBookIndex] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [:] }

        var result: [UUID: OCRBookIndex] = [:]
        let decoder = JSONDecoder()

        for url in urls where url.pathExtension.lowercased() == "json" {
            guard let data = try? Data(contentsOf: url),
                  let index = try? decoder.decode(OCRBookIndex.self, from: data),
                  index.schema == OCRBookIndex.schemaVersion,
                  let expectedBook = expected[index.bookID],
                  index.sourceIdentity == expectedBook.sourceIdentity,
                  index.pageCount == expectedBook.pageCount else {
                continue
            }
            result[index.bookID] = index
        }

        return result
    }

    static func save(_ index: OCRBookIndex, to url: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(index)
        try data.write(to: url, options: .atomic)
    }

    static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    static func search(
        query: String,
        books: [SmartSearchBookRecord],
        indexes: [UUID: OCRBookIndex],
        limit: Int = 120
    ) -> [SmartSearchHit] {
        let normalizedQuery = normalize(query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else { return [] }

        var hits: [SmartSearchHit] = []
        hits.reserveCapacity(min(limit, 80))

        // Title hits work even before OCR indexing.
        for book in books {
            if normalize(book.title).contains(normalizedQuery) {
                hits.append(
                    SmartSearchHit(
                        bookID: book.id,
                        bookTitle: book.title,
                        page: nil,
                        snippet: "Başlık eşleşmesi",
                        kind: .title
                    )
                )
                if hits.count >= limit { return hits }
            }
        }

        for book in books {
            guard let index = indexes[book.id] else { continue }

            for page in index.pages {
                let normalizedText = normalize(page.text)
                guard let range = normalizedText.range(of: normalizedQuery) else { continue }

                hits.append(
                    SmartSearchHit(
                        bookID: book.id,
                        bookTitle: book.title,
                        page: page.page,
                        snippet: snippet(
                            original: page.text,
                            normalized: normalizedText,
                            match: range
                        ),
                        kind: .pageText
                    )
                )
                if hits.count >= limit { return hits }
            }
        }

        return hits.sorted {
            if $0.kind != $1.kind { return $0.kind == .title }
            if $0.bookTitle != $1.bookTitle {
                return $0.bookTitle.localizedCaseInsensitiveCompare($1.bookTitle) == .orderedAscending
            }
            return ($0.page ?? -1) < ($1.page ?? -1)
        }
    }

    private static func snippet(
        original: String,
        normalized: String,
        match: Range<String.Index>
    ) -> String {
        guard !original.isEmpty else { return "" }

        let startOffset = normalized.distance(from: normalized.startIndex, to: match.lowerBound)
        let matchLength = normalized.distance(from: match.lowerBound, to: match.upperBound)

        let originalStart = original.index(
            original.startIndex,
            offsetBy: min(startOffset, original.count),
            limitedBy: original.endIndex
        ) ?? original.startIndex

        let leadingStart = original.index(
            originalStart,
            offsetBy: -min(70, original.distance(from: original.startIndex, to: originalStart)),
            limitedBy: original.startIndex
        ) ?? original.startIndex

        let afterMatch = original.index(
            originalStart,
            offsetBy: min(matchLength, original.distance(from: originalStart, to: original.endIndex)),
            limitedBy: original.endIndex
        ) ?? original.endIndex

        let trailingEnd = original.index(
            afterMatch,
            offsetBy: min(110, original.distance(from: afterMatch, to: original.endIndex)),
            limitedBy: original.endIndex
        ) ?? original.endIndex

        let raw = String(original[leadingStart..<trailingEnd])
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let prefix = leadingStart == original.startIndex ? "" : "…"
        let suffix = trailingEnd == original.endIndex ? "" : "…"
        return prefix + raw + suffix
    }
}
