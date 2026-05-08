import Foundation

struct PassRequest: Codable, Equatable {
    let type: PassType
    let label: String
    let description: String
    let colors: PassColors
    let barcode: PassBarcode
}

struct PassColors: Codable, Equatable {
    let background: String
    let foreground: String
    let label: String
}

struct PassBarcode: Codable, Equatable {
    let format: BarcodeFormat
    let message: String
    let altText: String?
}
