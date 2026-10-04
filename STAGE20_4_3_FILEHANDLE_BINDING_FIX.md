# ComicPort — Stage 20.4.3 / Mac v1.0.3

Compile hotfix for duplicate detection SHA-256 hashing.

Xcode error:
`Initializer for conditional binding must have Optional type, not 'Data'`

Fix:
Remove the redundant second `let data` binding after `guard let data = try? handle.read(upToCount: ...)`.

SHA-256 behavior is unchanged.
No target, package, framework, scheme, or Xcode project-file changes.
