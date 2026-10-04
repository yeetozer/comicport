# ComicPort — Stage 19.1 / Mac v0.6.1 RC1

Compile patch for `processQuickActionIfNeeded()`.

PanelQuickAction cases:
continueReading, randomComic, smartSearch, journal, readingGoal, importComics, library, home, smartCollections, sourcesSync, settings

The Stage 19 switch omitted:
smartCollections, sourcesSync, settings

Stage 19.1 explicitly routes:
- `.smartCollections` → Smart Collections
- `.sourcesSync` → Sources & Sync
- `.settings` → Settings

The switch now covers every PanelQuickAction case.
The Xcode project file remains byte-for-byte unchanged from Stage 19.
