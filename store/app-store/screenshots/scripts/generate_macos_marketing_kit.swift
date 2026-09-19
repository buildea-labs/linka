import AppKit
import Foundation

let width = 2880
let height = 1800
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sources = root.appendingPathComponent("store/app-store/screenshots/final/pt-BR/mac")
let output = root.appendingPathComponent("store/app-store/screenshots/marketing/pt-BR/mac")
let wordmarkURL = root.appendingPathComponent("documentacao/design/design_system/assets/wordmark.svg")

try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

struct Artwork {
    let file: String
    let source: String
    let headline: String
    let subtitle: String
}

let artworks = [
    Artwork(file: "01-measure-your-connection.jpg", source: "01-resultado.jpg", headline: "Veja sua conexão\nem segundos.", subtitle: "Velocidade, latência e estabilidade em uma leitura só."),
    Artwork(file: "02-understand-what-is-happening.jpg", source: "02-assist.jpg", headline: "Entenda o que está\nacontecendo.", subtitle: "Quando algo não vai bem, o Assist mostra por onde começar."),
    Artwork(file: "03-follow-your-network.jpg", source: "03-historico.jpg", headline: "Acompanhe sua\nconexão.", subtitle: "Compare as medições e perceba quando a rede muda."),
    Artwork(file: "04-improve-what-matters.jpg", source: "04-otimizacao.jpg", headline: "Melhore o que\nimporta.", subtitle: "Encontre oportunidades para deixar sua rede melhor.")
]

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func drawText(_ value: String, in rect: NSRect, font: NSFont, color: NSColor, lineSpacing: CGFloat = 0) {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = lineSpacing
    style.alignment = .left
    let attributed = NSAttributedString(string: value, attributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: style
    ])
    attributed.draw(in: rect)
}

// Mirrors the Linka Design System: prose uses the native SF Pro system face.
// Rounded is intentionally reserved in the app for measured numeric values.
func appDisplayFont(size: CGFloat) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: .bold)
}

func appBodyFont(size: CGFloat) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: .regular)
}

func drawArtwork(_ artwork: Artwork) throws {
    guard let screenshot = NSImage(contentsOf: sources.appendingPathComponent(artwork.source)) else {
        throw NSError(domain: "LinkaMarketing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Screenshot ausente: \(artwork.source)"])
    }
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "LinkaMarketing", code: 2, userInfo: [NSLocalizedDescriptionKey: "Falha ao preparar \(artwork.file)"])
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    defer { NSGraphicsContext.restoreGraphicsState() }

    // Background is intentionally restrained: the actual product UI is the hero.
    color(0x102245).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
    color(0x2B4A7A, alpha: 0.26).setFill()
    NSBezierPath(ovalIn: NSRect(x: 2200, y: 1170, width: 900, height: 900)).fill()
    color(0xE0701F, alpha: 0.95).setFill()
    NSBezierPath(ovalIn: NSRect(x: 2540, y: 1425, width: 40, height: 40)).fill()

    if let wordmark = NSImage(contentsOf: wordmarkURL) {
        wordmark.draw(in: NSRect(x: 145, y: 1660, width: 180, height: 104), from: .zero, operation: .sourceOver, fraction: 1)
    } else {
        drawText("linka", in: NSRect(x: 145, y: 1680, width: 250, height: 70), font: appDisplayFont(size: 52), color: .white)
    }

    drawText(artwork.headline, in: NSRect(x: 145, y: 1420, width: 1780, height: 260), font: appDisplayFont(size: 100), color: .white, lineSpacing: 2)
    drawText(artwork.subtitle, in: NSRect(x: 152, y: 1325, width: 1520, height: 70), font: appBodyFont(size: 36), color: color(0xDFE8FA))

    // The product capture is 16:10. Keep that exact ratio: screenshots must
    // never be squeezed merely to make room for the campaign headline.
    let imageRect = NSRect(x: 440, y: 55, width: 2000, height: 1250)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.48)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -16)
    shadow.set()
    color(0x192237).setFill()
    let card = NSBezierPath(roundedRect: imageRect, xRadius: 36, yRadius: 36)
    card.fill()
    NSShadow().set()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: imageRect, xRadius: 36, yRadius: 36).addClip()
    screenshot.draw(in: imageRect, from: NSRect(origin: .zero, size: screenshot.size), operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    color(0xFFFFFF, alpha: 0.18).setStroke()
    card.lineWidth = 2
    card.stroke()

    guard let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
        throw NSError(domain: "LinkaMarketing", code: 2, userInfo: [NSLocalizedDescriptionKey: "Falha ao exportar \(artwork.file)"])
    }
    try jpeg.write(to: output.appendingPathComponent(artwork.file))
}

for artwork in artworks {
    try drawArtwork(artwork)
    print("Generated \(artwork.file)")
}
