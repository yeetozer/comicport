import Foundation
final class UIImage: @unchecked Sendable {}
final class PanelCoverCache: @unchecked Sendable {
    static let shared = PanelCoverCache()
    let lock = NSLock()
    var values: [String: UIImage] = [:]
    func image(for key: String) -> UIImage? { lock.lock(); defer { lock.unlock() }; return values[key] }
    func insert(_ image: UIImage, for key: String) { lock.lock(); defer { lock.unlock() }; values[key] = image }
}
enum CachedCoverImage {
    static let lock = NSLock()
    static var active = 0
    static var peak = 0
    static var calls = 0
    static func downsample(url: URL, maxPixelSize: CGFloat) -> UIImage? {
        lock.lock(); active += 1; calls += 1; peak = max(peak, active); lock.unlock()
        Thread.sleep(forTimeInterval: 0.03)
        lock.lock(); active -= 1; lock.unlock()
        return UIImage()
    }
}
@main struct Checks {
    static func main() async {
        let loader = PanelCoverLoader.shared
        let url = URL(fileURLWithPath: "/tmp/cover-test")
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<16 { group.addTask { _ = await loader.image(url: url, maxPixelSize: 720, key: "cover\(i % 8)|0") } }
        }
        precondition(CachedCoverImage.calls == 8)
        precondition(CachedCoverImage.peak <= 2)
        _ = await loader.image(url: url, maxPixelSize: 720, key: "cover0|0")
        precondition(CachedCoverImage.calls == 8)
        _ = await loader.image(url: url, maxPixelSize: 720, key: "cover0|1")
        precondition(CachedCoverImage.calls == 9)
        print("PASS: cover request coalescing, decode concurrency <= 2, cache reuse and revision refresh")
    }
}
