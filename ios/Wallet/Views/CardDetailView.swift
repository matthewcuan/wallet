import SwiftData
import SwiftUI

struct CardDetailView: View {
    let card: Card

    @State private var isEditing = false
    @State private var draftLabel: String
    @State private var draftDescription: String
    @State private var draftPassType: PassType
    @State private var draftPalette: PassPalette

    @State private var passData: WalletPayload?
    @State private var errorMessage: String?
    @State private var isReissuing = false

    @Environment(\.passClient) private var passClient
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(card: Card) {
        self.card = card
        _draftLabel = State(initialValue: card.label)
        _draftDescription = State(initialValue: card.passDescription)
        _draftPassType = State(initialValue: card.passType)
        _draftPalette = State(initialValue: PassPalette.matching(card.passColors) ?? .midnight)
    }

    var body: some View {
        Form {
            if isEditing {
                editingSections
            } else {
                viewingSections
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Card" : card.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(item: $passData) { payload in
            WalletAdderSheet(passData: payload.data) { _ in
                passData = nil
            }
        }
    }

    @ViewBuilder
    private var viewingSections: some View {
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
    }

    @ViewBuilder
    private var editingSections: some View {
        Section("Pass") {
            TextField("Label", text: $draftLabel)
            TextField("Description", text: $draftDescription)
            Picker("Type", selection: $draftPassType) {
                ForEach(PassType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
        }

        Section("Color") {
            PassPalettePicker(selection: $draftPalette)
        }

        Section("Barcode") {
            LabeledContent("Format", value: card.barcodeFormat.displayName)
            LabeledContent("Value", value: card.barcodeMessage)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { cancelEditing() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveEdits() }
                    .disabled(!isDraftValid)
            }
        } else {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
            }
        }
    }

    private var isDraftValid: Bool {
        !draftLabel.trimmingCharacters(in: .whitespaces).isEmpty
            && !draftDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func cancelEditing() {
        draftLabel = card.label
        draftDescription = card.passDescription
        draftPassType = card.passType
        draftPalette = PassPalette.matching(card.passColors) ?? .midnight
        isEditing = false
    }

    private func saveEdits() {
        card.label = draftLabel.trimmingCharacters(in: .whitespaces)
        card.passDescription = draftDescription.trimmingCharacters(in: .whitespaces)
        card.passType = draftPassType
        card.backgroundColor = draftPalette.colors.background
        card.foregroundColor = draftPalette.colors.foreground
        card.labelColor = draftPalette.colors.label
        isEditing = false
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
