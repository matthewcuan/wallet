import SwiftData
import SwiftUI

struct PassFormView: View {
    let barcode: ScannedBarcode
    let onComplete: () -> Void

    @State private var name = ""
    @State private var kind: CardKind = .loyalty
    @State private var paletteIndex: Int = 0

    @State private var passData: WalletPayload?
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    @Environment(\.passClient) private var passClient
    @Environment(\.entitledPassTypeIdentifiers) private var entitledPassTypeIdentifiers
    @Environment(\.modelContext) private var modelContext

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    private var palette: PassPalette { PassPalette.at(paletteIndex) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 18) {
                    previewCard
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    nameSection
                    typeSection
                    colorSection
                    scannedCodeSection
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.stash(13))
                            .foregroundStyle(Color.stashCoral)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .background(Color.stashBackground.ignoresSafeArea())
        .sheet(item: $passData) { payload in
            WalletAdderSheet(
                passData: payload.data,
                entitledPassTypeIdentifiers: entitledPassTypeIdentifiers
            ) { outcome in
                passData = nil
                switch outcome {
                case .added:
                    persistCard()
                    onComplete()
                case .cancelled:
                    break
                case .failed(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button("Cancel", action: onComplete)
                .font(.stash(15, weight: .medium))
                .foregroundStyle(Color.stashInk.opacity(0.55))

            Spacer()

            Text("NEW CARD")
                .font(.stash(13, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color.stashInk.opacity(0.5))

            Spacer()

            Button("Save") { Task { await submit() } }
                .font(.stash(15, weight: .semibold))
                .foregroundStyle(canSave ? Color.stashCoral : Color.stashInk.opacity(0.3))
                .disabled(!canSave)
        }
        .padding(.horizontal, 18)
        .padding(.top, 60)
        .padding(.bottom, 14)
    }

    private var previewCard: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(kind.displayName.uppercased())
                        .font(.stash(10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(palette.foreground.opacity(0.65))
                    Spacer(minLength: 0)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(name.isEmpty ? "Untitled" : name)
                            .font(.stash(19, weight: .bold))
                            .tracking(-0.3)
                            .lineLimit(2)
                            .foregroundStyle(palette.foreground)
                        Text(barcode.message)
                            .font(.stashMono(11))
                            .lineLimit(1)
                            .foregroundStyle(palette.foreground.opacity(0.55))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                CodeTypeBadge(format: barcode.format, tint: palette.foreground)
                    .padding(14)
            }
            .background(palette.background)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .aspectRatio(1 / 1.18, contentMode: .fit)
            .shadow(color: .black.opacity(0.12), radius: 30, x: 0, y: 10)
        }
        .frame(maxWidth: 220)
        .frame(maxWidth: .infinity)
    }

    private var nameSection: some View {
        Section(label: "Name") {
            TextField("e.g. Daily Brew", text: $name)
                .font(.stash(16))
                .foregroundStyle(Color.stashInk)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
                .submitLabel(.done)
                .autocorrectionDisabled()
        }
    }

    private var typeSection: some View {
        Section(label: "Type") {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach(CardKind.allCases) { option in
                    Button(action: { kind = option }) {
                        Text(option.displayName)
                            .font(.stash(13, weight: .medium))
                            .foregroundStyle(option == kind ? Color.stashCream : Color.stashInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(option == kind ? Color.stashInk : Color.white)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colorSection: some View {
        Section(label: "Color") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8),
                spacing: 8
            ) {
                ForEach(PassPalette.allCases) { p in
                    Button(action: { paletteIndex = p.index }) {
                        Circle()
                            .fill(p.background)
                            .overlay {
                                if p.index == paletteIndex {
                                    Circle()
                                        .strokeBorder(Color.stashInk, lineWidth: 2)
                                        .padding(-3)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
            )
        }
    }

    private var scannedCodeSection: some View {
        Section(label: "Scanned code") {
            Text(barcode.message)
                .font(.stashMono(13))
                .foregroundStyle(Color.stashInk)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let request = PassRequest(
            type: kind.passType,
            label: trimmedName,
            description: kind.displayName,
            colors: palette.colors,
            barcode: PassBarcode(format: barcode.format, message: barcode.message, altText: nil)
        )

        do {
            let data = try await passClient.sign(request)
            passData = WalletPayload(data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistCard() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let card = Card(
            name: trimmedName,
            subtitle: kind.displayName,
            kind: kind,
            paletteIndex: paletteIndex,
            barcodeFormat: barcode.format,
            barcodeMessage: barcode.message
        )
        modelContext.insert(card)
    }
}

private struct Section<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.stash(11, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(Color.stashInk.opacity(0.45))
                .padding(.horizontal, 4)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WalletPayload: Identifiable {
    let id = UUID()
    let data: Data
}
