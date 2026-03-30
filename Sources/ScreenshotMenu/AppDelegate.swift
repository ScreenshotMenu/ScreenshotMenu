import Cocoa
import ServiceManagement
import UniformTypeIdentifiers

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

    @objc func windowToFile() {
        captureToFileAndSave(arguments: ["-w"])
    }

    @objc func areaToFile() {
        captureToFileAndSave(arguments: ["-s"])
    }
    @objc func windowToClipboard() {
        runScreencapture(["-wc"])
    }

    @objc func areaToClipboard() {
        runScreencapture(["-sc"])
    }

    // MARK: - Settings

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

    // MARK: - Screencapture

    private func defaultFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Screenshot \(formatter.string(from: Date())).png"
    }

    private func captureToFileAndSave(arguments: [String]) {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot_\(ProcessInfo.processInfo.globallyUniqueString).png")

        // Capture to temp file first (screen is clean)
        runScreencapture(arguments + [tempURL.path], wait: true)

        // If user cancelled the capture, no file exists
        guard FileManager.default.fileExists(atPath: tempURL.path) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultFilename()
        panel.allowedContentTypes = [.png]

        guard panel.runModal() == .OK, let url = panel.url else {
            try? FileManager.default.removeItem(at: tempURL)
            return
        }

        try? FileManager.default.moveItem(at: tempURL, to: url)

        if UserDefaults.standard.bool(forKey: "openInPreview") {
            NSWorkspace.shared.open(url)
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
