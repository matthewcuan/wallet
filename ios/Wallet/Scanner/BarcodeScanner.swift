import SwiftUI
import Vision
import VisionKit

struct ScannedBarcode: Equatable {
    let format: BarcodeFormat
    let message: String
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onScan: (ScannedBarcode) -> Void
    let onUnsupported: (_ symbologyName: String) -> Void

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

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onUnsupported: onUnsupported)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (ScannedBarcode) -> Void
        let onUnsupported: (String) -> Void

        init(
            onScan: @escaping (ScannedBarcode) -> Void,
            onUnsupported: @escaping (String) -> Void
        ) {
            self.onScan = onScan
            self.onUnsupported = onUnsupported
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
                  let payload = barcode.payloadStringValue
            else { return }

            let symbology = barcode.observation.symbology
            if let format = BarcodeFormat(visionSymbology: symbology) {
                onScan(ScannedBarcode(format: format, message: payload))
            } else {
                onUnsupported(Self.displayName(for: symbology))
            }
        }

        // Wallet only accepts QR, PDF417, Aztec and Code 128; everything else
        // VisionKit can recognise gets surfaced to the user by name.
        static func displayName(for symbology: VNBarcodeSymbology) -> String {
            switch symbology {
            case .ean8: return "EAN-8"
            case .ean13: return "EAN-13"
            case .upce: return "UPC-E"
            case .code39, .code39Checksum, .code39FullASCII, .code39FullASCIIChecksum:
                return "Code 39"
            case .code93, .code93i: return "Code 93"
            case .dataMatrix: return "Data Matrix"
            case .codabar: return "Codabar"
            case .i2of5, .i2of5Checksum: return "Interleaved 2 of 5"
            case .itf14: return "ITF-14"
            case .microQR: return "Micro QR"
            case .microPDF417: return "Micro PDF417"
            case .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited: return "GS1 DataBar"
            default: return "This barcode"
            }
        }
    }
}
