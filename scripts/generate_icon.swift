#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = root.appendingPathComponent("Resources", isDirectory: true)
let iconsetURL = resourcesURL.appendingPathComponent("Meridian.iconset", isDirectory: true)

try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let icons: [(name: String, size: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawIcon(size: CGFloat) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "MeridianIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
    }

    bitmap.size = NSSize(width: size, height: size)

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "MeridianIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer {
        NSGraphicsContext.restoreGraphicsState()
    }

    let context = graphicsContext.cgContext

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.055
    let iconRect = canvas.insetBy(dx: inset, dy: inset)
    let cornerRadius = size * 0.205

    let backgroundPath = CGPath(
        roundedRect: iconRect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -size * 0.018),
        blur: size * 0.035,
        color: color(0, 0, 0, 0.28)
    )
    context.addPath(backgroundPath)
    context.clip()
    let backgroundGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            color(250, 251, 252),
            color(216, 221, 228)
        ] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: iconRect.minX, y: iconRect.maxY),
        end: CGPoint(x: iconRect.maxX, y: iconRect.minY),
        options: []
    )
    context.restoreGState()

    context.addPath(backgroundPath)
    context.setStrokeColor(color(255, 255, 255, 0.70))
    context.setLineWidth(size * 0.012)
    context.strokePath()

    let globeRect = canvas.insetBy(dx: size * 0.205, dy: size * 0.205)
    let globePath = CGPath(ellipseIn: globeRect, transform: nil)

    context.saveGState()
    context.addPath(globePath)
    context.setFillColor(color(17, 19, 23))
    context.fillPath()
    context.restoreGState()

    let lineWidth = max(size * 0.045, 1.4)
    let center = CGPoint(x: globeRect.midX, y: globeRect.midY)
    let radius = globeRect.width / 2

    context.saveGState()
    context.setLineCap(.round)
    context.setLineJoin(.round)

    context.addPath(globePath)
    context.setStrokeColor(color(255, 255, 255, 0.96))
    context.setLineWidth(lineWidth)
    context.strokePath()

    context.addPath(globePath)
    context.clip()

    context.setStrokeColor(color(255, 255, 255, 0.92))
    context.setLineWidth(lineWidth * 0.86)

    for offset in [-0.34, 0, 0.34] {
        let y = center.y + radius * CGFloat(offset)
        context.move(to: CGPoint(x: center.x - radius * 0.88, y: y))
        context.addLine(to: CGPoint(x: center.x + radius * 0.88, y: y))
        context.strokePath()
    }

    let verticalWide = CGRect(
        x: center.x - radius * 0.45,
        y: globeRect.minY - lineWidth * 0.2,
        width: radius * 0.90,
        height: globeRect.height + lineWidth * 0.4
    )
    let verticalNarrow = CGRect(
        x: center.x - radius * 0.18,
        y: globeRect.minY - lineWidth * 0.2,
        width: radius * 0.36,
        height: globeRect.height + lineWidth * 0.4
    )
    context.strokeEllipse(in: verticalWide)
    context.strokeEllipse(in: verticalNarrow)

    context.restoreGState()

    context.saveGState()
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: -0.42)
    context.setLineCap(.round)
    context.setStrokeColor(color(10, 132, 255, 0.96))
    context.setLineWidth(max(size * 0.027, 1.0))
    let orbitRect = CGRect(
        x: -radius * 1.16,
        y: -radius * 0.47,
        width: radius * 2.32,
        height: radius * 0.94
    )
    context.strokeEllipse(in: orbitRect)
    context.restoreGState()

    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MeridianIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create PNG data"])
    }

    try png.write(to: url)
}

for icon in icons {
    let bitmap = try drawIcon(size: icon.size)
    try writePNG(bitmap, to: iconsetURL.appendingPathComponent(icon.name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c", "icns",
    iconsetURL.path,
    "-o", resourcesURL.appendingPathComponent("Meridian.icns").path
]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "MeridianIcon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}

print("Generated Resources/Meridian.icns")
