import XCTest
@testable import Wallet

final class CodeRendererTests: XCTestCase {
    func testRendersImageForEachSupportedFormat() {
        for format in BarcodeFormat.allCases {
            let image = CodeRenderer.image(for: format, message: "HELLO-12345")
            XCTAssertNotNil(
                image,
                "Expected CodeRenderer to produce an image for \(format.displayName) with an ASCII payload."
            )
        }
    }

    func testReturnsNilForEmptyMessageOnLinearFormats() {
        // CIFilter's Code 128 generator rejects empty messages; QR and Aztec
        // accept them. We only assert the behaviour we control — empty values
        // shouldn't reach the renderer in production because the form blocks
        // Continue while the value is empty.
        XCTAssertNil(CodeRenderer.image(for: .code128, message: ""))
    }
}
