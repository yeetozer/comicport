# Release Blockers / Decisions Still Needed

These cannot be safely guessed in the source package:

1. PRODUCTION BUNDLE ID
   Current value: `com.example.PanelReader`
   Must be replaced before the first App Store upload.

2. APPLE DEVELOPER TEAM
   Must be selected from your signed-in Apple Developer account.

3. PRIVACY POLICY URL
   A public HTTPS URL is required.
   A draft policy is included in this folder.

4. SUPPORT URL
   App Store Connect requires a working support URL.

5. APP NAME RESERVATION
   “ComicPort” should be checked/reserved inside App Store Connect.

6. AGE RATING
   Complete Apple's current questionnaire in App Store Connect.
   ComicPort itself has no ads/chat/gambling/unrestricted web browser, but the app
   reads user-supplied files, so answer the questionnaire based on the actual
   shipping functionality and Apple's prompts.

7. CONTENT RIGHTS
   Review the bundled local metadata database and all marketing screenshots.
   Do not use copyrighted comic pages in store assets without rights.

8. THIRD-PARTY BINARY
   ComicPort currently depends on the `okferret/libArchive` Swift package from
   its `main` branch. Before the final archive, prefer a pinned/reproducible
   dependency or a vendored verified binary and preserve applicable license notices.

9. FINAL XCODE PRIVACY REPORT
   Generate it from the Release archive and reconcile it with App Store privacy answers.

10. WIDGETKIT
    Deferred. Do not add it back before this first release unless separately tested.
