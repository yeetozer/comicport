# ComicPort — Stage 20.0.1 / Mac v0.9.1

Reader full-screen toolbar visual hotfix.

Problem:
The vertical full-screen toolbar used SwiftUI `Divider()` inside a `VStack`.
On Mac Catalyst the divider could claim the available horizontal width, which made
the toolbar material background expand across almost the entire reader window.

Fix:
- replace flexible `Divider()` views with fixed 28 × 1 separators
- constrain the right-side toolbar to the control width + padding
- keep the toolbar aligned to the right edge
- no reader behavior or page-layout logic changed

The Xcode project file is unchanged.
