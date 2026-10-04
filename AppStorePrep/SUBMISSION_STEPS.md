# ComicPort Mac — App Store Submission Steps

## A. Before creating the App Store record
1. Confirm the public name “ComicPort” is available in App Store Connect.
2. Choose a permanent production Bundle ID.
   Current development Bundle ID is still: `com.example.PanelReader`
3. Choose whether the Mac version should share an App Store record / universal
   purchase with the iPad version or be managed separately.
4. Confirm Apple Developer Program membership and Agreements/Tax/Banking status.

## B. Xcode identity
1. Select the PanelReader target (public display name is ComicPort).
2. Signing & Capabilities → select the real Team.
3. Replace the development Bundle ID with the permanent production ID.
4. If the bundle ID changes, decide how existing local test data should migrate.
5. Keep Mac Catalyst enabled.
6. Verify App Sandbox is active in the Catalyst build.
7. Test user-selected files, Source folders and security-scoped bookmarks.

## C. Public release version
Suggested first public release:
- Marketing Version: 1.0
- Build: 1

Do this only after the production Bundle ID is fixed.

## D. Privacy
1. PrivacyInfo.xcprivacy is included in the main app Resources phase.
2. Product → Archive.
3. Organizer → Generate Privacy Report.
4. Reconcile the report with `APP_PRIVACY_ANSWERS.md`.
5. Publish `PRIVACY_POLICY_DRAFT.md` at a real public HTTPS URL.
6. Enter that URL in App Store Connect.

## E. Mac screenshots
Capture 1–10 screenshots in an accepted 16:10 size.
Recommended: 6 screenshots at 2880 × 1800.
See `SCREENSHOT_PLAN.md`.

## F. App Store Connect
Fill:
- Name
- Subtitle
- Primary/secondary category
- Age rating questionnaire
- Content Rights
- Privacy
- Description
- Keywords
- Support URL
- Copyright
- App Review contact
- App Review notes
- Screenshots

Use `APP_STORE_METADATA.md` and `APP_REVIEW_NOTES_DRAFT.md`.

## G. Archive and upload
1. Scheme: ComicPort Mac
2. Destination: My Mac (Mac Catalyst)
3. Product → Archive
4. Organizer → Validate App
5. Fix every validation error/warning that can affect review.
6. Distribute App → App Store Connect → Upload.
7. Wait for build processing.
8. Select the processed build in the macOS version record.
9. Complete remaining compliance questions.
10. Submit for Review.

## H. Final clean-Mac smoke test
Before review, test a signed build on a clean macOS user account or another Mac:
- Import/open PDF
- CBZ/CBR/7z/TAR
- Finder Open With
- Source folder permission persistence
- Sync folder
- backup/restore
- reader
- OCR/TTS/translation
- permanent delete
- Diagnostics

WidgetKit remains deferred and is not a release blocker.
