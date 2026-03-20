---
name: island-best-practice
description: >
  Conventions, architecture, and design patterns for the boring.notch macOS Dynamic Island app.
  Use this skill whenever working on any feature, bugfix, or refactor in boring.notch — including
  adding new views, managers, settings, animations, or modifying the notch layout. Also consult
  this when the user asks about how the project works, how to add a new module, or when you need
  to understand the codebase structure before making changes.
---

# boring.notch Best Practices

boring.notch is a macOS app that replaces the MacBook's notch with a dynamic, interactive widget.
It displays music playback, notifications, system HUDs, calendar/weather, a file shelf, and more.

**Repository technical architecture (Chinese, contributor-oriented):** root [`ARCHITECTURE.md`](../../../ARCHITECTURE.md) — state layers, windowing, sizing, Liquid Glass summary, gestures, shortcuts/speech, and pointers into this skill’s `references/`. **Build, signing, notarization, CI, and Island vs. `boringNotch` naming:** [`BUILD.md`](../../../BUILD.md).

## References

Detailed module-specific docs live in `references/`. Consult them when working in the
relevant area:

| Reference | When to read |
|-----------|-------------|
| `references/design-conventions.md` | Colors, typography, spacing, liquid glass mode, glass text modifiers |
| `references/animation-patterns.md` | Spring values, matchedGeometryEffect IDs, transitions, gestures |
| `references/music-module.md` | Waveform coloring rules, canonical animation params, sneak peek |
| `references/widget-system.md` | Home layout, closed notch widgets, forbidden zone, todo/inspiration widgets |
| `references/window-and-input.md` | NSPanel config, hover-out, canBecomeKey, keyboard shortcuts |
| `references/xcode-integration.md` | Adding files to project.pbxproj, group IDs, dependencies |

## Project Structure

```
boringNotch/
├── boringNotchApp.swift          # App entry, window creation, lifecycle
├── ContentView.swift             # Root view — notch shape, background, gestures, state routing
├── components/
│   ├── Notch/                    # Core notch UI (BoringHeader, NotchHomeView, NotchSettingsView, etc.)
│   ├── Calendar/                 # Calendar + weather widgets
│   ├── Shelf/                    # Drag & drop file shelf
│   ├── Settings/                 # External settings window
│   ├── Live activities/          # Download progress, HUD indicators
│   ├── Music/                    # Lyrics, visualizer, slider
│   ├── Tabs/                     # Tab bar (home/shelf/widgets)
│   ├── Webcam/                   # Camera preview
│   └── Onboarding/               # First-launch flow
├── managers/                     # Singleton ObservableObject managers
├── models/                       # BoringViewModel, Constants, data models
├── extensions/                   # SwiftUI View extensions, helpers
├── helpers/                      # Utility classes (AppleScript, AppIcons, etc.)
├── observers/                    # System event observers (media keys, fullscreen, drag)
├── sizing/                       # Notch dimensions and corner radii
├── enums/                        # App-wide enums
├── animations/                   # Animation definitions
├── private/                      # CGSSpace (auto-synced in Xcode)
├── metal/                        # Metal shaders (audio visualizer)
├── menu/                         # Status bar menu
├── Shortcuts/                    # KeyboardShortcuts definitions (e.g. ShortcutConstants.swift)
└── utils/                        # Logging
```

## Architecture

### State Management — Three Layers

1. **`BoringViewModel`** — Per-screen notch state. Owns `notchState` (.open/.closed),
   `notchSize`, and transient UI state (hover, drop targeting, camera). Passed via
   `@EnvironmentObject` to all views.

2. **`BoringViewCoordinator`** — Global singleton (`BoringViewCoordinator.shared`). Controls
   which view is displayed (`currentView: NotchViews`), sneak peek / expanding view state,
   first-launch flow, and screen selection. Accessed via `@ObservedObject` in views.

3. **`Defaults` (sindresorhus/Defaults)** — Persisted user preferences. All keys live in
   `Constants.swift` under `extension Defaults.Keys`. Use `@Default(.keyName)` for reactive
   bindings in views, `Defaults[.keyName]` for read-only access.

### Adding a New Setting

1. Add the key to `Constants.swift`:
   ```swift
   static let myFeature = Key<Bool>("myFeature", default: false)
   ```
2. Use `@Default(.myFeature) var myFeature` in views that react to changes.
3. Add a toggle in `NotchSettingsView` (in-notch) and/or `SettingsView` (external window).

### Manager / Singleton Pattern

Every system-level service follows this pattern:

```swift
@MainActor
class FooManager: NSObject, ObservableObject {
    static let shared = FooManager()
    
    @Published var someState: Type = defaultValue
    
    private override init() {
        super.init()
        // setup observers, timers, etc.
    }
    
    func startMonitoring() { ... }
    func stopMonitoring() { ... }
}
```

Key rules:
- Always `@MainActor` if the manager drives UI via `@Published`.
- Use `static let shared` — never create multiple instances.
- Access in views with `@ObservedObject var foo = FooManager.shared`.
- Prefer `NSObject` base class when interfacing with system APIs (CoreAudio, CoreLocation, etc.).

### View Composition

ContentView is the root. It builds the notch layout in layers:

```
ContentView (body)
└── ZStack → VStack
    ├── NotchLayout()                    # Content inside the notch shape
    │   ├── [closed] state-specific views (music live activity, battery, HUD, notification, face)
    │   ├── [open] BoringHeader          # Top bar with tabs, notch cutout, action buttons
    │   ├── [closed] ClosedNotchWidgetBar  # Configurable widget indicators (market, pomodoro)
    │   └── [open] switch currentView:
    │       ├── .home       → NotchHomeView     # Music player + calendar/weather + pomodoro
    │       ├── .shelf      → ShelfView         # File shelf
    │       ├── .settings   → NotchSettingsView
    │       ├── .widgets    → WidgetHubView     # Widget management
    │       ├── .market     → MarketTickerView  # Crypto/stock/gold prices
    │       ├── .translation → TranslationView
    │       ├── .todoList   → TodoListView      # Quick todo list (fn+T)
    │       └── .inspiration → InspirationView  # Inspiration recorder (fn+I)
    └── Chin rectangle (click target below notch)
```

When adding a new top-level view to the notch:
1. Add a case to `NotchViews` enum in `enums/generic.swift`.
2. Add the `case` to the `switch coordinator.currentView` in `ContentView.NotchLayout()`.
3. If the view needs a different notch size, update `vm.notchSize` when switching to it.
4. If it needs keyboard input, see `references/window-and-input.md` for canBecomeKey setup.

## Enum Conventions

- Simple state enums: bare cases (`NotchState`, `NotchViews`, `Style`)
- User-facing enums with persistence: `String` raw values + `Defaults.Serializable`
- Add `CaseIterable, Identifiable` when used in pickers
- Associated values for complex state: `CalendarSelectionState`, `EventType`

## Common Patterns

### Conditional Modifiers
```swift
.conditionalModifier(someCondition) { view in
    view.someModifier()
}
```
Defined in `ConditionalModifier.swift`. Use instead of ternary-in-modifier for complex logic.

### Sneak Peek / Expanding View
Transient HUDs (volume, brightness, notifications) use `coordinator.toggleSneakPeek()`.
This shows a brief overlay in the closed notch, then auto-dismisses after a timeout.

## Checklist for New Features

1. Create the manager (if needed) in `managers/` following the singleton pattern.
2. Add settings keys to `Constants.swift`.
3. Create views in the appropriate `components/` subdirectory.
4. Wire into `ContentView` — either in `NotchLayout()` for closed-state displays, or in
   the `switch coordinator.currentView` for open-state views.
5. Add `project.pbxproj` entries for all new files (see `references/xcode-integration.md`).
6. Add toggles to `NotchSettingsView` and/or `SettingsView`.
7. Use existing animation values (see `references/animation-patterns.md`) — don't invent new springs.
8. Test both open and closed notch states, and with liquid glass on/off.
9. If the new view is full-height (like settings), add it to `scrollLocked` set in
   `handleUpGesture` and to the `needsTall` check in `onChange(of: currentView)`.
10. For widgets: add to `WidgetHubView` with enable toggle. Add a `HomeWidget` case
    for home view placement. Add to `homeWidgets` default order in `HomeWidget.defaultOrder`.
