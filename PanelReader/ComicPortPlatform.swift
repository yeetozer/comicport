import Foundation

enum ComicPortPlatform {
    static var displayName: String {
        #if targetEnvironment(macCatalyst)
        return "Mac"
        #else
        return "iPad"
        #endif
    }

    static var isMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }

    static let sharedCodebaseMessage = "iPad + Mac · Shared Core"
}
