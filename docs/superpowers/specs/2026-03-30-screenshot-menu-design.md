# ScreenshotMenu — Design Spec

## Overview

A macOS menu bar app that provides quick access to screenshot functionality via a status bar icon. Wraps the built-in `screencapture` CLI tool with a simple menu interface.

## Requirements

- macOS 13+ (Ventura)
- Swift, AppKit, no storyboards
- Single-file app, built with Swift Package Manager

## Menu Structure

```
📷 (status bar icon)
├── Window to File
├── Area to File
├── ─────────────
├── Window to Clipboard
├── Area to Clipboard
├── ─────────────
├── ☑ Autolaunch
├── ☑ Open in Preview
├── ─────────────
└── Quit
```

## Screenshot Actions

| Action              | Command                  | Notes                              |
|---------------------|--------------------------|------------------------------------|
| Window to File      | `screencapture -w <path>` | NSSavePanel before capture         |
| Area to File        | `screencapture -s <path>` | NSSavePanel before capture         |
| Window to Clipboard | `screencapture -wc`       | No file dialog needed              |
| Area to Clipboard   | `screencapture -sc`       | No file dialog needed              |

### File Save Behavior

- Show NSSavePanel before capture
- Default filename: `Screenshot YYYY-MM-DD at HH.MM.SS.png`
- Format: PNG only
- Default directory: Desktop (NSSavePanel remembers last used directory)

### Open in Preview

When enabled, after saving a file, open it via `NSWorkspace.shared.open(url)`. This opens in whatever app the user has set as default for PNG files (typically Preview).

## Settings

Stored in UserDefaults.

| Setting         | Key                | Default |
|-----------------|--------------------|---------|
| Autolaunch      | `autolaunch`       | `false` |
| Open in Preview | `openInPreview`    | `false` |

### Autolaunch

Uses `SMAppService.mainApp.register()` / `unregister()` (macOS 13+ ServiceManagement API) to add/remove the app from login items. Menu checkbox reflects current state.

## Architecture

Single Swift file containing:

- `AppDelegate`: Creates `NSStatusItem`, builds `NSMenu`, handles all actions
- Uses `Process` to shell out to `screencapture`
- `NSSavePanel` for file path selection
- `UserDefaults` for settings persistence
- `SMAppService` for login item management

No XIB, no storyboard, no separate view controllers.

## Build & Package

- Swift Package Manager with executable target
- Target: macOS 13+
- Wrap in `.app` bundle for distribution and login item support
- Info.plist with `LSUIElement = true` (no dock icon)

## Out of Scope

- Custom screenshot format selection
- Timed/delayed screenshots
- Screen recording
- Custom overlay UI for area/window selection (handled by `screencapture`)
- Hotkey/shortcut support
