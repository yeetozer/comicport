import Foundation
import UniformTypeIdentifiers

enum ComicArchiveFormat: String, CaseIterable, Sendable {
    case cbz
    case cbr
    case cb7
    case cbt
    case zip
    case rar
    case sevenZip = "7z"
    case tar

    static let supportedExtensions: Set<String> = Set(allCases.map(\.rawValue))

    static func supports(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    static var allowedImportTypes: [UTType] {
        var result: [UTType] = [.pdf]
        var identifiers = Set(result.map(\.identifier))

        for ext in supportedExtensions.sorted() {
            if let type = UTType(filenameExtension: ext), identifiers.insert(type.identifier).inserted {
                result.append(type)
            }
        }

        // Several comic extensions are not registered on every iPadOS build.
        // .data keeps the Files picker able to select them; import validation still
        // rejects everything outside the explicit extension allow-list.
        if identifiers.insert(UTType.data.identifier).inserted {
            result.append(.data)
        }
        return result
    }

    static func displayName(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "cbz": return "CBZ"
        case "cbr": return "CBR"
        case "cb7": return "CB7"
        case "cbt": return "CBT"
        case "zip": return "ZIP"
        case "rar": return "RAR / RAR5"
        case "7z": return "7-Zip"
        case "tar": return "TAR"
        default: return url.pathExtension.uppercased()
        }
    }

    static func usesLegacyZipExtractor(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "cbz" || ext == "zip"
    }
}
