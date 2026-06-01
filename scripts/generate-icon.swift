#!/usr/bin/env swift
import Cocoa

let iconsetPath = "/tmp/ScreenshotMenu.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // Background: rounded rect with gradient
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.2
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    let gradient = NSGradient(starting: NSColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 1.0),
                              ending: NSColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0))!
    gradient.draw(in: path, angle: -90)

    // Draw SF Symbol
    if let symbol = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: size * 0.45, weight: .medium)
        let configured = symbol.withSymbolConfiguration(config)!

        let symbolSize = configured.size
        let x = (size - symbolSize.width) / 2
        let y = (size - symbolSize.height) / 2

        NSColor.white.set()
        configured.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height),
                       from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()

    let tiff = image.tiffRepresentation!
    let rep = NSBitmapImageRep(data: tiff)!
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

print("Iconset created at \(iconsetPath)")
