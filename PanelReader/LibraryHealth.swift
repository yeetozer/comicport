import Foundation
import PDFKit

enum LibraryHealthSeverity: Int, Codable, Comparable, Sendable {
    case info = 0
    case warning = 1
    case critical = 2

    static func < (lhs: LibraryHealthSeverity, rhs: LibraryHealthSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum LibraryHealthIssueKind: String, Sendable {
    case missingFile
    case unreadableFile
    case pageCountMismatch
    case missingCover
    case duplicate
    case veryLargeFile
    case metadataUnknown
    case seriesGap
    case duplicateIssueNumber
}

struct LibraryHealthIssue: Identifiable, Hashable, Sendable {
    let id: String
    let kind: LibraryHealthIssueKind
    let severity: LibraryHealthSeverity
    let title: String
    let detail: String
    let bookID: UUID?
    let relatedBookIDs: [UUID]
    let seriesID: String?
}

struct LibraryHealthSnapshot: Sendable {
    let scannedAt: Date
    let deepScan: Bool
    let totalBooks: Int
    let availableBooks: Int
    let totalBytes: Int64
    let issues: [LibraryHealthIssue]

    var criticalCount: Int { issues.filter { $0.severity == .critical }.count }
    var warningCount: Int { issues.filter { $0.severity == .warning }.count }
}

struct LibraryHealthDescriptor: Sendable {
    let id: UUID
    let title: String
    let fileURL: URL
    let coverURL: URL?
    let type: ComicType
    let expectedPageCount: Int
    let fileAvailable: Bool
    let sourceIdentity: String
}

enum LibraryHealthScanEvent: Sendable {
    case progress(current: Int, total: Int, title: String)
    case finished(LibraryHealthSnapshot)
}

enum LibraryHealthScanner {
    static func stream(
        descriptors: [LibraryHealthDescriptor],
        deep: Bool
    ) -> AsyncThrowingStream<LibraryHealthScanEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task.detached(priority: .utility) {
                let fm = FileManager.default
                var issues: [LibraryHealthIssue] = []
                var totalBytes: Int64 = 0
                var available = 0
                var facts: [(descriptor: LibraryHealthDescriptor, bytes: Int64)] = []
                facts.reserveCapacity(descriptors.count)

                for (offset, item) in descriptors.enumerated() {
                    try Task.checkCancellation()
                    continuation.yield(.progress(current: offset + 1, total: descriptors.count, title: item.title))

                    let exists = fm.fileExists(atPath: item.fileURL.path)
                    if !exists {
                        issues.append(
                            LibraryHealthIssue(
                                id: "missing|\(item.id)",
                                kind: .missingFile,
                                severity: .warning,
                                title: item.title,
                                detail: "Çizgi roman dosyası bu cihazda değil. Kayıt ve istatistikler korunuyor; aynı dosyayı yeniden içe aktarabilirsin.",
                                bookID: item.id,
                                relatedBookIDs: [],
                                seriesID: nil
                            )
                        )
                        facts.append((item, 0))
                        continue
                    }

                    available += 1
                    let values = try? item.fileURL.resourceValues(forKeys: [.fileSizeKey])
                    let bytes = Int64(values?.fileSize ?? 0)
                    totalBytes += max(0, bytes)
                    facts.append((item, bytes))

                    if bytes >= 600 * 1024 * 1024 {
                        issues.append(
                            LibraryHealthIssue(
                                id: "large|\(item.id)",
                                kind: .veryLargeFile,
                                severity: .info,
                                title: item.title,
                                detail: "Dosya yaklaşık \(formatBytes(bytes)). Storage Optimizer ile alan kazanabilirsin.",
                                bookID: item.id,
                                relatedBookIDs: [],
                                seriesID: nil
                            )
                        )
                    }

                    if item.coverURL == nil || !(item.coverURL.map { fm.fileExists(atPath: $0.path) } ?? false) {
                        issues.append(
                            LibraryHealthIssue(
                                id: "cover|\(item.id)",
                                kind: .missingCover,
                                severity: .warning,
                                title: item.title,
                                detail: "Kapak önbelleği eksik. Dosyadan güvenli biçimde yeniden üretilebilir.",
                                bookID: item.id,
                                relatedBookIDs: [],
                                seriesID: nil
                            )
                        )
                    }

                    if item.expectedPageCount <= 0 {
                        issues.append(
                            LibraryHealthIssue(
                                id: "pages-zero|\(item.id)",
                                kind: .unreadableFile,
                                severity: .critical,
                                title: item.title,
                                detail: "Kayıt 0 okunabilir sayfa bildiriyor.",
                                bookID: item.id,
                                relatedBookIDs: [],
                                seriesID: nil
                            )
                        )
                    }

                    if deep {
                        let actual = actualPageCount(item)
                        if actual <= 0 {
                            issues.append(
                                LibraryHealthIssue(
                                    id: "unreadable|\(item.id)",
                                    kind: .unreadableFile,
                                    severity: .critical,
                                    title: item.title,
                                    detail: "Derin tarama dosyada okunabilir sayfa bulamadı.",
                                    bookID: item.id,
                                    relatedBookIDs: [],
                                    seriesID: nil
                                )
                            )
                        } else if item.expectedPageCount > 0 && actual != item.expectedPageCount {
                            issues.append(
                                LibraryHealthIssue(
                                    id: "page-mismatch|\(item.id)",
                                    kind: .pageCountMismatch,
                                    severity: .warning,
                                    title: item.title,
                                    detail: "Kayıt \(item.expectedPageCount) sayfa, dosya \(actual) sayfa bildiriyor.",
                                    bookID: item.id,
                                    relatedBookIDs: [],
                                    seriesID: nil
                                )
                            )
                        }
                    }
                }

                // Exact-ish duplicate groups: stable source identity is strongest, followed by
                // normalized title + page count + file size.
                var duplicateGroups: [String: [LibraryHealthDescriptor]] = [:]
                for fact in facts where fact.bytes > 0 {
                    let sourceKey = fact.descriptor.sourceIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
                    let key = sourceKey.isEmpty
                        ? "\(normalizeTitle(fact.descriptor.title))|\(fact.descriptor.expectedPageCount)|\(fact.bytes)"
                        : sourceKey
                    duplicateGroups[key, default: []].append(fact.descriptor)
                }

                for group in duplicateGroups.values where group.count > 1 {
                    let ids = group.map(\.id)
                    for item in group {
                        issues.append(
                            LibraryHealthIssue(
                                id: "duplicate|\(item.id)|\(ids.count)",
                                kind: .duplicate,
                                severity: .warning,
                                title: item.title,
                                detail: "Aynı içeriğe benzeyen \(ids.count) kütüphane kaydı bulundu.",
                                bookID: item.id,
                                relatedBookIDs: ids.filter { $0 != item.id },
                                seriesID: nil
                            )
                        )
                    }
                }

                let snapshot = LibraryHealthSnapshot(
                    scannedAt: .now,
                    deepScan: deep,
                    totalBooks: descriptors.count,
                    availableBooks: available,
                    totalBytes: totalBytes,
                    issues: issues.sorted {
                        if $0.severity != $1.severity { return $0.severity > $1.severity }
                        return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    }
                )
                continuation.yield(.finished(snapshot))
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func actualPageCount(_ item: LibraryHealthDescriptor) -> Int {
        switch item.type {
        case .epub:
            return (try? EPUBService.open(item.fileURL).chapters.count) ?? 0
        case .pdf:
            return autoreleasepool {
                PDFDocument(url: item.fileURL)?.pageCount ?? 0
            }
        case .cbz:
            return autoreleasepool {
                (try? CBZService.extractImages(from: item.fileURL).count) ?? 0
            }
        }
    }

    private static func normalizeTitle(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func formatBytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }
}
