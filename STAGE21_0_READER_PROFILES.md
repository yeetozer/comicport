# ComicPort — Stage 21.0 — Reader Profiles

ComicPort now has four reader profiles accessible from the top-right toolbar:

- Comics
- Manga
- Books
- Mix

Mix is the unified library and shows every item.

Each library item stores a content kind:
- Comic
- Manga
- Book

Existing right-to-left items migrate automatically to Manga.
New imported right-to-left comics are classified as Manga immediately.
Right-click any library card → Content Type to manually reclassify it.

The selected profile is saved and restored on launch.

Home, Library, Reading, To Read, Completed, Recent, Favorites and Search use the
active profile. Mix contains all items without duplicating files.

Books is the foundation for the future EPUB/reflowable text engine. Stage 21.0
does not falsely claim EPUB support yet.

No Xcode target/package/project configuration changes.
