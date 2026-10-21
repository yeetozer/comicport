# ComicPort — güncel proje (21 Ekim 2026)

Bu paket, Book Hub ve Comic Hub geliştirmelerinin son kaynak kodunu içerir.

- Comic Hub temaları: Kızıl Şehir, Gece Mağarası, Kıyı Atölyesi, Kayıp Orman ve Altın Salon.
- Temaları Comic Hub içindeki **Ayarlar → Özel temalar** bölümünden seçebilirsin.
- Book Hub: 10 çevrimdışı klasik, kitaplara özel başarımlar, sıcak raflar ve yazar portreleri.
- Comic Hub: sayı kutuları/kapak vitrini, bilgi kutucuğu ve okuma önerisi.
- Beş yıldızlı kitapları mağara/atölye vitrinlerine yerleştirme fikri iptal edildi; bu özellik bulunmaz.

**Çalıştırma:** `PanelReader.xcodeproj` dosyasını Xcode ile aç. Mac için `ComicPort Mac` şemasını ve `My Mac (Mac Catalyst)` hedefini seç. Cihazda çalıştırmak için kendi imzalama takımını seçmen gerekebilir.

Son uygulama değişikliği Mac Catalyst üzerinde derlendi ve görsel olarak kontrol edildi. iPad için bu son tema turunda görsel doğrulama yapılmadı.

Bu bir kaynak proje paketidir; derlenmiş/kurulabilir uygulama değildir. Kullanıcının içe aktardığı çizgi romanlar, puanları ve okuma geçmişi pakette yer almaz. Tema varlıkları, paketli klasikler, testler ve geliştirme belgeleri korunmuştur.

## Önceki sürüm notları

### v2.1 Stage 5

Native offline iPad comic reader.

## Stage 5 additions
- Storage Optimizer for PDF and CBZ
- High Quality / Balanced / Maximum Savings presets
- PDF -> optimized CBZ reading-copy conversion
- Uses saved Auto Crop / Full Bleed settings while optimizing PDFs
- Original file stays untouched until the optimized copy is complete and validated
- Safe replacement with rollback backup
- Reading progress, history, ratings, favorites, notes, reader settings and achievements stay attached to the same book ID
- Redesigned achievement unlock banner with tier-specific gradients, glow, sparkle reveal, haptic feedback and longer Legendary presentation

Open `PanelReader.xcodeproj`, choose your signing Team, select your iPad, then Run.


## Stage 7
- Reading Calendar + special comic/character days
- 365-day heatmap, streaks, weekly activity
- Panel Wrapped yearly summary and share text
- 400 offline comic facts with shuffle
- Upcoming comic days card on Home


## Stage 7.4 - Stability / Performance
- Reader preflight validates local files before opening
- Dashboard sleeps while immersive reader is active
- Dashboard direct-open uses item-based fullScreenCover
- PDFDocument preparation moved off the main thread
- CBZ extraction moved off the main thread
- CBZ page images are downsampled/decoded off-main and cached in RAM
- Stale fileAvailable metadata is repaired automatically when the local file exists


## Stage 8 - Apple Pencil + My Panels
- Debounced PencilKit note saving
- PencilKit tool picker (pen/highlighter/eraser) retained
- Per-page text notes
- Notes center with direct return to source page
- Crop-and-save favorite panels from PDF/CBZ pages
- My Panels gallery, source navigation, sharing and deletion
- Notes/My Panels achievements


## Stage 9 - Backup / Restore + Polish
- Single .panelbackup profile backup (comic PDF/CBZ files excluded)
- Books metadata, reading history/stats, achievements, reader/crop settings, story arcs
- Pencil drawings, text notes, My Panels images and offline book-info cache
- Restore merges by source identity and remaps IDs safely
- Re-restoring the same backup does not duplicate reading-history entries
- Theme and app preferences restored
- Annotation achievement checks now use an in-memory index rather than repeatedly scanning disk
- Settings screen reorganized and polished
- Wrapped lookup hot paths use book dictionaries rather than repeated linear scans


## Stage 10 - Offline Smart Search / OCR
- On-device Vision OCR for PDF and CBZ pages
- Manual background indexing; never scans the entire library automatically at launch
- Cancelable page-by-page indexing with progress
- One compact JSON index per comic in Documents/SearchIndex
- Search names, words and dialogue across the indexed library
- Search result jumps directly to the matching page
- Title matches work even before OCR indexing
- Per-book Index/Re-index card in Book Detail
- Missing comic files may retain their text index, but source-page opening is disabled until re-import
- OCR index is rebuildable and intentionally excluded from .panelbackup
- Permanent delete removes the comic's OCR index


## Stage 11 - Guided Panel View + Performance Pass 3
- On-device Vision rectangle detection for panel-by-panel reading
- LTR and RTL panel ordering
- Borderless-page smart-strip fallback
- Per-page Guided layout disk cache and 7-page in-memory rendered-page cache
- Next Guided page is prefetched in the background
- Tap left/right edges to move panel-by-panel; center toggles reader controls
- Whole-page overview, pinch zoom, double-tap zoom and per-page re-detect
- Guided mode persists across reading sessions and next issues
- Guided mode waits until the final panel before Auto Next Issue
- CBZ extraction moved to a validated persistent cache with old-cache pruning
- Background OCR / Book Info / optimization no longer deletes CBZ pages used by an active reader
- CBZ next/previous pages are image-decoded ahead of navigation
- PDF Auto Crop detection now has a thread-safe in-memory cache
- Smart Search result matching moved off the main thread


## Stage 12 - Recommendations + Calendar Alignment + Performance Pass 4
- Comic calendar event markers now wrap the exact day number in both compact and full calendars
- Multiple events on one day render centered secondary markers under the date
- New compact “Sana Öneri” bar directly under “Biliyor muydun?”
- Recommendations are fully offline and use favorites, ratings, reading status/progress plus the 950-record local catalog
- Owned books are excluded from recommendations; richer curated catalog entries are preferred
- Recommendation scoring runs off-main and is cached until taste/library metadata changes
- Hot yyyy-MM-dd conversions no longer create DateFormatter instances per calendar cell/streak calculation
- Full calendar precomputes the displayed month’s comic-event lookup map
- Publisher category classification now runs off-main
- Comic fact shuffle no longer filters all 400 facts for every tap
- Cover image cache explicitly clears on iPadOS memory warnings


## Stage 13 - Library Health + Smart Reading Order 2.0 + Performance Pass 5
- Library Health Center with quick and explicit deep scans
- Missing file, unreadable PDF/CBZ, page-count mismatch, missing cover, duplicate and oversized-file checks
- One-tap missing-cover regeneration
- Safe Cleanup removes only orphaned cover/search/guided/CBZ caches
- Reading Order 2.0 detects missing integer issues and duplicate issue numbers per series/volume
- Series details include offline related-reading candidates based on shared characters, tags and creators
- Related-reading suggestions are explicitly non-canonical unless backed by future curated crossover data
- Upcoming comic-calendar events influence the compact recommendation bar for a 10-day window
- Batman Day, Spider-Man Day, Superman Day, X-Men Day, Wonder Woman Day and creator anniversaries use event-specific local-catalog boosts
- Recommendation card explains the event context and days remaining
- Series title parsing now uses a 4,000-entry NSCache
- Fixed duplicate work in status filtering
- Story-arc progress avoids repeated linear book searches
- Health/deep file validation and maintenance cleanup run off the main thread


## Stage 14 - Reading Journal + Performance Pass 6
- Completion journal appears when a comic is newly finished
- 0–5 star rating, free-form note, re-read intent and optional favorite My Panels reference
- “Şimdi Değil” suppresses repeat prompts for 12 hours
- Guided Panel View waits until the final panel before offering the journal
- Auto Next Issue continues only after the journal is saved/skipped
- Dedicated Reading Journal library with search, stats and entry details
- Reading Journal is preserved by Delete File / Remove / Archive and removed by Permanent Delete
- Backup schema 2 adds Reading Journal while remaining compatible with schema 1 backups
- Upcoming special-day recommendations explicitly say “X yaklaştığından bunu öneriyorum • N gün kaldı”
- LibraryStore init no longer reads/decodes/enumerates the whole library synchronously
- First frame uses a lightweight launch view; persisted state is decoded on a user-initiated background bootstrap worker
- File-availability repair, Notes scan, My Panels validation and SearchIndex listing moved off-main at launch
- Existing achievement profiles are no longer fully re-evaluated during startup
- Local 950-record comic catalog is loaded off-main for recommendations
- Debounced library.json encoding/writing moved off-main
- Dashboard reading-summary aggregation moved off-main


## Stage 14.1 - Recommendation + Theme Fix
- Special-day recommendation window expanded from 10 to 30 days
- Checks the next 8 calendar events and prioritizes character/creator occasions over generic community days
- Event matching uses both event ID and display title, making localized/renamed calendar entries resilient
- Special-day relevance now weights title, aliases, characters, creators, tags and description
- Special-day reason gets its own visible calendar line in the compact recommendation card
- Settings shows the currently active recommendation mode for easy testing
- Added Cyan, Mint, Yellow, Amber, Rose and Violet accent themes
- Recommendation score cache remains keyed by taste + date + active occasion; shuffle reuses cached recommendations


## Stage 15 - Widgets + Shortcuts + Performance Pass 7
- Lightweight animated launch mark; animation never delays async library bootstrap
- Native WidgetKit extension: Continue Reading, Daily Goal quick-entry, Upcoming Comic Day
- Widgets deep-link with panelreader:// and require no App Group entitlement
- App Intents / Shortcuts: Continue Reading, Random Comic, Reading Goal, Offline Smart Search
- Reading Goal Shortcut reads analytics.json directly without loading the full app UI
- Cold-start widget/shortcut actions queue until LibraryStore bootstrap completes
- Dashboard Home uses LazyVStack
- Major JSON persistence is serialized through a background actor
- Widget timeline is independent from LibraryStore and refreshes every 6 hours


## Stage 15.1 - ComicPort Rebrand
- Public app name changed to ComicPort
- iPad Home Screen label now shows ComicPort
- Selected purple-neon open-comic artwork installed as AppIcon
- Launch animation wordmark changed to COMIC / PORT
- Dashboard/sidebar/navigation/alerts use ComicPort
- Panel Wrapped renamed ComicPort Wrapped
- Widgets and App Intents use ComicPort branding
- Primary deep link is comicport://
- Legacy panelreader:// links remain accepted
- Existing bundle ID, UserDefaults keys, cache paths and internal type names remain unchanged on purpose, protecting current local library data


## Stage 16 — Universal Library + Smart Metadata + Performance Pass 8

### Universal Comic Import
ComicPort now accepts:
- PDF
- CBZ / ZIP
- CBR / RAR / RAR5
- CB7 / 7z
- CBT / TAR

ZIP/CBZ keeps the mature native ZipExtractor fast path. RAR/RAR5, 7-Zip and TAR use
the LibArchive Swift Package (`everpcpc/libarchive-swift`, 0.1.6+). The dependency
ships an iOS XCFramework; comic extraction remains local/offline at runtime.

Password-protected archives are detected but intentionally not supported in Stage 16.

### ComicInfo.xml
Archive imports look for ComicInfo.xml before filename inference. Supported fields include:
Title, Series, Number, Volume, Count, Year/Month/Day, Writer, Penciller, Inker,
Colorist, Letterer, CoverArtist, Editor, Publisher, Imprint, Characters, Teams,
Locations, Genre, Tags, StoryArc, SeriesGroup, LanguageISO, Format, Manga,
AgeRating, Summary and PageCount.

ComicInfo.xml can:
- rename the imported library item using Series / issue / title
- set right-to-left manga reading automatically
- seed the existing offline Book Info cache immediately
- improve duplicate/relink matching when filenames differ

Metadata priority in offline analysis:
1. ComicInfo.xml — Verified
2. embedded PDF metadata
3. bundled local comic catalog
4. filename parser
5. OCR — Inferred

### Performance Pass 8
- File copy, PDF page counting, archive extraction, ComicInfo parsing and cover generation moved off the MainActor.
- Multi-file imports can prepare concurrently without freezing the dashboard.
- Universal extraction cache is validated by source size/modification date and pruned to six recent archive folders.
- Existing CBZ extraction cache behavior remains compatible, with a new universal cache root.
- ComicInfo.xml is read directly from the archive without requiring full image extraction.

### Compatibility
ComicBook's persisted enum remains `.pdf` / `.cbz` internally. Every non-PDF comic
archive uses the proven image-reader pipeline while preserving its actual stored
extension. This avoids breaking existing library.json backups and reading history.


## ComicPort Mac v0.1 — Shared Catalyst Foundation
- The existing main app target now supports both iPadOS and Mac Catalyst.
- Stage features are implemented once and automatically compile into both platforms.
- Finder drag-and-drop import uses the same LibraryStore import path as iPad Files import.
- SwiftUI Commands provide a ComicPort menu on Mac and hardware-keyboard commands on iPad.
- The iPad WidgetKit extension is platform-filtered and is not embedded in the Mac Catalyst build.
- Stage 16 archive access now uses a Catalyst-capable libarchive binary package so PDF/CBZ/CBR/RAR5/CB7/7z/CBT/TAR remain one shared feature.
- Existing bundle ID, local data models, backup format, reader settings and storage paths remain shared at source level.
- Automatic cross-device data synchronization is not implied by the shared codebase; Stage 18 remains the iCloud sync milestone.


## Stage 16.1 Linker Patch
The libArchive static XCFramework needs a few Apple SDK libraries resolved by the
final app target. ComicPort now explicitly links:
- libbz2.tbd
- libxml2.tbd
- libiconv.tbd
- existing libz.tbd

This targets the `_BZ2_*`, `_xmlTextReader*`, `_xmlReaderForIO`,
`_xmlCleanupParser`, and `_iconv*` undefined-symbol errors.


## ComicPort Mac v0.2 — Desktop Experience + Optimization
- Mac sidebar moved to a desktop-specific List interaction model
- Sidebar destinations react on a single click with no navigation animation delay
- Hover highlighting added to desktop sidebar
- Mobile bottom bar hidden when desktop sidebar is visible
- Dashboard bottom padding reduced on Mac
- Universal Stage 16 importer is used from Dashboard
- Command-O imports comics; Command-1 Home; Command-2 Library
- Finder drag-and-drop now gives a full-window visual drop affordance
- Cover cache: 360 images / 256 MB on Mac
- Comic page cache: 42 images / 384 MB on Mac
- Archive extraction cache: 12 recent archives on Mac
- Added a shared `ComicPort Mac` Xcode scheme to avoid accidentally running the Widget scheme


## Stage 17 / Mac v0.4.1 — clean project rebuild
Rebuilt from the stable v0.2 Xcode project without modifying project.pbxproj.
This specifically replaces the malformed v0.4 package.


## Stage 18 / Mac v0.5 — Smart Collections + Sources + Sync + Performance 10
Mac-first organization and local-first synchronization layer.
The Xcode project structure is intentionally unchanged; Stage 18 is implemented
inside existing compiled source files to preserve the stable project.


## Stage 19 / Mac v0.6 RC1
Mac roadmap release candidate: Finder/Open-With handling, backup schema 3,
Diagnostics & Release Health, desktop shortcut polish, release metadata hardening
and Performance 11. WidgetKit remains paused.


## Stage 19.2 / Mac v0.7 RC2 — Final Polish
Desktop-density controls, hover/context interactions, dashboard cleanup,
reader tooltips, Reduce Motion polish and Mac-facing language cleanup.
No project/target/package changes. WidgetKit remains paused.


## Stage 19.3 / Mac v0.8 — App Store Preparation
Adds the app privacy manifest and App Store preparation pack. The permanent
production Bundle ID / Apple Team remain intentionally unset until the developer
chooses them. WidgetKit stays paused.
