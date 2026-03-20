# Widget System

Widgets (market, calendar, pomodoro, music) are managed via `WidgetHubView`, accessible from the
"Widgets" tab in `TabSelectionView`. Each widget has an enable toggle and a "show in closed notch"
option.

## Home View Layout

Canonical open size is **`openNotchSize`** in `sizing/matters.swift` (currently **660×200**) — see also repo root **`ARCHITECTURE.md` §9**.

`NotchHomeView` is structured for a **two-row** home layout, but as of current source the **`body` only composes `primaryRow`** (music + optional camera or calendar). A **`secondaryWidgetRow`** property exists (market / pomodoro compact widgets from `Defaults[.homeWidgets]`) but is **not yet inserted** into the view hierarchy; wiring it in would likely require revisiting `openNotchSize` height and layout spacing.

Intended layout when both rows are active:
- **Top row**: Music player (full width, with optional camera).
- **Bottom row**: Horizontal widget row, driven by `Defaults[.homeWidgets]` — an ordered array of `HomeWidget` (`.calendar`, `.market`, `.pomodoro`). Only enabled widgets render; each uses `.frame(maxWidth: .infinity)`. No scroll.

Key rules:
- Music stays on top — never moves, never reorderable in the home widget order.
- New home widgets must be added to the `HomeWidget` enum.
- Each widget should be a compact, self-contained view with card backgrounds.

## Closed Notch Widgets — Forbidden Zone Architecture

The hardware notch cutout is a **forbidden zone** — no widget content may be placed there.
All closed notch widget indicators follow the same compact pattern: `icon + data`, using
`.fixedSize()` and `.lineLimit(1)` to prevent overflow.

### Layout: No Music Playing

`ClosedNotchWidgetBar` flanks the notch cutout (like `MusicLiveActivity`):
- If 1 widget: displayed on the **left** side, right-aligned toward the cutout.
- If 2 widgets: one on **left**, one on **right**, flanking the cutout.
- A black `Rectangle` fills the cutout gap (`closedNotchSize.width - cornerRadius`).
- Each side has 10pt inner padding from the cutout edge.

### Layout: Music Playing

`ClosedNotchMusicWidgets` appends widget pills to the **right** of the music spectrum,
with 8pt leading padding. `computedChinWidth` adds 120px extra for these.

### Sizing Safety

`computedChinWidth` is clamped to `windowSize.width - 20` to prevent overflow on small
screens. Each widget indicator uses `.fixedSize()` to render at natural width and prices
use `compactPrice` (e.g. `$67K` instead of `$67025`) when values are large.

Do NOT use separate "satellite pill" overlays — all widgets live within the notch shape.

## Expanding View (Sneak Peek)

When transient notifications expand the closed notch (e.g. pomodoro completion, battery):
- Content is split as: left text | center notch gap | right text.
- The center gap matches `vm.closedNotchSize.width + 10`.
- Use `.frame(maxWidth: .infinity)` on both sides with `.trailing` / `.leading` alignment
  and inner padding (8pt) to prevent text from being hidden behind the notch cutout.
- The `computedChinWidth` must be set wide enough (e.g. 400 for pomodoro) in `ContentView`.

## Todo List Widget

- **Manager**: `TodoListManager` (`managers/TodoListManager.swift`) — singleton, persists
  items via `Defaults[.todoItems]`.
- **Model**: `TodoItem` struct (Codable, Identifiable, Defaults.Serializable) with `id`,
  `text`, `isCompleted`, `createdAt`, `dueDate` (optional).
- **View**: `TodoListView` (`components/Notch/TodoListView.swift`) — date-grouped scrollable
  list. Items are grouped by date with section headers. Overdue incomplete items from
  previous days are shown at the top with an "Overdue" banner. Input bar with `TextField`.
- **Shortcut**: Fn + T (defined as `.openTodoList` in `ShortcutConstants.swift`).
- **WidgetHub**: Listed under "Productivity" in `WidgetHubView` with detail page
  `WidgetDetailTodoList`.

## Inspiration Widget

- **Manager**: `InspirationManager` (`managers/InspirationManager.swift`) — singleton,
  persists items via `Defaults[.inspirationItems]`.
- **Model**: `InspirationItem` struct (Codable, Identifiable, Defaults.Serializable) with
  `id`, `text`, `createdAt`.
- **View**: `InspirationView` (`components/Notch/InspirationView.swift`) — chat-style UI
  with header (back, copy all, trash), scrollable message bubbles with timestamps and
  per-item copy/delete, input bar at bottom. Auto-scrolls to newest entry.
- **Shortcut**: Fn + I (defined as `.openInspiration` in `ShortcutConstants.swift`).
- **WidgetHub**: Listed under "Productivity" in `WidgetHubView` with detail page
  `WidgetDetailInspiration`.
