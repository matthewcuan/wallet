import SwiftData
import SwiftUI

struct CardDetailView: View {
    let card: Card

    @Environment(\.passClient) private var passClient
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var passData: WalletPayload?
    @State private var errorMessage: String?
    @State private var isReissuing = false

    var body: some View {
        Form {
            Section("Pass") {
                LabeledContent("Label", value: card.label)
                LabeledContent("Description", value: card.passDescription)
                LabeledContent("Type", value: card.passType.displayName)
                LabeledContent(
                    "Created",
                    value: card.createdAt.formatted(date: .abbreviated, time: .shortened)
                )
            }

            Section("Barcode") {
                LabeledContent("Format", value: card.barcodeFormat.displayName)
                LabeledContent("Value", value: card.barcodeMessage)
            }

            Section {
                Button("Re-add to Wallet") {
                    Task { await reissue() }
                }
                .disabled(isReissuing)

                Button("Delete card", role: .destructive) {
                    modelContext.delete(card)
                    dismiss()
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(card.label)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $passData) { payload in
            WalletAdderSheet(passData: payload.data) { _ in
                passData = nil
            }
        }
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
