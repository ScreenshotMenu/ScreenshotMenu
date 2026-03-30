import Cocoa
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
        showSavePanelAndCapture(arguments: ["-w"])
    }

    @objc func areaToFile() {
        showSavePanelAndCapture(arguments: ["-s"])
    }
    @objc func windowToClipboard() {
        runScreencapture(["-wc"])
    }

    @objc func areaToClipboard() {
        runScreencapture(["-sc"])
    }

    // MARK: - Settings

    @objc func toggleAutolaunch(_ sender: NSMenuItem) {}
    @objc func toggleOpenInPreview(_ sender: NSMenuItem) {}

    // MARK: - Screencapture

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

    private func runScreencapture(_ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = arguments
        try? process.run()
    }
}
