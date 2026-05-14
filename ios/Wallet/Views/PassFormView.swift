import SwiftData
import SwiftUI

struct PassFormView: View {
    let barcode: ScannedBarcode
    let onComplete: () -> Void

    @State private var label = ""
    @State private var passDescription = ""
    @State private var passType: PassType = .storeCard
    @State private var palette: PassPalette = .midnight
    @State private var passData: WalletPayload?
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    @Environment(\.passClient) private var passClient
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            Section("Card") {
                TextField("Label", text: $label)
                TextField("Description", text: $passDescription)
                Picker("Type", selection: $passType) {
                    ForEach(PassType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }

            Section("Color") {
                PassPalettePicker(selection: $palette)
            }

            Section("Barcode") {
                LabeledContent("Format", value: barcode.format.displayName)
                LabeledContent("Value", value: barcode.message)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("New Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { Task { await submit() } }
                    .disabled(!isFormValid || isSubmitting)
            }
        }
        .sheet(item: $passData) { payload in
            WalletAdderSheet(passData: payload.data) { outcome in
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

    private var isFormValid: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty
            && !passDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        let request = PassRequest(
            type: passType,
            label: label,
            description: passDescription,
            colors: palette.colors,
            barcode: PassBarcode(
                format: barcode.format,
                message: barcode.message,
                altText: nil
            )
        )

        do {
            let data = try await passClient.sign(request)
            passData = WalletPayload(data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistCard() {
        let card = Card(
            label: label,
            passDescription: passDescription,
            passType: passType,
            barcodeFormat: barcode.format,
            barcodeMessage: barcode.message,
            backgroundColor: palette.colors.background,
            foregroundColor: palette.colors.foreground,
            labelColor: palette.colors.label
        )
        modelContext.insert(card)
    }
}

struct WalletPayload: Identifiable {
    let id = UUID()
    let data: Data
}
