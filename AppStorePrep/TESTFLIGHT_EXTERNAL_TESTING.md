# ComicPort — TestFlight external testing pack

Target: uploaded version 1.0.0, build 2, for iPad and Mac Catalyst. No App Store Connect changes were made while preparing this document. Replace every angle-bracket placeholder before pasting into ASC or sending invitations.

Character counts below include spaces and internal line breaks, but exclude code fences and the trailing newline. Recount after replacing placeholders. The 4,000-character ceilings for Beta App Description and What to Test are the requested drafting limits; Apple's current public TestFlight help describes these fields but does not state their numeric maxima. Confirm the live ASC counters before submission. Review Notes is also below Apple's published 4,000-byte Notes limit because its text is ASCII.[1][2][5] For other fields, Apple's cited help does not publish a numeric character limit: this is explicitly marked rather than guessed.

## 1. Quick checklist — ASC navigation (not a text field; no character limit)

1. Sign in to App Store Connect as Account Holder, Admin or App Manager. Apps > ComicPort > TestFlight > Additional > Test Information. Choose English, paste Test Information and Beta App Review Information below, then Save. Initial setup is one-time; update when details change.[1]
2. If no internal group exists: TestFlight > Internal Testing > + > create an internal group first. This is a one-time prerequisite for creating an external group, not a requirement to give friends team access.[2]
3. TestFlight > External Testing > + > enter Group Name > Create (one-time per group). Suggested Group Name (limit not published):

```text
Friends
```

4. External Testing > Friends > Add Builds > select platform and version > select build 2 > Add. Paste What to Test. Select Automatically notify testers if you want distribution after approval; otherwise use Notify Testers after approval. Repeat build selection for the other platform as needed; Apple allows only one build to be added at a time. Do not assume adding the iPad build adds Mac too.[2]
5. Complete any missing review/contact/export information, then click Submit Review (Beta App Review / TestFlight App Review). If the build is already approved, ASC may show Start Testing instead. Wait for approval before inviting friends to install. The first external build needs full review; later builds may still require review.[2][3]
6. External Testing > Friends > Testers > + > Email > enter friends' email addresses > follow the invitation dialog; OR share the existing public link: https://testflight.apple.com/join/jbWWWKy5. The public link already exists; no initial link creation is needed. Sharing can be repeated.[2]
7. For Filter by Criteria, add compatible iPad/iPadOS 17+ and Mac/macOS 14+ criteria where available. Explain the Apple Silicon requirement in the invite regardless; do not assume ASC has a chip filter. Optionally Set Limit for a small friends group. Links can be reshared by anyone, and can be changed/disabled via Manage next to Public Link. The app-wide maximum is 10,000 external testers; a public-link limit can be 1–10,000.[2]

Invitation Experience > App Information (checkbox; no character limit): leave the default if desired. It pulls screenshots/category from the latest approved Ready for Distribution version, not arbitrary draft screenshots.[1]

## 2. Test Information
### Beta App Description — maximum 4,000 characters (draft ceiling; verify ASC counter)

Draft: 905 characters. 

```text
ComicPort is an offline comic reader for your own files. Import PDF, CBZ, CBR, CB7, CBT, ZIP, RAR, 7z and TAR files, read pages or use Guided Panel View, and organize your library with reading statuses, favorites, ratings and collections. Reading progress is remembered. Backup and restore preserve library data; backups do not include the comic files themselves.

This beta is for iPad on iPadOS 17 or later and Apple Silicon Mac on macOS 14 or later (Mac Catalyst). iPhone and Intel Mac are not supported. iPad includes Home Screen widgets. Mac includes keyboard commands and user-selected source folders.

Bring files you own or have permission to use. ComicPort does not supply or download comics. No ComicPort account, login, ads, analytics or tracking is required or included. Reading and library processing work locally. Please report import problems, crashes, lost progress and confusing controls.
```

### Feedback Email — numeric character limit not published

Draft: 24 characters. Required contact/reply-to address for testers.[1][2]

```text
yigit@yigitsolutions.com
```

### Marketing URL — optional; numeric character limit not published

Leave blank. No public marketing website is being claimed or created. Draft count: 0 characters. This is a blank-field instruction, not text to paste.[5]

### Privacy Policy URL — required for review compliance; numeric character limit not published

The policy is NOT hosted yet. Yigit Solutions is hosting it; publish the completed AppStorePrep/PRIVACY_POLICY_DRAFT.md at a public HTTPS URL, replace the placeholder below and verify it opens without sign-in. Do not paste the placeholder as a real URL.

For external testing, treat a published policy as required for review compliance: Apple says TestFlight apps must comply with the App Review Guidelines (2.2), and 5.1.1(i) requires a policy link in ASC metadata and in the app. Apple's App Privacy help also says a URL is required for all apps. The Test Information help does not explicitly document whether the beta form's URL box itself is a hard submission gate; that live-form enforcement was not verified. No-data collection is not an exemption.[7][8]

Draft: 20 characters. 

```text
<PRIVACY POLICY URL>
```

### Licence Agreement — default; no drafted text / no character limit for this choice

Use the default agreement; do not supply a custom licence. If ASC spells the label "License Agreement", it is the same control. Draft count: 0 characters.

## 3. Beta App Review Information

Contact Information: use someone Apple can actually reach during review; these details are not public tester-facing app metadata. Numeric limits for the contact fields are not published in the cited help. Phone Number must be international format, with + and country code.[5]

### First Name — numeric character limit not published

Draft: 20 characters. 

```text
<CONTACT FIRST NAME>
```

### Last Name — numeric character limit not published

Draft: 19 characters. 

```text
<CONTACT LAST NAME>
```

### Phone Number — numeric character limit not published

Draft: 22 characters. 

```text
<CONTACT PHONE NUMBER>
```

### Email — numeric character limit not published

Draft: 24 characters.

```text
yigit@yigitsolutions.com
```

### Sign-in required — checkbox; no character limit

```text
No
```

Reason: ComicPort has no account/login, and import, reading and library features work without credentials. Leave Username and Password blank (0 drafted characters each; numeric limits not published).[5]

### Review Notes — maximum 4,000 characters for this draft; Apple documents Notes as 4,000 bytes

Draft: 2182 characters. 

```text
ComicPort is an offline reader for user-supplied comic files. It has no account or sign-in, no network client, no advertising, analytics or tracking. Reading, panel detection and library processing run locally. Optional Sync Folder writes reading-state metadata to a user-selected folder, not to a ComicPort server; a cloud storage provider may separately sync that folder.

The reviewer needs a CBZ or PDF file to test reading. No commercial comic books are bundled or supplied. A reviewer-ready, self-made or verified public-domain sample will be provided here: <SAMPLE COMIC FILE URL>. Download it outside the app, save it in Files on iPad or Finder on Mac, then select Import in ComicPort. On Mac, Command-O also opens Import. Select the sample, open its library item, turn pages, enable Guided Panel View in the reader controls, and check that reading progress is remembered after closing and reopening the book.

Legal sample candidates include Digital Comic Museum (https://digitalcomicmuseum.com/) and Comic Book Plus (https://comicbookplus.com/), which offer public-domain golden-age comics. Verify the specific work's public-domain status, download terms and rights in the relevant jurisdiction before using or redistributing it. The recommended review sample is a small comic drawn by the developer or a specifically verified public-domain file, provided directly so the reviewer does not need to register at a third-party site.

Supported devices: iPad with iPadOS 17+, or Apple Silicon Mac with macOS 14+ via Mac Catalyst. iPhone and Intel Mac are not supported. Both platforms import PDF, CBZ/ZIP, CBR/RAR, CB7/7z and CBT/TAR. The iPad build includes WidgetKit Home Screen widgets and touch navigation. Mac has desktop menus, keyboard navigation, Finder drag-and-drop import and security-scoped source folders in Sources & Sync. Choose a local source folder, quit and relaunch, then scan it again to check persistent access. The Mac build does not include the iPad widget.

Backup & Restore is available in Settings. Backups preserve library/profile data, not comic file contents; keep original comic files separately. No credentials or paid content access are needed.
```

Sample preparation (not an ASC field; no character limit): Yigit should provide a small, self-made or verified public-domain multipage CBZ/PDF with clear panels and a working direct download at <SAMPLE COMIC FILE URL>. Do not claim it already exists. Digital Comic Museum and Comic Book Plus are candidate sources, not blanket clearance for every file or country. Verify the specific licence/status and any redistribution conditions before sharing.

## 4. Build 2 — What to Test

### What to Test — maximum 4,000 characters (draft ceiling; verify ASC counter)

Draft: 2563 characters.

```text
Please use disposable test files you own or have permission to use. Keep your original comics separately; this is a beta. Build 2 is for iPadOS 17+ on iPad or macOS 14+ on Apple Silicon Mac, not iPhone or Intel Mac.

1. Import: try one valid file of EACH format you have: PDF, CBZ, CBR, CB7, CBT, ZIP, RAR, 7z and TAR. Report untested formats too. Check covers, page count, page order and readable first/last pages. Use real matching archive formats, not renamed unrelated files. Password-protected archives are not supported. Try selecting multiple files.
2. Reading: turn pages forward/back, zoom, switch Single Page/Two Pages, and try right-to-left reading. Close/reopen a book and relaunch the app: does it resume correctly? On Mac, also try arrow keys, Space/Shift-Space and resizing/full screen.
3. Guided panels: enable Guided Panel View on a comic with clear panels. Move forward/back panel by panel, check whole-page overview and zoom, then reach the final panel/page. Report incorrect order, missing panels or awkward smart splits, including the page number.
4. Library/organizing: search a title, mark a favorite, rate a book, change its reading status, and try series grouping/Smart Collections. Check that changes survive relaunch.
5. Backup/restore: in Settings > Backup & Restore, export a backup of a small test library and restore it. Check progress, favorites, ratings and notes. Restore the same backup again and check for duplicated history. Backups do NOT contain comic files: keep originals and do not delete your real library to test this.
6. iPad only: add a ComicPort Home Screen widget. Try Continue Reading and Daily Goal; check that tapping opens the expected app destination, including after closing the app. There is no Mac widget in this build.
7. Mac only: in Sources & Sync, add a local test folder. Scan/import a comic, quit ComicPort fully, add another comic to that folder in Finder, relaunch and scan again. Does the folder remain listed and accessible without choosing it again? Report permission errors or missed files. Also try Command-O and Finder drag-and-drop import.

Feedback: on iPad, take a screenshot in ComicPort, tap its thumbnail, then Done > Share Beta Feedback (labels may vary by OS); or TestFlight > ComicPort > Send Beta Feedback. On Mac, use TestFlight > ComicPort > Send Beta Feedback, attach a screenshot, or email yigit@yigitsolutions.com. Include device/model, OS, build 2, file format/page, steps, expected result and actual result. Remove private pages or information from screenshots before sending.
```

## 5. Export compliance — App Uses Non-Exempt Encryption / encryption questions

Boolean/choice fields: no character limit. PanelReader/Info.plist already declares ITSAppUsesNonExemptEncryption = false. ASC should not need an additional encryption-documentation prompt when the uploaded binary carries that declaration; it is not a guarantee that no compliance dialog ever appears. Apple allows the plist declaration for no encryption or exempt encryption.[6]

If asked whether the app uses non-exempt encryption:

```text
No
```

If instead asked which encryption algorithms the app implements, choose the option equivalent to "None of the algorithms mentioned above" for this offline app; do not claim custom/proprietary or non-exempt encryption. Answer the actual prompt, not every question with an automatic No. No export documentation is expected for the supplied no-non-exempt-encryption declaration.[6]

## 6. Friend invite message — WhatsApp / Telegram (not an ASC field)

### Friend invite message — draft limit about 600 characters

Draft: 517 characters.

```text
Hey! Want to help me test ComicPort, my offline comic reader?
https://testflight.apple.com/join/jbWWWKy5

You need an iPad on iPadOS 17+ or an Apple Silicon Mac on macOS 14+. Not iPhone, not Intel Mac.

Get Apple's TestFlight app from the App Store on that device, open the link, tap/click Accept, then Install. Bring a CBZ or PDF you can legally use (or ask me for a sample). Try importing, reading and Guided Panel View. Send bugs through TestFlight's Send Beta Feedback, with a screenshot and what you did. Thanks!
```

## 7. Tester FAQ — not ASC fields; no character limits

### I only have an iPhone

```text
ComicPort cannot be installed on iPhone. You'll need an iPad with iPadOS 17+ or an Apple Silicon Mac with macOS 14+. Intel Macs are not supported either.
```

### The link says full

```text
Ask me to check the group's public-link limit and available places. I can raise the limit if there is room, or check an email invite. Email is not a bypass for the app's overall tester cap. Also tell me if TestFlight says no compatible build or the beta has expired.
```

Yigit: check the group insight cards and Public Link > Manage; the public-link cap is separate from the app-wide 10,000 external tester maximum.[2]

### How do I get comics to test?

```text
Ask me for a small legal CBZ or PDF sample, or use a file you own or are authorized to use. Save it in Files on iPad or Finder on Mac, then choose Import in ComicPort (Command-O also works on Mac). The app does not download or supply comics. Don't send commercial comic files or private pages with your bug report.
```

### Does it collect my data?

```text
ComicPort itself does not collect your data and has no accounts, ads, analytics or tracking. Your library stays local. TestFlight is Apple's separate service: Apple collects beta usage/crash information and shares it and your submitted feedback with the developer. A chosen cloud-managed folder may also sync through its storage provider.
```

Apple's TestFlight data practices are separate from ComicPort's no-data-collection answer; public-link testers appear anonymous in ASC, but sessions/crashes are still visible.[2][4]

### How long does the build last?

```text
Each TestFlight build expires after 90 days from upload, not from when you install it. TestFlight shows the days remaining. I can also stop a beta early. Keep your original comics and a backup; you'll need a newer available build when this one expires.
```

The 90-day upload-based window is documented by Apple.[3][4]

## 8. Open items before submitting for Beta App Review

- [ ] Yigit Solutions is hosting the privacy policy: publish the completed draft at public HTTPS; fill <PRIVACY POLICY URL>. Also confirm the policy is easily accessible within the shipped app as required by the guidelines. This pack does not add an in-app link or change source.[7][8]
- [ ] Fill <CONTACT FIRST NAME>, <CONTACT LAST NAME>, <CONTACT PHONE NUMBER> (international format); make sure Apple can reach the contact.
- [ ] Supply and test a legal sample download; fill <SAMPLE COMIC FILE URL> in Review Notes. No sample file has been created or hosted by this task.
- [ ] Confirm the ASC distribution version shown as 1.0 versus the uploaded marketing version 1.0.0 does not block selection/submission. TestFlight has its own platform/version/build selector; do not assume the distribution version label determines beta eligibility. The exact account state and equivalence were not verified; check that 1.0.0 (2) appears and can be added on each platform, and resolve any ASC validation message before submission. No project/version changes are authorized here.[2]

### Evidence and scope notes

The app claims were checked against the requested AppStorePrep drafts, README, all STAGE20 notes, ComicArchiveFormat.swift, ComicPortCommands.swift, LibraryView.swift, ReaderView.swift, GuidedPanelView.swift, LibraryStore.swift source-folder bookmarks, PanelReaderWidgets.swift, Info.plist and project build settings. Older AppStorePrep/README notes are Mac-first and mention paused widgets/old identifiers; this pack uses the current source and supplied shipping context rather than repeating those stale details.

The supplied context identifies uploaded build 2. Checked-in project settings still say CURRENT_PROJECT_VERSION = 1, while MARKETING_VERSION = 1.0.0; the upload's build number was not independently inspected in ASC. No ASC, Apple-account, repository-settings, hosting or source changes were made. Public Apple documentation retrieved for this pack does not publish numeric beta-description/What-to-Test/contact/URL field limits or verify the account-specific 1.0/1.0.0 behaviour. These are explicit checks, not fabricated assurances.

## Sources

[1] https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information
[2] https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers
[3] https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview
[4] https://developer.apple.com/testflight/testers
[5] https://developer.apple.com/help/app-store-connect/reference/app-review-information
[6] https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation
[7] https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
[8] https://developer.apple.com/app-store/review/guidelines
