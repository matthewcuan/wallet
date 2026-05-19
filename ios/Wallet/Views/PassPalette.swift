import SwiftUI

enum PassPalette: String, CaseIterable, Identifiable {
    case forest, clay, ink, mustard, slate, plum, sage, coral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .forest:  "Forest"
        case .clay:    "Clay"
        case .ink:     "Ink"
        case .mustard: "Mustard"
        case .slate:   "Slate"
        case .plum:    "Plum"
        case .sage:    "Sage"
        case .coral:   "Coral"
        }
    }

    var backgroundHex: String {
        switch self {
        case .forest:  "#1F3A2E"
        case .clay:    "#C24A2C"
        case .ink:     "#15171C"
        case .mustard: "#D7A23C"
        case .slate:   "#3B4A5C"
        case .plum:    "#5B2E47"
        case .sage:    "#8A9A7B"
        case .coral:   "#E8593E"
        }
    }

    var foregroundHex: String {
        switch self {
        case .forest:  "#E8E0CF"
        case .clay:    "#FFF4E8"
        case .ink:     "#E8E0CF"
        case .mustard: "#1A1814"
        case .slate:   "#E8E8EC"
        case .plum:    "#F2DCEA"
        case .sage:    "#1A1814"
        case .coral:   "#FFF4E8"
        }
    }

    var background: Color { Color(stashHex: backgroundHex) }
    var foreground: Color { Color(stashHex: foregroundHex) }

    // Backend takes a separate label colour; for this palette we reuse the
    // foreground for both so the request stays consistent with what we show.
    var colors: PassColors {
        PassColors(background: backgroundHex, foreground: foregroundHex, label: foregroundHex)
    }

    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    static func at(_ index: Int) -> PassPalette {
        let cases = allCases
        guard !cases.isEmpty else { return .forest }
        let bounded = ((index % cases.count) + cases.count) % cases.count
        return cases[bounded]
    }

    static func matching(_ colors: PassColors) -> PassPalette? {
        allCases.first { $0.colors == colors }
    }
}
