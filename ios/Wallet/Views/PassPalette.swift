import SwiftUI

enum PassPalette: String, CaseIterable, Identifiable {
    case midnight, sunrise, forest, slate, crimson

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight: "Midnight"
        case .sunrise: "Sunrise"
        case .forest: "Forest"
        case .slate: "Slate"
        case .crimson: "Crimson"
        }
    }

    var colors: PassColors {
        switch self {
        case .midnight: PassColors(background: "#0A2540", foreground: "#FFFFFF", label: "#7AC0FF")
        case .sunrise:  PassColors(background: "#FFB347", foreground: "#1A1A1A", label: "#7A4500")
        case .forest:   PassColors(background: "#1F4D2B", foreground: "#FFFFFF", label: "#9CCFA8")
        case .slate:    PassColors(background: "#2B2D31", foreground: "#FFFFFF", label: "#B5B7BD")
        case .crimson:  PassColors(background: "#7A1F2B", foreground: "#FFFFFF", label: "#F2A1A8")
        }
    }
}

struct PassPalettePicker: View {
    @Binding var selection: PassPalette

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PassPalette.allCases) { palette in
                    PaletteSwatch(palette: palette, isSelected: palette == selection)
                        .onTapGesture { selection = palette }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct PaletteSwatch: View {
    let palette: PassPalette
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: palette.colors.background) ?? .gray)
                .frame(width: 56, height: 80)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                    }
                }
            Text(palette.displayName).font(.caption2)
        }
    }
}

extension Color {
    init?(hex: String) {
        var sanitized = hex
        if sanitized.hasPrefix("#") { sanitized.removeFirst() }
        guard sanitized.count == 6, let value = UInt32(sanitized, radix: 16) else {
            return nil
        }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }
}

#Preview {
    struct Wrapper: View {
        @State private var palette = PassPalette.midnight
        var body: some View { PassPalettePicker(selection: $palette).padding() }
    }
    return Wrapper()
}
