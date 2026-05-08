import Vision
import XCTest
@testable import Wallet

final class BarcodeFormatTests: XCTestCase {
    func testKnownSymbologiesMap() {
        XCTAssertEqual(BarcodeFormat(visionSymbology: .qr), .qr)
        XCTAssertEqual(BarcodeFormat(visionSymbology: .pdf417), .pdf417)
        XCTAssertEqual(BarcodeFormat(visionSymbology: .aztec), .aztec)
        XCTAssertEqual(BarcodeFormat(visionSymbology: .code128), .code128)
    }

    func testUnsupportedSymbologyReturnsNil() {
        XCTAssertNil(BarcodeFormat(visionSymbology: .ean13))
    }

    func testRawValueRoundTrip() throws {
        for format in BarcodeFormat.allCases {
            let data = try JSONEncoder().encode(format)
            let decoded = try JSONDecoder().decode(BarcodeFormat.self, from: data)
            XCTAssertEqual(decoded, format)
        }
    }
}
