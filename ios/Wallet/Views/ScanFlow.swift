import SwiftUI

struct ScanFlow: View {
    @State private var scanned: ScannedBarcode?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if let scanned {
                PassFormView(barcode: scanned, onComplete: { dismiss() })
                    .transition(.opacity)
            } else {
                ScanView(onScan: { scanned = $0 })
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: scanned)
    }
}
