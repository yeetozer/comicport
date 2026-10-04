# ComicPort — Stage 19 / Mac v0.6 RC1

Stage 19 closes the planned Mac feature roadmap and turns the current build into a
release candidate. WidgetKit remains intentionally paused.

## Finder / Open With
Declared and accepted:
- PDF
- CBZ
- CBR
- CB7
- CBT
- ZIP
- RAR
- 7z
- TAR

Finder launches use the same safe import pipeline as Command-O. If the app is
still bootstrapping, external file URLs wait in memory until the library is ready.

## Desktop shortcuts
- Command-1: Home
- Command-2: Library
- Command-3: Smart Collections
- Command-4: Sources & Sync
- Command-O: Import
- Command-Comma: Settings

## Backup schema 3
Smart Collections are now portable through `.panelbackup`.

Older schema 1/2 files stay readable because the new Smart Collections field is
optional.

Source Folder and Sync Folder bookmarks are intentionally NOT backed up: macOS
security-scoped bookmarks should be granted again on another Mac.

## Diagnostics & Release Health
Settings → Diagnostics & Release Health:
- library/missing-file health
- local storage breakdown
- Source/Sync status
- safe cache cleanup
- copyable support report
- local library folder shortcut

Diagnostics are local-only and never uploaded.

## Release metadata hardening
- Finder document declarations expanded to every Stage 16 format
- non-exempt-encryption declaration set to false
- public display name stays ComicPort
- internal legacy target/bundle naming stays unchanged to protect existing data

## Performance 11
- external Finder file launches no longer race bootstrap
- diagnostics storage enumeration runs off the main actor
- cache cleanup remains non-destructive
- Stage 17 reader caches and Stage 18 source/sync coalescing remain intact
- project.pbxproj is byte-for-byte unchanged from the known-good project

## Remaining before a PUBLIC Mac App Store submission
These require the developer's Apple account / real macOS runtime and cannot be
completed generically inside the source ZIP:

1. Run a clean Release build and Archive in Xcode.
2. Select the real Apple Developer Team and production bundle identifier.
3. If changing the legacy bundle ID, decide how existing local app data should migrate.
4. Create/finish the App Store Connect record.
5. Complete privacy answers, age rating, category, description and subtitle.
6. Supply Mac screenshots and any promotional artwork.
7. Test the signed archive on a clean macOS user account or second Mac.
8. Smoke-test every declared Finder/Open-With file format.
9. Test Backup schema 3 restore with real data.
10. Test Source Folder + Sync Folder with real folders.
11. Test Apple Translation language packs on a supported macOS/Catalyst version.
12. Upload through Xcode/App Store Connect/TestFlight as appropriate.

RC1 means the current planned code feature roadmap is complete. It does not mean
Apple account-specific review/submission work has already happened.
