import SwiftUI

public extension Color {
    static let linkaBackground = Color.black
    static let linkaSurface = Color(white: 0.12)
    static let linkaPrimary = Color.blue
    static let linkaSecondary = Color.cyan
    static let linkaAccent = Color.green
    
    static let linkaText = Color.white
    static let linkaTextSecondary = Color.gray
}

public extension Font {
    static let linkaLargeTitle = Font.system(size: 48, weight: .bold, design: .rounded)
    static let linkaTitle = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let linkaHeadline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let linkaBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let linkaCaption = Font.system(size: 14, weight: .medium, design: .rounded)
}
