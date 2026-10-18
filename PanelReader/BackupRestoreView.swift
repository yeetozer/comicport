import SwiftUI
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    @EnvironmentObject var store: LibraryStore
    @EnvironmentObject var theme: PanelThemeStore
    @Environment(\.panelAccentColor) private var accentColor

    @State private var exportDocument: PanelBackupDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showRestoreWarning = false
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var statusIsError = false

    private var unlockedCount: Int { store.achievementProfile.unlockedIDs.count }
    private var noteCount: Int { store.annotationPageCount }
    private var lastBackup: Date? {
        UserDefaults.standard.object(forKey: "PanelReader.lastBackupDate") as? Date
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero

                HStack(alignment: .top, spacing: 14) {
                    actionCard(
                        title: "Create Backup",
                        detail: "Export your profile to a single .panelbackup file.",
                        icon: "externaldrive.badge.plus",
                        button: "Backup",
                        action: createBackup
                    )

                    actionCard(
                        title: "Restore Backup",
                        detail: "Merge profile data from a backup without deleting existing data.",
                        icon: "arrow.counterclockwise.icloud",
                        button: "Restore",
                        action: { showRestoreWarning = true }
                    )
                }

                backupHealthCard
                includedCard
                safetyCard

                if let statusMessage {
                    HStack(spacing: 10) {
                        Image(systemName: statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        Text(statusMessage)
                            .font(.subheadline)
                    }
                    .foregroundStyle(statusIsError ? .red : .green)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((statusIsError ? Color.red : Color.green).opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
            .padding(.bottom, 70)
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isWorking {
                ZStack {
                    Color.black.opacity(0.36).ignoresSafeArea()
                    VStack(spacing: 13) {
                        ProgressView().controlSize(.large).tint(.white)
                        Text("Preparing ComicPort…")
                            .font(.headline)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .data,
            defaultFilename: backupFileName
        ) { result in
            switch result {
            case .success:
                UserDefaults.standard.set(Date.now, forKey: "PanelReader.lastBackupDate")
                setStatus("Backup saved.", error: false)
            case .failure(let error):
                setStatus("Could not save backup: \(error.localizedDescription)", error: true)
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                restore(from: url)
            case .failure(let error):
                setStatus("Could not select file: \(error.localizedDescription)", error: true)
            }
        }
        .confirmationDialog(
            "Restore this backup?",
            isPresented: $showRestoreWarning,
            titleVisibility: .visible
        ) {
            Button("Choose Backup File") {
                showImporter = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Restore does not delete existing comic files. Statistics, history, achievements, notes and settings are merged. Comics missing from this device are kept as unavailable records.")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(accentColor.opacity(0.16))
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ComicPort Backup")
                        .font(.largeTitle.bold())
                    Text("Keep your reading history and personal data portable.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 20) {
                compactStat("\(store.analytics.history.count)", "sessions")
                compactStat("\(unlockedCount)", "achievements")
                compactStat("\(noteCount)", "annotated pages")
                compactStat("\(store.savedPanels.count)", "panel")
                if let lastBackup {
                    compactStat(lastBackup.formatted(.dateTime.day().month(.abbreviated)), "last backup")
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.18), .white.opacity(0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func compactStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func actionCard(
        title: String,
        detail: String,
        icon: String,
        button: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 46, height: 46)
                .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            Text(title).font(.title3.bold())
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 5)

            Button(action: action) {
                Text(button)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 215, alignment: .leading)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
    }

    private var backupHealthCard: some View {
        let health = store.backupHealthReport()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Backup Health Check", systemImage: health.missingFiles == 0 ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(health.missingFiles == 0 ? .green : .orange)
                Spacer()
                Text(health.missingFiles == 0 ? "READY" : "CHECK FILES")
                    .font(.caption.bold())
            }
            Text("\(health.libraryRecords) library records · \(health.readingSessions) sessions · \(health.textNotes + health.pencilNotes) notes · \(health.savedPanels) panels · \(health.smartCollections) smart collections")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if health.missingFiles > 0 {
                Text("\(health.missingFiles) comic file(s) are not currently on this device. Their metadata/history can still be backed up.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(18)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
    }

    private var includedCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Included in Backup")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 10)], spacing: 10) {
                included("Library metadata", "books.vertical.fill")
                included("Reading history & statistics", "chart.bar.fill")
                included("Achievements & XP", "trophy.fill")
                included("Favorites & ratings", "heart.fill")
                included("Crop & Reader settings", "crop")
                included("Story Arc / Reading Order", "point.3.connected.trianglepath.dotted")
                included("Pencil & text notes", "pencil.and.scribble")
                included("Reading Journal", "book.pages.fill")
                included("My Panels images", "rectangle.stack.fill")
                included("Theme & app preferences", "paintpalette.fill")
                included("Smart Collections", "rectangle.3.group.fill")
            }
        }
        .padding(18)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
    }

    private func included(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Image(systemName: icon)
                .foregroundStyle(accentColor)
                .frame(width: 22)
            Text(title).font(.subheadline)
            Spacer()
        }
        .padding(10)
        .background(.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 10))
    }

    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Comic files are not included in backups", systemImage: "info.circle.fill")
                .font(.headline)
            Text("Comic files and the rebuildable OCR index are not included. Your .panelbackup preserves your profile, notes, Smart Collection rules and saved panels. Select source folders again when restoring on another device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.orange.opacity(0.14)))
    }

    private var backupFileName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "ComicPort-\(formatter.string(from: .now)).panelbackup"
    }

    private func createBackup() {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = nil

        Task { @MainActor in
            do {
                let data = try await store.makeBackupData(accentTheme: theme.accent)
                exportDocument = PanelBackupDocument(data: data)
                isWorking = false
                showExporter = true
            } catch {
                isWorking = false
                setStatus("Could not create backup: \(error.localizedDescription)", error: true)
            }
        }
    }

    private func restore(from url: URL) {
        guard !isWorking else { return }
        isWorking = true
        statusMessage = nil

        Task { @MainActor in
            let gotAccess = url.startAccessingSecurityScopedResource()
            defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }

            do {
                let path = url.path
                let data = try await Task.detached(priority: .userInitiated) {
                    try Data(contentsOf: URL(fileURLWithPath: path))
                }.value

                let result = try store.restoreBackupData(data)
                if let restoredTheme = result.accentTheme {
                    theme.accent = restoredTheme.releaseSelection
                }

                isWorking = false
                setStatus(
                    "Restore complete: \(result.importedBooks) comic records, \(result.historyEntries) sessions, \(result.notes) annotated pages and \(result.panels) saved panels processed.",
                    error: false
                )
            } catch {
                isWorking = false
                setStatus("Restore failed: \(error.localizedDescription)", error: true)
            }
        }
    }

    private func setStatus(_ message: String, error: Bool) {
        statusMessage = message
        statusIsError = error
    }
}
