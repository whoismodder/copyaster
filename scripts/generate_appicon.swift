#!/usr/bin/env swift
/// Genera el AppIcon.icns monocromático para Copyaster.
/// Uso:  swift scripts/generate_appicon.swift

import AppKit

func createAppIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    return NSImage(size: NSSize(width: s, height: s), flipped: false) { rect in

        // Fondo negro — squircle macOS
        let inset = s * 0.05
        let iconRect = rect.insetBy(dx: inset, dy: inset)
        let corner = s * 0.185
        let bg = NSBezierPath(roundedRect: iconRect, xRadius: corner, yRadius: corner)
        NSColor(white: 0.08, alpha: 1).setFill()
        bg.fill()
        NSColor(white: 0.18, alpha: 1).setStroke()
        bg.lineWidth = s * 0.004
        bg.stroke()

        // Clipboard — blanco
        let clipW = s * 0.44, clipH = s * 0.54
        let clipX = (s - clipW) / 2, clipY = s * 0.15

        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowOffset = NSSize(width: 0, height: -s * 0.01)
        shadow.shadowBlurRadius = s * 0.02
        shadow.set()

        let body = NSBezierPath(roundedRect: NSRect(x: clipX, y: clipY, width: clipW, height: clipH),
                                xRadius: s * 0.03, yRadius: s * 0.03)
        NSColor(white: 0.92, alpha: 1).setFill()
        body.fill()
        ctx.restoreGState()

        // Clip tab
        let tabW = s * 0.18, tabH = s * 0.06
        let tabX = (s - tabW) / 2, tabY = clipY + clipH - tabH * 0.35
        let tab = NSBezierPath(roundedRect: NSRect(x: tabX, y: tabY, width: tabW, height: tabH),
                               xRadius: s * 0.02, yRadius: s * 0.02)
        NSColor(white: 0.92, alpha: 1).setFill()
        tab.fill()

        // Clip hole
        let hr = s * 0.018
        NSColor(white: 0.45, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: s / 2 - hr, y: tabY + tabH / 2 - hr, width: hr * 2, height: hr * 2)).fill()

        // "C" — negro sobre blanco
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: s * 0.28, weight: .bold),
            .foregroundColor: NSColor(white: 0.12, alpha: 1)
        ]
        let c = "C" as NSString
        let cs = c.size(withAttributes: attrs)
        c.draw(at: NSPoint(x: (s - cs.width) / 2,
                           y: clipY + (clipH - cs.height) / 2 - s * 0.03),
               withAttributes: attrs)

        return true
    }
}

func save(_ image: NSImage, to path: String, px: Int) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .calibratedRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = image.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(origin: .zero, size: image.size))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: path))
}

let dir = "build/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

for (name, px) in [
    ("icon_16x16.png", 16),    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
] {
    save(createAppIcon(size: px), to: "\(dir)/\(name)", px: px)
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", dir, "-o", "build/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "build/AppIcon.icns OK" : "ERROR")
if task.terminationStatus != 0 { exit(1) }
