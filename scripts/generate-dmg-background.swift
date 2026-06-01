#!/usr/bin/env swift
import Cocoa

// Renders the DMG window background.
// Usage: swift generate-dmg-background.swift <scale> <output.png>
// Window is 620x420 points; icons sit at y≈230 from the top.

let args = CommandLine.arguments
let scale = CGFloat(args.count > 1 ? (Double(args[1]) ?? 1) : 1)
let outPath = args.count > 2 ? args[2] : "dmg-background.png"

let W: CGFloat = 620, H: CGFloat = 420
let pw = Int(W * scale), ph = Int(H * scale)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                           pixelsWide: pw, pixelsHigh: ph,
                           bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background gradient (soft, matches the app's blue brand)
let bg = NSGradient(starting: NSColor(red: 0.96, green: 0.98, blue: 1.00, alpha: 1.0),
                    ending:   NSColor(red: 0.87, green: 0.92, blue: 0.99, alpha: 1.0))!
bg.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

// Title
let title = "ScreenshotMenu"
let titleAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 32, weight: .semibold),
    .foregroundColor: NSColor(red: 0.12, green: 0.18, blue: 0.30, alpha: 1.0)
]
let tSize = title.size(withAttributes: titleAttr)
title.draw(at: NSPoint(x: (W - tSize.width) / 2, y: H - 72), withAttributes: titleAttr)

// Subtitle
let sub = "Drag the app onto the Applications folder to install"
let subAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .regular),
    .foregroundColor: NSColor(red: 0.38, green: 0.45, blue: 0.58, alpha: 1.0)
]
let sSize = sub.size(withAttributes: subAttr)
sub.draw(at: NSPoint(x: (W - sSize.width) / 2, y: H - 102), withAttributes: subAttr)

// Arrow between the two icons (icon centers are at y≈230 from top → 190 from bottom)
let arrowY: CGFloat = H - 230
let accent = NSColor(red: 0.20, green: 0.50, blue: 0.95, alpha: 1.0)
accent.setStroke()
accent.setFill()

let shaft = NSBezierPath()
shaft.lineWidth = 5
shaft.lineCapStyle = .round
shaft.move(to: NSPoint(x: 268, y: arrowY))
shaft.line(to: NSPoint(x: 344, y: arrowY))
shaft.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: 364, y: arrowY))
head.line(to: NSPoint(x: 342, y: arrowY + 12))
head.line(to: NSPoint(x: 342, y: arrowY - 12))
head.close()
head.fill()

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath) (\(pw)x\(ph))")
