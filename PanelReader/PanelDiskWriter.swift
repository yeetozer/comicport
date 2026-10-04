import Foundation

actor PanelDiskWriter {
    static let shared = PanelDiskWriter()

    private init() {}

    func write<T: Encodable & Sendable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }
}
