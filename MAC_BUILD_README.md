# ComicPort Mac v0.2

## Run
Open `PanelReader.xcodeproj`, choose the **ComicPort Mac** scheme, then choose
**My Mac (Mac Catalyst)** and press Command-R.

## Desktop changes
- Sidebar rows use a dedicated single-click desktop interaction path.
- Mobile bottom navigation is hidden whenever the desktop sidebar is visible.
- Command-O opens the universal comic importer.
- Command-1 opens Home; Command-2 opens Library.
- Finder drag-and-drop shows a visible drop target.
- Mac receives larger cover/page image caches and a larger archive extraction cache.
- Dashboard importer accepts every Stage 16 format.

The underlying target is intentionally still named `PanelReader` for migration and
project stability. The public app name remains ComicPort.
