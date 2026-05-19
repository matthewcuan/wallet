import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var name: String
    var subtitle: String
    var kind: CardKind
    var paletteIndex: Int
    var barcodeFormat: BarcodeFormat
    var barcodeMessage: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        kind: CardKind,
        paletteIndex: Int,
        barcodeFormat: BarcodeFormat,
        barcodeMessage: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.kind = kind
        self.paletteIndex = paletteIndex
        self.barcodeFormat = barcodeFormat
        self.barcodeMessage = barcodeMessage
        self.createdAt = createdAt
    }
}

extension Card {
    var palette: PassPalette { PassPalette.at(paletteIndex) }
    var passType: PassType { kind.passType }

    func makeRequest() -> PassRequest {
        PassRequest(
            type: passType,
            label: name,
            description: subtitle.isEmpty ? kind.displayName : subtitle,
            colors: palette.colors,
            barcode: PassBarcode(format: barcodeFormat, message: barcodeMessage, altText: nil)
        )
    }
}
