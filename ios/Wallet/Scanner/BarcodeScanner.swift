import SwiftUI
import VisionKit

struct ScannedBarcode: Equatable {
    let format: BarcodeFormat
    let message: String
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onScan: (ScannedBarcode) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_: DataScannerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (ScannedBarcode) -> Void

        init(onScan: @escaping (ScannedBarcode) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(
            _: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            handle(item)
        }

        func dataScanner(
            _: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems _: [RecognizedItem]
        ) {
            if let first = addedItems.first { handle(first) }
        }

        private func handle(_ item: RecognizedItem) {
            guard case let .barcode(barcode) = item,
                  let payload = barcode.payloadStringValue,
                  let format = BarcodeFormat(visionSymbology: barcode.observation.symbology)
            else { return }
            onScan(ScannedBarcode(format: format, message: payload))
        }
    }
}
