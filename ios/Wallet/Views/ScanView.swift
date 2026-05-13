import SwiftUI
import VisionKit

struct ScanView: View {
    let onScan: (ScannedBarcode) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var unsupportedMessage: String?

    var body: some View {
        Group {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeScannerView(
                    onScan: onScan,
                    onUnsupported: { name in
                        unsupportedMessage = "\(name) isn't supported by Apple Wallet. Try a QR, PDF417, Aztec, or Code 128 barcode."
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .bottom) {
                    if let unsupportedMessage {
                        Text(unsupportedMessage)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.25), value: unsupportedMessage)
                .task(id: unsupportedMessage) {
                    guard unsupportedMessage != nil else { return }
                    try? await Task.sleep(for: .seconds(3))
                    if !Task.isCancelled { unsupportedMessage = nil }
                }
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
