import SwiftUI

struct ComicPortCommands: Commands {
    let store: LibraryStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Import Comics…") {
                store.setPendingQuickAction(.importComics)
            }
            .keyboardShortcut("o", modifiers: [.command])
        }

        CommandMenu("ComicPort") {
            Button("Command Palette…") {
                store.setPendingQuickAction(.commandPalette)
            }
            .keyboardShortcut("k", modifiers: [.command])

            Divider()
            Button("Home") {
                store.setPendingQuickAction(.home)
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Library") {
                store.setPendingQuickAction(.library)
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Smart Collections") {
                store.setPendingQuickAction(.smartCollections)
            }
            .keyboardShortcut("3", modifiers: [.command])

            Button("Sources & Sync") {
                store.setPendingQuickAction(.sourcesSync)
            }
            .keyboardShortcut("4", modifiers: [.command])

            Divider()

            Button("Continue Reading") {
                store.setPendingQuickAction(.continueReading)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Button("Random Comic") {
                store.setPendingQuickAction(.randomComic)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Divider()

            Button("Smart Search") {
                store.setPendingQuickAction(.smartSearch)
            }
            .keyboardShortcut("f", modifiers: [.command, .option])

            Button("Reading Journal") {
                store.setPendingQuickAction(.journal)
            }
            .keyboardShortcut("j", modifiers: [.command, .shift])

            Button("Reading Goal") {
                store.setPendingQuickAction(.readingGoal)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])

            Divider()

            Button("Settings") {
                store.setPendingQuickAction(.settings)
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
    }
}
