import Foundation

@main struct EPUBPackageChecks {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("epub-tests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("META-INF"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("OPS"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        func write(_ path: String, _ value: String) throws { try Data(value.utf8).write(to: root.appendingPathComponent(path)) }
        try write("META-INF/container.xml", """
        <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OPS/package.opf" /></rootfiles></container>
        """)
        try write("OPS/package.opf", """
        <package xmlns="http://www.idpf.org/2007/opf"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Örnek Kitap</dc:title><dc:creator>Çağrı Yılmaz</dc:creator><dc:publisher>Test Press</dc:publisher><dc:language>tr</dc:language><dc:identifier>urn:isbn:9780306406157</dc:identifier><dc:date>2024-01-01</dc:date></metadata><manifest><item id="one" href="chapter%20one.xhtml" media-type="application/xhtml+xml"/><item id="two" href="two.xhtml" media-type="application/xhtml+xml"/><item id="extra" href="missing.xhtml" media-type="application/xhtml+xml"/><item id="cover" href="cover.jpg" media-type="image/jpeg" properties="cover-image"/></manifest><spine><itemref idref="two"/><itemref idref="extra" linear="no"/><itemref idref="one"/></spine></package>
        """)
        try write("OPS/two.xhtml", "<html xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>Hidden head</title></head><body><h1>İkinci Bölüm</h1><p>Türkçe <em>metin</em> &amp; örnek.</p><script>private script</script><style>hidden style</style><p>Son&nbsp;satır.</p></body></html>")
        try write("OPS/chapter one.xhtml", "<html><body><p>Birinci bölüm.</p></body></html>")
        let publication = try EPUBPackage.load(root: root)
        precondition(publication.chapters.count == 2 && publication.chapters[0].fileURL.lastPathComponent == "two.xhtml")
        precondition(publication.chapters[1].fileURL.lastPathComponent == "chapter one.xhtml")
        precondition(publication.metadata.title == "Örnek Kitap" && publication.metadata.authors == ["Çağrı Yılmaz"] && publication.metadata.isbn == "9780306406157" && publication.metadata.publicationYear == "2024")
        precondition(publication.coverURL?.lastPathComponent == "cover.jpg")
        let text = try EPUBPackage.text(at: publication.chapters[0].fileURL)
        precondition(text.contains("Türkçe metin & örnek.") && text.contains("Son") && !text.contains("private script") && !text.contains("hidden style") && !text.contains("Hidden head"))
        for path in ["../../outside", "%2e%2e/%2e%2e/outside", "/etc/passwd", "https://example.com/file", "..\\outside"] {
            do { _ = try EPUBPackage.resource(path, relativeTo: root.appendingPathComponent("OPS"), root: root); preconditionFailure("Unsafe path accepted") }
            catch EPUBError.unsafePath { }
        }
        try write("OPS/two.xhtml", """
        <html><body><p>Tekrar bağlantı.</p><p><a href="chapter%20one.xhtml#note">Tekrar <em>bağlantı</em></a> ve <a href="https://example.com">web</a>.</p><img src="cover.jpg" alt="Bölüm resmi"/><img src="../../escape.jpg"/><img src="https://example.com/remote.jpg"/><a href="javascript:alert(1)">tehlikeli</a><script><img src="hidden.jpg"/></script></body></html>
        """)
        try write("OPS/cover.jpg", "fixture")
        let content = try EPUBPackage.content(at: publication.chapters[0].fileURL, root: root)
        precondition(content.images.count == 1 && content.images[0].caption == "Bölüm resmi")
        precondition(content.links.count == 2 && content.links[0].url.lastPathComponent == "chapter one.xhtml")
        precondition(content.links[1].url.scheme == "https")
        precondition(content.links[0].location > 0 && (content.text as NSString).substring(with: NSRange(location: content.links[0].location, length: content.links[0].length)) == "Tekrar bağlantı")
        let unchangedText = try EPUBPackage.text(at: publication.chapters[0].fileURL)
        precondition(content.text == unchangedText)
        precondition(content.links[0].url.fragment == "note")
        try write("OPS/two.xhtml", "<html><body><p>😀 Önce <a href=\"#dip%20not\">dipnot</a>.</p><img src=\"cover.jpg\"/><p id=\"dip not\">Dipnot metni</p><a name=\"eski\">Eski hedef</a><script id=\"gizli\">x</script></body></html>")
        let anchored = try EPUBPackage.content(at: publication.chapters[0].fileURL, root: root)
        let ns = anchored.text as NSString
        precondition(anchored.anchors["dip not"] == ns.range(of: "Dipnot metni").location)
        precondition(anchored.anchors["eski"] == ns.range(of: "Eski hedef").location)
        precondition(anchored.anchors["gizli"] == nil)
        precondition(URLComponents(url: anchored.links[0].url, resolvingAgainstBaseURL: false)?.fragment == "dip not")
        precondition(anchored.images[0].location <= anchored.anchors["dip not"]!)
        let map = EPUBDisplayMap(imageLocations: [0, 5, 5, 12])
        for location in 0...20 { precondition(map.sourceOffset(map.displayOffset(location)) == location) }
        precondition(map.sourceOffset(1) == 0 && map.sourceOffset(9) == 5)
        try write("OPS/two.xhtml", "<html><body><img src=\"cover.jpg\"/></body></html>")
        let imageOnly = try EPUBPackage.content(at: publication.chapters[0].fileURL, root: root)
        precondition(imageOnly.images.count == 1)
        try write("OPS/two.xhtml", "<html><body><p>broken</body></html>")
        do { _ = try EPUBPackage.text(at: publication.chapters[0].fileURL); preconditionFailure("Malformed chapter accepted") }
        catch EPUBError.invalidPackage { }
        print("PASS: EPUB spine order, non-linear exclusion, embedded metadata, encoded paths, Unicode text, script/style exclusion, traversal rejection, local image discovery, image-only chapters, repeated link labels, safe link targets, unchanged highlight text and malformed XML")
    }
}
