import SwiftUI

struct ScanFlow: View {
    @State private var scanned: ScannedBarcode?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let scanned {
                PassFormView(barcode: scanned, onComplete: { dismiss() })
            } else {
                ScanView { scanned = $0 }
            }
        }
    }
}
