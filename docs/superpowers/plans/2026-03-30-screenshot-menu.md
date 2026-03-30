# ScreenshotMenu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that wraps `screencapture` CLI with a simple dropdown menu for taking screenshots.

**Architecture:** Single Swift file AppKit app with no storyboards. NSStatusItem with a menu that calls `screencapture` via Process. NSSavePanel for file destinations, UserDefaults for settings, SMAppService for login items.

**Tech Stack:** Swift, AppKit, Swift Package Manager, macOS 13+

---

## File Structure

| File | Responsibility |
|------|---------------|
| `Package.swift` | SPM manifest, macOS 13+ executable target |
| `Sources/ScreenshotMenu/main.swift` | Entry point — creates NSApplication and AppDelegate |
| `Sources/ScreenshotMenu/AppDelegate.swift` | All app logic: status item, menu, screenshot actions, settings |
| `Info.plist` | LSUIElement=true (no dock icon) |
| `Makefile` | Build, bundle into .app, run |

---

### Task 1: Project Scaffold

**Files:**
- Create: `Package.swift`
- Create: `Sources/ScreenshotMenu/main.swift`
- Create: `Sources/ScreenshotMenu/AppDelegate.swift`

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenshotMenu",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ScreenshotMenu",
            path: "Sources/ScreenshotMenu"
        )
    ]
)
```

- [ ] **Step 2: Create main.swift**

```swift
import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 3: Create AppDelegate.swift with empty shell**

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "📷"
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `cd /Users/ex/ScreenshotMenu && swift build 2>&1`
Expected: Build succeeds. Running the app should show 📷 in the menu bar.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/
git commit -m "feat: scaffold SPM project with status bar icon"
```

---

### Task 2: Build the Menu

**Files:**
- Modify: `Sources/ScreenshotMenu/AppDelegate.swift`

- [ ] **Step 1: Add menu construction to AppDelegate**

Replace AppDelegate.swift with:

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "📷"

        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Window to File", action: #selector(windowToFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Area to File", action: #selector(areaToFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Window to Clipboard", action: #selector(windowToClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Area to Clipboard", action: #selector(areaToClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let autolaunchItem = NSMenuItem(title: "Autolaunch", action: #selector(toggleAutolaunch(_:)), keyEquivalent: "")
        autolaunchItem.state = UserDefaults.standard.bool(forKey: "autolaunch") ? .on : .off
        menu.addItem(autolaunchItem)

        let previewItem = NSMenuItem(title: "Open in Preview", action: #selector(toggleOpenInPreview(_:)), keyEquivalent: "")
        previewItem.state = UserDefaults.standard.bool(forKey: "openInPreview") ? .on : .off
        menu.addItem(previewItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Screenshot Actions

    @objc func windowToFile() {}
    @objc func areaToFile() {}
    @objc func windowToClipboard() {}
    @objc func areaToClipboard() {}

    // MARK: - Settings

    @objc func toggleAutolaunch(_ sender: NSMenuItem) {}
    @objc func toggleOpenInPreview(_ sender: NSMenuItem) {}
}
```

- [ ] **Step 2: Build and verify**

Run: `cd /Users/ex/ScreenshotMenu && swift build 2>&1`
Expected: Build succeeds. Running shows 📷 menu with all items, Quit works.

- [ ] **Step 3: Commit**

```bash
git add Sources/
git commit -m "feat: add full menu structure with placeholder actions"
```

---

### Task 3: Implement Clipboard Screenshot Actions

**Files:**
- Modify: `Sources/ScreenshotMenu/AppDelegate.swift`

- [ ] **Step 1: Add screencapture helper method**

Add to AppDelegate, after the settings section:

```swift
// MARK: - Screencapture

private func runScreencapture(_ arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    process.arguments = arguments
    try? process.run()
}
```

- [ ] **Step 2: Implement clipboard actions**

Replace the empty clipboard methods:

```swift
@objc func windowToClipboard() {
    runScreencapture(["-wc"])
}

@objc func areaToClipboard() {
    runScreencapture(["-sc"])
}
```

- [ ] **Step 3: Build and verify manually**

Run: `cd /Users/ex/ScreenshotMenu && swift build 2>&1`
Expected: Build succeeds. "Window to Clipboard" shows crosshair, captures window to clipboard. "Area to Clipboard" lets you drag an area, captures to clipboard.

- [ ] **Step 4: Commit**

```bash
git add Sources/
git commit -m "feat: implement clipboard screenshot actions"
```

---

### Task 4: Implement File Screenshot Actions with NSSavePanel

**Files:**
- Modify: `Sources/ScreenshotMenu/AppDelegate.swift`

- [ ] **Step 1: Add save panel helper**

Add to AppDelegate:

```swift
private func defaultFilename() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
    return "Screenshot \(formatter.string(from: Date())).png"
}

private func showSavePanelAndCapture(arguments: [String]) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = defaultFilename()
    panel.allowedContentTypes = [.png]

    guard panel.runModal() == .OK, let url = panel.url else { return }

    runScreencapture(arguments + [url.path])

    if UserDefaults.standard.bool(forKey: "openInPreview") {
        // Small delay to let screencapture finish writing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSWorkspace.shared.open(url)
        }
    }
}
```

- [ ] **Step 2: Implement file actions**

Replace the empty file methods:

```swift
@objc func windowToFile() {
    showSavePanelAndCapture(arguments: ["-w"])
}

@objc func areaToFile() {
    showSavePanelAndCapture(arguments: ["-s"])
}
```

- [ ] **Step 3: Build and verify manually**

Run: `cd /Users/ex/ScreenshotMenu && swift build 2>&1`
Expected: Build succeeds. "Window to File" shows save dialog, then crosshair, saves PNG. "Area to File" shows save dialog, then lets you drag area, saves PNG.

- [ ] **Step 4: Commit**

```bash
git add Sources/
git commit -m "feat: implement file screenshot actions with save dialog"
```

---

### Task 5: Implement Settings Toggles

**Files:**
- Modify: `Sources/ScreenshotMenu/AppDelegate.swift`

- [ ] **Step 1: Implement toggle methods**

Replace the empty settings methods:

```swift
@objc func toggleAutolaunch(_ sender: NSMenuItem) {
    let newValue = sender.state != .on
    UserDefaults.standard.set(newValue, forKey: "autolaunch")
    sender.state = newValue ? .on : .off

    if newValue {
        try? SMAppService.mainApp.register()
    } else {
        try? SMAppService.mainApp.unregister()
    }
}

@objc func toggleOpenInPreview(_ sender: NSMenuItem) {
    let newValue = sender.state != .on
    UserDefaults.standard.set(newValue, forKey: "openInPreview")
    sender.state = newValue ? .on : .off
}
```

- [ ] **Step 2: Add ServiceManagement import**

At the top of AppDelegate.swift, add:

```swift
import ServiceManagement
```

- [ ] **Step 3: Build and verify**

Run: `cd /Users/ex/ScreenshotMenu && swift build 2>&1`
Expected: Build succeeds. Checkboxes toggle on/off, persist across restarts.

- [ ] **Step 4: Commit**

```bash
git add Sources/
git commit -m "feat: implement autolaunch and open-in-preview settings"
```

---

### Task 6: App Bundle and Info.plist

**Files:**
- Create: `Info.plist`
- Create: `Makefile`

- [ ] **Step 1: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.local.ScreenshotMenu</string>
    <key>CFBundleName</key>
    <string>ScreenshotMenu</string>
    <key>CFBundleExecutable</key>
    <string>ScreenshotMenu</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
```

- [ ] **Step 2: Create Makefile**

```makefile
APP_NAME = ScreenshotMenu
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app

.PHONY: build bundle run clean

build:
	swift build -c release

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/

run: bundle
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)

install: bundle
	cp -r $(APP_BUNDLE) /Applications/
```

- [ ] **Step 3: Build bundle and verify**

Run: `cd /Users/ex/ScreenshotMenu && make bundle 2>&1`
Expected: `ScreenshotMenu.app` created. `open ScreenshotMenu.app` launches the app, shows 📷 in menu bar, no dock icon.

- [ ] **Step 4: Commit**

```bash
git add Info.plist Makefile
git commit -m "feat: add Info.plist and Makefile for app bundle"
```

---

### Task 7: Final Verification

- [ ] **Step 1: Clean build and bundle**

Run: `cd /Users/ex/ScreenshotMenu && make clean && make bundle 2>&1`
Expected: Clean build succeeds, app bundle created.

- [ ] **Step 2: Manual test all features**

Run: `open ScreenshotMenu.app`

Test checklist:
- 📷 appears in menu bar, no dock icon
- "Window to File" — shows save dialog, then window selector, saves PNG
- "Area to File" — shows save dialog, then area selector, saves PNG
- "Window to Clipboard" — captures window to clipboard
- "Area to Clipboard" — captures area to clipboard
- "Autolaunch" checkbox toggles and persists
- "Open in Preview" checkbox toggles; when on, file screenshots open after save
- "Quit" exits the app

- [ ] **Step 3: Install to Applications (optional)**

Run: `make install`
Expected: App copied to /Applications/

- [ ] **Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "fix: address issues found during final verification"
```
