# Xcode Project Change Note

Stage 19.3 intentionally changes `project.pbxproj` for one reason only:
to include `PanelReader/PrivacyInfo.xcprivacy` in the main application's Resources
build phase.

Before SHA-256:
`24ef18eac0984be355de38ed7564cec3a9eba65780a43f9c5e8741a08efb8a5e`

After SHA-256:
`0e48a9e98834b42f89cf75f3e834659e527bd042e1e619bea0d92c34a6ddda9b`

No target, scheme, package dependency, bundle identifier, widget target, framework
linkage, or platform configuration was changed in this stage.
