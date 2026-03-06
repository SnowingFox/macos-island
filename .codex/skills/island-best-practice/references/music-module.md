# Music Module

## Waveform (Spectrum) Coloring — MANDATORY

The audio spectrum visualizer in the closed notch **MUST always** follow the album art's
dominant color. This is non-negotiable and must never be gated behind a user setting.

Rules:
- `MusicManager.calculateAverageColor()` must always be called inside `updateAlbumArt()` —
  never wrap it in a conditional (no `if Defaults[...]` guards).
- `MusicManager.avgColor` is the single source of truth for the album-derived color.
- The spectrum fill in `ClosedNotchContent.MusicLiveActivity` must always use
  `Color(nsColor: musicManager.avgColor).gradient` — never `.gray`, `.white`, or any
  hardcoded color.
- Song title and artist name text in the closed notch must also use
  `Color(nsColor: musicManager.avgColor)` — not `.gray`.
- The `coloredSpectrogram` setting key exists in `Constants.swift` but is **dead code** —
  it must NOT be checked anywhere in the rendering path. Do not re-introduce conditionals
  around spectrum coloring.
- If you modify `ClosedNotchContent`, `MusicLiveActivity`, or `MusicManager`, verify that
  `avgColor` is still unconditionally computed and used.

## Waveform Animation — CANONICAL (Do Not Change)

The `AudioSpectrum` in `MusicVisualizer.swift` is the original animation from the project's
initial commit and MUST NOT be modified. It uses `Timer` + `CABasicAnimation` with
`autoreverses` for a bouncing effect:

**Exact parameters (do not alter):**
- `barCount = 4`, `barWidth = 2`, `spacing = barWidth` (2pt), `totalHeight = 14`
- Timer interval: `0.3` seconds
- Random target scale: `CGFloat.random(in: 0.35 ... 1.0)`
- `CABasicAnimation(keyPath: "transform.scale.y")`
  - `duration = 0.3`
  - `autoreverses = true`
  - `fillMode = .forwards`, `isRemovedOnCompletion = false`
  - `preferredFrameRateRange = (minimum: 24, maximum: 24, preferred: 24)`
- On pause: `removeAllAnimations()` + reset to `CATransform3DMakeScale(1, 0.35, 1)`
- `setPlaying(true)` starts the timer, `setPlaying(false)` stops + resets

**Forbidden changes:**
- Do NOT replace with sine waves, display links, CADisplayLink, or vDSP/FFT audio capture.
- Do NOT change the timer interval, scale range, duration, or autoreverses behavior.
- Do NOT add smooth interpolation or easing beyond what `autoreverses` provides.
- This is the intended design — simple, lightweight, and correct.

## Music Sneak Peek

Music sneak peek / expanding view on song change is disabled. The `updateSneakPeek()` in
`MusicManager` is intentionally empty. Other sneak peek types (volume, brightness, battery,
pomodoro) remain active.
