import SwiftUI

struct ReaderSettingsView: View {
    @EnvironmentObject var store: LibraryStore
    let bookID: UUID
    let isPDF: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var originalSettings: ReaderSettings?
    @State private var showSavedConfirmation = false
    @State private var showDefaultConfirmation = false

    private var settings: ReaderSettings { store.readerSettings(for: bookID) }

    var body: some View {
        NavigationStack {
            Form {
                if isPDF {
                    Section("Page Crop") {
                        Toggle("Auto Crop", isOn: binding(\.autoCropEnabled))
                        Picker("Crop Strength", selection: binding(\.cropStrength)) {
                            ForEach(CropStrength.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .disabled(!settings.autoCropEnabled)

                        Toggle("Trim Web Footer", isOn: binding(\.trimWebFooter))
                            .disabled(!settings.autoCropEnabled)

                        Toggle("Full Bleed", isOn: binding(\.fullBleed))
                            .disabled(!settings.autoCropEnabled)

                        Text("Trim Web Footer ignores small URL/date/page-number bands below the main comic. Full Bleed removes the last thin paper edge after detection. The PDF file itself is never modified.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Fit") {
                        Picker("Fit Mode", selection: binding(\.fitMode)) {
                            ForEach(ReaderFitMode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        Picker("Page Gap", selection: binding(\.pageGap)) {
                            ForEach(ReaderPageGap.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        cropSlider("Top", keyPath: \.top)
                        cropSlider("Bottom", keyPath: \.bottom)
                        cropSlider("Left", keyPath: \.leading)
                        cropSlider("Right", keyPath: \.trailing)

                        Button("Reset Manual Crop") {
                            store.updateReaderSettings(bookID: bookID) { $0.manualCrop = ManualCropInsets() }
                        }
                        .disabled(settings.manualCrop.isZero)
                    } header: {
                        Text("Manual Crop")
                    } footer: {
                        Text("Manual crop is applied after Auto Crop. Use small values; 5% is usually plenty.")
                    }
                }

                Section("Reading Layout") {
                    Picker("Page Layout", selection: binding(\.pageLayout)) {
                        ForEach(ReaderPageLayout.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle(
                        "Hide Controls After 5 Seconds",
                        isOn: binding(\.autoHideControls)
                    )

                    Text("Single Page and Two Pages can also be changed directly from the reader controls. Automatic follows the window shape.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Opening Pages") {
                    Stepper(value: binding(\.skipInitialPages), in: 0...20) {
                        LabeledContent("Skip when starting", value: "\(settings.skipInitialPages) pages")
                    }
                    Text("If you are still before this point, opening the comic jumps past web printouts, ads or other unwanted opening pages. You can always navigate back manually.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Comic Enhance") {
                    Picker("Enhancement", selection: binding(\.enhancePreset)) {
                        ForEach(ComicEnhancePreset.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }

                    Text("Non-destructive: only the live reader image changes. The original PDF/archive is never rewritten.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Appearance") {
                    Picker("Theme", selection: binding(\.theme)) {
                        ForEach(ReaderTheme.allCases) { option in
                            Label(option.rawValue, systemImage: option.systemImage).tag(option)
                        }
                    }
                }

                Section("Language & Accessibility") {
                    Picker("Translate To", selection: binding(\.translationTarget)) {
                        ForEach(ReaderTranslationLanguage.allCases) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }

                    Toggle("Larger Reader Controls", isOn: binding(\.largeControls))
                    Toggle("High Contrast Reader Bars", isOn: binding(\.highContrastControls))
                    Toggle("Reduce Reader Motion", isOn: binding(\.reduceReaderMotion))

                    Text("Language Tools first uses embedded PDF text; otherwise ComicPort runs local Vision OCR on the current page.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Save Settings") {
                    Button {
                        store.persistReaderSettings(bookID: bookID)
                        originalSettings = store.readerSettings(for: bookID)
                        showSavedConfirmation = true
                    } label: {
                        Label("Save for This Comic", systemImage: "checkmark.circle.fill")
                    }

                    Button {
                        store.useCurrentReaderSettingsAsDefault(bookID: bookID)
                        store.persistReaderSettings(bookID: bookID)
                        originalSettings = store.readerSettings(for: bookID)
                        showDefaultConfirmation = true
                    } label: {
                        Label("Use as Default for New Comics", systemImage: "square.and.arrow.down")
                    }

                    Text("Changes are previewed live. Save for This Comic keeps crop, fit, Comic Enhance, theme, translation target and accessibility settings when you reopen this comic.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reader Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let originalSettings {
                            store.restoreReaderSettings(originalSettings, for: bookID)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.persistReaderSettings(bookID: bookID)
                        originalSettings = store.readerSettings(for: bookID)
                        showSavedConfirmation = true
                    }
                }
            }
            .onAppear {
                if originalSettings == nil {
                    originalSettings = store.readerSettings(for: bookID)
                }
            }
            .alert("Saved", isPresented: $showSavedConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Reader and crop settings were saved for this comic.")
            }
            .alert("Default Saved", isPresented: $showDefaultConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("These settings will be used as the starting point for comics that do not have their own saved reader settings.")
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<ReaderSettings, Value>) -> Binding<Value> {
        Binding(
            get: { store.readerSettings(for: bookID)[keyPath: keyPath] },
            set: { value in store.updateReaderSettings(bookID: bookID) { $0[keyPath: keyPath] = value } }
        )
    }

    @ViewBuilder
    private func cropSlider(_ title: String, keyPath: WritableKeyPath<ManualCropInsets, Double>) -> some View {
        HStack {
            Text(title).frame(width: 58, alignment: .leading)
            Slider(
                value: Binding(
                    get: { store.readerSettings(for: bookID).manualCrop[keyPath: keyPath] },
                    set: { value in store.updateReaderSettings(bookID: bookID) { $0.manualCrop[keyPath: keyPath] = value } }
                ),
                in: 0...0.15,
                step: 0.005
            )
            Text("\(Int((store.readerSettings(for: bookID).manualCrop[keyPath: keyPath] * 100).rounded()))%")
                .monospacedDigit()
                .frame(width: 38, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}
