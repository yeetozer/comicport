# App Store Privacy Answers — Current Technical Draft

Based on the Stage 19.3 source audit:

Suggested App Privacy answer:
- Data Collection: “No, we do not collect data from this app.”

Why:
- No URLSession/network-client code exists in the current app source.
- No account system.
- No analytics SDK.
- No ads SDK.
- No tracking SDK.
- ComicPort Sync writes to a user-selected filesystem folder rather than a
  ComicPort-operated server.

Privacy manifest included in the app target:
- Tracking: false
- Collected data types: none
- UserDefaults: CA92.1
- File timestamps:
  - C617.1 for app-container cache/file metadata
  - 3B52.1 for user-selected Source folder metadata
- Disk space: 85F4.1 because ComicPort visibly shows storage information

Before submission:
1. Archive the app in Xcode.
2. In Organizer, generate the Privacy Report.
3. Compare the aggregate report with these App Store Connect answers.
4. Re-check the bundled libarchive package and any future SDK before answering.

If any future telemetry, crash-reporting, account, cloud API, ad SDK, or analytics
service is added, these answers must be re-evaluated.
