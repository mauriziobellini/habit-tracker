#!/usr/bin/env swift
//
// Renders the still artwork for the App Store app preview: the full-screen
// motivational title cards, and the transparent lower-third captions that name
// the feature on screen.
//
// Drawn with CoreText rather than composed in ffmpeg's drawtext so the type is
// real SF Pro with proper tracking and line height — ffmpeg's text rendering
// cannot reach the system font and looks it.
//
// Usage: swift scripts/render-preview-cards.swift <output-directory>

import AppKit
import CoreGraphics
import Foundation

// Matches the iPhone 6.9" recording, so artwork composites 1:1 with the footage.
let canvas = CGSize(width: 1320, height: 2868)

// MARK: - Palette

extension NSColor {
    /// `#RRGGBB`, optionally with alpha applied on top.
    convenience init(hex: String, alpha: CGFloat = 1) {
        var value: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value)
        self.init(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: alpha
        )
    }
}

let backdrop = NSColor(hex: "#07080D")

// MARK: - Drawing helpers

func makeContext() -> CGContext {
    guard let context = CGContext(
        data: nil,
        width: Int(canvas.width),
        height: Int(canvas.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create a bitmap context")
    }
    return context
}

func write(_ context: CGContext, to url: URL) {
    guard let image = context.makeImage() else { fatalError("Could not snapshot the context") }
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = canvas
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }
    try! data.write(to: url)
    print("    \(url.lastPathComponent)")
}

/// A soft circular glow, used to lift the title cards off flat black.
func drawGlow(
    _ context: CGContext,
    center: CGPoint,
    radius: CGFloat,
    color: NSColor,
    strength: CGFloat = 1
) {
    let colors = [
        color.withAlphaComponent(0.55 * strength).cgColor,
        color.withAlphaComponent(0.16 * strength).cgColor,
        color.withAlphaComponent(0).cgColor,
    ] as CFArray
    guard let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: colors,
        locations: [0, 0.45, 1]
    ) else { return }
    context.drawRadialGradient(
        gradient,
        startCenter: center, startRadius: 0,
        endCenter: center, endRadius: radius,
        options: []
    )
}

/// The stroked ring motif the app is named for.
func drawRing(
    _ context: CGContext,
    center: CGPoint,
    radius: CGFloat,
    lineWidth: CGFloat,
    color: NSColor,
    fraction: CGFloat
) {
    context.saveGState()
    context.setLineCap(.round)
    context.setLineWidth(lineWidth)

    context.setStrokeColor(color.withAlphaComponent(0.18).cgColor)
    context.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    context.strokePath()

    context.setStrokeColor(color.cgColor)
    context.addArc(
        center: center,
        radius: radius,
        startAngle: .pi / 2,
        endAngle: .pi / 2 - .pi * 2 * fraction,
        clockwise: true
    )
    context.strokePath()
    context.restoreGState()
}

func attributed(
    _ text: String,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    tracking: CGFloat = 0,
    lineHeightMultiple: CGFloat = 1.1
) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineHeightMultiple = lineHeightMultiple
    return NSAttributedString(string: text, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .kern: tracking,
        .paragraphStyle: paragraph,
    ])
}

/// Draws `text` centred in a box of `width`, shrinking it until it fits, and
/// returns the height it occupied.
@discardableResult
func draw(
    _ text: String,
    in context: CGContext,
    centeredAtY y: CGFloat,
    width: CGFloat,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    tracking: CGFloat = 0,
    lineHeightMultiple: CGFloat = 1.1
) -> CGFloat {
    let graphics = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    defer { NSGraphicsContext.restoreGraphicsState() }

    var pointSize = size
    var string = attributed(
        text, size: pointSize, weight: weight, color: color,
        tracking: tracking, lineHeightMultiple: lineHeightMultiple
    )
    var bounds = string.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin]
    )
    // Guards the captions, whose length is set by copy rather than by layout.
    while bounds.height > canvas.height * 0.5 && pointSize > 24 {
        pointSize -= 4
        string = attributed(
            text, size: pointSize, weight: weight, color: color,
            tracking: tracking, lineHeightMultiple: lineHeightMultiple
        )
        bounds = string.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin]
        )
    }

    let rect = CGRect(
        x: (canvas.width - width) / 2,
        y: y - bounds.height / 2,
        width: width,
        height: bounds.height
    )
    string.draw(with: rect, options: [.usesLineFragmentOrigin])
    return bounds.height
}

// MARK: - Title cards

struct Card {
    let name: String
    let eyebrow: String?
    let headline: String
    let footnote: String?
    let accent: String
    /// How far round the ring motif is drawn — the cards read as a habit growing
    /// from first rep to fully formed across the length of the video.
    let ringFraction: CGFloat
}

let cards: [Card] = [
    Card(
        name: "card_open",
        eyebrow: "RING HABITS",
        headline: "Be the designer\nof your world",
        footnote: nil,
        accent: "#A78BFA",
        ringFraction: 0.18
    ),
    Card(
        name: "card_mid",
        eyebrow: nil,
        headline: "Small habits\ndon’t add up.\nThey compound.",
        footnote: nil,
        accent: "#2BD9C0",
        ringFraction: 0.62
    ),
    Card(
        name: "card_close",
        eyebrow: nil,
        headline: "Tiny daily changes,\nremarkable results",
        footnote: "Ring Habits",
        accent: "#FF9F0A",
        ringFraction: 1.0
    ),
]

func render(_ card: Card, to directory: URL) {
    let context = makeContext()
    let accent = NSColor(hex: card.accent)

    context.setFillColor(backdrop.cgColor)
    context.fill(CGRect(origin: .zero, size: canvas))

    drawGlow(
        context,
        center: CGPoint(x: canvas.width / 2, y: canvas.height * 0.57),
        radius: canvas.width * 1.05,
        color: accent
    )
    // A second, far weaker glow low in the frame keeps the composition from
    // reading as a single flat halo.
    drawGlow(
        context,
        center: CGPoint(x: canvas.width * 0.18, y: canvas.height * 0.14),
        radius: canvas.width * 0.95,
        color: NSColor(hex: "#4F46E5"),
        strength: 0.35
    )

    drawRing(
        context,
        center: CGPoint(x: canvas.width / 2, y: canvas.height * 0.655),
        radius: 132,
        lineWidth: 20,
        color: accent,
        fraction: card.ringFraction
    )

    var cursor = canvas.height * 0.44
    let headlineHeight = draw(
        card.headline,
        in: context,
        centeredAtY: cursor,
        width: canvas.width - 150,
        size: 132,
        weight: .bold,
        color: .white,
        tracking: -2.5,
        lineHeightMultiple: 1.08
    )

    if let eyebrow = card.eyebrow {
        cursor += headlineHeight / 2 + 78
        draw(
            eyebrow,
            in: context,
            centeredAtY: cursor,
            width: canvas.width - 150,
            size: 40,
            weight: .semibold,
            color: accent.withAlphaComponent(0.9),
            tracking: 10
        )
    }

    if let footnote = card.footnote {
        draw(
            footnote,
            in: context,
            centeredAtY: canvas.height * 0.275,
            width: canvas.width - 150,
            size: 46,
            weight: .medium,
            color: NSColor(white: 1, alpha: 0.55),
            tracking: 4
        )
    }

    write(context, to: directory.appendingPathComponent("\(card.name).png"))
}

// MARK: - Captions

struct Caption {
    let name: String
    let text: String
    let accent: String
}

let captions: [Caption] = [
    Caption(name: "caption_dashboard", text: "Every habit, one ring", accent: "#A78BFA"),
    Caption(name: "caption_complete", text: "Tap and hold to complete", accent: "#E0409E"),
    Caption(name: "caption_summary", text: "Watch your habit strength grow", accent: "#A78BFA"),
    Caption(name: "caption_stats", text: "See the trend, not just today", accent: "#A78BFA"),
    Caption(name: "caption_config", text: "Your habit, your color, your rules", accent: "#FF9F0A"),
]

func render(_ caption: Caption, to directory: URL) {
    let context = makeContext()
    let accent = NSColor(hex: caption.accent)

    // A scrim rather than a solid bar: the screenshot stays legible behind the
    // type, which is the point of putting the caption over the footage at all.
    let scrimHeight = canvas.height * 0.30
    let colors = [
        NSColor(hex: "#07080D", alpha: 0).cgColor,
        NSColor(hex: "#07080D", alpha: 0.82).cgColor,
        NSColor(hex: "#07080D", alpha: 0.94).cgColor,
    ] as CFArray
    if let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: colors,
        locations: [0, 0.55, 1]
    ) {
        context.saveGState()
        context.clip(to: CGRect(x: 0, y: 0, width: canvas.width, height: scrimHeight))
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: scrimHeight),
            end: CGPoint(x: 0, y: 0),
            options: []
        )
        context.restoreGState()
    }

    let baseline = canvas.height * 0.105
    draw(
        caption.text,
        in: context,
        centeredAtY: baseline,
        width: canvas.width - 130,
        size: 72,
        weight: .semibold,
        color: .white,
        tracking: -0.8,
        lineHeightMultiple: 1.12
    )

    // A short accent rule ties the caption to the habit colour on screen.
    context.setFillColor(accent.cgColor)
    let rule = CGRect(x: (canvas.width - 96) / 2, y: baseline + 108, width: 96, height: 8)
    context.addPath(CGPath(roundedRect: rule, cornerWidth: 4, cornerHeight: 4, transform: nil))
    context.fillPath()

    write(context, to: directory.appendingPathComponent("\(caption.name).png"))
}

// MARK: - Entry point

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    fatalError("Usage: swift render-preview-cards.swift <output-directory>")
}
let outputDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
try! FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

print("==> Rendering title cards")
cards.forEach { render($0, to: outputDirectory) }
print("==> Rendering captions")
captions.forEach { render($0, to: outputDirectory) }
