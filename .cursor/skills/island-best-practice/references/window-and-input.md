# Window Management & Input

## Window Management

The notch window is a borderless `NSPanel` (`BoringNotchSkyLightWindow`) with:
- `isOpaque = false`, `backgroundColor = .clear` (required for glass effect)
- `level = .screenSaver` (always on top)
- Positioned at the top-center of the screen, aligned with the hardware notch

## Hover-Out Behavior

All views close when the mouse leaves the notch — no "pinned" views. The `handleHover` handler
calls `self.vm.close()` whenever hover ends, and `close()` resets `currentView` to `.home`.

Guard `handleUpGesture` against expanded views (`.settings`, `.translation`, `.market`, `.widgets`)
to prevent scroll-triggered shrinking within those views.

## Views with Text Input — canBecomeKey

The notch window (`BoringNotchSkyLightWindow`) is an `NSPanel` that defaults to non-key
status. Views that require keyboard input (text fields) must be listed in the
`canBecomeKey` override:

```swift
override var canBecomeKey: Bool {
    let view = BoringViewCoordinator.shared.currentView
    return view == .translation || view == .todoList || view == .inspiration
}
```

When adding a new view with text input:
1. Add the view's `NotchViews` case to the `canBecomeKey` check above.
2. Do NOT use `@FocusState` — the window's `makeKey()` call handles focus.
3. Follow the `TranslationView` pattern for text field implementation.

## Keyboard Shortcuts

Global shortcuts are defined in `ShortcutConstants.swift` using `KeyboardShortcuts.Name`:

| Shortcut | Action |
|----------|--------|
| Fn + Y | Translate selected text |
| Fn + T | Open Todo List |
| Fn + I | Open Inspiration |
| Fn + D | Toggle voice input (dictation) |

Shortcut handlers live in `boringNotchApp.swift` and follow a standard pattern: find the
correct `BoringViewModel` for the current screen, set `coordinator.currentView`, adjust
`vm.notchSize`, and call `vm.open()`.

**Exception: Voice Input (Fn+D)** — Unlike other shortcuts, this does NOT open the notch.
It toggles `SpeechManager.shared.toggleRecording()` directly. The closed notch shows a
`SpeechRecordingIndicator` while recording is active. When recording stops, the
transcribed text is pasted into the previously-focused app via `CGEvent` Cmd+V simulation.

## Voice Input Feature

- **Manager**: `SpeechManager` (`managers/SpeechManager.swift`) — singleton using
  `SFSpeechRecognizer` + `AVAudioEngine` for real-time speech-to-text.
- **Language**: Automatically detected by the system `SFSpeechRecognizer` (no locale needed).
- **Closed Notch UI**: `SpeechRecordingIndicator` (`components/Notch/SpeechRecordingIndicator.swift`)
  — shows a pulsing red dot, mic icon, audio level bars, and duration timer. Follows the
  same left-gap-right pattern as `MusicLiveActivity`.
- **Priority**: Recording indicator appears before music live activity in the closed notch
  content chain, so it takes visual priority while recording.
- **Text Output**: On stop, the final transcription is copied to `NSPasteboard` and pasted
  via `CGEvent` (Cmd+V) into whatever app had focus before recording started. The notch
  window never becomes key during recording.
- **Permissions**: `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`
  are declared in `Info.plist`.
