import Foundation
import Vision

enum BarcodeFormat: String, Codable, CaseIterable, Identifiable {
    case qr
    case pdf417
    case aztec
    case code128

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .qr: "QR"
        case .pdf417: "PDF417"
        case .aztec: "Aztec"
        case .code128: "Code 128"
        }
    }
}

extension BarcodeFormat {
    init?(visionSymbology symbology: VNBarcodeSymbology) {
        switch symbology {
        case .qr: self = .qr
        case .pdf417: self = .pdf417
        case .aztec: self = .aztec
        case .code128: self = .code128
        default: return nil
        }
    }
}
