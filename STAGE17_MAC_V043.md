# ComicPort — Stage 17 / Mac v0.4.3

Compile fix for ReaderView local scope.

Problem:
`readerSettings` was declared inside the ZStack ViewBuilder but referenced by
modifiers attached to the ZStack, including:
- animation
- language tools sheet

Fix:
`readerSettings` is now declared at the `else if let book` branch scope, before
the ZStack. The reader content and all modifiers share the same binding value.

The Xcode project file remains byte-for-byte unchanged from v0.4.2 / stable v0.2.
