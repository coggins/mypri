import SwiftUI

public extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    // Backgrounds
    static let mpBackground = Color(hex: "16161B")
    static let mpSurface = Color(hex: "1F1F27")
    static let mpSurfaceElevated = Color(hex: "292933")
    static let mpBorder = Color.white.opacity(0.08)

    // Accents
    static let mpElectricBlue = Color(hex: "22C3FF")
    static let mpElectricPurple = Color(hex: "B15CFF")
    static let mpSlate = Color(hex: "6E7180")

    // Text
    static let mpTextPrimary = Color.white.opacity(0.94)
    static let mpTextSecondary = Color.white.opacity(0.56)
    static let mpTextTertiary = Color.white.opacity(0.34)
}

public extension LinearGradient {
    static let mpAccent = LinearGradient(
        colors: [.mpElectricBlue, .mpElectricPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public struct MPPanelBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.mpBackground
            RadialGradient(
                colors: [Color.mpElectricPurple.opacity(0.08), Color.clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 500
            )
            RadialGradient(
                colors: [Color.mpElectricBlue.opacity(0.06), Color.clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
    }
}
