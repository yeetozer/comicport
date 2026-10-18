import SwiftUI

struct CompactComicFactBar: View {
    @Environment(\.panelAccentColor) private var accentColor
    @State private var fact: ComicFact = ComicFactCatalog.random()

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.12))
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(accentColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("DID YOU KNOW?")
                        .font(.caption2.bold())
                        .foregroundStyle(accentColor)
                    Text(fact.category)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(fact.text)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 8)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    fact = ComicFactCatalog.random(excluding: fact.id)
                }
            } label: {
                Image(systemName: "shuffle")
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show another fact")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 62, maxHeight: 82, alignment: .leading)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentColor.opacity(0.12)))
        .onAppear { fact = ComicFactCatalog.random() }
    }
}


struct CompactComicRecommendationBar: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var recommendations: [ComicRecommendation] = []
    @State private var currentIndex = 0
    @State private var loading = true

    private var recommendation: ComicRecommendation? {
        guard recommendations.indices.contains(currentIndex) else { return recommendations.first }
        return recommendations[currentIndex]
    }

    private var recommendationCardMaxHeight: CGFloat {
        recommendation?.occasionTitle == nil ? 82 : 96
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.12))
                Image(systemName: recommendation?.occasionTitle == nil ? "sparkles" : "calendar.badge.clock")
                    .foregroundStyle(accentColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(recommendation?.occasionTitle == nil ? "RECOMMENDED FOR YOU" : "EVENT RECOMMENDATION")
                        .font(.caption2.bold())
                        .foregroundStyle(accentColor)

                    if let recommendation {
                        Text(recommendation.publisher)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let year = recommendation.year {
                            Text("• \(year)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let recommendation {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 7) {
                            Text(recommendation.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)

                            if recommendation.occasionTitle == nil {
                                Text("— \(recommendation.reason)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        if recommendation.occasionTitle != nil {
                            Label(recommendation.reason, systemImage: "calendar.badge.clock")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(accentColor)
                                .lineLimit(2)
                        }
                    }
                } else if loading {
                    Text("Finding a recommendation for your library…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Add or rate a few comics to get recommendations.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Button {
                nextRecommendation()
            } label: {
                Image(systemName: "shuffle")
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(recommendations.count < 2)
            .accessibilityLabel("Show another recommendation")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 62, maxHeight: recommendationCardMaxHeight, alignment: .leading)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentColor.opacity(0.12)))
        .task(id: store.recommendationTasteKey) {
            loading = true
            let result = await store.comicRecommendations()
            guard !Task.isCancelled else { return }
            recommendations = result
            currentIndex = 0
            loading = false
        }
    }

    private func nextRecommendation() {
        guard recommendations.count > 1 else { return }
        withAnimation(.easeInOut(duration: 0.16)) {
            let visibleWindow = min(18, recommendations.count)
            var next = Int.random(in: 0..<visibleWindow)
            if next == currentIndex { next = (next + 1) % visibleWindow }
            currentIndex = next
        }
    }
}

struct CalendarDateBadge: View {
    @Environment(\.panelAccentColor) private var accentColor
    let date: Date
    let pages: Int
    let isToday: Bool
    let events: [ComicCalendarEvent]
    var size: CGFloat = 28

    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                if pages > 0 {
                    Circle()
                        .fill(Color.green.opacity(min(0.86, 0.30 + Double(pages) / 180.0)))
                } else if isToday {
                    Circle()
                        .fill(accentColor.opacity(0.09))
                }

                if let event = events.first {
                    Circle()
                        .stroke(event.kind.color, lineWidth: 1.7)
                } else if isToday {
                    Circle()
                        .stroke(accentColor.opacity(0.85), lineWidth: 1.35)
                }

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption2.weight(isToday || !events.isEmpty ? .bold : .regular))
                    .foregroundStyle(pages > 0 ? .white : .primary)
            }
            .frame(width: size, height: size)

            HStack(spacing: 2) {
                if events.count > 1 {
                    ForEach(Array(events.dropFirst().prefix(3))) { event in
                        Circle()
                            .fill(event.kind.color)
                            .frame(width: 4, height: 4)
                    }
                } else {
                    Color.clear.frame(width: 4, height: 4)
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let day = date.formatted(date: .long, time: .omitted)
        let reading = pages > 0 ? ", \(pages) pages read" : ""
        let eventText = events.isEmpty ? "" : ", " + events.map(\.title).joined(separator: ", ")
        return day + reading + eventText
    }
}


struct Stage7StatisticsView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    private var currentStreak: Int { ReadingInsightsService.currentStreak(store: store) }
    private var bestStreak: Int { ReadingInsightsService.longestStreak(store: store) }
    private var week: [(Date, DailyReadingStat)] { ReadingInsightsService.last7Days(store: store) }
    private var maxWeekPages: Int { max(1, week.map(\.1.pages).max() ?? 1) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Statistics").font(.largeTitle.bold())

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
                        insightCard("Current Streak", "\(currentStreak) days", "flame.fill", .orange)
                        insightCard("Longest Streak", "\(bestStreak) days", "bolt.fill", .yellow)
                        insightCard("Active Days", "\(store.analytics.daily.values.filter { $0.pages > 0 }.count)", "calendar", accentColor)
                        insightCard("Total Sessions", "\(store.analytics.history.count)", "rectangle.stack.fill", .purple)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 Days").font(.title2.bold())
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(Array(week.enumerated()), id: \.offset) { _, item in
                                VStack(spacing: 6) {
                                    Text("\(item.1.pages)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(accentColor.opacity(item.1.pages > 0 ? 0.85 : 0.12))
                                        .frame(height: max(5, CGFloat(item.1.pages) / CGFloat(maxWeekPages) * 120))
                                    Text(item.0.formatted(.dateTime.weekday(.narrow)))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 165, alignment: .bottom)
                        .padding()
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                    }

                    YearReadingHeatmap()
                    FullComicCalendarView()
                }
                .padding(20)
                .padding(.bottom, 70)
            }
            .navigationTitle("Reading Insights")
        }
    }

    @ViewBuilder
    private func insightCard(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 50, height: 50)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading) {
                Text(title).foregroundStyle(.secondary)
                Text(value).font(.title2.bold())
            }
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct YearReadingHeatmap: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<365).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 365 Days").font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                let weeks = stride(from: 0, to: days.count, by: 7).map {
                    Array(days[$0..<min($0 + 7, days.count)])
                }
                HStack(alignment: .top, spacing: 4) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: 4) {
                            ForEach(week, id: \.self) { day in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(heatColor(day))
                                    .frame(width: 13, height: 13)
                                    .help("\(day.formatted(date: .abbreviated, time: .omitted)) • \(pages(day)) pages")
                            }
                        }
                    }
                }
                .padding(14)
            }
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func pages(_ date: Date) -> Int {
        store.analytics.daily[dayKey(date)]?.pages ?? 0
    }

    private func heatColor(_ date: Date) -> Color {
        let value = pages(date)
        if value == 0 { return .white.opacity(0.06) }
        if value < 25 { return accentColor.opacity(0.30) }
        if value < 75 { return accentColor.opacity(0.50) }
        if value < 150 { return accentColor.opacity(0.72) }
        return accentColor
    }

    private func dayKey(_ date: Date) -> String {
        PanelDayKey.string(date)
    }
}

struct FullComicCalendarView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @State private var shownMonth: Date
    @State private var selectedDate: Date?
    @State private var showJumpPicker = false
    @State private var jumpDate: Date
    @State private var monthEventMap: [String: [ComicCalendarEvent]] = [:]

    init(initialDate: Date = .now) {
        let calendar = Calendar.current
        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: initialDate)
        ) ?? initialDate
        _shownMonth = State(initialValue: monthStart)
        _jumpDate = State(initialValue: initialDate)
    }

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Reading Calendar").font(.title2.bold())
                Spacer()

                Button {
                    jumpDate = shownMonth
                    showJumpPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(shownMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                    }
                    .frame(minWidth: 175)
                }
                .buttonStyle(.bordered)

                Button {
                    jumpTo(.now)
                } label: {
                    Text("Today")
                }
                .buttonStyle(.bordered)

                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.bordered)
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.bordered)
            }

            HStack {
                ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { day in
                    Text(day).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 7) {
                ForEach(Array(monthDays().enumerated()), id: \.offset) { _, date in
                    if let date {
                        Button { selectedDate = date } label: {
                            let key = PanelDayKey.string(date, calendar: calendar)
                            let events = monthEventMap[key] ?? []
                            let pages = store.analytics.daily[key]?.pages ?? 0

                            VStack(spacing: 2) {
                                CalendarDateBadge(
                                    date: date,
                                    pages: pages,
                                    isToday: calendar.isDateInToday(date),
                                    events: events,
                                    size: 30
                                )

                                Text(pages > 0 ? "\(pages)p" : " ")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(cellBackground(date), in: RoundedRectangle(cornerRadius: 9))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }

            HStack(spacing: 14) {
                legend(.official)
                legend(.publisher)
                legend(.community)
                legend(.milestone)
            }
            .font(.caption2)
        }
        .padding(16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
        .task(id: monthCacheKey) {
            monthEventMap = ComicCalendarService.eventMap(inMonthContaining: shownMonth, calendar: calendar)
        }
        .sheet(item: Binding(
            get: { selectedDate.map { SelectedCalendarDate(date: $0) } },
            set: { selectedDate = $0?.date }
        )) { item in
            DayReadingDetailView(date: item.date)
                .environmentObject(store)
        }
        .sheet(isPresented: $showJumpPicker) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Jump to a date")
                        .font(.title2.bold())

                    DatePicker(
                        "Date",
                        selection: $jumpDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)

                    Text("Choose a date to jump to its month and year. Browse your reading history and upcoming comic events in one calendar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(20)
                .navigationTitle("Choose Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showJumpPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Go") {
                            jumpTo(jumpDate)
                            showJumpPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func cellBackground(_ date: Date) -> Color {
        let pages = store.analytics.daily[dayKey(date)]?.pages ?? 0
        if pages > 0 { return accentColor.opacity(min(0.42, 0.12 + Double(pages) / 700)) }
        if calendar.isDateInToday(date) { return accentColor.opacity(0.12) }
        return .white.opacity(0.035)
    }

    private func legend(_ kind: ComicCalendarEventKind) -> some View {
        HStack(spacing: 4) { Circle().fill(kind.color).frame(width: 7, height: 7); Text(kind.rawValue) }
    }

    private var monthCacheKey: String {
        let parts = calendar.dateComponents([.year, .month], from: shownMonth)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)"
    }

    private func changeMonth(_ delta: Int) {
        if let value = calendar.date(byAdding: .month, value: delta, to: shownMonth) {
            shownMonth = monthStart(value)
            jumpDate = shownMonth
        }
    }

    private func jumpTo(_ date: Date) {
        shownMonth = monthStart(date)
        jumpDate = date
    }

    private func monthStart(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func monthDays() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: shownMonth),
              let interval = calendar.dateInterval(of: .month, for: shownMonth) else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leading = (weekday + 5) % 7
        var result = Array<Date?>(repeating: nil, count: leading)
        for day in range {
            result.append(calendar.date(bySetting: .day, value: day, of: shownMonth))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func dayKey(_ date: Date) -> String {
        PanelDayKey.string(date)
    }
}

private struct SelectedCalendarDate: Identifiable {
    let id = UUID()
    let date: Date
}

struct DayReadingDetailView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let date: Date

    private var sessions: [ReadingHistoryEntry] { ReadingInsightsService.daySessions(store: store, date: date) }
    private var events: [ComicCalendarEvent] { ComicCalendarService.events(on: date) }
    private var pages: Int { store.analytics.daily[dayKey(date)]?.pages ?? 0 }
    private var seconds: TimeInterval { store.analytics.daily[dayKey(date)]?.seconds ?? 0 }

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Pages read", value: "\(pages)")
                    LabeledContent("Reading time", value: shortDuration(seconds))
                    LabeledContent("Sessions", value: "\(sessions.count)")
                }

                if !events.isEmpty {
                    Section("Comic Calendar") {
                        ForEach(events) { event in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: event.kind.icon).foregroundStyle(event.kind.color)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title).font(.headline)
                                    Text(event.detail).font(.caption).foregroundStyle(.secondary)
                                    Text(event.kind.rawValue).font(.caption2.bold()).foregroundStyle(event.kind.color)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }

                if !sessions.isEmpty {
                    Section("Read") {
                        ForEach(sessions) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.bookTitle(for: entry.bookID)).font(.headline)
                                Text("\(entry.pagesRead) pages • \(shortDuration(entry.seconds))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(date: .long, time: .omitted))
            .toolbar { Button("Close") { dismiss() } }
        }
    }

    private func dayKey(_ date: Date) -> String {
        PanelDayKey.string(date)
    }
}

struct PanelWrappedView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @State private var year = Calendar.current.component(.year, from: .now)

    private var summary: YearReadingSummary {
        ReadingInsightsService.yearSummary(store: store, year: year)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PANEL").font(.caption.bold()).tracking(2).foregroundStyle(accentColor)
                            Text("\(year) WRAPPED").font(.largeTitle.bold())
                        }
                        Spacer()
                        Stepper("", value: $year, in: 2020...Calendar.current.component(.year, from: .now))
                            .labelsHidden()
                    }

                    wrappedHero
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 14)], spacing: 14) {
                        wrappedCard("Total Pages", "\(summary.pages)", "book.pages.fill", .green)
                        wrappedCard("Reading Time", shortDuration(summary.seconds), "clock.fill", .purple)
                        wrappedCard("Completed", "\(summary.completedBooks)", "checkmark.circle.fill", .orange)
                        wrappedCard("Active Days", "\(summary.activeDays)", "calendar", accentColor)
                        wrappedCard("Longest Streak", "\(summary.longestStreak) days", "flame.fill", .red)
                        wrappedCard("Achievements", "\(summary.achievements)", "trophy.fill", .yellow)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Favorites of the Year").font(.title2.bold())
                        wrappedLine("Most-read character", summary.topCharacter, "person.fill")
                        wrappedLine("Most-read series", summary.topSeries, "books.vertical.fill")
                        wrappedLine("Most-read publisher", summary.topPublisher, "building.2.fill")
                        wrappedLine("Busiest month", summary.busiestMonthName, "calendar.badge.clock")
                        wrappedLine("Longest session", shortDuration(summary.longestSession), "hourglass")
                    }
                    .padding()
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))

                    ShareLink(item: summary.shareText) {
                        Label("Share Your Year in Review", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(20)
                .padding(.bottom, 70)
            }
            .navigationTitle("Panel Wrapped")
        }
    }

    private var wrappedHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(summary.pages > 0 ? "A year of stories, one panel at a time." : "This year’s story has not started yet.")
                .font(.title2.bold())
            Text(summary.pages > 0
                 ? "You read \(summary.pages) pages across \(summary.sessions) sessions. Your busiest month was \(summary.busiestMonthName)."
                 : "Start reading to build your year in review.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [accentColor.opacity(0.26), .white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func wrappedCard(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.title2).foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(15)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private func wrappedLine(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(accentColor).frame(width: 28)
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).lineLimit(1)
        }
        .padding(.vertical, 6)
    }
}
