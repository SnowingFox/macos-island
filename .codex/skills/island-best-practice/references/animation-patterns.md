# Animation Patterns

## Springs — Use These Specific Values

| Purpose | Animation |
|---------|-----------|
| Open/close notch, hover, gestures | `.interactiveSpring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)` |
| Notch opening | `.spring(response: 0.42, dampingFraction: 0.8)` |
| Notch closing | `.spring(response: 0.45, dampingFraction: 1.0)` |
| View switching, settings | `.spring(response: 0.35, dampingFraction: 0.8)` |
| Drop animation | `.spring(.bouncy(duration: 0.4))` |
| Smooth transitions | `.smooth` or `.smooth(duration: 0.35)` |

## matchedGeometryEffect

Used for smooth transitions between closed and open states:
- `"albumArt"` — album art image morphs from small (closed) to large (open)
- `"spectrum"` — audio visualizer
- `"capsule"` — tab selection indicator

## Transitions

```swift
// Standard content transition
.transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))

// Notification appearance
.transition(.opacity.combined(with: .scale(scale: 0.95)))

// Settings slide-in
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .trailing).combined(with: .opacity)
))
```

## Gesture Handling

Gestures use `.panGesture(direction:)` (custom extension) with `gestureProgress` state.
The progress drives a `scaleEffect` on the entire notch. On completion, animate progress
back to zero with the interaction spring.
