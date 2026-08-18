import SwiftUI

#if canImport(UIKit)
import UIKit
private typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
private typealias PlatformColor = NSColor
#endif

public extension Color {
    private static func dynamicColor(light: PlatformColor, dark: PlatformColor) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        })
        #elseif canImport(AppKit)
        // Fallback trivial pro macOS nativo (issue #75): sem trait
        // collection de UIKit, usa o provider dinâmico equivalente do
        // AppKit — mesma lógica de claro/escuro, sem nova UX no Mac.
        return Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
        #endif
    }

    private static func hex(_ hexString: String) -> PlatformColor {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return PlatformColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }

    private static let lightBg = hex("#FCFCFD")
    private static let lightSurface = hex("#FFFFFF")
    private static let lightInk = hex("#102245")
    private static let lightAccentWarm = hex("#C15300") // Darkened to meet 4.5:1 contrast in Light Mode
    private static let lightMuted = hex("#5F6C88")
    private static let lightBorder = hex("#E6E8ED")
    private static let lightBorderStrong = hex("#7C859B")
    
    private static let darkBg = hex("#000000")
    private static let darkSurface = hex("#262629")
    private static let darkInk = hex("#F6F6F9")
    private static let darkAccentWarm = hex("#FF9552")
    private static let darkMuted = hex("#9BA3B4")
    private static let darkBorder = hex("#25272D")
    private static let darkBorderStrong = hex("#5C6577")
    
    static let surfacePage = dynamicColor(light: lightBg, dark: darkBg)
    static let surfaceCard = dynamicColor(light: lightSurface, dark: darkSurface)
    static let textPrimary = dynamicColor(light: lightInk, dark: darkInk)
    static let textSecondary = dynamicColor(light: lightMuted, dark: darkMuted)
    static let borderDefault = dynamicColor(light: lightBorder, dark: darkBorder)
    static let borderStrong = dynamicColor(light: lightBorderStrong, dark: darkBorderStrong)
    static let brandSurface = dynamicColor(light: lightInk, dark: darkInk)
    static let brandOnSurface = dynamicColor(light: hex("#FFFFFF"), dark: hex("#000000"))
    static let brandAccentWarm = dynamicColor(light: lightAccentWarm, dark: darkAccentWarm)
}

public extension Font {
    static let displayHuge = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let displayLarge = Font.system(.title, design: .rounded, weight: .bold)
    static let displayTitle = Font.system(.title2, design: .rounded, weight: .bold)
    static let displayMedium = Font.system(.title3, design: .rounded, weight: .bold)
    static let buttonLabel = Font.system(.headline, design: .default, weight: .semibold)
    static let metricSecondary = Font.system(.headline, design: .default, weight: .bold)
    static let bodyRegular = Font.system(.body, design: .default, weight: .regular)
    static let bodyRegularStrong = Font.system(.body, design: .default, weight: .semibold)
    static let bodySmall = Font.system(.subheadline, design: .default, weight: .regular)
    static let bodySmallStrong = Font.system(.subheadline, design: .default, weight: .semibold)
    static let bodySmallMedium = Font.system(.subheadline, design: .default, weight: .medium)
    static let captionStrong = Font.system(.footnote, design: .default, weight: .bold)
    static let captionMedium = Font.system(.caption, design: .default, weight: .medium)
    static let captionSmall = Font.system(.caption2, design: .default, weight: .regular)
    static let captionSmallStrong = Font.system(.caption2, design: .default, weight: .semibold)
    static let monoEyebrow = Font.system(.footnote, design: .monospaced, weight: .regular)
    static let monoCaption = Font.system(.caption2, design: .monospaced, weight: .regular)
}

public struct LinkaMotion {
    public static let spring = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.35)
    public static let fade = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.25)
    public static let pulse = Animation.spring(response: 0.3, dampingFraction: 0.5)
}
