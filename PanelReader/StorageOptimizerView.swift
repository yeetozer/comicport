import SwiftUI

struct StorageOptimizerView: View {
    @EnvironmentObject var store: LibraryStore
    @Environment(\.dismiss) private var dismiss

    let bookID: UUID

    @State private var preset: StorageOptimizationPreset = .balanced
    @State private var optimizing = false
    @State private var result: StorageOptimizationResult?
    @State private var errorMessage: String?
    @State private var installing = false

    private var book: ComicBook? { store.books.first(where: { $0.id == bookID }) }

    var body: some View {
        NavigationStack {
            Group {
                if let book, book.fileAvailable {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            overview(book)
                            presetPicker(book)
                            safetyCard
                            actionArea(book)
                        }
                        .padding()
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ContentUnavailableView("File unavailable", systemImage: "externaldrive.badge.xmark", description: Text("Re-import the comic before optimizing it."))
                }
            }
            .comicHubSurface().navigationTitle("Storage Optimizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        StorageOptimizer.discard(result)
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(optimizing || installing)
            .alert("Storage Optimizer", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func overview(_ book: ComicBook) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Optimize this comic", systemImage: "externaldrive.fill.badge.checkmark")
                .font(.title2.bold())
            Text(book.title).font(.headline)
            HStack(spacing: 22) {
                storageMetric("Current", bytes: currentBytes(book), icon: "internaldrive")
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                storageMetric("Estimated", bytes: StorageOptimizer.estimatedBytes(original: currentBytes(book), preset: preset), icon: "arrow.down.circle")
            }
            Text(book.type == .pdf
                 ? "PDF pages will be rendered into an optimized CBZ reading copy. Your progress, notes, ratings and achievements stay attached to the same comic."
                 : "CBZ pages will be resized and re-encoded into a smaller CBZ reading copy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func presetPicker(_ book: ComicBook) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality").font(.title3.bold())
            ForEach(StorageOptimizationPreset.allCases) { option in
                Button {
                    guard !optimizing else { return }
                    StorageOptimizer.discard(result)
                    result = nil
                    preset = option
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: option.systemImage)
                            .font(.title3)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(option.rawValue).font(.headline)
                                if option == .balanced {
                                    Text("RECOMMENDED")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 7).padding(.vertical, 3)
                                        .background(.blue.opacity(0.2), in: Capsule())
                                }
                            }
                            Text(option.detail).font(.caption).foregroundStyle(.secondary)
                            Text("Estimated ~\(formatBytes(StorageOptimizer.estimatedBytes(original: currentBytes(book), preset: option)))")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: preset == option ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(preset == option ? .blue : .secondary)
                    }
                    .padding(14)
                    .background(preset == option ? Color.blue.opacity(0.10) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var safetyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.checkered").foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text("Safe replacement").font(.headline)
                Text("ComicPort creates and validates the optimized copy first. The original is replaced only after you explicitly choose Use Optimized Copy. If replacement fails, the original is restored.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func actionArea(_ book: ComicBook) -> some View {
        if optimizing {
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Optimizing pages locally…").font(.headline)
                Text("Large omnibus files can take a while. Keep ComicPort open until this finishes.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(30)
        } else if let result {
            VStack(alignment: .leading, spacing: 14) {
                Label("Optimized copy ready", systemImage: "checkmark.seal.fill")
                    .font(.title3.bold()).foregroundStyle(.green)
                HStack {
                    storageMetric("Before", bytes: result.originalBytes, icon: "externaldrive")
                    Spacer()
                    storageMetric("After", bytes: result.optimizedBytes, icon: "externaldrive.fill")
                    Spacer()
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Saved").font(.caption).foregroundStyle(.secondary)
                        Text(formatBytes(result.savedBytes)).font(.title3.bold())
                        Text("\(result.savingsPercent)% smaller").font(.caption2).foregroundStyle(.green)
                    }
                }
                if result.optimizedBytes >= result.originalBytes {
                    Text("This preset did not make the file smaller. Try a stronger preset; the original has not been changed.")
                        .font(.caption).foregroundStyle(.orange)
                }
                HStack {
                    Button {
                        StorageOptimizer.discard(result)
                        self.result = nil
                    } label: { Label("Discard Copy", systemImage: "xmark") }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        install(result, book: book)
                    } label: {
                        if installing { ProgressView() } else { Label("Use Optimized Copy", systemImage: "checkmark.circle.fill") }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(installing || result.optimizedBytes >= result.originalBytes)
                }
            }
            .padding()
            .comicHubMaterial(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        } else {
            Button {
                start(book)
            } label: {
                Label("Create Optimized Copy", systemImage: "wand.and.stars")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func start(_ book: ComicBook) {
        optimizing = true
        errorMessage = nil
        StorageOptimizer.discard(result)
        result = nil
        let url = store.fileURL(for: book)
        let settings = store.readerSettings(for: book.id)
        Task {
            do {
                let optimized = try await StorageOptimizer.optimize(type: book.type, source: url, preset: preset, readerSettings: settings)
                await MainActor.run {
                    result = optimized
                    optimizing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    optimizing = false
                }
            }
        }
    }

    private func install(_ result: StorageOptimizationResult, book: ComicBook) {
        installing = true
        do {
            try store.installOptimizedCopy(result, for: book.id)
            self.result = nil
            installing = false
            dismiss()
        } catch {
            installing = false
            errorMessage = error.localizedDescription
        }
    }

    private func currentBytes(_ book: ComicBook) -> Int64 {
        let url = store.fileURL(for: book)
        return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    private func storageMetric(_ label: String, bytes: Int64, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(formatBytes(bytes)).font(.title3.bold()).monospacedDigit()
        }
    }
}

private func formatBytes(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: max(0, bytes), countStyle: .file)
}
