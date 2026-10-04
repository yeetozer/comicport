import SwiftUI

@main
struct PanelReaderApp: App {
    @StateObject private var store = LibraryStore()
    @StateObject private var theme = PanelThemeStore()

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
