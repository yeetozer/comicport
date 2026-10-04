# ComicPort — Stage 20.4.2 / Mac v1.0.2

Compile hotfix for ComicArchiveService.

Xcode error:
`Cannot find 'AE_IFREG' in scope`

Fix:
Replace the unavailable libarchive C macro with the POSIX regular-file type bits
that `archive_entry_set_filetype` expects:

`UInt32(0o100000)`

No archive workflow, target, package, scheme, or Xcode project configuration was
otherwise changed.
