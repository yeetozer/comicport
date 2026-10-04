# ComicPort — Stage 20.0 / Mac v0.9 — Reader Core

First implementation batch from the post-RC improvement list.

## Implemented in this batch

### Keyboard reader navigation
- Left / Right arrow: previous / next in the physical reading direction
- RTL comics invert physical arrow meaning appropriately
- Space: move forward
- Shift-Space: move backward
- S: switch Single Page ↔ Two Pages
- Escape: leave reader
- Double-page mode advances two pages at a time

### Reader layout
- New per-comic Reader Page Layout:
  - Automatic
  - Single Page
  - Two Pages
- Single/Two Page buttons are directly in reader controls.
- PDF and archive readers both obey the saved page-layout preference.

### Full-screen controls
- On Mac, when the reader window occupies essentially the full screen, controls
  move to a compact right-side vertical bar.
- Normal window mode retains the top/bottom controls.

### Five-second auto-hide
- New “Hide Controls After 5 Seconds” reader setting.
- Auto-hide is per comic and optional.
- Opening sheets pauses the hide action.

### Cover presentation
- Library cover images use aspect-fit rather than destructive center-crop.
- Character cards use a portrait comic-cover shape.
- Full cover art remains visible.

### Stability / Performance 12
- CBZ no longer forces an odd requested page back to the prior even page when
  opening in single-page mode.
- The duplicate CBZ bottom controls were removed; ReaderView owns the chrome.
- Nearby-page prefetch remains active.
- No package, framework, target, scheme or project-file changes.

## Next Stage 20.x batches

### Stage 20.1 — Library Power Tools
- duplicate detector
- metadata editor
- ComicInfo.xml write-back
- cover chooser
- Quick Look-style preview
- library quick tabs
- Storage by Series

### Stage 20.2 — Cleaner / Repair Lab
- dirty web-print PDF detector
- cleanup preview
- blank-page removal
- header/footer crop
- Convert to clean CBZ
- CBZ page-order repair
- original files remain untouched by default

### Stage 20.3 — Desktop Flow
- thumbnail scrubber
- richer progress scrubber
- trackpad page gestures
- Command-K palette
- window/session restore
- reading-session summary
- source-folder new-comic notices
- backup health check

Every 20.x stage includes a separate optimization/stability pass.
