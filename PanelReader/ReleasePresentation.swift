import SwiftUI
import Foundation

/// Presentation only: never changes a source filename or persisted metadata.
enum ComicDisplayTitle {
    static func clean(_ source: String) -> String {
        let title = source.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = title.range(of: #"\s+#?0*([0-9]+)$"#, options: .regularExpression),
              let issue = Int(title[range].filter(\.isNumber)) else { return title }
        return String(title[..<range.lowerBound]) + " #\(issue)"
    }

    static func series(_ source: String) -> String {
        clean(source).replacingOccurrences(of: #"\s+#[0-9]+$"#, with: "", options: .regularExpression)
    }

    static func issues(_ count: Int) -> String {
        count == 1 ? String(localized: "1 issue") : String(localized: "\(count) issues")
    }
}

extension ComicBook {
    var displayTitle: String { ComicDisplayTitle.clean(title) }

    /// Do not present an unopened comic as one page read.
    var displayProgress: Double {
        if readingStatus == .completed { return 1 }
        guard currentPage > 0 || lastReadAt != nil else { return 0 }
        return progress
    }

    var displayProgressPercent: Int { Int((displayProgress * 100).rounded()) }
}

enum ComicPortRelease {
    /// Presentation adapter for legacy store messages; storage APIs remain untouched.
    static func copy(_ value: String) -> String {
        switch value {
        case "Ana ekran hazırlanıyor…": return String(localized: "Preparing your home screen…")
        case "ComicPort hazırlanıyor…": return String(localized: "Preparing ComicPort…")
        case "Kütüphane yükleniyor…": return String(localized: "Loading your library…")
        default: return value.replacingOccurrences(of: "Kapak onarılamadı: ", with: String(localized: "Could not repair cover: "))
        }
    }

    static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        return "\(info["CFBundleShortVersionString"] as? String ?? "1.0") (\(info["CFBundleVersion"] as? String ?? "1"))"
    }
}

/// The same destination inventory is available in portrait and narrow windows.
struct DashboardBrowseView: View {
    @Binding var selection: DashboardSection
    private let groups: [(String, [DashboardSection])] = [
        ("Library", [.library, .series, .lists, .favorites, .recentAdded, .smartCollections, .saved]),
        ("Reading", [.reading, .toRead, .completed, .recentRead, .readingOrder2, .notes, .myPanels, .characters]),
        ("You", [.achievements, .statistics, .journal, .wrapped, .history]),
        ("Tools", [.smartSearch, .libraryHealth, .libraryTools, .sourcesSync, .settings])
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups.indices, id: \.self) { index in
                    Section(LocalizedStringKey(groups[index].0)) {
                        ForEach(groups[index].1) { destination in
                            Button { selection = destination } label: {
                                HStack {
                                    Label(destination == .library ? String(localized: "All Comics") : destination == .reading ? String(localized: "Currently Reading") : destination.title, systemImage: destination.icon)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .navigationTitle("Browse")
        }
    }
}

extension PanelAccentTheme {
    static let releaseChoices: [Self] = [.blue, .purple, .red, .orange, .green, .teal, .pink, .yellow]
    var releaseSelection: Self {
        switch self {
        case .indigo: return .blue
        case .cyan, .mint: return .teal
        case .amber: return .orange
        case .rose: return .pink
        case .violet: return .purple
        default: return self
        }
    }
}
