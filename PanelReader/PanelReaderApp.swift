import SwiftUI

@main
struct PanelReaderApp: App {
    @StateObject private var store = LibraryStore()
    @StateObject private var theme = PanelThemeStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(\.locale, Locale(identifier: "en_US"))
                .environmentObject(store)
                .environmentObject(theme)
                .environment(\.panelAccentColor, theme.accentColor)
                .tint(theme.accentColor)
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .background, store.isBootstrapped else { return }
                    let token = UIApplication.shared.beginBackgroundTask(withName: "Persist library")
                    Task { @MainActor in
                        defer { if token != .invalid { UIApplication.shared.endBackgroundTask(token) } }
                        do { try await store.flush() }
                        catch { store.importError = "Could not save library: \(error.localizedDescription)" }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    if store.isBootstrapped { store.flushForTermination() }
                }
        }
        .commands {
            ComicPortCommands(store: store)
        }
    }
}
