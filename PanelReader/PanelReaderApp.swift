import SwiftUI
import UIKit

@main
struct PanelReaderApp: App {
    @UIApplicationDelegateAdaptor(ComicPortAppDelegate.self) private var appDelegate
    @StateObject private var store = PanelReaderApp.makeStore()
    @StateObject private var theme = PanelThemeStore()

    @MainActor private static func makeStore() -> LibraryStore {
        #if DEBUG
        if let path = ProcessInfo.processInfo.environment["COMICPORT_TEST_LIBRARY"], path.hasPrefix("/"), path != "/" {
            return LibraryStore(documentsDirectory: URL(fileURLWithPath: path, isDirectory: true))
        }
        #endif
        return LibraryStore()
    }

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(store)
                .environmentObject(theme)
                .environment(\.panelAccentColor, theme.accentColor)
                .tint(theme.accentColor)
        }
        .commands {
            ComicPortCommands(store: store)
        }
    }
}

final class ComicPortAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *) {
            let configuration = UIMainMenuSystem.Configuration()
            configuration.documentPreference = .removed
            UIMainMenuSystem.shared.setBuildConfiguration(configuration)
        }
        #endif
        return true
    }

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        #if targetEnvironment(macCatalyst)
        // SwiftUI supplies Import Comics with Command-O. Remove UIKit's unused
        // Open command so it cannot consume the same shortcut.
        if builder.system == .main {
            builder.remove(menu: .open)
        }
        #endif
    }
}
