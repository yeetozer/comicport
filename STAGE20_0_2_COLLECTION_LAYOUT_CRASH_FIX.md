# ComicPort — Stage 20.0.2 / Mac v0.9.2

Mac Catalyst reader crash hotfix.

## Crash
`UpdateCoalescingCollectionView is stuck in a recursive layout loop`

## Cause
SwiftUI `.tabViewStyle(.page)` uses a collection view internally. The Stage 20
Single Page / Two Pages feature changes the set of spread items and valid
selection tags while the reader is live. On Mac Catalyst this can make the
self-sizing collection repeatedly update its bounds/layout.

## Fix
- Mac Catalyst CBZ/archive reader no longer uses page-style TabView.
- The active single page or two-page spread is rendered directly.
- iPad keeps the existing page-style TabView behavior.
- External progress changes still update the displayed page.
- Single/Two Page switching still works.
- Keyboard page navigation still works.
- Page indexes are clamped defensively during layout-mode changes.
- The Stage 20.0.1 narrow right-side toolbar fix is retained.

No target, package, framework, or project-file changes.
