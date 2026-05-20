import SwiftUI
import UIKit

struct ManualEntryView: View {
    let onContinue: (ScannedBarcode) -> Void

    @State private var format: BarcodeFormat = .qr
    @State private var value: String = ""
    @FocusState private var valueFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var trimmedValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var renderedImage: Image? {
        guard !trimmedValue.isEmpty else { return nil }
        return CodeRenderer.image(for: format, message: trimmedValue)
    }

    private var canContinue: Bool {
        !trimmedValue.isEmpty && renderedImage != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 18) {
                    previewPanel
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    formatSection
                    valueSection
                    helpText
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }
        }
        .background(Color.stashBackground.ignoresSafeArea())
        .onAppear { valueFocused = true }
    }

    private var topBar: some View {
        HStack {
            Button("Cancel", action: { dismiss() })
                .font(.stash(15, weight: .medium))
                .foregroundStyle(Color.stashInk.opacity(0.55))

            Spacer()

            Text("NEW CARD")
                .font(.stash(13, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color.stashInk.opacity(0.5))

            Spacer()

            Button("Continue") { handleContinue() }
                .font(.stash(15, weight: .semibold))
                .foregroundStyle(canContinue ? Color.stashCoral : Color.stashInk.opacity(0.3))
                .disabled(!canContinue)
        }
        .padding(.horizontal, 18)
        .padding(.top, 60)
        .padding(.bottom, 14)
    }

    private var previewPanel: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)

                Group {
                    if trimmedValue.isEmpty {
                        previewPlaceholder
                    } else if let image = renderedImage {
                        image
                            .aspectRatio(format.isMatrix ? 1 : 3.2, contentMode: .fit)
                            .frame(maxWidth: format.isMatrix ? 200 : .infinity)
                            .frame(maxHeight: format.isMatrix ? 200 : 110)
                            .padding(.horizontal, format.isMatrix ? 0 : 16)
                    } else {
                        previewEncodingError
                    }
                }
                .padding(22)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }

    private var previewPlaceholder: some View {
        VStack(spacing: 6) {
            Image(systemName: format.isMatrix ? "qrcode" : "barcode")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Color.stashInk.opacity(0.25))
            Text("Type a value to see a preview")
                .font(.stash(13))
                .foregroundStyle(Color.stashInk.opacity(0.45))
        }
    }

    private var previewEncodingError: some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(Color.stashCoral.opacity(0.85))
            Text("Can't encode as \(format.displayName).")
                .font(.stash(13, weight: .medium))
                .foregroundStyle(Color.stashInk)
            Text("Try a different format or a shorter value.")
                .font(.stash(12))
                .foregroundStyle(Color.stashInk.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }

    private var formatSection: some View {
        Section(label: "Format") {
            Picker("Format", selection: $format) {
                ForEach(BarcodeFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var valueSection: some View {
        Section(label: "Code value") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("e.g. MEMBER-12345", text: $value, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.stashMono(14))
                    .foregroundStyle(Color.stashInk)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($valueFocused)

                HStack(spacing: 8) {
                    Spacer()
                    if !value.isEmpty {
                        Button("Clear", action: { value = "" })
                            .font(.stash(13, weight: .medium))
                            .foregroundStyle(Color.stashInk.opacity(0.5))
                    }
                    Button(action: pasteFromClipboard) {
                        Label("Paste", systemImage: "doc.on.clipboard")
                            .font(.stash(13, weight: .semibold))
                            .foregroundStyle(Color.stashCoral)
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
            )
        }
    }

    private var helpText: some View {
        Text("Wallet only supports QR, PDF417, Aztec, and Code 128.")
            .font(.stash(12))
            .foregroundStyle(Color.stashInk.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func pasteFromClipboard() {
        guard let pasted = UIPasteboard.general.string else { return }
        value = pasted
    }

    private func handleContinue() {
        let trimmed = trimmedValue
        guard !trimmed.isEmpty, renderedImage != nil else { return }
        onContinue(ScannedBarcode(format: format, message: trimmed))
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
