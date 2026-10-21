import Foundation

enum EPUBError: LocalizedError {
    case invalidPackage, unsafePath, tooLarge, protectedFile, unreadableChapter
    var errorDescription: String? {
        switch self {
        case .invalidPackage: return "EPUB paketinin bölüm bilgileri okunamadı."
        case .unsafePath: return "EPUB paketinde geçersiz bir dosya yolu var."
        case .tooLarge: return "EPUB paketi desteklenen boyut sınırını aşıyor."
        case .protectedFile: return "Şifreli veya DRM korumalı EPUB dosyaları desteklenmiyor."
        case .unreadableChapter: return "EPUB bölümünün metni okunamadı."
        }
    }
}

struct EPUBChapter: Identifiable, Sendable {
    let id: Int
    let title: String
    let fileURL: URL
}

struct EPUBPublication: Sendable {
    let root: URL
    let metadata: BookBibliography
    let chapters: [EPUBChapter]
    let coverURL: URL?
}

struct EPUBChapterImage: Identifiable, Sendable {
    let id: Int
    let fileURL: URL
    let caption: String
    let location: Int
}

struct EPUBChapterLink: Sendable {
    let location: Int
    let length: Int
    let url: URL
}

struct EPUBChapterContent: Sendable {
    let text: String
    let images: [EPUBChapterImage]
    let links: [EPUBChapterLink]
    let anchors: [String: Int]
}

enum EPUBPackage {
    static func resource(_ href: String, relativeTo base: URL, root: URL, archiveEntry: Bool = false) throws -> URL {
        let value = archiveEntry ? href : href.components(separatedBy: "#").first?.removingPercentEncoding
        guard let decoded = value,
              !decoded.isEmpty, !decoded.contains("\\"), !decoded.contains("\0"),
              !decoded.hasPrefix("/"), URL(string: decoded)?.scheme == nil else { throw EPUBError.unsafePath }
        let target = base.appendingPathComponent(decoded).standardizedFileURL
        guard target.path.hasPrefix(root.standardizedFileURL.path + "/") else { throw EPUBError.unsafePath }
        return target
    }

    static func load(root: URL) throws -> EPUBPublication {
        let container = try parse(root.appendingPathComponent("META-INF/container.xml"))
        guard let packagePath = container.rootfile else { throw EPUBError.invalidPackage }
        let packageURL = try resource(packagePath, relativeTo: root, root: root)
        let package = try parse(packageURL)
        let base = packageURL.deletingLastPathComponent()
        var chapters: [EPUBChapter] = []
        for id in package.spine {
            guard let item = package.manifest[id], ["application/xhtml+xml", "text/html"].contains(item.mediaType) else { throw EPUBError.invalidPackage }
            let url = try resource(item.href, relativeTo: base, root: root)
            guard FileManager.default.fileExists(atPath: url.path) else { throw EPUBError.invalidPackage }
            chapters.append(EPUBChapter(id: chapters.count, title: "Bölüm \(chapters.count + 1)", fileURL: url))
        }
        guard !chapters.isEmpty else { throw EPUBError.invalidPackage }
        let title = package.values["title"]?.first
        var metadata = BookBibliography(title: title, authors: package.values["creator"] ?? [], publisher: package.values["publisher"]?.first, isbn: package.values["identifier"]?.compactMap { BookISBN.normalized($0.replacingOccurrences(of: "urn:isbn:", with: "")) }.first, language: package.values["language"]?.first, publicationYear: package.values["date"]?.first.map { String($0.prefix(4)) }, summary: package.values["description"]?.first)
        for field in ["title", "authors", "publisher", "isbn", "language", "publicationYear", "summary"] { metadata.sources[field] = .embedded }
        let cover = package.manifest.values.first { $0.properties.split(separator: " ").contains("cover-image") }
            ?? package.coverID.flatMap { package.manifest[$0] }
        let coverURL = try cover.map { try resource($0.href, relativeTo: base, root: root) }
        return EPUBPublication(root: root, metadata: metadata, chapters: chapters, coverURL: coverURL)
    }

    static func text(at url: URL) throws -> String {
        let delegate = try parse(url)
        let text = normalizedText(delegate.bodyText)
        guard !text.isEmpty else { throw EPUBError.unreadableChapter }
        return text
    }

    static func content(at url: URL, root: URL) throws -> EPUBChapterContent {
        let delegate = try parse(url)
        let text = normalizedText(delegate.bodyText)
        let images = delegate.images.compactMap { item -> EPUBChapterImage? in
            guard let target = try? resource(item.src, relativeTo: url.deletingLastPathComponent(), root: root),
                  FileManager.default.fileExists(atPath: target.path) else { return nil }
            return EPUBChapterImage(id: item.id, fileURL: target, caption: item.alt, location: delegate.location(at: item.offset, textLength: (text as NSString).length))
        }
        guard !text.isEmpty || !images.isEmpty else { throw EPUBError.unreadableChapter }
        var links: [EPUBChapterLink] = []
        let source = text as NSString
        var offset = 0
        for item in delegate.links {
            let label = normalizedText(item.label)
            guard !label.isEmpty, offset <= source.length else { continue }
            let start = max(offset, item.prefixLength)
            guard start <= source.length else { continue }
            let range = source.range(of: label, options: [], range: NSRange(location: start, length: source.length - start))
            guard range.location != NSNotFound else { continue }
            offset = NSMaxRange(range)
            let target: URL?
            if let external = URL(string: item.href), ["https", "http"].contains(external.scheme?.lowercased() ?? "") {
                target = external
            } else if item.href.hasPrefix("#") {
                target = url
            } else {
                target = try? resource(item.href, relativeTo: url.deletingLastPathComponent(), root: root)
            }
            let resolved: URL?
            if let target, target.isFileURL, let fragment = URLComponents(string: item.href)?.percentEncodedFragment {
                var components = URLComponents(url: target, resolvingAgainstBaseURL: false)
                components?.percentEncodedFragment = fragment
                resolved = components?.url
            } else { resolved = target }
            if let target = resolved { links.append(EPUBChapterLink(location: range.location, length: range.length, url: target)) }
        }
        return EPUBChapterContent(text: text, images: images, links: links, anchors: delegate.anchors.mapValues { delegate.location(at: $0, textLength: source.length) })
    }

    fileprivate static func normalizedText(_ value: String) -> String {
        value.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\n[ \t]+", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parse(_ url: URL) throws -> EPUBXML {
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 16 * 1024 * 1024 else { throw EPUBError.tooLarge }
        var data = try Data(contentsOf: url)
        if let string = String(data: data, encoding: .utf8) {
            data = Data(string.replacingOccurrences(of: "&nbsp;", with: "&#160;").utf8)
        }
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.shouldResolveExternalEntities = false
        let delegate = EPUBXML()
        parser.delegate = delegate
        guard parser.parse() else { throw EPUBError.invalidPackage }
        return delegate
    }
}

private final class EPUBXML: NSObject, XMLParserDelegate {
    struct Item { let href: String; let mediaType: String; let properties: String }
    var rootfile: String?
    var manifest: [String: Item] = [:]
    var spine: [String] = []
    var values: [String: [String]] = [:]
    var coverID: String?
    var bodyText = ""
    var images: [(id: Int, src: String, alt: String, offset: Int)] = []
    var anchors: [String: Int] = [:]
    func location(at offset: Int, textLength: Int) -> Int {
        let prefix = (bodyText as NSString).substring(to: offset)
        return min(textLength, max(0, (EPUBPackage.normalizedText(prefix + "\u{FFFC}") as NSString).length - 1))
    }
    var links: [(href: String, label: String, prefixLength: Int)] = []
    private var activeLink: (href: String, label: String, prefixLength: Int)?
    private var stack: [String] = []
    private var capture: String?
    private var captured = ""
    private var ignoredDepth = 0
    private var inBody = false
    private let breaks: Set<String> = ["p", "div", "br", "h1", "h2", "h3", "li", "section", "blockquote"]
    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        stack.append(name)
        if name == "rootfile", rootfile == nil { rootfile = attributes["full-path"] }
        if name == "item", let id = attributes["id"], let href = attributes["href"] { manifest[id] = Item(href: href, mediaType: attributes["media-type"] ?? "", properties: attributes["properties"] ?? "") }
        if name == "itemref", attributes["linear"] != "no", let id = attributes["idref"] { spine.append(id) }
        if name == "meta", attributes["name"] == "cover" { coverID = attributes["content"] }
        if stack.contains("metadata"), ["title", "creator", "publisher", "identifier", "language", "date", "description"].contains(name) { capture = name; captured = "" }
        if name == "body" { inBody = true }
        if ["script", "style", "iframe", "object"].contains(name) || ignoredDepth > 0 { ignoredDepth += 1 }
        if inBody && ignoredDepth == 0 && breaks.contains(name) { bodyText += "\n\n" }
        if inBody && ignoredDepth == 0 {
            if let anchor = attributes["id"] ?? (name == "a" ? attributes["name"] : nil), anchors[anchor] == nil, anchors.count < 4096 {
                anchors[anchor] = (bodyText as NSString).length
            }
            if name == "img", images.count < 256, let src = attributes["src"] { images.append((images.count, src, attributes["alt"] ?? "", (bodyText as NSString).length)) }
            if name == "a", links.count < 256, let href = attributes["href"] { activeLink = (href, "", (EPUBPackage.normalizedText(bodyText) as NSString).length) }
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if capture != nil { captured += string }
        if inBody && ignoredDepth == 0 { bodyText += string; activeLink?.label += string }
    }
    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if name == "a", let link = activeLink { links.append(link); activeLink = nil }
        if capture == name {
            let value = captured.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { values[name, default: []].append(value) }
            capture = nil
        }
        if ignoredDepth > 0 { ignoredDepth -= 1 }
        else if inBody && breaks.contains(name) { bodyText += "\n\n" }
        if name == "body" { inBody = false }
        _ = stack.popLast()
    }
}

/// Translate UTF-16 text positions without changing persisted quotes/highlights.
struct EPUBDisplayMap {
    let imageLocations: [Int]
    init(imageLocations: [Int]) { self.imageLocations = imageLocations.sorted() }
    func displayOffset(_ source: Int) -> Int {
        source + 3 * imageLocations.filter { $0 <= source }.count
    }
    func sourceOffset(_ display: Int) -> Int {
        var removed = 0
        for location in imageLocations {
            let start = location + removed
            if display < start { break }
            if display <= start + 3 { return location }
            removed += 3
        }
        return max(0, display - removed)
    }
}
