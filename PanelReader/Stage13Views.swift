import SwiftUI

private struct Stage13BookRoute: Identifiable, Hashable {
    let id: UUID
}

struct LibraryHealthView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var snapshot: LibraryHealthSnapshot?
    @State private var progress: (current: Int, total: Int, title: String)?
    @State private var scanTask: Task<Void, Never>?
    @State private var activeBook: Stage13BookRoute?
    @State private var repairingBookID: UUID?
    @State private var cleanupMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    controls

                    if let progress {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(progress.title).font(.headline).lineLimit(1)
                                Spacer()
                                Text("\(progress.current)/\(max(1, progress.total))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: Double(progress.current), total: Double(max(1, progress.total)))
                                .tint(accentColor)
                        }
                        .padding()
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                    }

                    if let snapshot {
                        summary(snapshot)
                        issues(snapshot)
                    } else if progress == nil {
                        ContentUnavailableView(
                            "Kütüphane taranmaya hazır",
                            systemImage: "stethoscope",
                            description: Text("Hızlı tarama dosya, kapak, boyut ve duplicate sorunlarını kontrol eder. Derin tarama ayrıca PDF/CBZ sayfalarını doğrular.")
                        )
                        .padding(.top, 45)
                    }

                    if let cleanupMessage {
                        Label(cleanupMessage, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Library Health")
            .task {
                if snapshot == nil && progress == nil {
                    startScan(deep: false)
                }
            }
            .onDisappear {
                scanTask?.cancel()
            }
            .navigationDestination(item: $activeBook) { route in
                BookDetailView(bookID: route.id)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(accentColor.opacity(0.14))
                Image(systemName: "heart.text.clipboard.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(accentColor)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("Library Health Center").font(.largeTitle.bold())
                Text("Kütüphaneyi bozuk dosya, duplicate, eksik kapak, büyük dosya ve seri boşlukları için kontrol et.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(19)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.16), .white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var controls: some View {
        HStack {
            Button {
                startScan(deep: false)
            } label: {
                Label("Hızlı Tara", systemImage: "bolt.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(progress != nil)

            Button {
                startScan(deep: true)
            } label: {
                Label("Derin Tara", systemImage: "doc.text.magnifyingglass")
            }
            .buttonStyle(.bordered)
            .disabled(progress != nil)

            if progress != nil {
                Button(role: .destructive) {
                    scanTask?.cancel()
                    scanTask = nil
                    progress = nil
                } label: {
                    Label("İptal", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button {
                Task { @MainActor in
                    let freed = await store.performSafeCacheCleanup()
                    cleanupMessage = freed > 0
                        ? "\(LibraryHealthScanner.formatBytes(freed)) güvenli cache temizlendi."
                        : "Temizlenecek yetim cache bulunmadı."
                    startScan(deep: false)
                }
            } label: {
                Label("Safe Cleanup", systemImage: "sparkles")
            }
            .buttonStyle(.bordered)
            .disabled(progress != nil)
        }
    }

    private func summary(_ snapshot: LibraryHealthSnapshot) -> some View {
        HStack(spacing: 12) {
            healthStat("\(snapshot.availableBooks)/\(snapshot.totalBooks)", "cihazda", "internaldrive.fill")
            healthStat("\(snapshot.criticalCount)", "kritik", "exclamationmark.octagon.fill")
            healthStat("\(snapshot.warningCount)", "uyarı", "exclamationmark.triangle.fill")
            healthStat(LibraryHealthScanner.formatBytes(snapshot.totalBytes), "kitap boyutu", "externaldrive.fill")
        }
    }

    private func healthStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(accentColor)
            Text(value).font(.title3.bold()).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 15))
    }

    @ViewBuilder
    private func issues(_ snapshot: LibraryHealthSnapshot) -> some View {
        let seriesIssues = readingOrderIssues()
        let all = snapshot.issues + seriesIssues

        if all.isEmpty {
            ContentUnavailableView(
                "Kütüphane temiz",
                systemImage: "checkmark.seal.fill",
                description: Text(snapshot.deepScan ? "Derin taramada sorun bulunmadı." : "Hızlı taramada sorun bulunmadı.")
            )
            .padding(.top, 20)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Bulunanlar").font(.title2.bold())
                ForEach(all) { issue in
                    issueRow(issue)
                }
            }
        }
    }

    private func issueRow(_ issue: LibraryHealthIssue) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon(for: issue.kind))
                .foregroundStyle(color(for: issue.severity))
                .frame(width: 38, height: 38)
                .background(color(for: issue.severity).opacity(0.11), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(issue.title).font(.headline)
                Text(issue.detail).font(.subheadline).foregroundStyle(.secondary)

                HStack {
                    if issue.kind == .missingCover, let bookID = issue.bookID {
                        Button {
                            repairingBookID = bookID
                            Task { @MainActor in
                                _ = await store.regenerateCover(for: bookID)
                                repairingBookID = nil
                                startScan(deep: false)
                            }
                        } label: {
                            if repairingBookID == bookID { ProgressView() }
                            else { Label("Kapağı Onar", systemImage: "photo.badge.arrow.down") }
                        }
                        .buttonStyle(.bordered)
                        .disabled(repairingBookID != nil)
                    }

                    if let bookID = issue.bookID {
                        Button {
                            activeBook = Stage13BookRoute(id: bookID)
                        } label: {
                            Label(issue.kind == .veryLargeFile ? "Optimizer'a Git" : "Kitabı Aç", systemImage: "chevron.right")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            Spacer()
        }
        .padding(13)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15))
    }

    private func readingOrderIssues() -> [LibraryHealthIssue] {
        let missing = SeriesService.allMissingIssues(in: store.libraryBooks).map { gap in
            LibraryHealthIssue(
                id: "series-gap|\(gap.id)",
                kind: .seriesGap,
                severity: .info,
                title: gap.seriesTitle,
                detail: "Okuma sırasında #\(gap.issueNumber) eksik görünüyor\(gap.volume.map { " • Vol. \($0)" } ?? "").",
                bookID: nil,
                relatedBookIDs: [],
                seriesID: gap.seriesID
            )
        }

        let duplicates = SeriesService.allDuplicateIssues(in: store.libraryBooks).map { item in
            LibraryHealthIssue(
                id: "series-duplicate|\(item.id)",
                kind: .duplicateIssueNumber,
                severity: .warning,
                title: item.seriesTitle,
                detail: "Aynı seri numarası #\(formatIssue13(item.issueNumber)) birden fazla kayıtta görünüyor.",
                bookID: item.bookIDs.first,
                relatedBookIDs: Array(item.bookIDs.dropFirst()),
                seriesID: item.seriesID
            )
        }
        return missing + duplicates
    }

    private func startScan(deep: Bool) {
        scanTask?.cancel()
        progress = (0, max(1, store.books.count), "Hazırlanıyor…")
        cleanupMessage = nil

        let descriptors = store.books.map {
            LibraryHealthDescriptor(
                id: $0.id,
                title: $0.title,
                fileURL: store.fileURL(for: $0),
                coverURL: store.coverURL(for: $0),
                type: $0.type,
                expectedPageCount: $0.pageCount,
                fileAvailable: $0.fileAvailable,
                sourceIdentity: $0.sourceIdentity
            )
        }

        scanTask = Task { @MainActor in
            do {
                for try await event in LibraryHealthScanner.stream(descriptors: descriptors, deep: deep) {
                    guard !Task.isCancelled else { return }
                    switch event {
                    case .progress(let current, let total, let title):
                        progress = (current, total, title)
                    case .finished(let result):
                        snapshot = result
                        progress = nil
                    }
                }
            } catch is CancellationError {
                progress = nil
            } catch {
                progress = nil
                store.importError = "Library Health scan failed: \(error.localizedDescription)"
            }
            scanTask = nil
        }
    }

    private func color(for severity: LibraryHealthSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return accentColor
        }
    }

    private func icon(for kind: LibraryHealthIssueKind) -> String {
        switch kind {
        case .missingFile: return "externaldrive.badge.questionmark"
        case .unreadableFile: return "doc.badge.ellipsis"
        case .pageCountMismatch: return "number.square"
        case .missingCover: return "photo.badge.exclamationmark"
        case .duplicate: return "square.on.square"
        case .veryLargeFile: return "internaldrive.fill"
        case .metadataUnknown: return "tag.slash"
        case .seriesGap: return "number.square.fill"
        case .duplicateIssueNumber: return "square.stack.3d.up.fill"
        }
    }
}

struct SmartReadingOrder2View: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @State private var series: [ComicSeries] = []

    private var signature: Int {
        var hasher = Hasher()
        for book in store.libraryBooks {
            hasher.combine(book.id)
            hasher.combine(book.title)
            hasher.combine(book.readingStatus.rawValue)
        }
        return hasher.finalize()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Smart Reading Order 2.0").font(.largeTitle.bold())
                            Text("Seri sırasını kontrol et, eksik/tekrar eden sayıları bul ve ilişkili okumaları keşfet.")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    let missingCount = series.reduce(0) { $0 + SeriesService.missingIssues(in: $1, from: store.libraryBooks).count }
                    let duplicateCount = series.reduce(0) { $0 + SeriesService.duplicateIssueNumbers(in: $1, from: store.libraryBooks).count }

                    HStack(spacing: 12) {
                        status("\(series.count)", "seri", "books.vertical.fill")
                        status("\(missingCount)", "eksik sayı", "number.square.fill")
                        status("\(duplicateCount)", "tekrar", "square.stack.3d.up.fill")
                        status("\(store.storyArcs.count)", "özel sıra", "point.3.connected.trianglepath.dotted")
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(series) { item in
                            let missing = SeriesService.missingIssues(in: item, from: store.libraryBooks)
                            let duplicates = SeriesService.duplicateIssueNumbers(in: item, from: store.libraryBooks)

                            NavigationLink {
                                SeriesDetailView(series: item)
                            } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: missing.isEmpty && duplicates.isEmpty ? "checkmark.circle.fill" : "list.number")
                                        .foregroundStyle(missing.isEmpty && duplicates.isEmpty ? .green : accentColor)
                                        .frame(width: 42, height: 42)
                                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 11))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title).font(.headline).foregroundStyle(.primary)
                                        HStack(spacing: 8) {
                                            Text("\(item.bookIDs.count) kitap")
                                            if !missing.isEmpty { Text("• \(missing.count) eksik") }
                                            if !duplicates.isEmpty { Text("• \(duplicates.count) tekrar") }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                }
                                .padding(13)
                                .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .navigationTitle("Reading Order 2.0")
            .task(id: signature) {
                series = SeriesService.series(from: store.libraryBooks)
            }
        }
    }

    private func status(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon).foregroundStyle(accentColor)
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct SeriesReadingOrder2Card: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    let series: ComicSeries

    @State private var suggestions: [RelatedReadingSuggestion] = []

    private var books: [ComicBook] { SeriesService.books(in: series, from: store.libraryBooks) }
    private var missing: [SeriesMissingIssue] { SeriesService.missingIssues(in: series, from: store.libraryBooks) }
    private var duplicates: [SeriesDuplicateIssue] { SeriesService.duplicateIssueNumbers(in: series, from: store.libraryBooks) }

    private var signature: Int {
        var hasher = Hasher()
        for book in store.libraryBooks {
            hasher.combine(book.id)
            hasher.combine(book.title)
        }
        return hasher.finalize()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("Reading Order 2.0", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.title2.bold())
                Spacer()
                if missing.isEmpty && duplicates.isEmpty {
                    Label("Sıra temiz", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }

            if !missing.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Eksik görünen sayılar").font(.headline)
                    Text(missing.prefix(12).map {
                        ($0.volume.map { "Vol. \($0) " } ?? "") + "#\($0.issueNumber)"
                    }.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                }
            }

            if !duplicates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tekrar eden seri numaraları").font(.headline)
                    Text(duplicates.prefix(8).map { "#\(formatIssue13($0.issueNumber))" }.joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            if !suggestions.isEmpty {
                Divider().opacity(0.15)
                Text("İlişkili okuma adayları")
                    .font(.headline)

                Text("Bunlar kanonik crossover sırası iddiası değildir; yerel katalogdaki ortak karakter, tema ve yaratıcı eşleşmelerinden üretilen offline önerilerdir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(suggestions.prefix(5)) { suggestion in
                    if let book = store.books.first(where: { $0.id == suggestion.bookID }) {
                        NavigationLink {
                            BookDetailView(bookID: book.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(suggestion.title).font(.subheadline.bold()).foregroundStyle(.primary)
                                    Text(suggestion.reason).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(9)
                            .background(.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
        .task(id: signature) {
            let sameIDs = Set(books.map(\.id))
            let sourceTitles = books.map(\.title)
            let candidates = store.libraryBooks
                .filter { !sameIDs.contains($0.id) }
                .map { RelatedReadingBook(id: $0.id, title: $0.title) }

            suggestions = await Task.detached(priority: .utility) {
                ReadingOrder2Service.relatedSuggestions(
                    seriesTitles: sourceTitles,
                    candidates: candidates
                )
            }.value
        }
    }
}

private func formatIssue13(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(value)
}
