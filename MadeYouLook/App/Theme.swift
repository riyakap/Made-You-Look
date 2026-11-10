import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Colors and type sampled from the Figma prototype.
enum Theme {
    static let background = Color(hex: 0xFBEDE4)
    static let backgroundDeep = Color(hex: 0xF4DACD)
    static let card = Color(hex: 0xF3E1D9)
    static let cardBorder = Color(hex: 0xE2BCB6)
    static let surface = Color(hex: 0xFCF6F2)
    static let primary = Color(hex: 0xB86F79)
    static let primaryDark = Color(hex: 0x9C5862)
    static let ink = Color(hex: 0x3A2626)
    static let inkSecondary = Color(hex: 0x7D6862)
    static let chip = Color(hex: 0xE8D4CC)
    static let tabBar = Color(hex: 0xFBF3EE)

    /// Elegant serif used for headings ("Made You Look", screen titles, card titles).
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// Clean sans-serif used for body copy and buttons.
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

/// The soft peach "silk" backdrop used behind every screen.
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.backgroundDeep, Theme.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if UIImage(named: "bg_silk") != nil {
                Image("bg_silk")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.85)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func appBackground() -> some View {
        background(AppBackground())
    }
}
