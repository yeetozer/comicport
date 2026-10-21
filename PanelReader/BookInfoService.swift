import Foundation
import PDFKit
import UIKit
import Vision

struct OfflineComicInfo: Codable, Hashable {
    var analyzedAt: Date = .now
    var displayTitle: String
    var series: String?
    var issue: String?
    var year: String?
    var creators: [String]
    var publisher: String?
    var pageCount: Int
    var fileType: String
    var embeddedAuthor: String?
    var embeddedSubject: String?
    var detectedText: String
    var summary: String
    var confidenceNote: String
    var databaseMatch: LocalComicRecord?
    var databaseConfidence: Int?

    // Stage 16 fields are optional so every existing cached BookInfo JSON remains decodable.
    var metadataAuthority: ComicMetadataAuthority?
    var comicInfoPresent: Bool?
    var volume: Int?
    var imprint: String?
    var characters: [String]?
    var genres: [String]?
    var languageISO: String?
    var storyArc: String?
    var format: String?
    var titleSource: BookMetadataSource?
    var authorsSource: BookMetadataSource?
}

enum BookInfoService {
    static func analyze(book: ComicBook, fileURL: URL) async throws -> OfflineComicInfo {
        try await Task.detached(priority: .userInitiated) {
            if book.type == .epub {
                let publication = try EPUBService.open(fileURL)
                let metadata = publication.metadata
                return OfflineComicInfo(displayTitle: metadata.title ?? book.title, year: metadata.publicationYear, creators: metadata.authors, publisher: metadata.publisher, pageCount: publication.chapters.count, fileType: "EPUB", detectedText: "", summary: metadata.summary ?? "", confidenceNote: "EPUB paketindeki bilgiler okundu.", languageISO: metadata.language, titleSource: .embedded, authorsSource: .embedded)
            }
            let parsed = parseFilename(book.title)
            let comicInfo = book.type == .pdf ? nil : ComicInfoService.metadata(from: fileURL)
            var embeddedTitle: String?
            var embeddedAuthor: String?
            var embeddedSubject: String?
            var ocrImages: [CGImage] = []

            if book.type == .pdf {
                if let document = PDFDocument(url: fileURL) {
                    if let attributes = document.documentAttributes {
                        embeddedTitle = clean(attributes[PDFDocumentAttribute.titleAttribute] as? String)
                        embeddedAuthor = clean(attributes[PDFDocumentAttribute.authorAttribute] as? String)
                        embeddedSubject = clean(attributes[PDFDocumentAttribute.subjectAttribute] as? String)
                    }
                    for index in 0..<min(BookHubPerformancePolicy.metadataPageLimit, document.pageCount) {
                        guard let page = document.page(at: index) else { continue }
                        let image = page.thumbnail(of: CGSize(width: 1500, height: 2000), for: .mediaBox)
                        if let cg = image.cgImage { ocrImages.append(cg) }
                    }
                }
            } else {
                let imageURLs = try CBZService.extractImages(from: fileURL)
                for url in imageURLs.prefix(BookHubPerformancePolicy.metadataPageLimit) {
                    if let image = UIImage(contentsOfFile: url.path), let cg = image.cgImage { ocrImages.append(cg) }
                }
            }

            var recognized: [String] = []
            for image in ocrImages {
                recognized.append(contentsOf: try recognizeText(in: image))
            }
            recognized = uniqueUsefulLines(recognized)

            let inferredCreators = inferCreators(from: recognized, embeddedAuthor: embeddedAuthor)
            let inferredPublisher = inferPublisher(from: recognized)
            let detectedText = recognized.prefix(40).joined(separator: "\n")

            // Metadata priority: ComicInfo.xml > embedded PDF metadata > local catalog >
            // filename > OCR. ComicInfo is treated as authoritative because it is
            // explicitly embedded in the user's comic archive.
            let baseTitle = comicInfo?.displayTitle(fallback: embeddedTitle ?? parsed.title)
                ?? embeddedTitle
                ?? parsed.title
            let localMatch = book.contentKind == .book ? nil : LocalComicDatabase.bestMatch(
                title: [book.title, baseTitle, comicInfo?.series ?? ""].joined(separator: " "),
                OCRText: detectedText
            )

            let resolvedCreators: [String]
            if let comicInfo, !comicInfo.creators.isEmpty {
                resolvedCreators = comicInfo.creators
            } else if book.contentKind == .book, let embeddedAuthor {
                resolvedCreators = [embeddedAuthor]
            } else if localMatch?.record.creators.isEmpty == false {
                resolvedCreators = localMatch!.record.creators
            } else {
                resolvedCreators = inferredCreators
            }

            let resolvedPublisher = comicInfo?.publisher ?? localMatch?.record.publisher ?? inferredPublisher
            let resolvedSummary = comicInfo?.summary
                ?? localMatch?.record.description
                ?? makeSummary(
                    title: baseTitle,
                    subject: embeddedSubject,
                    text: recognized,
                    creators: inferredCreators,
                    publisher: inferredPublisher,
                    pageCount: book.pageCount,
                    isBook: book.contentKind == .book
                )

            let authority: ComicMetadataAuthority = comicInfo == nil ? .inferred : .verified
            let authorityText = book.contentKind == .book
                ? "Book metadata uses embedded fields, filename and OCR. Inferred fields need review."
                : comicInfo == nil
                ? "Metadata is inferred from filename, PDF metadata, the bundled local catalog and OCR. Automatic matches can be wrong."
                : "Verified metadata was read from ComicInfo.xml inside this comic archive. OCR and local-catalog enrichment remain best-effort."

            return OfflineComicInfo(
                displayTitle: baseTitle,
                series: book.contentKind == .book ? nil : (comicInfo?.series ?? parsed.series),
                issue: book.contentKind == .book ? nil : (comicInfo?.number ?? parsed.issue),
                year: comicInfo?.year.map(String.init) ?? parsed.year,
                creators: resolvedCreators,
                publisher: resolvedPublisher,
                pageCount: book.pageCount,
                fileType: fileURL.pathExtension.uppercased(),
                embeddedAuthor: embeddedAuthor,
                embeddedSubject: embeddedSubject,
                detectedText: detectedText,
                summary: resolvedSummary,
                confidenceNote: "\(authorityText) Everything was processed locally on this device; nothing was sent to the internet.",
                databaseMatch: localMatch?.record,
                databaseConfidence: localMatch?.confidence,
                metadataAuthority: authority,
                comicInfoPresent: comicInfo != nil,
                volume: comicInfo?.volume,
                imprint: comicInfo?.imprint,
                characters: comicInfo?.characters,
                genres: comicInfo?.genres,
                languageISO: comicInfo?.languageISO,
                storyArc: comicInfo?.storyArc,
                format: comicInfo?.format,
                titleSource: comicInfo != nil || embeddedTitle != nil ? .embedded : .filename,
                authorsSource: (comicInfo?.creators.isEmpty == false || (book.contentKind == .book && embeddedAuthor != nil)) ? .embedded : .inferred
            )
        }.value
    }

    private static func recognizeText(in image: CGImage) throws -> [String] {
        var lines: [String] = []
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else { return }
            lines = observations.compactMap { $0.topCandidates(1).first?.string }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "tr-TR"]
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        return lines
    }

    private struct ParsedName { var title: String; var series: String?; var issue: String?; var year: String? }

    private static func parseFilename(_ raw: String) -> ParsedName {
        var text = raw.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: ".", with: " ")
        text = text.replacingOccurrences(of: "  ", with: " ")
        let year = firstMatch(in: text, pattern: #"\b(19|20)\d{2}\b"#)
        let issue = firstMatch(in: text, pattern: #"(?:#|issue\s*)(\d{1,4})\b"#, group: 1)
        text = text.replacingOccurrences(of: #"\s*[\(\[]?(19|20)\d{2}[\)\]]?\s*"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s*(?:#|issue\s*)\d{1,4}\b"#, with: " ", options: [.regularExpression, .caseInsensitive])
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return ParsedName(title: text.isEmpty ? raw : text, series: text.isEmpty ? nil : text, issue: issue, year: year)
    }

    private static func inferCreators(from lines: [String], embeddedAuthor: String?) -> [String] {
        var names: [String] = []
        if let embeddedAuthor { names.append(contentsOf: embeddedAuthor.components(separatedBy: CharacterSet(charactersIn: ",;&")).map { $0.trimmingCharacters(in: .whitespaces) }) }
        let keys = ["written by", "writer", "writers", "story by", "art by", "artist", "artists", "pencils", "penciller", "penciler", "illustrated by", "script"]
        for line in lines {
            let lower = line.lowercased()
            if keys.contains(where: { lower.contains($0) }) {
                let parts = line.components(separatedBy: ":")
                let candidate = (parts.count > 1 ? parts.dropFirst().joined(separator: ":") : line)
                    .replacingOccurrences(of: "Written by", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "Art by", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if candidate.count >= 3 && candidate.count <= 90 { names.append(candidate) }
            }
        }
        var seen = Set<String>()
        return names.filter { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }
            let key = trimmed.lowercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private static func inferPublisher(from lines: [String]) -> String? {
        let publishers = ["DC Comics", "DC", "Marvel Comics", "Marvel", "Image Comics", "Dark Horse Comics", "Dark Horse", "IDW Publishing", "IDW", "Boom! Studios", "Dynamite Entertainment", "Vertigo", "Kodansha", "VIZ Media"]
        for publisher in publishers {
            if lines.contains(where: { $0.range(of: publisher, options: .caseInsensitive) != nil }) { return publisher }
        }
        return nil
    }

    private static func makeSummary(title: String, subject: String?, text: [String], creators: [String], publisher: String?, pageCount: Int, isBook: Bool = false) -> String {
        if let subject, subject.count > 20 { return subject }
        var sentences: [String] = ["\(title) is a \(pageCount)-page \(isBook ? "book" : "comic") file in your local library."]
        if let publisher { sentences.append("The first pages appear to identify \(publisher) as the publisher/imprint.") }
        if !creators.isEmpty { sentences.append("Creator names detected in the file include \(creators.prefix(4).joined(separator: ", ")).") }
        let prose = text.filter { $0.count > 45 && $0.count < 220 && !$0.lowercased().contains("copyright") }.prefix(2)
        if !prose.isEmpty { sentences.append("Early-page text detected by OCR: " + prose.joined(separator: " ")) }
        return sentences.joined(separator: " ")
    }

    private static func uniqueUsefulLines(_ lines: [String]) -> [String] {
        var seen = Set<String>()
        return lines.compactMap { raw in
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count >= 2 else { return nil }
            let key = line.lowercased()
            guard !seen.contains(key) else { return nil }
            seen.insert(key)
            return line
        }
    }

    private static func firstMatch(in text: String, pattern: String, group: Int = 0) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              group < match.numberOfRanges,
              let range = Range(match.range(at: group), in: text) else { return nil }
        return String(text[range])
    }

    private static func clean(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// On-demand only. One heavy analysis runs at a time, duplicate callers share work,
// and both pending work and completed results are bounded. No network on startup.
actor BookMetadataIntelligence {
    static let shared = BookMetadataIntelligence()
    private var pending: [String: Task<OfflineComicInfo, Error>] = [:]
    private var results: [String: OfflineComicInfo] = [:]
    private var insertionOrder: [String] = []
    private var tail: Task<Void, Never>?

    enum AnalysisError: LocalizedError {
        case busy
        var errorDescription: String? { "Metadata kuyruğu dolu. Biraz sonra tekrar dene." }
    }

    func analyze(book: ComicBook, fileURL: URL, force: Bool = false) async throws -> OfflineComicInfo {
        var identityURL = fileURL
        identityURL.removeAllCachedResourceValues()
        let attributes = try identityURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        let key = "\(book.id)|\(fileURL.path)|\(attributes.contentModificationDate?.timeIntervalSince1970 ?? 0)|\(attributes.fileSize ?? 0)|\(book.title)|\(book.contentKind.rawValue)|\(book.pageCount)"
        if let task = pending[key] { return try await task.value }
        if !force, let result = results[key] { return result }
        guard pending.count < BookHubPerformancePolicy.metadataPendingLimit else { throw AnalysisError.busy }
        let predecessor = tail
        let task = Task {
            if let predecessor { await predecessor.value }
            return try await BookInfoService.analyze(book: book, fileURL: fileURL)
        }
        pending[key] = task
        tail = Task { _ = try? await task.value }
        do {
            let result = try await task.value
            pending[key] = nil
            insertionOrder.removeAll { $0 == key }
            insertionOrder.append(key)
            results[key] = result
            while insertionOrder.count > BookHubPerformancePolicy.metadataMemoryEntries {
                results[insertionOrder.removeFirst()] = nil
            }
            if pending.isEmpty { tail = nil }
            return result
        } catch {
            pending[key] = nil
            if pending.isEmpty { tail = nil }
            throw error
        }
    }
}
