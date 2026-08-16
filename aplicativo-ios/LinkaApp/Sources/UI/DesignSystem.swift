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
    private static let lightAccentWarm = hex("#E0701F")
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
    static let displayTitle = Font.system(size: 26, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 20, weight: .bold, design: .rounded)
    static let bodyRegular = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    static let monoEyebrow = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let monoCaption = Font.system(size: 11, weight: .regular, design: .monospaced)
}

public struct LinkaMotion {
    public static let spring = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.35)
    public static let fade = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.25)
}
