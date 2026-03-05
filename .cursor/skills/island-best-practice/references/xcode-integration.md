# Xcode Project Integration

Most files require **manual addition** to `project.pbxproj`. Only `private/` and
`BoringNotchXPCHelper/` use `fileSystemSynchronizedGroups`.

## Adding a New Swift File

1. Create the file in the correct directory.
2. Add a `PBXFileReference` entry (generate a unique ID like `AA00000100000007AABB0077`).
3. Add a `PBXBuildFile` entry pointing to the file reference.
4. Add the file reference to the parent `PBXGroup`'s `children` array.
5. Add the build file to the main target's `PBXSourcesBuildPhase` `files` array.

## Key Group IDs

(grep the pbxproj to confirm these haven't shifted):
- `managers`: `147163B52C5D804B0068B555`
- `Notch` (components): `B186542F2C6F455E000B926A`
- `extensions`: `B15063502C63D3F600EBB0E3`
- `Calendar` (components): contains `BoringCalendar.swift`

## Dependencies

| Package | Purpose |
|---------|---------|
| Defaults | Typed user preferences with SwiftUI bindings |
| KeyboardShortcuts | Global keyboard shortcut registration |
| LaunchAtLogin | Login item management |
| Sparkle | Auto-update framework |
| Lottie | Rich animations |
| SwiftUIIntrospect | Access underlying AppKit views |
| Pow | Additional animation effects |
