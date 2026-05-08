import SwiftUI
import VisionKit

struct ScanView: View {
    let onScan: (ScannedBarcode) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeScannerView(onScan: onScan)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView(
                    "Camera unavailable",
                    systemImage: "camera.metering.unknown",
                    description: Text("Barcode scanning needs a real device with a working camera and camera permission.")
                )
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
