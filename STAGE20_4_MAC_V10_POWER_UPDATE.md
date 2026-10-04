# ComicPort — Stage 20.4 / Mac v1.0 Power Update

One-package implementation of the remaining post-RC improvement roadmap.

## Reader
- robust UIViewController first-responder keyboard layer for Mac Catalyst
- Left/Right arrows, Space, Shift-Space, S, F and Escape
- horizontal swipe gesture
- rich draggable page scrubber
- thumbnail scrubber around the current page
- quick Normal/Night/Sepia reader theme menu
- Stage 20 single/two-page and right-side fullscreen controls retained

## Library Power Tools
- exact SHA-256 duplicate detector
- Storage by Series
- Library quick tabs: All / Reading / To Read / Completed / Favorites
- right-click Quick Preview
- metadata editor
- ComicInfo.xml write-back; archive normalized to CBZ when necessary
- cover chooser from any page

## Cleaner & Repair Lab
- local PDF inspection
- likely blank-page detection
- adjustable header/footer crop
- non-destructive PDF -> clean CBZ conversion
- basic ComicInfo.xml generation
- CBZ page-order repair/repack to 0001, 0002...
- original files are preserved by default

## Desktop Flow
- Command-K command palette
- last dashboard destination restored
- most recent reader book ID persisted
- reading-session summary
- Source-folder new-comic notice
- backup health check

## Optimization / Stability 13
- Mac CBZ reader remains UICollectionView-free
- thumbnails load only around the current page
- duplicate hashing runs off-main and streams files in 1 MB chunks
- storage scan runs off-main
- Cleaner/Repair work runs off-main
- existing cache limits remain intact

The Xcode project structure is unchanged from Stage 20.0.2.
