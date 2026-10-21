import SwiftUI
import UIKit

struct BookLookupView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss
    let bookID: UUID
    @State private var isbn = ""
    @State private var suggestion: BookLookupSuggestion?
    @State private var coverData: Data?
    @State private var busy = false
    @State private var message: String?
    @State private var operation: Task<Void, Never>?
    private var book: ComicBook? { store.books.first { $0.id == bookID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("ISBN ile kitap bilgisi").font(.title2.bold()); Spacer(); Button("Kapat") { dismiss() } }
                Text("Ara düğmesi yalnızca ISBN numarasını Open Library’ye gönderir. Önerileri inceleyip eksik bilgileri tamamlayabilir veya kapağı seçebilirsin.")
                    .font(.callout).foregroundStyle(.secondary)
                HStack {
                    TextField("ISBN-10 veya ISBN-13", text: $isbn).textFieldStyle(.roundedBorder).onSubmit { lookup() }
                    Button("Ara", systemImage: "magnifyingglass") { lookup() }.disabled(busy || BookISBN.normalized(isbn) == nil)
                }
                if busy { ProgressView("Open Library’den alınıyor…") }
                if let message { Text(message).foregroundStyle(.secondary).textSelection(.enabled) }
                if let suggestion {
                    let metadata = suggestion.metadata
                    LabeledContent("Kitap", value: metadata.title ?? "—")
                    LabeledContent("Yazar", value: metadata.authors.joined(separator: ", "))
                    LabeledContent("Yayınevi", value: metadata.publisher ?? "—")
                    LabeledContent("Yayın yılı", value: metadata.publicationYear ?? "—")
                    LabeledContent("Dil", value: metadata.language ?? "—")
                    LabeledContent("ISBN", value: metadata.isbn ?? "—")
                    if let summary = metadata.summary { Text(summary).textSelection(.enabled) }
                    Text("Mevcut bilgiler ve elle boş bırakılmış alanlar korunur. Kütüphanedeki kitap adı değişmez.").font(.caption).foregroundStyle(.secondary)
                    Button("Eksik bilgileri tamamla") {
                        message = store.applyBookSuggestion(bookID: bookID, metadata: metadata)
                    }.buttonStyle(.borderedProminent).disabled(busy)
                    if let coverID = suggestion.coverID {
                        Divider()
                        if let coverData, let image = UIImage(data: coverData) {
                            Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 300)
                            Button("Bu kapağı kullan") { saveCover(coverData, isbn: metadata.isbn ?? "") }.disabled(busy)
                        } else {
                            Button("Kapak önerisini yükle", systemImage: "photo") { loadCover(coverID) }.disabled(busy)
                        }
                    }
                    Link("Open Library kaydını aç", destination: URL(string: "https://openlibrary.org/isbn/\(metadata.isbn ?? "")")!)
                }
            }.padding(24)
        }
        .bookHubSurface()
        .frame(minWidth: 480, minHeight: 500)
        .onAppear { isbn = book?.bookMetadata?.isbn ?? "" }
        .onDisappear { operation?.cancel() }
    }

    private func lookup() {
        guard !busy else { return }
        busy = true; message = nil; suggestion = nil; coverData = nil
        let value = isbn
        operation = Task { @MainActor in
            defer { busy = false }
            do {
                let result = try await BookLookupService.shared.lookup(isbn: value)
                guard !Task.isCancelled else { return }
                suggestion = result
            } catch { if !Task.isCancelled { message = error.localizedDescription } }
        }
    }
    private func loadCover(_ id: Int) {
        busy = true; message = nil
        operation = Task { @MainActor in
            defer { busy = false }
            do {
                let data = try await BookLookupService.shared.cover(id: id)
                let prepared = await Task.detached(priority: .utility) { BookCoverPreparation.jpeg(data) }.value
                guard !Task.isCancelled else { return }
                guard let prepared else { throw BookLookupError.invalidResponse }
                coverData = prepared
            } catch { if !Task.isCancelled { message = error.localizedDescription } }
        }
    }
    private func saveCover(_ data: Data, isbn: String) {
        busy = true; message = nil
        operation = Task { @MainActor in
            defer { busy = false }
            message = await store.applyBookCoverSuggestion(bookID: bookID, data: data, isbn: isbn)
        }
    }
}
