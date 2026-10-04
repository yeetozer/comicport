# ComicPort — Stage 18 / Mac v0.5

## Smart Collections
Built-in dynamic collections:
- Unread
- In Progress
- Completed
- Favorites
- 4–5 Stars
- Manga / RTL
- Added in Last 30 Days
- Long Reads (150+ pages)
- PDF
- Archives
- Missing Files

Custom Smart Collections can combine:
- title contains
- reading status
- minimum rating
- favorite-only
- PDF / Archive
- Manga / RTL

Smart Collections are filters only; they never duplicate comic files.

## Local Sources
Mac source folders use security-scoped bookmarks.
ComicPort scans recursively for:
PDF, CBZ, CBR/RAR5, RAR, CB7/7z, CBT/TAR, ZIP and TAR.

Performance:
- recursive directory enumeration runs off main
- fingerprints use path + size + modification time
- already-seen files are not queued again
- up to 12,000 known fingerprints are retained per source
- startup scanning is delayed until after the UI is visible

## ComicPort Sync Folder
No ComicPort server is involved.

The user chooses a folder and ComicPort writes:
`ComicPort-Sync-v1.json`

State included:
- current page / reading progress
- reading status
- favorites
- ratings
- daily goal
- reading history mapped through `sourceIdentity`

Comic files are NOT copied by Sync Folder.

The selected folder can be:
- local-only
- iCloud Drive
- Dropbox / OneDrive / other filesystem-backed provider

The operating system/provider owns any network transfer.

Sync behavior:
- remote state is merged after launch when configured
- manual Sync Now imports remote first, then exports merged state
- normal ComicPort state changes trigger a debounced metadata export

## Conflict policy
With no per-field server timestamps, merges are intentionally conservative:
- newer `lastReadAt` wins page/status
- otherwise higher page progress is retained
- Completed wins over non-completed
- Favorite is unioned
- higher rating is retained
- reading-history entries merge by stable history UUID

## Performance 10
- source scan off-main
- fingerprint-based incremental scan
- compact metadata-only sync file
- 1.4 second coalesced sync writes
- launch does not wait for Sources or Sync
- Xcode project file is unchanged from the known-good Stage 17 / v0.4.3 project

## Widget status
Mac widgets remain paused and are not part of this Stage.
