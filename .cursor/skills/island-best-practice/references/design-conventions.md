# Design Conventions

## Colors

| Context | Value |
|---------|-------|
| Notch background (solid) | `Color.black` |
| Notch background (glass) | `VisualEffectBlur(material: .popover, blendingMode: .behindWindow)` |
| Primary text | `.white` |
| Secondary text | `.gray` or `Color(white: 0.65)` |
| Dimmed text | `Color(white: 0.5)` |
| Accent | `Color.effectiveAccent` (respects system or custom accent) |
| Shadow | `.black.opacity(0.7)`, radius 4–6 |
| Subtle backgrounds | `Color.white.opacity(0.06)` (dark) or `.opacity(0.12)` (glass) |
| Buttons on glass | `Color.white.opacity(0.12)` capsule fill |

The app always uses `.preferredColorScheme(.dark)`. Never add light-mode styling.

## Typography

- Headers: `.system(.headline, design: .rounded)`
- Body: `.system(size: 12–14, weight: .medium)`
- Captions: `.system(size: 10–11)`
- Time/clock displays: `.system(size: ..., design: .rounded)` with `.monospacedDigit()`
- Section headers in settings: `.system(size: 10, weight: .semibold)`, uppercased

## Spacing & Sizing

| Constant | Value |
|----------|-------|
| `openNotchSize` | 660 × 200 |
| `settingsNotchSize` | 660 × 380 |
| Corner radii (open) | top: 19, bottom: 24 |
| Corner radii (closed) | top: 6, bottom: 14 |
| Album art corner radius | opened: 13, closed: 4 |
| Horizontal padding (open) | 12 |
| Content spacing | 0, 4, 6 (tight); 15 (between major sections) |

## Liquid Glass Mode

When `Defaults[.useLiquidGlass]` is true and the notch is **open**:
- Background: `Color.black` opacity animates to 0, then SwiftUI's native `.ultraThinMaterial`
  fades in. Use `Rectangle().fill(.ultraThinMaterial)` — never custom `VisualEffectBlur`.
  The black layer MUST become transparent (`opacity: 0`) for pure glass.
- The notch cutout fill in `BoringHeader` becomes `.clear`.
- Button capsules use `Color.white.opacity(0.12)` instead of `.black`.
- Section backgrounds use `Color.white.opacity(0.12)` instead of `0.06`.

When **closed**, the notch is always solid black regardless of the glass setting.

### Glass-Mode Text & Icon Styling (Apple Design Guidelines)

On translucent glass backgrounds, text and icons need contrast assistance.
Use the shared modifiers in `VisualEffectBlur.swift`:

| Element | Modifier | Effect |
|---------|----------|--------|
| Primary text | `.glassText()` | White + drop shadow `(0.35, r:1, y:0.5)` |
| Secondary text | `.glassSecondaryText()` | White 75% + lighter shadow |
| Icons | `.glassIcon()` | White 90% + shadow |
| Card surface | `.glassSurface()` | `white.opacity(0.1)` fill + subtle top highlight |
| Adaptive | `.adaptiveText(isGlass:)` | Conditional glass/solid styling |

Key principles from Apple HIG for translucent surfaces:
- Always add a subtle drop shadow to text over glass — never rely on color alone.
- Use `foregroundStyle(.white)` not `.primary` on glass — system primary may be too dim.
- Icons should be slightly less opaque (0.9) than text for visual hierarchy.
- Card/section backgrounds on glass should be `white.opacity(0.08–0.12)`.
- Never use `Color.black` backgrounds on elements inside glass — use `Color.clear` or
  very low-opacity white instead.
