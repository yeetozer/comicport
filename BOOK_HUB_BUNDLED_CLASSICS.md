# Book Hub — preloaded classics

20 October 2026. Six original-English literary texts, bundled offline with new typographic covers. No modern translations or source illustrations are shipped.

| Work | Author | First publication | Author death | Reading sections |
|---|---|---:|---:|---:|
| Pride and Prejudice | Jane Austen | 1813 | 1817 | 61 |
| Frankenstein | Mary Shelley | 1818 | 1851 | 28 |
| Dracula | Bram Stoker | 1897 | 1912 | 28 including final Note |
| The Adventures of Sherlock Holmes | Arthur Conan Doyle | 1892 | 1930 | 12 |
| Alice’s Adventures in Wonderland | Lewis Carroll | 1865 | 1898 | 12 |
| The Picture of Dorian Gray | Oscar Wilde | 1891 | 1900 | 21 including author’s Preface |

Publication years identify the original work, not a claim that every source transcription reproduces its first edition. These are reflowable text editions, not facsimiles; publisher advertisements, illustration captions/art and source-service wrappers are omitted. Original decorative initial letters represented as image alternatives are retained as text. Public-domain status is not claimed over modern translations, film adaptations or unrelated covers.

## Provenance and rights scope

The six sources are the original-English public-domain entries at:
- https://www.gutenberg.org/ebooks/1342
- https://www.gutenberg.org/ebooks/84
- https://www.gutenberg.org/ebooks/345
- https://www.gutenberg.org/ebooks/1661
- https://www.gutenberg.org/ebooks/11
- https://www.gutenberg.org/ebooks/174

Source-service trademark and license wrappers are removed from the derived novel EPUBs under the public-domain text redistribution route described at https://www.gutenberg.org/policy/license. Source links are retained as bibliographic acknowledgements in the catalogue/details, not endorsement, publisher identity, or promotional branding. No claim of copyright ownership over the original texts is made.

The recorded review scope is the United States (source catalogue public-domain status) and Türkiye (all named original authors died more than 70 years ago; https://www.telifakademi.gov.tr/TR-295519/sikca-sorulan-sorular.html). This is not worldwide clearance. Other store territories, especially countries with longer terms or special rules, remain a distribution review item. Nothing was published or submitted to an app store.

Each resource entry records the source URL, saved-source SHA-256, packaged EPUB SHA-256, author, language, publication year and rights scope in `PanelReader/BundledClassics/catalog.json`. The original saved HTML, including its original license, is retained compressed under `Scripts/classic_sources/` for local provenance/rebuilds; these source snapshots are not app resources.

## Installation behavior

- The complete six-book pack is copied from signed app resources during the background library bootstrap; no runtime download, account, analytics, or network connection is needed.
- Stable IDs, source checksums and a per-library receipt prevent duplicates on restart. Existing matching imports, progress, custom covers and archive state are preserved.
- Books removed or archived by the user are not inserted again. Missing files are not automatically resurrected.
- Corrupt library JSON is never replaced with starter records. Invalid resource checksums and invalid receipts fail without committing a replacement library.
- A known earlier resource revision can be corrected only when its installed copy remains unread and byte-identical to that earlier revision. Edited/read copies are left alone.
- Existing Comics/Manga profiles remain unchanged. The samples belong to Books and Mix.

## Verification

`python3 Tests/run-bundled-classics.py` passed against all six shipped files: XML/package structure, hashes, 162 reading sections, native production EPUB text parsing, covers/metadata, installation, duplicate prevention, archive/delete receipts, imported-copy deduplication, corrupt-source rejection and preservation of user-edited files during resource revision correction.

Xcode Mac Catalyst Debug build succeeded with no compiler diagnostics in the latest activity log. The built application contains the resource folder. Normal Book Hub showed six covers and six author shelves; Frankenstein opened directly to Letter 1. All six installed file hashes match the current catalogue. New iPad and Release/archive verification were not performed in this step.

## Rebuild

Restore the six `Scripts/classic_sources/*.html.gz` files to a temporary directory, keeping the `classic-N.html` names. Generate covers with `Scripts/classic_covers.swift` using the retained catalogue, then run `python3 Scripts/build_classics.py /path/to/source-html`. Run the check script before building. The script has no network access; do not replace source text or artwork without updating its provenance review.

Türkçe klasikler uygun kaynak baskı doğrulamasını bekliyor. Akademik Kitaplar sekmesi hâlâ ertelenmiş durumda.


## 2026-10-21 — ten classics and dedicated achievements

Added four original English texts with custom covers: Dr. Jekyll and Mr. Hyde (PG43, 10 chapters), A Christmas Carol (PG46, five staves), Treasure Island (PG120, 34 chapters), The Time Machine (PG35, 16 chapters plus epilogue). Sources and original HTML hashes are in catalog.json; unmodified HTML is retained compressed in Scripts/classic_sources. No source illustrations or modern translations ship. USA source status and author dates were checked against the four official Gutenberg catalogue pages; territory scope remains USA/Türkiye as above.

All ten bundled titles now have three themed awards: start reading (50 XP), reach 50% (100 XP), explicitly complete (200 XP). Thirty new awards bring the Books tab to 90; comic awards and existing unlock IDs remain unchanged. Stable bundled UUIDs distinguish titles, including the two Stevenson books. Merely installing a book grants no title-specific awards. EPUB chapter index and saved scroll fraction determine halfway progress; opening a reader marks it as reading. Completion follows the app's explicit completed status. Archived books retain eligibility, and unlocked awards remain persisted after removal.

Verification: all ten EPUBs parse through production EPUBPackage with correct chapter counts, embedded covers and hashes. Installer tests cover six-to-ten upgrade while preserving existing reading progress, repeated launches, archive/delete receipts, imported duplicate reconciliation and corrupt-resource refusal. Achievement tests cover untouched, started, below-half, half, completed and archived states, unrelated same-title books and comic isolation. Existing Book Hub model, EPUB, workspace and queue checks pass.

Mac Catalyst UI validation: Debug build runs successfully, dashboard displays ten books, Books tab displays 90 awards, Special filter shows themed cards, and an existing started Frankenstein record earns Yaratılış Kıvılcımı after reevaluation. The UI displays award requirements without internal stage counters. Opening Achievements reevaluates newly introduced awards for existing profiles.
