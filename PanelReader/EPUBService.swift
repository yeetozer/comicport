import Foundation
import CryptoKit
import libarchive
import Darwin

enum EPUBService {
    private static let lock = NSLock()

    // Extraction is serial and disk-cached; chapter text is loaded only on demand.
    static func open(_ source: URL) throws -> EPUBPublication {
        lock.lock()
        defer { lock.unlock() }
        let fm = FileManager.default
        let values = try source.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let identity = "\(source.standardizedFileURL.path)|\(values.fileSize ?? 0)|\(values.contentModificationDate?.timeIntervalSince1970 ?? 0)"
        let key = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
        let cache = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ComicPortEPUB", isDirectory: true)
        try fm.createDirectory(at: cache, withIntermediateDirectories: true)
        let destination = cache.appendingPathComponent(key, isDirectory: true)
        if fm.fileExists(atPath: destination.path) {
            try? fm.setAttributes([.modificationDate: Date()], ofItemAtPath: destination.path)
            return try EPUBPackage.load(root: destination)
        }
        let temporary = cache.appendingPathComponent("pending-" + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temporary) }
        try extract(source, to: temporary)
        _ = try EPUBPackage.load(root: temporary)
        try fm.moveItem(at: temporary, to: destination)
        let entries = (try? fm.contentsOfDirectory(at: cache, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        let others = entries.filter { $0 != destination }.sorted {
            ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }
        for stale in others.dropFirst(7) { try? fm.removeItem(at: stale) }
        return try EPUBPackage.load(root: destination)
    }

    private static func extract(_ source: URL, to root: URL) throws {
        guard let archive = archive_read_new() else { throw EPUBError.invalidPackage }
        defer { archive_read_free(archive) }
        archive_read_support_format_zip(archive)
        guard source.path.withCString({ archive_read_open_filename(archive, $0, 64 * 1024) }) == ARCHIVE_OK else { throw EPUBError.invalidPackage }
        var entry: OpaquePointer?
        var count = 0
        var total = 0
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let status = archive_read_next_header(archive, &entry)
            if status == ARCHIVE_EOF { break }
            guard status >= ARCHIVE_WARN, let entry, let name = archive_entry_pathname(entry) else { throw EPUBError.invalidPackage }
            count += 1
            guard count <= 5000 else { throw EPUBError.tooLarge }
            if archive_entry_is_encrypted(entry) == 1 { throw EPUBError.protectedFile }
            let path = String(cString: name)
            if archive_entry_filetype(entry) == UInt32(S_IFDIR) { archive_read_data_skip(archive); continue }
            guard archive_entry_filetype(entry) == UInt32(S_IFREG), archive_entry_symlink(entry) == nil,
                  archive_entry_hardlink(entry) == nil else { throw EPUBError.unsafePath }
            let output = try EPUBPackage.resource(path, relativeTo: root, root: root, archiveEntry: true)
            var data = Data()
            while true {
                let bytes = buffer.withUnsafeMutableBytes { Int(archive_read_data(archive, $0.baseAddress, $0.count)) }
                if bytes == 0 { break }
                guard bytes > 0 else { throw EPUBError.protectedFile }
                total += bytes
                guard data.count + bytes <= 16 * 1024 * 1024, total <= 200 * 1024 * 1024 else { throw EPUBError.tooLarge }
                data.append(contentsOf: buffer.prefix(bytes))
            }
            try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: output, options: .atomic)
        }
        guard let mime = try? String(contentsOf: root.appendingPathComponent("mimetype"), encoding: .utf8), mime.trimmingCharacters(in: .whitespacesAndNewlines) == "application/epub+zip" else { throw EPUBError.invalidPackage }
        if FileManager.default.fileExists(atPath: root.appendingPathComponent("META-INF/encryption.xml").path) { throw EPUBError.protectedFile }
    }
}
