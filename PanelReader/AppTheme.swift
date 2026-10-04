import SwiftUI

enum PanelAccentTheme: String, CaseIterable, Identifiable, Codable {
    case blue = "Blue"
    case purple = "Purple"
    case red = "Red"
    case orange = "Orange"
    case green = "Green"
    case teal = "Teal"
    case pink = "Pink"
    case indigo = "Indigo"
    case cyan = "Cyan"
    case mint = "Mint"
    case yellow = "Yellow"
    case amber = "Amber"
    case rose = "Rose"
    case violet = "Violet"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .red: return .red
        case .orange: return .orange
        case .green: return .green
        case .teal: return .teal
        case .pink: return .pink
        case .indigo: return .indigo
        case .cyan: return .cyan
        case .mint: return .mint
        case .yellow: return .yellow
        case .amber: return Color(red: 1.00, green: 0.64, blue: 0.08)
        case .rose: return Color(red: 0.94, green: 0.30, blue: 0.46)
        case .violet: return Color(red: 0.57, green: 0.34, blue: 0.95)
        }
    }
}

final class PanelThemeStore: ObservableObject {
    @Published var accent: PanelAccentTheme {
        didSet {
            UserDefaults.standard.set(accent.rawValue, forKey: Self.key)
        }
    }

    private static let key = "PanelReader.accentTheme"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.key),
           let saved = PanelAccentTheme(rawValue: raw) {
            accent = saved
        } else {
            accent = .blue
        }
    }

    var accentColor: Color { accent.color }
}

private struct PanelAccentColorKey: EnvironmentKey {
    static let defaultValue = Color.blue
}

extension EnvironmentValues {
    var panelAccentColor: Color {
        get { self[PanelAccentColorKey.self] }
        set { self[PanelAccentColorKey.self] = newValue }
    }
}
