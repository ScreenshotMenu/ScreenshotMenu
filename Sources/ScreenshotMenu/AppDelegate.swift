import Cocoa
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var lastScreenshotURL: URL?
    // changeCount of the pasteboard right after we put a capture on it.
    // If it still matches, the clipboard is untouched and holds our image.
    private var lastClipboardChangeCount: Int?
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
        if let url = lastScreenshotURL, FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)
            return
        }

        // The last capture went to the clipboard, so there is no file to
        // reopen -- re-materialise it, but only if the clipboard is still ours.
        guard let expected = lastClipboardChangeCount else { return }
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount == expected,
              let image = NSImage(pasteboard: pasteboard) else {
            reportClipboardGone()
            return
        }
        openDetached(image)
    }

    private func reportClipboardGone() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Nothing to open"
        alert.informativeText = "The last screenshot was copied to the clipboard, "
            + "but the clipboard has changed since then, so there is nothing left to open."
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
        guard UserDefaults.standard.string(forKey: "afterSave") == "preview" else {
            // A cancelled selection (Esc) leaves the clipboard untouched, so
            // only claim the capture if the pasteboard actually moved.
            let before = NSPasteboard.general.changeCount
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = arguments + silentArgs()
            process.terminationHandler = { [weak self] _ in
                DispatchQueue.main.async {
                    let pasteboard = NSPasteboard.general
                    guard pasteboard.changeCount != before,
                          NSImage(pasteboard: pasteboard) != nil else { return }
                    self?.rememberClipboardCapture()
                }
            }
            try? process.run()
            return
        }

        // "to Clipboard" plus "Open in Preview". There is no file to hand
        // Preview, and no public API asks another app to paste -- doing that
        // needs UI scripting, which costs the Accessibility permission.
        // Instead: capture to a scratch file, put the image on the clipboard
        // ourselves, hand Preview the file, then unlink it. Preview keeps the
        // open document but loses its backing path, so Save falls through to
        // Save As, exactly as an untitled document would.
        sweepScratch()
        let url = scratchURL()

        // drop -c so screencapture writes a file rather than the clipboard
        let fileArgs = arguments
            .map { $0.replacingOccurrences(of: "c", with: "") }
            .filter { $0 != "-" && !$0.isEmpty }
        runScreencapture(fileArgs + silentArgs() + [url.path], wait: true)

        guard let image = NSImage(contentsOf: url) else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        rememberClipboardCapture()

        openDetached(url, deletingAfterOpen: true)
    }

    private func rememberClipboardCapture() {
        lastClipboardChangeCount = NSPasteboard.general.changeCount
        lastScreenshotURL = nil
        lastScreenshotItem.isEnabled = true
    }

    // MARK: - Detached Preview

    /// Scratch files live in their own directory so sweeping is unambiguous.
    private func scratchDirectory() -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ScreenshotMenu", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func scratchURL() -> URL {
        scratchDirectory().appendingPathComponent(defaultFilename())
    }

    /// Remove leftovers from captures whose unlink never landed.
    private func sweepScratch() {
        let dir = scratchDirectory()
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func openDetached(_ image: NSImage) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        sweepScratch()
        let url = scratchURL()
        guard (try? png.write(to: url)) != nil else { return }
        openDetached(url, deletingAfterOpen: true)
    }

    /// Seconds-resolution access time, or 0 if the file is gone.
    private func accessTime(of url: URL) -> TimeInterval {
        var info = stat()
        guard stat(url.path, &info) == 0 else { return 0 }
        return Double(info.st_atimespec.tv_sec) + Double(info.st_atimespec.tv_nsec) / 1e9
    }

    private func openDetached(_ url: URL, deletingAfterOpen: Bool) {
        guard let preview = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Preview") else {
            NSWorkspace.shared.open(url)
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        let baseline = accessTime(of: url)
        NSWorkspace.shared.open([url], withApplicationAt: preview, configuration: configuration) { [weak self] _, error in
            guard deletingAfterOpen, error == nil, let self = self else { return }

            // The completion handler only means the open request was
            // delivered; Preview reads the file a moment later. Unlinking
            // before that read makes the open fail outright -- measured
            // reliably at 0ms, safe from ~100ms. So wait for the read itself
            // rather than guessing an interval: the access time moving is the
            // signal. Anything never read is left to sweepScratch().
            DispatchQueue.global(qos: .utility).async {
                let deadline = Date().addingTimeInterval(5)
                while Date() < deadline {
                    if self.accessTime(of: url) > baseline {
                        try? FileManager.default.removeItem(at: url)
                        return
                    }
                    Thread.sleep(forTimeInterval: 0.05)
                }
            }
        }
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
        lastClipboardChangeCount = nil
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
