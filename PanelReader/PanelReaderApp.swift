import SwiftUI

/// Main-actor ownership makes expiration and completion idempotent.
@MainActor
final class BackgroundTaskToken {
    private var ended = false
    private var endAction: (() -> Void)?

    func install(_ action: @escaping () -> Void) {
        if ended { action() } else { endAction = action }
    }

    func end() {
        guard !ended else { return }
        ended = true
        let action = endAction
        endAction = nil
        action?()
    }
}

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
                    #if !targetEnvironment(macCatalyst)
                    let token = BackgroundTaskToken()
                    let identifier = UIApplication.shared.beginBackgroundTask(withName: "Persist library") {
                        Task { @MainActor in token.end() }
                    }
                    token.install {
                        if identifier != .invalid { UIApplication.shared.endBackgroundTask(identifier) }
                    }
                    #endif
                    Task { @MainActor in
                        #if !targetEnvironment(macCatalyst)
                        defer { token.end() }
                        #endif
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
