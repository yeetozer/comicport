# App Review Notes — Draft

ComicPort is a local file reader for user-supplied comic files.

Important review context:
- The app does not sell, stream, download, or provide copyrighted comic books.
- Reviewers can use their own PDF/CBZ/CBR/7z sample files through Import.
- All reading-library features work without a ComicPort account.
- The app has no advertising SDK and no ComicPort analytics backend.
- OCR and library analysis are designed to run locally.
- Apple system Translation is optional and depends on OS/framework availability and
  any language resources installed by the operating system.
- Source folders are user-selected local folders.
- Sync Folder is optional and writes lightweight reading-state metadata to a folder
  selected by the user; it does not upload comic files to a ComicPort service.
- Mac WidgetKit is intentionally not included in this release.

Suggested reviewer path:
1. Launch ComicPort.
2. Use Command-O or Import to add a sample PDF/CBZ.
3. Open the book and test page navigation / reader settings.
4. Open Smart Collections.
5. Open Sources & Sync if desired.
6. Settings → Diagnostics & Release Health provides local diagnostics.

Content-rights note:
ComicPort displays files selected by the user and does not bundle commercial comic
pages for reading. Any sample media used in App Store screenshots should be original,
licensed, or public-domain content.

Before submission:
- Replace any placeholder support contact details.
- Confirm the final production bundle identifier.
