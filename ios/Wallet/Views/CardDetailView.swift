import SwiftData
import SwiftUI

struct CardDetailView: View {
    let card: Card

    @Environment(\.passClient) private var passClient
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var draftName: String
    @State private var draftKind: CardKind
    @State private var draftPaletteIndex: Int

    @State private var brightenScreen = false
    @State private var showMenu = false
    @State private var passData: WalletPayload?
    @State private var errorMessage: String?
    @State private var isReissuing = false

    init(card: Card) {
        self.card = card
        _draftName = State(initialValue: card.name)
        _draftKind = State(initialValue: card.kind)
        _draftPaletteIndex = State(initialValue: card.paletteIndex)
    }

    private var palette: PassPalette { card.palette }

    private var isDraftValid: Bool {
        !draftName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            (brightenScreen ? Color.white : Color.stashBackground)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.2), value: brightenScreen)

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    if isEditing {
                        editingBody
                    } else {
                        viewingBody
                    }
                }
            }

            if showMenu {
                menuOverlay
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $passData) { payload in
            WalletAdderSheet(passData: payload.data) { outcome in
                passData = nil
                if case .failed(let error) = outcome {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            RoundIconButton(systemName: "chevron.left", action: { dismiss() })
            Spacer()
            Text(card.kind.displayName.uppercased())
                .font(.stash(13, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color.stashInk.opacity(0.5))
            Spacer()
            if isEditing {
                Button("Save") { saveEdits() }
                    .font(.stash(15, weight: .semibold))
                    .foregroundStyle(isDraftValid ? Color.stashCoral : Color.stashInk.opacity(0.3))
                    .disabled(!isDraftValid)
            } else {
                RoundIconButton(systemName: "ellipsis", action: { withAnimation { showMenu.toggle() } })
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    // MARK: - Viewing body

    private var viewingBody: some View {
        VStack(spacing: 22) {
            // Color block header
            VStack(alignment: .leading, spacing: 0) {
                Text(card.kind.displayName.uppercased())
                    .font(.stash(11, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(palette.foreground.opacity(0.65))
                    .padding(.bottom, 8)
                Text(card.name)
                    .font(.stash(28, weight: .bold))
                    .tracking(-0.7)
                    .foregroundStyle(palette.foreground)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.stash(14))
                        .foregroundStyle(palette.foreground.opacity(0.7))
                        .padding(.top, 6)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(palette.background)
            )

            // Code panel
            VStack(spacing: 16) {
                codeImage
                    .frame(maxWidth: .infinity)

                Text(card.barcodeMessage)
                    .font(.stashMono(14))
                    .tracking(1.5)
                    .foregroundStyle(Color.stashInk)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            )

            // Help text + brighten toggle
            HStack(spacing: 4) {
                Text("Hold up the screen at the register. Tap")
                    .foregroundStyle(Color.stashInk.opacity(0.5))
                Button(action: { brightenScreen.toggle() }) {
                    Text(brightenScreen ? "dim screen" : "brighten screen")
                        .foregroundStyle(Color.stashCoral)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                Text("for easier scanning.")
                    .foregroundStyle(Color.stashInk.opacity(0.5))
            }
            .font(.stash(13))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, -4)

            if let errorMessage {
                Text(errorMessage)
                    .font(.stash(13))
                    .foregroundStyle(Color.stashCoral)
                    .padding(.horizontal, 4)
            }

            Button(action: { Task { await reissue() } }) {
                Label("Re-add to Wallet", systemImage: "wallet.pass")
                    .font(.stash(15, weight: .semibold))
                    .foregroundStyle(Color.stashCream)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule(style: .continuous).fill(Color.stashInk)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isReissuing)
            .padding(.top, 4)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private var codeImage: some View {
        let format = card.barcodeFormat
        if let image = CodeRenderer.image(for: format, message: card.barcodeMessage) {
            image
                .aspectRatio(format.isMatrix ? 1 : 3.2, contentMode: .fit)
                .frame(maxWidth: format.isMatrix ? 220 : .infinity)
                .frame(maxHeight: format.isMatrix ? 220 : 110)
        } else {
            Text("Could not render code")
                .font(.stash(13))
                .foregroundStyle(Color.stashInk.opacity(0.5))
                .padding()
        }
    }

    // MARK: - Editing body

    private var editingBody: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(.stash(11, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Color.stashInk.opacity(0.45))
                    .padding(.horizontal, 4)
                TextField("Card name", text: $draftName)
                    .font(.stash(16))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14).fill(Color.white)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("TYPE")
                    .font(.stash(11, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Color.stashInk.opacity(0.45))
                    .padding(.horizontal, 4)
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(CardKind.allCases) { option in
                        Button(action: { draftKind = option }) {
                            Text(option.displayName)
                                .font(.stash(13, weight: .medium))
                                .foregroundStyle(option == draftKind ? Color.stashCream : Color.stashInk)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(option == draftKind ? Color.stashInk : Color.white)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("COLOR")
                    .font(.stash(11, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Color.stashInk.opacity(0.45))
                    .padding(.horizontal, 4)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8),
                    spacing: 8
                ) {
                    ForEach(PassPalette.allCases) { p in
                        Button(action: { draftPaletteIndex = p.index }) {
                            Circle()
                                .fill(p.background)
                                .overlay {
                                    if p.index == draftPaletteIndex {
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
                    RoundedRectangle(cornerRadius: 14).fill(Color.white)
                )
            }

            Button(action: cancelEditing) {
                Text("Cancel")
                    .font(.stash(15, weight: .medium))
                    .foregroundStyle(Color.stashInk.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(Color.stashInk.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    // MARK: - Menu

    private var menuOverlay: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showMenu = false } }

            VStack(spacing: 0) {
                Button {
                    showMenu = false
                    isEditing = true
                } label: {
                    menuRow(label: "Edit card", color: Color.stashInk)
                }
                Divider()
                Button(role: .destructive, action: deleteCard) {
                    menuRow(label: "Delete card", color: Color.stashCoral)
                }
            }
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 10)
            )
            .padding(.top, 102)
            .padding(.trailing, 18)
        }
        .transition(.opacity)
    }

    private func menuRow(label: String, color: Color) -> some View {
        Text(label)
            .font(.stash(15, weight: .medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func saveEdits() {
        card.name = draftName.trimmingCharacters(in: .whitespaces)
        card.kind = draftKind
        card.paletteIndex = draftPaletteIndex
        card.subtitle = draftKind.displayName
        isEditing = false
    }

    private func cancelEditing() {
        draftName = card.name
        draftKind = card.kind
        draftPaletteIndex = card.paletteIndex
        isEditing = false
    }

    private func deleteCard() {
        modelContext.delete(card)
        dismiss()
    }

    private func reissue() async {
        isReissuing = true
        defer { isReissuing = false }
        do {
            let data = try await passClient.sign(card.makeRequest())
            passData = WalletPayload(data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct RoundIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.stashInk)
                .frame(width: 38, height: 38)
                .background(
                    Circle().fill(Color.stashInk.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }
}
