# Stage 21.1 — Book Hub Foundation

Books now has a Book Hub sidebar identity and a warm amber/walnut dashboard with lazy shelves, a Books-only summary and an empty-library state. Books imports are classified at request time, so changing profiles during an import cannot change its classification. Existing records keep their identities, classifications and reading progress.

## Data and intelligence

ComicBook has optional BookBibliography data: title, authors, publisher, ISBN, language, publication year, summary, field provenance and analysis date. Missing bibliography and cover revision decode from Stage 21.0.1 without migration loss. ISBN is a storage field, not an implemented lookup feature.

On-demand local analysis uses existing PDF/ComicInfo/OCR readers through BookMetadataIntelligence. Books bypass the comics catalog and comic series/issue inference. Embedded book authors and title provenance are retained. User-edited bibliography fields survive re-analysis. Network providers and EPUB support are outside this foundation package; the current importer supports PDF and comic archives.

## Performance rules

- No metadata scans, OCR or remote calls on dashboard startup.
- Maximum 4 pages per analysis, one heavy analysis at a time.
- Duplicate requests share one analysis; at most 8 distinct jobs may be pending.
- At most 32 completed analysis results in memory; file timestamp/size, title and classification participate in identity. URL resource caches are explicitly refreshed.
- Dashboard shelves contain at most 8 continuing / 12 recent books and use lazy layouts.
- Dashboard covers downsample to 640 pixels off the UI actor. Existing NSCache limits and memory-warning eviction remain in place; costs use decoded pixel bytes.
- Persisted cover revision refreshes thumbnails after cover replacement/relink without reading file timestamps in the view.
- Existing library persistence is still synchronous. Large-library UI FPS, peak memory and large-file import/reader profiling need a separate measured performance pass; model tests are not evidence of UI scalability.

## Validation

Mac Catalyst clean baseline build passed; incremental builds and app-launch smoke checks followed each implementation step. The final build passed without compiler warnings in its log. Ad-hoc local signing was used for execution; this is not an App Store/signing validation.

A generated 4-page PDF fixture verified Books import, cover display, reader entry/navigation/return, progress persistence across restart, local embedded title/author analysis, updated cover selection, metadata persistence and manual author preservation after re-analysis. The generated fixture was archived after testing; existing books were left unchanged. Comics, Manga, Mix and Books profile switches were exercised. An idle process sample after launch used about 92 MiB RSS and 0% CPU; this is not a peak-memory or large-library benchmark. Foundation checks verify legacy decoding, bibliography round-trip, 1,000-record encoding/decoding/filtering, serial scheduling, queue bounds, duplicate coalescing, cache hits and changed-file invalidation.

Run repeatable checks with `python3 Tests/run-bookhub-checks.py` from the project. Xcode/Swift compiler cache permissions may be required.
