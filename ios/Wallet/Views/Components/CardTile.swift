import SwiftUI

struct CardTile: View {
    let card: Card
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            tileBody
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.name), \(card.kind.displayName)")
        .accessibilityAddTraits(.isButton)
    }

    private var tileBody: some View {
        let palette = card.palette
        return ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Text(card.kind.displayName.uppercased())
                    .font(.stash(10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(palette.foreground.opacity(0.65))

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.stash(19, weight: .bold))
                        .tracking(-0.3)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(palette.foreground)
                    if !card.subtitle.isEmpty {
                        Text(card.subtitle)
                            .font(.stash(12))
                            .foregroundStyle(palette.foreground.opacity(0.65))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)

            CodeTypeBadge(format: card.barcodeFormat, tint: palette.foreground)
                .padding(14)
        }
        .background(palette.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .aspectRatio(1 / 1.18, contentMode: .fit)
        .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 4)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

struct CodeTypeBadge: View {
    let format: BarcodeFormat
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.14))
            Image(systemName: format.isMatrix ? "qrcode" : "barcode")
                .font(.system(size: 13))
                .foregroundStyle(tint.opacity(0.9))
        }
        .frame(width: 28, height: 28)
    }
}
