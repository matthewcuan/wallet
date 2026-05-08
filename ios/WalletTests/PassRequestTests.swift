import XCTest
@testable import Wallet

final class PassRequestTests: XCTestCase {
    func testEncodesExpectedKeysAndValues() throws {
        let request = PassRequest(
            type: .storeCard,
            label: "Coffee",
            description: "Loyalty card",
            colors: PassColors(background: "#0A2540", foreground: "#FFFFFF", label: "#7AC0FF"),
            barcode: PassBarcode(format: .qr, message: "abc-123", altText: "abc")
        )

        let data = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["type"] as? String, "storeCard")
        XCTAssertEqual(json["label"] as? String, "Coffee")
        XCTAssertEqual(json["description"] as? String, "Loyalty card")

        let colors = try XCTUnwrap(json["colors"] as? [String: String])
        XCTAssertEqual(colors["background"], "#0A2540")
        XCTAssertEqual(colors["foreground"], "#FFFFFF")
        XCTAssertEqual(colors["label"], "#7AC0FF")

        let barcode = try XCTUnwrap(json["barcode"] as? [String: Any])
        XCTAssertEqual(barcode["format"] as? String, "qr")
        XCTAssertEqual(barcode["message"] as? String, "abc-123")
        XCTAssertEqual(barcode["altText"] as? String, "abc")
    }

    func testRoundTripsThroughDecoder() throws {
        let original = PassRequest(
            type: .generic,
            label: "Library",
            description: "Membership",
            colors: PassColors(background: "#000000", foreground: "#FFFFFF", label: "#CCCCCC"),
            barcode: PassBarcode(format: .code128, message: "1234567890", altText: nil)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PassRequest.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testOmitsAltTextWhenNil() throws {
        let request = PassRequest(
            type: .coupon,
            label: "Promo",
            description: "10% off",
            colors: PassColors(background: "#000000", foreground: "#FFFFFF", label: "#CCCCCC"),
            barcode: PassBarcode(format: .aztec, message: "PROMO-2026", altText: nil)
        )

        let data = try JSONEncoder().encode(request)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let barcode = try XCTUnwrap(json["barcode"] as? [String: Any])
        XCTAssertNil(barcode["altText"])
    }
}
