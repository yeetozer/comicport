# Book Hub — EPUB reader polish

20 October 2026. Based on 5b332d8.

## Implemented
- Local chapter images appear inside the reading text, in source order. The image gallery remains available.
- Image preparation runs off the main thread, uses the existing 1200-pixel downsampling, and retains thumbnails within a 32 MiB decoded-pixel budget per chapter. Unsupported/budget-exceeding images use a placeholder; the gallery can display them separately. This is not a total app RAM limit.
- Internal links retain fragments. Same-chapter and cross-chapter targets scroll to their normalized UTF-16 text positions after native layout is ready. Both id and legacy named anchors are recognized; duplicate IDs keep the first target.
- Persisted text/highlight offsets remain based on the unchanged normalized source text. A display map removes inserted image characters from new selections.
- Line spacing and horizontal margins have compact/normal/wide choices. Older reader records retain the existing defaults.
- The roadmap now reflects completed Book Hub work. Academic Books is explicitly deferred until after Book Hub.

## Verification
- Xcode Mac Catalyst Debug builds succeeded.
- The existing model, EPUB, workspace, metadata queue and cover queue check suite passed.
- Updated model checks passed for old settings defaults and new layout setting round trips.
- EPUB checks passed for Unicode/percent-encoded fragment names, named anchors, ignored script targets, unchanged text, image positions and display/source mapping.
- Native isolated-library test: inline image visible; same-chapter footnote reached; cross-chapter target reached after 50 paragraphs; return link worked.
- Native selection after an inline image saved the exact quote “Görsel sonrası metin.” at source location 78. Reopening the book showed the yellow highlight on that exact text.
- Wide line spacing persisted to the isolated library and remained applied when the reader reopened.
- Temporary COMICPORT_TEST_LIBRARY scheme setting was removed after verification.

## Scope and outstanding validation
- Basic reflowable EPUB reader, not a publisher-CSS/fixed-layout engine. SVG, DRM, audio/video remain unsupported. Missing fragments leave the target chapter available without guessing a text match.
- New Release/archive and iPad/device verification were not performed for this change.
- Full backup restoration and long-duration testing with large real books remain separate Book Hub QA work.
- Active development copy: /Users/baranyolcu/Documents/Codex/2026-10-20/new-chat/ComicPort-next. The earlier /Users/baranyolcu/Documents/Codex/ComicPort copy was not modified.
