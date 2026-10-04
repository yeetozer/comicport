import SwiftUI
import UIKit

struct PageTextNoteEditor: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    let page: Int

    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $text)
                    .font(.body)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .padding()

                HStack {
                    Text("Page \(page + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(text.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Page Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(role: .destructive) {
                            store.deleteTextNote(bookID: bookID, page: page)
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    Button("Save") {
                        store.saveTextNote(bookID: bookID, page: page, text: text)
                        dismiss()
                    }
                }
            }
            .onAppear {
                text = store.textNote(bookID: bookID, page: page)?.text ?? ""
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct PanelCaptureView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.panelAccentColor) private var accentColor

    let bookID: UUID
    let page: Int

    @State private var sourceData: Data?
    @State private var sourceImage: UIImage?
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var top = 0.08
    @State private var leading = 0.08
    @State private var bottom = 0.08
    @State private var trailing = 0.08
    @State private var saving = false

    private var book: ComicBook? { store.books.first { $0.id == bookID } }

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    VStack(spacing: 14) {
                        ProgressView().controlSize(.large)
                        Text("Preparing page…").font(.headline)
                    }
                } else if let errorMessage {
                    ContentUnavailableView("Panel capture unavailable", systemImage: "rectangle.dashed", description: Text(errorMessage))
                } else if let sourceImage {
                    ScrollView {
                        VStack(spacing: 18) {
                            cropPreview(sourceImage)
                                .frame(minHeight: 420)

                            presets

                            VStack(spacing: 12) {
                                cropSlider("Top", value: $top)
                                cropSlider("Bottom", value: $bottom)
                                cropSlider("Left", value: $leading)
                                cropSlider("Right", value: $trailing)
                            }
                            .padding()
                            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                            Text("The bright rectangle is what will be saved to My Panels.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Save to My Panels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        savePanel()
                    } label: {
                        if saving { ProgressView() }
                        else { Label("Save", systemImage: "heart.rectangle.fill") }
                    }
                    .disabled(sourceData == nil || saving)
                }
            }
            .task(id: "\(bookID.uuidString)-\(page)") {
                await loadPage()
            }
        }
    }

    private func cropPreview(_ image: UIImage) -> some View {
        GeometryReader { proxy in
            let container = proxy.size
            let imageSize = image.size
            let imageAspect = max(0.01, imageSize.width / max(1, imageSize.height))
            let containerAspect = max(0.01, container.width / max(1, container.height))
            let fitted: CGSize = imageAspect > containerAspect
                ? CGSize(width: container.width, height: container.width / imageAspect)
                : CGSize(width: container.height * imageAspect, height: container.height)
            let origin = CGPoint(
                x: (container.width - fitted.width) / 2,
                y: (container.height - fitted.height) / 2
            )
            let cropRect = CGRect(
                x: origin.x + fitted.width * leading,
                y: origin.y + fitted.height * top,
                width: fitted.width * max(0.10, 1 - leading - trailing),
                height: fitted.height * max(0.10, 1 - top - bottom)
            )

            ZStack {
                Color.black.opacity(0.35)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: container.width, height: container.height)

                Path { path in
                    path.addRect(CGRect(origin: origin, size: fitted))
                    path.addRect(cropRect)
                }
                .fill(.black.opacity(0.56), style: FillStyle(eoFill: true))

                Rectangle()
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var presets: some View {
        HStack {
            presetButton("Full") { setInsets(0, 0, 0, 0) }
            presetButton("Center") { setInsets(0.20, 0.12, 0.20, 0.12) }
            presetButton("Top") { setInsets(0.03, 0.06, 0.48, 0.06) }
            presetButton("Bottom") { setInsets(0.48, 0.06, 0.03, 0.06) }
        }
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
    }

    private func cropSlider(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title).frame(width: 58, alignment: .leading)
            Slider(value: value, in: 0...0.45, step: 0.01)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption.monospacedDigit())
                .frame(width: 42)
        }
    }

    private func setInsets(_ t: Double, _ l: Double, _ b: Double, _ r: Double) {
        withAnimation(.easeInOut(duration: 0.16)) {
            top = t
            leading = l
            bottom = b
            trailing = r
        }
    }

    @MainActor
    private func loadPage() async {
        guard let book else {
            loading = false
            errorMessage = "Comic not found."
            return
        }
        let url = store.fileURL(for: book)
        let settings = store.readerSettings(for: book.id)
        let data = await ReaderPageSnapshotService.loadSnapshot(
            fileURL: url,
            type: book.type,
            page: page,
            settings: settings
        )
        guard !Task.isCancelled else { return }
        sourceData = data
        sourceImage = data.flatMap(UIImage.init(data:))
        loading = false
        if sourceImage == nil {
            errorMessage = "The current page could not be rendered."
        }
    }

    private func savePanel() {
        guard let sourceData else { return }
        saving = true
        let t = top, l = leading, b = bottom, r = trailing
        Task { @MainActor in
            let cropped = await Task.detached(priority: .userInitiated) {
                ReaderPageSnapshotService.cropJPEG(
                    sourceData: sourceData,
                    top: t,
                    leading: l,
                    bottom: b,
                    trailing: r
                )
            }.value
            if let cropped, store.savePanel(cropped, bookID: bookID, page: page) != nil {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            } else {
                errorMessage = "The selected panel could not be saved."
                saving = false
            }
        }
    }
}

struct NotesCenterView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.panelAccentColor) private var accentColor
    @State private var rows: [AnnotationPageSummary] = []
    @State private var activeReader: NotesReaderRoute?

    var body: some View {
        NavigationStack {
            Group {
                if rows.isEmpty {
                    ContentUnavailableView(
                        "No notes yet",
                        systemImage: "pencil.and.scribble",
                        description: Text("Use Apple Pencil or add a text note while reading.")
                    )
                } else {
                    List(rows) { row in
                        Button {
                            store.updateProgress(id: row.bookID, page: row.page)
                            activeReader = NotesReaderRoute(id: row.bookID)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 11)
                                        .fill(accentColor.opacity(0.12))
                                    Image(systemName: row.hasPencilDrawing ? "pencil.tip" : "note.text")
                                        .foregroundStyle(accentColor)
                                }
                                .frame(width: 46, height: 46)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.bookTitle(for: row.bookID))
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Page \(row.page + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let note = row.textNote, !note.isEmpty {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }

                                Spacer()

                                HStack(spacing: 8) {
                                    if row.hasPencilDrawing {
                                        Image(systemName: "pencil.tip").foregroundStyle(.secondary)
                                    }
                                    if row.textNote != nil {
                                        Image(systemName: "text.bubble").foregroundStyle(.secondary)
                                    }
                                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Notes")
            .task(id: store.annotationRevision) {
                rows = store.annotationPages()
            }
            .fullScreenCover(item: $activeReader) { route in
                ReadingSessionHostView(initialBookID: route.id)
                    .environmentObject(store)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

private struct NotesReaderRoute: Identifiable {
    let id: UUID
}

struct MyPanelsView: View {
    @EnvironmentObject var store: LibraryStore
    @State private var selectedPanel: SavedPanel?

    var body: some View {
        NavigationStack {
            Group {
                if store.savedPanels.isEmpty {
                    ContentUnavailableView(
                        "My Panels is empty",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("While reading, use the panel button to crop and save a favorite moment.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 16)], spacing: 16) {
                            ForEach(store.savedPanels) { panel in
                                Button {
                                    selectedPanel = panel
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        PanelThumbnail(url: store.panelURL(for: panel))
                                            .aspectRatio(0.74, contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))

                                        Text(store.bookTitle(for: panel.bookID))
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        Text("Page \(panel.page + 1)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Panels")
            .sheet(item: $selectedPanel) { panel in
                SavedPanelDetailView(panel: panel)
                    .environmentObject(store)
            }
        }
    }
}

private struct PanelThumbnail: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(.secondary.opacity(0.08))
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task(id: url.path) {
            let path = url.path
            let data = await Task.detached(priority: .utility) {
                try? Data(contentsOf: URL(fileURLWithPath: path))
            }.value
            guard !Task.isCancelled else { return }
            image = data.flatMap(UIImage.init(data:))
        }
    }
}

private struct SavedPanelDetailView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let panel: SavedPanel

    @State private var activeReader: NotesReaderRoute?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                PanelThumbnail(url: store.panelURL(for: panel))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    VStack(alignment: .leading) {
                        Text(store.bookTitle(for: panel.bookID)).font(.headline)
                        Text("Page \(panel.page + 1) • \(panel.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    Button {
                        store.updateProgress(id: panel.bookID, page: panel.page)
                        activeReader = NotesReaderRoute(id: panel.bookID)
                    } label: {
                        Label("Open Source", systemImage: "book.pages")
                    }
                    .buttonStyle(.borderedProminent)

                    ShareLink(item: store.panelURL(for: panel)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Saved Panel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        store.deletePanel(panel)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .fullScreenCover(item: $activeReader) { route in
                ReadingSessionHostView(initialBookID: route.id)
                    .environmentObject(store)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
