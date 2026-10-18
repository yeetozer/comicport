import SwiftUI
import UIKit

struct BookDetailView: View {
    @EnvironmentObject var store: LibraryStore
    let bookID: UUID
    @State private var info: OfflineComicInfo?
    @State private var analyzing = false
    @State private var analysisError: String?
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var confirmRestart = false
    @State private var confirmArchive = false
    @State private var confirmRemove = false
    @State private var confirmFileDelete = false
    @State private var confirmPermanentDelete = false
    @State private var showReader = false
    @State private var showStorageOptimizer = false
    @State private var readerLaunchError: String?
    @State private var showMetadataEditor = false
    @State private var showCoverChooser = false
    @State private var showRepairLab = false

    private var book: ComicBook? { store.books.first(where: { $0.id == bookID }) }

    var body: some View {
        Group {
            if let book {
                ScrollView {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 28) {
                            VStack(alignment: .leading, spacing: 20) {
                                header(book)
                                readingActions(book)
                                metadataControls(book)
                            }
                            .frame(width: 360)
                            VStack(alignment: .leading, spacing: 24) {
                                seriesControls(book)
                                advancedControls(book)
                            }
                            .frame(minWidth: 340, maxWidth: .infinity)
                        }
                        VStack(alignment: .leading, spacing: 24) {
                            header(book)
                            readingActions(book)
                            metadataControls(book)
                            seriesControls(book)
                            advancedControls(book)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
                .navigationTitle(book.displayTitle)
                .navigationBarTitleDisplayMode(.inline)
                .task { loadCachedInfo(book) }
            } else {
                ContentUnavailableView("Book not found", systemImage: "exclamationmark.triangle")
            }
        }
        .fullScreenCover(isPresented: $showReader) {
            ReadingSessionHostView(initialBookID: bookID)
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
        .alert("Could not open comic", isPresented: Binding(
            get: { readerLaunchError != nil },
            set: { if !$0 { readerLaunchError = nil } }
        )) {
            Button("OK", role: .cancel) { readerLaunchError = nil }
        } message: {
            Text(readerLaunchError ?? "")
        }
        .sheet(isPresented: $showStorageOptimizer) {
            StorageOptimizerView(bookID: bookID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showMetadataEditor) {
            ComicMetadataEditorView(bookID: bookID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showCoverChooser) {
            ComicCoverChooserView(bookID: bookID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showRepairLab) {
            ComicRepairLabView(bookID: bookID)
                .environmentObject(store)
        }
        .confirmationDialog("Start over?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Start Over", role: .destructive) { store.restartComic(id: bookID) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your progress will reset and this comic will be marked To Read.")
        }
        .confirmationDialog("Archive this comic?", isPresented: $confirmArchive, titleVisibility: .visible) {
            if let book { Button("Archive", role: .destructive) { store.archive(book) } }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog("Remove from Library?", isPresented: $confirmRemove, titleVisibility: .visible) {
            if let book { Button("Remove from Library", role: .destructive) { store.removeFromLibrary(book) } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The file and reading data are kept. You can restore this comic from Saved.")
        }
        .confirmationDialog("Delete the comic file from this device?", isPresented: $confirmFileDelete, titleVisibility: .visible) {
            if let book { Button("Delete File Only", role: .destructive) { store.deleteFileKeepingData(book) } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your reading history, progress, rating, favorite status, notes and saved information stay in ComicPort.")
        }
        .confirmationDialog("Delete completely?", isPresented: $confirmPermanentDelete, titleVisibility: .visible) {
            if let book { Button("Delete Everything", role: .destructive) { store.permanentlyDelete(book) } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes the file and all saved data associated with this comic.")
        }
        .alert("Offline analysis", isPresented: Binding(get: { analysisError != nil }, set: { if !$0 { analysisError = nil } })) {
            Button("OK", role: .cancel) { analysisError = nil }
        } message: { Text(analysisError ?? "") }
    }

    @ViewBuilder private func header(_ book: ComicBook) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            CachedCoverImage(url: store.coverURL(for: book), comicType: book.type, maxPixelSize: 700)
            .frame(width: 190, height: 285)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 12) {
                Text(info?.comicInfoPresent == true ? info!.displayTitle : book.displayTitle).font(.largeTitle.bold()).lineLimit(2).truncationMode(.tail)
                Label("\(book.pageCount) pages", systemImage: "book.pages")
                Label("\(book.displayProgressPercent)% read · page \(min(book.currentPage + 1, max(1, book.pageCount)))/\(book.pageCount)", systemImage: "chart.line.uptrend.xyaxis")
                ProgressView(value: book.displayProgress).frame(maxWidth: 320)
                if let date = book.lastReadAt { Label { Text("Last read ") + Text(date, style: .relative) } icon: { Image(systemName: "clock") } }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func readingActions(_ book: ComicBook) -> some View {
        HStack {
            if book.fileAvailable {
                Button {
                    if let error = store.readerLaunchError(for: book.id) {
                        readerLaunchError = error
                    } else {
                        showReader = true
                    }
                } label: {
                    Label(book.currentPage > 0 ? String(localized: "Continue · page \(book.currentPage + 1)") : String(localized: "Start Reading"), systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: 360, alignment: .leading)

            } else {
                Label("File is not on this device · import the same comic to reconnect", systemImage: "externaldrive.badge.xmark")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func metadataControls(_ book: ComicBook) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 8) {
            Button { store.toggleFavorite(id: book.id) } label: { Label(book.favorite ? "Favorite" : "Add Favorite", systemImage: book.favorite ? "heart.fill" : "heart") }
            Menu { ForEach(ReadingStatus.allCases) { status in Button(status.rawValue) { store.setStatus(id: book.id, status: status) } } } label: { Label(book.readingStatus.rawValue, systemImage: book.readingStatus.systemImage) }
            Menu { Button("No rating") { store.setRating(id: book.id, rating: 0) }; ForEach(1...5, id: \.self) { n in Button(String(repeating: "★", count: n)) { store.setRating(id: book.id, rating: n) } } } label: { Label(book.rating == 0 ? "Rate" : "\(book.rating)/5", systemImage: "star.fill") }
            Menu {
                Section("Advanced") {
                    Button("Edit Metadata", systemImage: "pencil.and.list.clipboard") { showMetadataEditor = true }
                    Button("Choose Cover", systemImage: "photo.on.rectangle") { showCoverChooser = true }
                    Button("Repair Comic", systemImage: "wand.and.stars") { showRepairLab = true }
                    Button("Optimize Storage", systemImage: "internaldrive") { showStorageOptimizer = true }
                    Button("Analyze Offline", systemImage: "viewfinder") { analyze(book, force: true) }
                        .disabled(analyzing || !book.fileAvailable)
                    Button("Start Over", systemImage: "arrow.counterclockwise") { confirmRestart = true }
                }
                Section("Library & Storage") {
                    if book.isArchived {
                        Button("Return from Archive") { store.unarchive(book) }
                    } else {
                        Button("Archive", role: .destructive) { confirmArchive = true }
                    }
                    if book.isInLibrary {
                        Button("Remove from Library", role: .destructive) { confirmRemove = true }
                    } else if book.fileAvailable {
                        Button("Return to Library") { store.restoreToLibrary(book) }
                    }
                    if book.fileAvailable {
                        Button("Delete File Only", role: .destructive) { confirmFileDelete = true }
                    }
                    Button("Delete Completely", role: .destructive) { confirmPermanentDelete = true }
                }
            } label: {
                Image(systemName: "ellipsis").frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("More comic actions")
            Spacer()
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder private func seriesControls(_ book: ComicBook) -> some View {
        if let series = store.series(for: book.id) {
            let ordered = SeriesService.books(in: series, from: store.libraryBooks)
            let parsed = SeriesService.parse(book.title)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Series & Reading Order", systemImage: "books.vertical.fill")
                        .font(.title2.bold())
                    Spacer()
                    Text(ComicDisplayTitle.issues(ordered.count))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Series", value: ComicDisplayTitle.series(series.title))
                if let issue = parsed.issueNumber {
                    LabeledContent("Issue", value: "#\(issue.rounded() == issue ? String(Int(issue)) : String(issue))")
                }
                if let volume = parsed.volume { LabeledContent("Volume", value: String(volume)) }
                if parsed.edition != .standard { LabeledContent("Edition", value: parsed.edition.rawValue) }

                HStack {
                    if let previous = store.previousIssue(before: book.id) {
                        NavigationLink {
                            BookDetailView(bookID: previous.id)
                        } label: {
                            Label("Previous Issue", systemImage: "chevron.left")
                        }
                    }

                    Spacer()

                    if let next = store.nextIssue(after: book.id) {
                        NavigationLink {
                            BookDetailView(bookID: next.id)
                        } label: {
                            Label("Next Issue", systemImage: "chevron.right")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func advancedControls(_ book: ComicBook) -> some View {
        DisclosureGroup("Advanced") {
            BookSearchIndexCard(book: book)
            offlineInfoCard(book)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder private func offlineInfoCard(_ book: ComicBook) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Book Info · Offline", systemImage: "iphone.gen3.radiowaves.left.and.right.slash")
                    .font(.title2.bold())
                Spacer()
                Button { analyze(book, force: true) } label: { Label(info == nil ? "Analyze" : "Analyze Again", systemImage: "viewfinder") }
                    .buttonStyle(.borderedProminent)
                    .disabled(analyzing || !book.fileAvailable)
            }

            if analyzing {
                HStack { ProgressView(); Text("Reading metadata and scanning the first pages locally on this device…").foregroundStyle(.secondary) }
            } else if let info {
                HStack {
                    LabeledContent("Detected title", value: info.displayTitle)
                    if let authority = info.metadataAuthority {
                        Text(authority.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                authority == .verified ? Color.green.opacity(0.16) : Color.orange.opacity(0.16),
                                in: Capsule()
                            )
                    }
                }
                if info.comicInfoPresent == true {
                    Label("ComicInfo.xml metadata", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                if let series = info.series { LabeledContent("Series", value: series) }
                if let issue = info.issue { LabeledContent("Issue", value: "#\(issue)") }
                if let year = info.year { LabeledContent("Year", value: year) }
                if let volume = info.volume { LabeledContent("Volume", value: String(volume)) }
                if let publisher = info.publisher { LabeledContent("Publisher", value: publisher) }
                if let imprint = info.imprint { LabeledContent("Imprint", value: imprint) }
                if let language = info.languageISO { LabeledContent("Language", value: language) }
                if let format = info.format { LabeledContent("Format", value: format) }
                if let storyArc = info.storyArc { LabeledContent("Story Arc", value: storyArc) }
                if !info.creators.isEmpty { LabeledContent("Creators", value: info.creators.joined(separator: ", ")) }
                if let characters = info.characters, !characters.isEmpty {
                    LabeledContent("Characters", value: characters.joined(separator: ", "))
                }
                if let genres = info.genres, !genres.isEmpty {
                    LabeledContent("Genres", value: genres.joined(separator: ", "))
                }
                LabeledContent("File", value: "\(info.fileType) · \(info.pageCount) pages")

                if let match = info.databaseMatch {
                    Divider()
                    HStack {
                        Label("Local catalog match", systemImage: "internaldrive")
                            .font(.headline)
                        Spacer()
                        if let confidence = info.databaseConfidence {
                            Text("\(confidence)% match")
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    LabeledContent("Catalog title", value: match.title)
                    LabeledContent("Publisher", value: match.publisher)
                    if let year = match.year { LabeledContent("First published", value: String(year)) }
                    if !match.creators.isEmpty { LabeledContent("Known creators", value: match.creators.joined(separator: ", ")) }
                    if !match.characters.isEmpty {
                        Text("Characters").font(.subheadline.bold())
                        Text(match.characters.joined(separator: " · ")).foregroundStyle(.secondary)
                    }
                    if !match.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(match.tags, id: \.self) { tag in Text(tag).font(.caption).padding(.horizontal, 9).padding(.vertical, 5).background(.quaternary, in: Capsule()) } }
                        }
                    }
                }

                Divider()
                Text("Local summary").font(.headline)
                Text(info.summary).textSelection(.enabled)

                if !info.detectedText.isEmpty {
                    DisclosureGroup("Text detected on cover / first pages") {
                        Text(info.detectedText).font(.callout.monospaced()).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                    }
                }

                Text(info.confidenceNote).font(.caption).foregroundStyle(.secondary)
            } else {
                ContentUnavailableView("Not analyzed yet", systemImage: "text.viewfinder", description: Text("Tap Analyze. The comic stays on your \(ComicPortPlatform.displayName); ComicInfo.xml, OCR and local matching use no API or web service."))
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func loadCachedInfo(_ book: ComicBook) {
        if let cached = store.loadOfflineInfo(bookID: book.id) { info = cached }
    }

    private func analyze(_ book: ComicBook, force: Bool) {
        if !force, let cached = store.loadOfflineInfo(bookID: book.id) { info = cached; return }
        analyzing = true
        analysisError = nil
        Task {
            do {
                let result = try await BookInfoService.analyze(book: book, fileURL: store.fileURL(for: book))
                await MainActor.run {
                    info = result
                    store.saveOfflineInfo(result, bookID: book.id)
                    analyzing = false
                }
            } catch {
                await MainActor.run { analysisError = error.localizedDescription; analyzing = false }
            }
        }
    }
}


// MARK: - Stage 20.4 Library Power Tools

private struct ComicMetadataEditorView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID

    @State private var title = ""
    @State private var series = ""
    @State private var issue = ""
    @State private var year = ""
    @State private var publisher = ""
    @State private var creators = ""
    @State private var summary = ""
    @State private var writeComicInfo = true
    @State private var status: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Title", text: $title)
                    TextField("Series", text: $series)
                    TextField("Issue", text: $issue)
                    TextField("Year", text: $year)
                    TextField("Publisher", text: $publisher)
                }
                Section("Creators") {
                    TextField("Comma-separated creators", text: $creators, axis: .vertical)
                }
                Section("Summary") {
                    TextField("Summary", text: $summary, axis: .vertical)
                        .lineLimit(4...10)
                }
                Section("ComicInfo.xml") {
                    Toggle("Write metadata into the archive", isOn: $writeComicInfo)
                    Text("For archive comics, write-back creates a normalized CBZ and preserves page images. PDF metadata remains local unless you convert it to CBZ in Repair Lab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let status {
                    Section { Text(status).font(.caption).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Edit Metadata")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") {
                        saving = true
                        Task {
                            status = await store.saveEditedMetadata(
                                bookID: bookID,
                                title: title,
                                series: series,
                                issue: issue,
                                year: year,
                                publisher: publisher,
                                creators: creators,
                                summary: summary,
                                writeComicInfo: writeComicInfo
                            )
                            saving = false
                        }
                    }
                    .disabled(saving)
                }
            }
            .task { load() }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 620, idealWidth: 700, minHeight: 620)
        #endif
    }

    private func load() {
        guard let book = store.books.first(where: { $0.id == bookID }) else { return }
        let info = store.loadOfflineInfo(bookID: bookID)
        title = info?.displayTitle ?? book.title
        series = info?.series ?? SeriesService.parse(book.title).seriesTitle
        issue = info?.issue ?? ""
        year = info?.year ?? ""
        publisher = info?.publisher ?? ""
        creators = info?.creators.joined(separator: ", ") ?? ""
        summary = info?.summary ?? ""
        writeComicInfo = book.type == .cbz
    }
}

private struct ComicCoverChooserView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    @State private var page = 0
    @State private var preview: UIImage?
    @State private var loading = false
    @State private var saving = false

    private var book: ComicBook? { store.books.first { $0.id == bookID } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let preview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 480)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else if loading {
                    ProgressView().controlSize(.large)
                }

                if let book {
                    HStack {
                        Text("Page \(page + 1)").monospacedDigit()
                        Slider(
                            value: Binding(
                                get: { Double(page) },
                                set: { page = Int($0.rounded()) }
                            ),
                            in: 0...Double(max(1, book.pageCount - 1)),
                            step: 1
                        )
                        Text("\(book.pageCount)").monospacedDigit()
                    }
                }
            }
            .padding(22)
            .navigationTitle("Choose Cover")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Use This Page") {
                        saving = true
                        Task {
                            if await store.setCover(bookID: bookID, page: page) { dismiss() }
                            saving = false
                        }
                    }
                    .disabled(saving || preview == nil)
                }
            }
            .task(id: page) { await loadPreview() }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 560, minHeight: 650)
        #endif
    }

    private func loadPreview() async {
        guard let book else { return }
        loading = true
        preview = nil
        let data = await ReaderPageSnapshotService.loadSnapshot(
            fileURL: store.fileURL(for: book),
            type: book.type,
            page: page,
            settings: store.readerSettings(for: book.id),
            maxPixel: 1200
        )
        if !Task.isCancelled { preview = data.flatMap(UIImage.init(data:)); loading = false }
    }
}

private struct ComicRepairLabView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID

    @State private var preview: ComicRepairPreview?
    @State private var removeBlankPages = true
    @State private var topCrop = 0.045
    @State private var bottomCrop = 0.065
    @State private var working = false
    @State private var status: String?

    private var book: ComicBook? { store.books.first { $0.id == bookID } }

    var body: some View {
        NavigationStack {
            Form {
                if let book, book.type == .pdf {
                    Section("PDF Cleaner Preview") {
                        if let preview {
                            LabeledContent("Pages", value: "\(preview.pageCount)")
                            LabeledContent("Likely blank", value: "\(preview.likelyBlankPages.count)")
                            if !preview.likelyBlankPages.isEmpty {
                                Text("Detected pages: " + preview.likelyBlankPages.prefix(24).map { String($0 + 1) }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView("Inspecting PDF locally…")
                        }
                    }
                    Section("Cleanup") {
                        Toggle("Remove likely blank pages", isOn: $removeBlankPages)
                        LabeledContent("Crop top", value: "\(Int(topCrop * 100))%")
                        Slider(value: $topCrop, in: 0...0.12, step: 0.005)
                        LabeledContent("Crop bottom", value: "\(Int(bottomCrop * 100))%")
                        Slider(value: $bottomCrop, in: 0...0.14, step: 0.005)
                    }
                    Section {
                        Button {
                            working = true
                            Task {
                                status = await store.createCleanCBZ(
                                    bookID: bookID,
                                    removeBlankPages: removeBlankPages,
                                    topCrop: topCrop,
                                    bottomCrop: bottomCrop
                                )
                                working = false
                            }
                        } label: {
                            Label(working ? "Converting…" : "Create Clean CBZ", systemImage: "sparkles.rectangle.stack")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(working)
                        Text("Original PDF is never rewritten. ComicPort creates a new CBZ with clean page images and ComicInfo.xml.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("CBZ Repair") {
                        Text("Rebuild this archive in natural page order (0001, 0002, …), preserve page images and ComicInfo.xml when available, and create a new CBZ copy.")
                            .foregroundStyle(.secondary)
                        Button {
                            working = true
                            Task {
                                status = await store.repairArchive(bookID: bookID)
                                working = false
                            }
                        } label: {
                            Label(working ? "Repairing…" : "Create Repaired CBZ", systemImage: "wrench.adjustable")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(working)
                    }
                }
                if let status { Section("Result") { Text(status) } }
            }
            .navigationTitle("Cleaner & Repair Lab")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { await inspectIfNeeded() }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 620, minHeight: 600)
        #endif
    }

    private func inspectIfNeeded() async {
        guard let book, book.type == .pdf else { return }
        let url = store.fileURL(for: book)
        preview = try? await Task.detached(priority: .utility) {
            try ComicRepairService.inspectPDF(url)
        }.value
        if let preview { topCrop = preview.suggestedTopCrop; bottomCrop = preview.suggestedBottomCrop }
    }
}
