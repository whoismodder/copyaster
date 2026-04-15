<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="Copyaster">
</p>

<h1 align="center">Copyaster</h1>

<p align="center">
  <strong>Clipboard manager for macOS. Minimal, fast, always there.</strong>
</p>

<p align="center">
  <a href="https://github.com/whoismodder/copyaster/releases/latest"><img src="https://img.shields.io/github/v/release/whoismodder/copyaster?style=flat-square" alt="Release"></a>
  <a href="https://github.com/whoismodder/copyaster/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-black?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-native-orange?style=flat-square" alt="Swift">
  <a href="https://github.com/whoismodder/copyaster/releases/latest"><img src="https://img.shields.io/github/downloads/whoismodder/copyaster/total?style=flat-square&color=green" alt="Downloads"></a>
</p>

---

## Install

```bash
brew tap whoismodder/copyaster
brew install --cask copyaster
```

Or [download the DMG](https://github.com/whoismodder/copyaster/releases/latest) → drag to Applications.

> If macOS says "damaged": `xattr -cr /Applications/Copyaster.app`

## What it does

Copyaster lives in your menu bar. Every time you copy something, it saves it. You pick what you need, when you need it.

**Two layers:**
- **Recientes** — last 20 clips, auto-managed
- **Guardados** — persistent clips with emoji + title

## Features

- 📋 **Menu bar app** — always one click away
- ⌨️ **⌘⇧V anywhere** — inline selector in any text field
- 🏷️ **Save with emoji + title** — organize what matters
- 🔍 **Search** — find clips instantly
- 📒 **Apple Notes** — send clips to Notes with one click
- 👀 **Hover preview** — see your clipboard without clicking
- 🔒 **Password safe** — never saves passwords or sensitive data
- ⚙️ **Configurable** — change the hotkey, auto-start at login
- 🪶 **1.5MB** — native Swift, no Electron, no bloat

## Shortcuts

| Key | Action |
|-----|--------|
| Click 📋 | Open panel |
| Hover 📋 | Preview current clip |
| ⌘⇧V | Inline selector |
| ↑↓ | Navigate clips |
| ⏎ | Copy to clipboard |
| ⇥ | Switch Recientes / Guardados |
| Esc | Close |
| Right click 📋 | Settings / Quit |

## Build from source

```bash
git clone https://github.com/whoismodder/copyaster.git
cd copyaster
make icons  # generate app icon
make run    # build and open
```

Requires macOS 14+ and Xcode Command Line Tools (`xcode-select --install`).

## Stack

- Swift 5.9 + SwiftUI + AppKit
- Carbon Events for global hotkeys (no accessibility required)
- JSON file storage (~/.local/share/Copyaster/)
- Zero dependencies — only system frameworks

## License

[MIT](LICENSE) — use it however you want.
