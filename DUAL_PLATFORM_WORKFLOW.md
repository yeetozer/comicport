# ComicPort iPad + Mac shared-release policy

ComicPort now uses one SwiftUI/UIKit codebase and one main application target. The target builds for iPadOS and Mac Catalyst.

## Rule for Stage 17 and later

1. Shared reader, library, metadata, search, journal, achievements, backup, recommendation and performance changes go into `PanelReader/` once. They automatically ship to both iPad and Mac.
2. Platform-specific behavior is isolated with `#if targetEnvironment(macCatalyst)` or small platform adapters. Do not fork a second copy of the feature.
3. iPad-only extensions (currently WidgetKit) stay platform-filtered to iOS and do not block the Mac build.
4. Every release should be tested with two Xcode destinations: an iPad destination and `My Mac (Mac Catalyst)`.
5. Persisted model formats and backup schema stay shared so `.panelbackup` remains portable between iPad and Mac.
6. Stage numbering remains shared. Mac gets a secondary compatibility version only when needed (for example `Mac v0.1`).

## Data sync

Shared code does not automatically synchronize two devices' local app containers. Manual backup/restore remains portable today. Automatic iCloud state sync is still planned for Stage 18.
