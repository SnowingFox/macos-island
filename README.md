<h1 align="center">
  <br>
  Island
  <br>
</h1>

<p align="center">
  <strong>Turn your MacBook's notch into a Dynamic Island</strong>
</p>

<p align="center">
  <a title="Crowdin" target="_blank" href="https://crowdin.com/project/boring-notch"><img src="https://badges.crowdin.net/boring-notch/localized.svg"></a>
  <img src="https://github.com/TheBoredTeam/boring.notch/actions/workflows/cicd.yml/badge.svg" alt="Build & Test" style="margin-right: 10px;" />
  <a href="https://discord.gg/c8JXA7qrPm">
    <img src="https://dcbadge.limes.pink/api/server/https://discord.gg/c8JXA7qrPm?style=flat" alt="Discord" />
  </a>
  <a href="https://www.ko-fi.com/alexander5015">
    <img src="https://srv-cdn.himpfen.io/badges/kofi/kofi-flat.svg" alt="Ko-Fi" />
  </a>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d5f69c1-6e7b-4bc2-a6f1-bb9e27cf88a8" alt="Demo" width="800" />
</p>

---

## What is Island?

**Island** transforms your MacBook's notch from dead space into a living, interactive hub. Inspired by the iPhone's Dynamic Island, it brings music controls, calendar, file shelf, system HUDs, and widgets right to the top of your screen.

- **Hover** to peek at what's playing or your next meeting
- **Click** to expand into a full control center
- **Drop files** to quickly share via AirDrop
- **Control everything** without leaving your current app

---

## Features

### 🎵 Music
- Live activity showing current playback
- Full player with album art, lyrics, and visualizer
- Works with Apple Music, Spotify, YouTube Music, and any app using Now Playing

### 📅 Calendar & Weather
- Time, date, and upcoming events at a glance
- Weather with animated particles
- Reminders integration

### 📦 Shelf
- Drag & drop files for quick access
- One-click AirDrop sharing
- Persistent storage across sessions

### 🎛️ System HUDs
- Replace macOS volume, brightness, and backlight overlays
- Clean, minimal indicators that don't disrupt your workflow

### 🪞 Mirror
- Quick camera preview in the notch
- Perfect for video call check-ins

### ⏱️ Pomodoro
- Built-in focus timer
- Visual progress indicator

### 📈 Market Ticker
- Live crypto, stock, and commodity prices
- Customizable watchlist

### 🌐 Translation
- Instant translation for selected text
- Keyboard shortcut activation

### 🎨 Liquid Glass
- Optional translucent glass background
- Beautiful depth and blur effects when the notch is open

### ✨ Smart States
The notch intelligently shows what matters:
- Music playing? See the live activity
- Battery charging? See the status
- Files dragged nearby? Shelf opens automatically
- Fullscreen video? Notch hides itself

---

## Installation

**Requirements:**
- macOS 14 Sonoma or later
- MacBook with notch (Apple Silicon or Intel)

### Download

<a href="https://github.com/TheBoredTeam/boring.notch/releases/latest/download/boringNotch.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/e3179be1-8416-4b8a-b417-743e1ecc67d6" alt="Download for macOS" /></a>

1. Open the `.dmg` and drag **Island** to your `/Applications` folder
2. Launch the app

> [!IMPORTANT]
> Since we don't have an Apple Developer account yet, macOS will show a security warning on first launch. This is expected.
>
> **To bypass:**
> ```bash
> xattr -dr com.apple.quarantine /Applications/Island.app
> ```

### Homebrew

```bash
brew install --cask TheBoredTeam/boring-notch/boring-notch --no-quarantine
```

---

## Usage

- **Hover** over the notch to expand
- **Click** to toggle open/closed
- **Swipe down** to open (if gestures enabled)
- **Drop files** near the notch to open Shelf
- Use the **menu bar star** to access settings

---

## Roadmap

- [x] Music live activity with lyrics
- [x] Calendar & reminders integration
- [x] Weather widget with particles
- [x] File shelf with AirDrop
- [x] Mirror / camera preview
- [x] Battery & charging indicator
- [x] System HUD replacement (volume, brightness)
- [x] Pomodoro timer
- [x] Market ticker
- [x] Translation
- [x] Liquid glass mode
- [ ] Bluetooth live activity
- [ ] Extension system
- [ ] Lock screen widgets
- [ ] Customizable layouts

---

## Building from Source

**Prerequisites:**
- macOS 14+
- Xcode 16+

```bash
git clone https://github.com/TheBoredTeam/boring.notch.git
cd boring.notch
open boringNotch.xcodeproj
# Then press Cmd+R to build and run
```

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

<a href="https://discord.gg/GvYcYpAKTu" target="_blank"><img src="https://iili.io/28m3GHv.png" alt="Join our Discord" style="height: 60px; width: 217px;" ></a>

---

## Star History

<a href="https://www.star-history.com/#TheBoredTeam/boring.notch&Timeline">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=TheBoredTeam/boring.notch&type=Timeline&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=TheBoredTeam/boring.notch&type=Timeline" />
   <img alt="Star History" src="https://api.star-history.com/svg?repos=TheBoredTeam/boring.notch&type=Timeline" />
 </picture>
</a>

---

## Support

<a href="https://www.ko-fi.com/alexander5015" target="_blank"><img src="https://github.com/user-attachments/assets//a76175ef-7e93-475a-8b67-4922ba5964c2" alt="Support us on Ko-fi" style="height: 70px; width: 346px;" ></a>

---

## Acknowledgments

- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** — Now Playing support for macOS 15.4+
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** — Inspiration for the Shelf feature
- **Icon:** [@maxtron95](https://github.com/maxtron95)
- **Website:** [@himanshhhhuv](https://github.com/himanshhhhuv)

See [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md) for full license details.

---

<p align="center">
  <strong>Island</strong> — Your notch, reimagined.
</p>
