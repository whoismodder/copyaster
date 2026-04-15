#!/usr/bin/env swift
/// App icon monocromático para Copyaster — estilo Apple
import AppKit

func createAppIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    return NSImage(size: NSSize(width: s, height: s), flipped: false) { rect in

        // ── Squircle background ──
        let inset = s * 0.05
        let iconRect = rect.insetBy(dx: inset, dy: inset)
        let corner = s * 0.22  // Apple usa ~22% del tamaño
        let bg = NSBezierPath(roundedRect: iconRect, xRadius: corner, yRadius: corner)

        // Fondo negro profundo
        NSColor(white: 0.06, alpha: 1).setFill()
        bg.fill()

        // Borde interno sutil
        NSColor(white: 0.14, alpha: 1).setStroke()
        bg.lineWidth = s * 0.003
        bg.stroke()

        // ── Clipboard centrado ──
        let clipW = s * 0.40
        let clipH = s * 0.50
        let clipX = (s - clipW) / 2
        let clipY = (s - clipH) / 2 - s * 0.02  // ligeramente abajo del centro óptico

        // Sombra del clipboard
        let ctx = NSGraphicsContext.current!.cgContext
        ctx.saveGState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowOffset = NSSize(width: 0, height: -s * 0.008)
        shadow.shadowBlurRadius = s * 0.025
        shadow.set()

        // Clipboard body
        let bodyRadius = s * 0.035
        let body = NSBezierPath(roundedRect: NSRect(x: clipX, y: clipY, width: clipW, height: clipH),
                                xRadius: bodyRadius, yRadius: bodyRadius)
        NSColor(white: 0.93, alpha: 1).setFill()
        body.fill()
        ctx.restoreGState()

        // Borde del clipboard
        NSColor(white: 0.75, alpha: 0.3).setStroke()
        body.lineWidth = s * 0.002
        body.stroke()

        // ── Clip tab (la pestaña de arriba) ──
        let tabW = s * 0.16
        let tabH = s * 0.055
        let tabX = (s - tabW) / 2
        let tabY = clipY + clipH - tabH * 0.4
        let tabRadius = s * 0.018

        let tab = NSBezierPath(roundedRect: NSRect(x: tabX, y: tabY, width: tabW, height: tabH),
                               xRadius: tabRadius, yRadius: tabRadius)
        NSColor(white: 0.93, alpha: 1).setFill()
        tab.fill()
        NSColor(white: 0.75, alpha: 0.3).setStroke()
        tab.lineWidth = s * 0.002
        tab.stroke()

        // Clip hole (circulito en la pestaña)
        let hr = s * 0.014
        NSColor(white: 0.55, alpha: 0.4).setFill()
        NSBezierPath(ovalIn: NSRect(x: s / 2 - hr, y: tabY + tabH / 2 - hr, width: hr * 2, height: hr * 2)).fill()

        // ── "C" centrada ópticamente ──
        let fontSize = s * 0.26
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(white: 0.10, alpha: 1)
        ]
        let c = "C" as NSString
        let cs = c.size(withAttributes: attrs)
        // Centro óptico: ligeramente arriba del centro matemático
        let cx = (s - cs.width) / 2
        let cy = clipY + (clipH - cs.height) / 2 - s * 0.015
        c.draw(at: NSPoint(x: cx, y: cy), withAttributes: attrs)

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
print(task.terminationStatus == 0 ? "OK" : "ERROR")
if task.terminationStatus != 0 { exit(1) }
