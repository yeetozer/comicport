# ComicPort — Stage 17 / Mac v0.4.1

This is a clean rebuild from the last known-good Mac v0.2 project.

IMPORTANT:
- `PanelReader.xcodeproj/project.pbxproj` is byte-for-byte unchanged from v0.2.
- Widget development remains paused; this package does not add or modify widget targets.
- The existing dormant iPad widget target from the stable project is left untouched rather
  than destructively editing the Xcode project.

## Reader
- Comic Enhance: Off / Clarity / Vivid / Ink / Soft
- non-destructive contrast / saturation / grayscale presentation
- larger controls
- high contrast reader bars
- reduced reader animation
- Mac PencilKit accepts mouse/trackpad input

## Page Language Tools
- native PDF text first
- local Vision OCR only when needed
- archive-page OCR on the selected page
- Copy
- Read Aloud
- Apple Translation when the framework/system supports it
- Copy Translation
- Read Translation

Translation may require a one-time Apple language-model download.

## Performance 9
- OCR text cache capped at 24 pages
- PDF crop cache capped at 28 entries on Mac
- an additional PDF crop page is warmed on Mac
- CBZ prefetch looks two pages behind and three ahead on Mac

## Run
ComicPort Mac → My Mac (Mac Catalyst) → Command-R
