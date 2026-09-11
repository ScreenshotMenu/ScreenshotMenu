import Cocoa
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var lastScreenshotURL: URL?
    private var lastScreenshotItem: NSMenuItem!
    private var previewItem: NSMenuItem!
    private var finderItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Screenshot Menu") {
            let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            let sized = image.withSymbolConfiguration(config)!
            sized.isTemplate = true
            statusItem.button?.image = sized
        }

        let menu = NSMenu()

        // Capture to File
        menu.addItem(NSMenuItem(title: "Fullscreen to File", action: #selector(fullscreenToFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Window to File", action: #selector(windowToFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Area to File", action: #selector(areaToFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Capture to Clipboard
        menu.addItem(NSMenuItem(title: "Fullscreen to Clipboard", action: #selector(fullscreenToClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Window to Clipboard", action: #selector(windowToClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Area to Clipboard", action: #selector(areaToClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Timed
        menu.addItem(NSMenuItem(title: "Timed Fullscreen (5s)", action: #selector(timedFullscreen), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Timed Window (5s)", action: #selector(timedWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Timed Area (5s)", action: #selector(timedArea), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Last screenshot
        lastScreenshotItem = NSMenuItem(title: "Open Last Screenshot", action: #selector(openLastScreenshot), keyEquivalent: "")
        lastScreenshotItem.isEnabled = false
        menu.addItem(lastScreenshotItem)
        menu.addItem(NSMenuItem.separator())

        // Settings
        let silentItem = NSMenuItem(title: "Silent Mode", action: #selector(toggleSilent(_:)), keyEquivalent: "")
        silentItem.state = UserDefaults.standard.bool(forKey: "silent") ? .on : .off
        menu.addItem(silentItem)

        let autolaunchItem = NSMenuItem(title: "Autolaunch", action: #selector(toggleAutolaunch(_:)), keyEquivalent: "")
        autolaunchItem.state = UserDefaults.standard.bool(forKey: "autolaunch") ? .on : .off
        menu.addItem(autolaunchItem)

        previewItem = NSMenuItem(title: "Open in Preview", action: #selector(selectOpenInPreview(_:)), keyEquivalent: "")
        previewItem.state = UserDefaults.standard.string(forKey: "afterSave") == "preview" ? .on : .off
        menu.addItem(previewItem)

        finderItem = NSMenuItem(title: "Show in Finder", action: #selector(selectShowInFinder(_:)), keyEquivalent: "")
        finderItem.state = UserDefaults.standard.string(forKey: "afterSave") == "finder" ? .on : .off
        menu.addItem(finderItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Screenshot Actions (File)

    @objc func fullscreenToFile() {
        captureToFileAndSave(arguments: [])
    }

    @objc func windowToFile() {
        captureToFileAndSave(arguments: ["-w"])
    }

    @objc func areaToFile() {
        captureToFileAndSave(arguments: ["-s"])
    }

    // MARK: - Screenshot Actions (Clipboard)

    @objc func fullscreenToClipboard() {
        captureToClipboard(arguments: ["-c"])
    }

    @objc func windowToClipboard() {
        captureToClipboard(arguments: ["-wc"])
    }

    @objc func areaToClipboard() {
        captureToClipboard(arguments: ["-sc"])
    }

    // MARK: - Timed Screenshots

    @objc func timedFullscreen() {
        captureToFileAndSave(arguments: ["-T", "5"])
    }

    @objc func timedWindow() {
        captureToFileAndSave(arguments: ["-T", "5", "-w"])
    }

    @objc func timedArea() {
        captureToFileAndSave(arguments: ["-T", "5", "-s"])
    }

    // MARK: - Last Screenshot

    @objc func openLastScreenshot() {
        guard let url = lastScreenshotURL, FileManager.default.fileExists(atPath: url.path) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Settings

    @objc func toggleSilent(_ sender: NSMenuItem) {
        let newValue = sender.state != .on
        UserDefaults.standard.set(newValue, forKey: "silent")
        sender.state = newValue ? .on : .off
    }

    @objc func toggleAutolaunch(_ sender: NSMenuItem) {
        let newValue = sender.state != .on
        UserDefaults.standard.set(newValue, forKey: "autolaunch")
        sender.state = newValue ? .on : .off

        let plistPath = NSHomeDirectory() + "/Library/LaunchAgents/com.local.ScreenshotMenu.plist"
        if newValue {
            let appPath = Bundle.main.bundlePath
            let plist: [String: Any] = [
                "Label": "com.local.ScreenshotMenu",
                "ProgramArguments": [appPath + "/Contents/MacOS/ScreenshotMenu"],
                "RunAtLoad": true
            ]
            (plist as NSDictionary).write(toFile: plistPath, atomically: true)
        } else {
            try? FileManager.default.removeItem(atPath: plistPath)
        }
    }

    @objc func selectOpenInPreview(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.string(forKey: "afterSave")
        let newValue = current == "preview" ? "" : "preview"
        UserDefaults.standard.set(newValue, forKey: "afterSave")
        previewItem.state = newValue == "preview" ? .on : .off
        finderItem.state = .off
    }

    @objc func selectShowInFinder(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.string(forKey: "afterSave")
        let newValue = current == "finder" ? "" : "finder"
        UserDefaults.standard.set(newValue, forKey: "afterSave")
        finderItem.state = newValue == "finder" ? .on : .off
        previewItem.state = .off
    }

    // MARK: - Clipboard Capture

    private func captureToClipboard(arguments: [String]) {
        // -P hands the capture to Preview as a detached document: macOS writes
        // the scratch file, opens it and unlinks it at the moment it knows is
        // safe, so Save falls through to Save As like an untitled document.
        //
        // Doing this by hand costs either the Accessibility permission (to
        // drive Preview's "New from Clipboard" menu item through System
        // Events) or a guess at when Preview has finished decoding. Both were
        // tried. The open callback, the file's access time and its memory
        // mapping all fire before the decode completes, and unlinking on any
        // of them leaves a blank window that hangs on save; locking the file
        // instead trades that for a Duplicate button that does nothing once
        // the file is gone. screencapture knows the safe moment from the
        // inside, so let it.
        let openInPreview = UserDefaults.standard.string(forKey: "afterSave") == "preview"

        runScreencapture(arguments + (openInPreview ? ["-P"] : []) + silentArgs())
    }

    // MARK: - Screencapture

    private func silentArgs() -> [String] {
        UserDefaults.standard.bool(forKey: "silent") ? ["-x"] : []
    }

    private func defaultFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Screenshot \(formatter.string(from: Date())).png"
    }

    private func captureToFileAndSave(arguments: [String]) {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot_\(ProcessInfo.processInfo.globallyUniqueString).png")

        runScreencapture(arguments + silentArgs() + [tempURL.path], wait: true)

        guard FileManager.default.fileExists(atPath: tempURL.path) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultFilename()
        panel.allowedContentTypes = [.png]

        guard panel.runModal() == .OK, let url = panel.url else {
            try? FileManager.default.removeItem(at: tempURL)
            return
        }

        try? FileManager.default.moveItem(at: tempURL, to: url)

        lastScreenshotURL = url
        lastScreenshotItem.isEnabled = true

        switch UserDefaults.standard.string(forKey: "afterSave") {
        case "preview": NSWorkspace.shared.open(url)
        case "finder": NSWorkspace.shared.activateFileViewerSelecting([url])
        default: break
        }
    }

    private func runScreencapture(_ arguments: [String], wait: Bool = false) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = arguments
        try? process.run()
        if wait {
            process.waitUntilExit()
        }
    }
}
