# ComicPort — Stage 17 / Mac v0.4.2

Compile fix for Apple's Translation framework availability on Mac Catalyst.

Xcode currently marks `TranslationSession` as available on:
- iOS 18.0+
- Mac Catalyst 26.0+

The previous build guarded only iOS 18, which caused the Catalyst compiler error:
`'TranslationSession' is only available in Mac Catalyst 26.0 or newer`.

v0.4.2 changes:
- `ReaderSystemTranslateButton` is explicitly annotated
  `@available(iOS 18.0, macCatalyst 26.0, *)`
- the call site checks
  `#available(iOS 18.0, macCatalyst 26.0, *)`
- on older Catalyst systems, OCR / Copy / Read Aloud stay available;
  only system Translation is hidden.

The Xcode project file is unchanged from the known-good v0.2 base.
