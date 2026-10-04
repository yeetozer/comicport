import WidgetKit
import SwiftUI

struct PanelWidgetEntry: TimelineEntry {
    let date: Date
    let specialDay: WidgetComicDay?
}

struct WidgetComicDay: Hashable {
    let title: String
    let date: Date
    let daysAway: Int
}

struct PanelWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PanelWidgetEntry {
        PanelWidgetEntry(date: .now, specialDay: WidgetComicCalendar.next(from: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (PanelWidgetEntry) -> Void) {
        completion(PanelWidgetEntry(date: .now, specialDay: WidgetComicCalendar.next(from: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PanelWidgetEntry>) -> Void) {
        let now = Date.now
        let entry = PanelWidgetEntry(date: now, specialDay: WidgetComicCalendar.next(from: now))
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(21600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

private enum PanelWidgetLook {
    static let background = LinearGradient(
        colors: [Color(red: 0.04, green: 0.055, blue: 0.08), Color(red: 0.025, green: 0.035, blue: 0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ContinueReadingWidgetView: View {
    let entry: PanelWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "book.pages.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.cyan)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Text("DEVAM ET")
                .font(.caption2.bold())
                .foregroundStyle(.cyan)
            Text("Son okuduğun çizgi romana dön")
                .font(.headline)
                .lineLimit(2)
            Text("ComicPort")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(15)
        .containerBackground(for: .widget) { PanelWidgetLook.background }
        .widgetURL(URL(string: "comicport://continue"))
    }
}

struct ReadingGoalWidgetView: View {
    let entry: PanelWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: "target")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("GÜNLÜK HEDEF")
                .font(.caption2.bold())
                .foregroundStyle(.green)
            Text("Bugünkü okuma hedefini kontrol et")
                .font(.headline)
                .lineLimit(2)
            Text("Hedef ve istatistikler uygulamada")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(15)
        .containerBackground(for: .widget) { PanelWidgetLook.background }
        .widgetURL(URL(string: "comicport://goal"))
    }
}

struct ComicDayWidgetView: View {
    let entry: PanelWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2.bold())
                    .foregroundStyle(.purple)
                Spacer()
                if let event = entry.specialDay {
                    Text(event.daysAway == 0 ? "BUGÜN" : "\(event.daysAway) GÜN")
                        .font(.caption2.bold())
                        .foregroundStyle(.purple)
                }
            }

            Spacer()
            Text("ÇİZGİ ROMAN TAKVİMİ")
                .font(.caption2.bold())
                .foregroundStyle(.purple)

            if let event = entry.specialDay {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(event.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Yaklaşan özel günü ComicPort'ta gör")
                    .font(.headline)
                    .lineLimit(2)
            }
        }
        .padding(15)
        .containerBackground(for: .widget) { PanelWidgetLook.background }
        .widgetURL(URL(string: "comicport://goal"))
    }
}

struct PanelContinueWidget: Widget {
    let kind = "PanelReaderContinue"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PanelWidgetProvider()) { entry in
            ContinueReadingWidgetView(entry: entry)
        }
        .configurationDisplayName("Okumaya Devam")
        .description("ComicPort'ta son okuduğun çizgi romana hızlıca dön.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PanelGoalWidget: Widget {
    let kind = "PanelReaderGoal"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PanelWidgetProvider()) { entry in
            ReadingGoalWidgetView(entry: entry)
        }
        .configurationDisplayName("Okuma Hedefi")
        .description("Günlük okuma hedefin için hızlı giriş.")
        .supportedFamilies([.systemSmall])
    }
}

struct PanelComicDayWidget: Widget {
    let kind = "PanelReaderComicDay"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PanelWidgetProvider()) { entry in
            ComicDayWidgetView(entry: entry)
        }
        .configurationDisplayName("Çizgi Roman Günü")
        .description("Yaklaşan çizgi roman özel gününü gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct PanelReaderWidgetBundle: WidgetBundle {
    var body: some Widget {
        PanelContinueWidget()
        PanelGoalWidget()
        PanelComicDayWidget()
    }
}

private enum WidgetComicCalendar {
    private struct FixedEvent {
        let title: String
        let month: Int
        let day: Int
    }

    private static let fixed: [FixedEvent] = [
        .init(title: "Superman Day", month: 4, day: 18),
        .init(title: "X-Men Day", month: 5, day: 13),
        .init(title: "Spider-Man Day", month: 8, day: 1),
        .init(title: "Read Comics in Public Day", month: 8, day: 28),
        .init(title: "National Comic Book Day", month: 9, day: 25),
        .init(title: "Wonder Woman Day", month: 10, day: 21),
        .init(title: "Stan Lee Birthday", month: 12, day: 28),
        .init(title: "Batman Comic Anniversary", month: 3, day: 30)
    ]

    static func next(from date: Date, calendar: Calendar = .current) -> WidgetComicDay? {
        let start = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: start)
        var candidates: [(Date, String)] = []

        for candidateYear in [year, year + 1] {
            for event in fixed {
                if let d = calendar.date(from: DateComponents(year: candidateYear, month: event.month, day: event.day)), d >= start {
                    candidates.append((d, event.title))
                }
            }

            if let batman = nthWeekday(
                year: candidateYear,
                month: 9,
                weekday: 7,
                ordinal: 3,
                calendar: calendar
            ), batman >= start {
                candidates.append((batman, "Batman Day"))
            }

            if let fcbd = nthWeekday(
                year: candidateYear,
                month: 5,
                weekday: 7,
                ordinal: 1,
                calendar: calendar
            ), fcbd >= start {
                candidates.append((fcbd, "Free Comic Book Day"))
            }
        }

        guard let next = candidates.min(by: { $0.0 < $1.0 }) else { return nil }
        let days = max(0, calendar.dateComponents([.day], from: start, to: next.0).day ?? 0)
        return WidgetComicDay(title: next.1, date: next.0, daysAway: days)
    }

    private static func nthWeekday(
        year: Int,
        month: Int,
        weekday: Int,
        ordinal: Int,
        calendar: Calendar
    ) -> Date? {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
        let firstWeekday = calendar.component(.weekday, from: first)
        let offset = (weekday - firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: offset + (ordinal - 1) * 7, to: first)
    }
}
