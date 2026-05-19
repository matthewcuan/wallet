import SwiftUI

extension Color {
    static let stashBackground = Color(stashHex: "#F7F5F1")
    static let stashEdge       = Color(stashHex: "#E8E4DC")
    static let stashInk        = Color(stashHex: "#1A1814")
    static let stashCream      = Color(stashHex: "#FFF4E8")
    static let stashCoral      = Color(stashHex: "#C24A2C")
    static let stashSuccess    = Color(stashHex: "#A7E27A")
    static let stashScannerBg  = Color(stashHex: "#0A0A0C")

    static var stashInkSubtle: Color { stashInk.opacity(0.5) }
    static var stashInkSoft:   Color { stashInk.opacity(0.55) }
    static var stashInkFaint:  Color { stashInk.opacity(0.06) }
    static var stashInkTint:   Color { stashInk.opacity(0.05) }

    init(stashHex hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt32(s, radix: 16) ?? 0
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}

extension Font {
    // Use Helvetica Neue for richer weight coverage — matches the design's
    // 500/600/700 ladder; Helvetica itself only ships Regular and Bold on iOS.
    static func stash(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .black, .heavy, .bold: name = "HelveticaNeue-Bold"
        case .semibold:             name = "HelveticaNeue-Medium"
        case .medium:               name = "HelveticaNeue-Medium"
        case .light:                name = "HelveticaNeue-Light"
        case .thin, .ultraLight:    name = "HelveticaNeue-Thin"
        default:                    name = "HelveticaNeue"
        }
        return .custom(name, size: size)
    }

    static func stashMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
