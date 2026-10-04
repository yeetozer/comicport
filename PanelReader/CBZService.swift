import Foundation

private struct CBZExtractionManifest: Codable {
    let sourceBytes: Int64
    let sourceModified: TimeInterval
}

struct CBZService {
    private static let extractionLock = NSLock()

    static func extractionDirectory(for cbzURL: URL) -> URL {
        let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PanelReaderArchives", isDirectory: true)
        return root.appendingPathComponent(cbzURL.deletingPathExtension().lastPathComponent, isDirectory: true)
    }

    static func extractImages(from cbzURL: URL) throws -> [URL] {
        extractionLock.lock()
        defer { extractionLock.unlock() }

        let fm = FileManager.default
        let destination = extractionDirectory(for: cbzURL)
        let fingerprint = sourceFingerprint(cbzURL)

        if fm.fileExists(atPath: destination.path),
           manifestMatches(at: destination, fingerprint: fingerprint),
           let existing = try? imageFiles(in: destination),
           !existing.isEmpty {
            try? fm.setAttributes([.modificationDate: Date.now], ofItemAtPath: destination.path)
            return existing
        }

        try? fm.removeItem(at: destination)
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        try ComicArchiveService.extractArchive(at: cbzURL, to: destination)

        let images = try imageFiles(in: destination)
        guard !images.isEmpty else {
            try? fm.removeItem(at: destination)
            return []
        }

        saveManifest(fingerprint, at: destination)
        #if targetEnvironment(macCatalyst)
        pruneOldCaches(keeping: destination, maximumFolders: 12)
        #else
        pruneOldCaches(keeping: destination, maximumFolders: 6)
        #endif
        return images
    }

    static func cleanTemporaryExtraction(for cbzURL: URL) {
        extractionLock.lock()
        defer { extractionLock.unlock() }
        try? FileManager.default.removeItem(at: extractionDirectory(for: cbzURL))
    }

    private static func sourceFingerprint(_ url: URL) -> CBZExtractionManifest {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        return CBZExtractionManifest(
            sourceBytes: Int64(values?.fileSize ?? 0),
            sourceModified: values?.contentModificationDate?.timeIntervalSince1970 ?? 0
        )
    }

    private static func manifestURL(_ directory: URL) -> URL {
        directory.appendingPathComponent(".panelreader-cache.json")
    }

    private static func manifestMatches(at directory: URL, fingerprint: CBZExtractionManifest) -> Bool {
        guard let data = try? Data(contentsOf: manifestURL(directory)),
              let saved = try? JSONDecoder().decode(CBZExtractionManifest.self, from: data) else { return false }
        return saved.sourceBytes == fingerprint.sourceBytes && abs(saved.sourceModified - fingerprint.sourceModified) < 0.5
    }

    private static func saveManifest(_ manifest: CBZExtractionManifest, at directory: URL) {
        guard let data = try? JSONEncoder().encode(manifest) else { return }
        try? data.write(to: manifestURL(directory), options: .atomic)
    }

    private static func pruneOldCaches(keeping current: URL, maximumFolders: Int) {
        let fm = FileManager.default
        let root = current.deletingLastPathComponent()
        guard let folders = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let candidates = folders.filter { url in
            guard url != current else { return false }
            return (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
        guard candidates.count + 1 > maximumFolders else { return }

        let sorted = candidates.sorted {
            let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return a < b
        }

        let deleteCount = max(0, candidates.count + 1 - maximumFolders)
        for url in sorted.prefix(deleteCount) {
            try? fm.removeItem(at: url)
        }
    }

    private static func imageFiles(in directory: URL) throws -> [URL] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            if ["jpg", "jpeg", "png", "webp", "heic", "avif"].contains(ext) {
                urls.append(url)
            }
        }
        return urls.sorted { naturalLess($0.lastPathComponent, $1.lastPathComponent) }
    }

    private static func naturalLess(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
}
