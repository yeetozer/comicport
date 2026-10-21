# ComicPort — Stage 21.0.1 — Profile Switch Fix

Fixes Reader Profile switching on Mac.

## Changes
- Replaces the profile Menu's individual Buttons with a real SwiftUI Picker binding.
- Active profile persists directly from the @Published property.
- Changing profile clears search and returns Dashboard to Home.
- DashboardContent receives a profile-specific identity so SwiftUI cannot reuse
  stale profile content after a switch.
- Library label changes visibly:
  - Comics
  - Manga
  - Books
  - Mix Kitaplık
- The profile button always displays the current selected profile.

No target, framework, package, scheme or Xcode project-file changes.
