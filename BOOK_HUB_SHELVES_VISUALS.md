# Book Hub shelves and authors — 2026-10-21

The home page previously used generic metadata rectangles for authors and omitted the visual shelf shortcuts from the approved library concept. It now presents four warm walnut shelf panels (reading, to-read, completed, favorites), showing a bounded selection of actual library covers and live counts. Each opens the matching collection. Author cards use circular sepia illustrations, names and real per-author book counts; selecting one opens that author's books. Other authors receive initials rather than an unrelated portrait.

The shared shelf panel is also used in Kitap Raflarım, replacing plain list rows for smart shelves and personal collections. Collection creation, editing and removal retain the existing behavior. A shelf opens a responsive cover grid that links to BookDetailView. Shelf groups continue to exclude archived/out-of-library books according to existing filters.

Visual direction follows the previously approved warm dark wood, amber accents, real bookshelf panels and circular author portraits in ComicPort Book Hub Reading Library.png and Cozy Book Hub Library Dashboard.png. This is an implemented adaptation, not a pixel-identical copy of the concept image.

Two original generated assets are bundled in Assets.xcassets: BookHubShelfBackdrop (empty walnut alcove with brass lamp and ivy; real book covers are overlaid at runtime) and BookHubAuthorPortraits (3×3 sepia author illustration atlas). Portraits are generated illustrations, not archival photographs. Atlas order is Stevenson, Conan Doyle, Stoker / Dickens, Wells, Austen / Carroll, Shelley, Wilde. The source atlas is displayed in clipped SwiftUI cells, avoiding nine additional asset copies. Each cell uses its measured portrait centre and a consistent inner crop, since the generated sheet is not a mathematically even grid. This removes neighbouring portrait fragments and baked-in double rims. The portraits and backdrop work offline. Decorative imagery is hidden from accessibility; buttons announce full names and live counts. Existing cached thumbnail loading handles book covers.

Validation: Mac Catalyst Debug build and native visual inspection; author selection opens Stevenson's two books, smart shelf selection opens the nine unstarted books, existing library remains ten books and existing progress is unchanged. No model or persistence formats changed.

## Warm secondary surfaces

Book Hub now shares a dark walnut canvas (RGB 0.145 / 0.095 / 0.060) and lighter brown list/card surface (0.225 / 0.150 / 0.095). The surface modifier hides system scroll backgrounds and colors the navigation and presentation backgrounds. It is applied inside navigation containers, including shelves and their book grids, goals, quotes, maintenance, collection and note editors, author/shelf sheets, book details and bibliography/lookup sheets. Shared achievements, Notes, Smart Search and Wrapped screens opt into it for Books. Book achievement cards also use the warm surface. The dashboard provides a matching base behind child screens.

Mac Catalyst Debug validation: shelves, goals, maintenance, achievements, quotes, Notes and Smart Search display the brown canvas; list rows remain readable on the lighter brown. The collection editor was opened and visually checked, then cancelled without creating a collection. Build succeeds. Reading/content persistence is unchanged.

## Wooden shelves in the library

Book Hub collections now use full-width wooden shelf rows instead of the cover grid, including Kütüphanem and filtered/search collections. The row capacity is calculated from the available width and existing cover-size preference; sorting/filtering occurs before grouping, preserving every displayed book and its order. Each book uses the existing detail link, quick preview and favorite/status/content-kind context actions. A shared continuous wooden lip sits directly below the covers, with titles, authors and reading progress underneath. The existing BookHubShelfBackdrop asset provides the same warm wood appearance as the home shelf panels. Other reader profiles retain their own collection layouts.

Validation: Mac Catalyst build succeeded in Xcode. Native UI showed all 10 classics on wooden rows; the Reading filter returned Frankenstein, its detail view opened, and title sorting reordered the collection. Restored All and default sorting after validation. Swift parser and git diff whitespace checks passed.
