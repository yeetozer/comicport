# ComicPort — Stage 19.2 / Mac v0.7 RC2

Final Mac UI/UX polish before App Store preparation.

## Dashboard
- Mac sidebar uses a cleaner material surface.
- Storage card is now clickable and opens Settings.
- Excess desktop bottom padding under the storage card is removed.
- Top bar no longer shows two buttons that perform the same import action.
- Import button shows Command-O.
- Import-in-progress state appears in the top bar.
- Search gets a one-click clear control.
- Empty states use a consistent visual treatment.

## Library
- Cover size is adjustable on Mac with a persistent density slider.
- Grid spacing responds to cover size.
- Comic cards get subtle hover lift/shadow.
- Right-click on comic cards exposes Favorite and Reading Status actions.
- Collection headers show comic counts.

## Reader
- Mac reader controls use plain button styling.
- Common reader controls have hover tooltips.
- Existing Comic Enhance / OCR / accessibility behavior is unchanged.

## Accessibility
- App bootstrap and achievement transition honor Reduce Motion.
- Launch glow animation is disabled when Reduce Motion is enabled.

## Platform-language cleanup
Mac-facing UI no longer says things such as “on this iPad” in:
- Book Detail
- offline metadata
- Library Health
- Guided Panels
- Smart Search
- Storage Optimizer

## Stability
No new framework, package, target or widget work was introduced.
`project.pbxproj` is byte-for-byte unchanged from Stage 19.1.

WidgetKit remains paused.

Next step after RC2 smoke testing: App Store preparation.
