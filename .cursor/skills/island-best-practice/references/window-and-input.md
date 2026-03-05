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

Shortcut handlers live in `boringNotchApp.swift` and follow a standard pattern: find the
correct `BoringViewModel` for the current screen, set `coordinator.currentView`, adjust
`vm.notchSize`, and call `vm.open()`.
