import SwiftUI

struct ManualEntryFlow: View {
    @State private var payload: ScannedBarcode?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if let payload {
                PassFormView(barcode: payload, onComplete: { dismiss() })
                    .transition(.opacity)
            } else {
                ManualEntryView(onContinue: { payload = $0 })
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: payload)
    }
}
