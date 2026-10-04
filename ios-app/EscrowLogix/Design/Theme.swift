import SwiftUI
import UIKit

// Brand tokens come straight from the website's :root, so the app and the page stay one brand.

extension Color {
    /// A color from a 0xRRGGBB value.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// A color that follows the phone's light or dark setting.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

/// Fixed brand colors (website :root).
enum Brand {
    static let black = Color(hex: 0x111315)
    static let charcoal = Color(hex: 0x191C1F)
    static let charcoal2 = Color(hex: 0x23272B)
    static let gold = Color(hex: 0xCAA45D)
    static let gold2 = Color(hex: 0xE1C285)
    static let goldDark = Color(hex: 0x8A6631)
    static let goldLight = Color(hex: 0xF0D9AE)
    static let cream = Color(hex: 0xF6F1E8)
    static let green = Color(hex: 0x2A7459)
    static let red = Color(hex: 0xA33A2C)

    /// The website's gold button.
    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xD4B06A), Color(hex: 0xC49D55)],
        startPoint: .top, endPoint: .bottom
    )
    /// The website's progress segments.
    static let progressGradient = LinearGradient(
        colors: [goldDark, gold2],
        startPoint: .leading, endPoint: .trailing
    )
}

/// Colors by role, with a light and a dark value.
enum Palette {
    static let bg = Color(light: Color(hex: 0xFBF8F3), dark: Color(hex: 0x0F1113))
    static let surface = Color(light: .white, dark: Color(hex: 0x1A1D20))
    static let surface2 = Color(light: Color(hex: 0xF6F1E8), dark: Color(hex: 0x22262A))
    static let sunk = Color(light: Color(hex: 0xF3EEE5), dark: Color(hex: 0x16191B))
    static let text = Color(light: Color(hex: 0x20242A), dark: Color(hex: 0xECE7DE))
    static let heading = Color(light: Color(hex: 0x191C1F), dark: .white)
    static let text2 = Color(light: Color(hex: 0x62676E), dark: Color(hex: 0xA8A49C))
    static let text3 = Color(light: Color(hex: 0xA29D95), dark: Color(hex: 0x6F6C66))
    static let separator = Color(light: Color(hex: 0xE9E4DB), dark: Color.white.opacity(0.085))
    static let line = Color(light: Color(hex: 0xE6E1D8), dark: Color.white.opacity(0.1))
    static let accent = Color(light: Brand.goldDark, dark: Brand.gold2)
    static let fill = Color(light: Color(hex: 0x191C1F, opacity: 0.055), dark: Color.white.opacity(0.075))
    static let primaryBackground = Color(light: Brand.charcoal, dark: Brand.gold)
    static let primaryForeground = Color(light: .white, dark: Brand.black)
    static let tile = Color(light: Brand.charcoal, dark: Color(hex: 0x26292D))
    static let radio = Color(light: Color(hex: 0xD6D0C5), dark: Color.white.opacity(0.22))
    static let track = Color(light: Color(hex: 0xEBE6DD), dark: Color.white.opacity(0.1))
    static let error = Color(light: Brand.red, dark: Color(hex: 0xE5877A))
    static let success = Color(light: Color(hex: 0x22694F), dark: Color(hex: 0x74C9A0))
    static let wireBackground = Color(light: Color(hex: 0xFFF7EA), dark: Color(hex: 0x221D14))
    static let wireLine = Color(light: Color(hex: 0xEFD9B0), dark: Color(hex: 0x4B3C22))
    static let wireText = Color(light: Color(hex: 0x5B5A57), dark: Color(hex: 0xCDC4B4))
    static let selectedCard = Color(light: Color(hex: 0xFFFBF3), dark: Color(hex: 0x1F1D18))
}

/// Type scale. Text styles keep Dynamic Type working.
extension Font {
    static let heroTitle = Font.system(.largeTitle, weight: .bold)
    static let stepTitle = Font.system(.title, weight: .bold)
    static let sectionTitle = Font.system(.title2, weight: .bold)
    static let cardTitle = Font.system(.title3, weight: .bold)
    static let fieldLabel = Font.system(.caption, weight: .semibold)
    static let kicker = Font.system(.caption2, weight: .heavy)
}
