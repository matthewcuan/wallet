import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var label: String
    var passDescription: String
    var passType: PassType
    var barcodeFormat: BarcodeFormat
    var barcodeMessage: String
    var backgroundColor: String
    var foregroundColor: String
    var labelColor: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String,
        passDescription: String,
        passType: PassType,
        barcodeFormat: BarcodeFormat,
        barcodeMessage: String,
        backgroundColor: String,
        foregroundColor: String,
        labelColor: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.label = label
        self.passDescription = passDescription
        self.passType = passType
        self.barcodeFormat = barcodeFormat
        self.barcodeMessage = barcodeMessage
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.labelColor = labelColor
        self.createdAt = createdAt
    }
}

extension Card {
    var passColors: PassColors {
        PassColors(
            background: backgroundColor,
            foreground: foregroundColor,
            label: labelColor
        )
    }

    func makeRequest() -> PassRequest {
        PassRequest(
            type: passType,
            label: label,
            description: passDescription,
            colors: passColors,
            barcode: PassBarcode(format: barcodeFormat, message: barcodeMessage, altText: nil)
        )
    }
}
