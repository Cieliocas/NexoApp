import SwiftUI

extension Color {
    /// Initialises a `Color` from a CSS-style hex string, e.g. `"#FF3B30"` or `"FF3B30"`.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6: // RGB
            (r, g, b, a) = (Double((int >> 16) & 0xFF) / 255,
                            Double((int >> 8)  & 0xFF) / 255,
                            Double( int        & 0xFF) / 255,
                            1)
        case 8: // ARGB
            (r, g, b, a) = (Double((int >> 16) & 0xFF) / 255,
                            Double((int >> 8)  & 0xFF) / 255,
                            Double( int        & 0xFF) / 255,
                            Double((int >> 24) & 0xFF) / 255)
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
