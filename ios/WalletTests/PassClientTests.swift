import XCTest
@testable import Wallet

final class PassClientTests: XCTestCase {
    private let validRequest = PassRequest(
        type: .storeCard,
        label: "Coffee",
        description: "Loyalty card",
        colors: PassColors(background: "#000000", foreground: "#FFFFFF", label: "#888888"),
        barcode: PassBarcode(format: .qr, message: "abc-123", altText: nil)
    )

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testPostsJSONBodyAndReturnsPassData() async throws {
        var observed: URLRequest?
        MockURLProtocol.handler = { request in
            observed = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/vnd.apple.pkpass"]
            )!
            return (response, Data("PASS_BYTES".utf8))
        }

        let client = LivePassClient(
            baseURL: URL(string: "http://example.com")!,
            session: makeSession()
        )

        let data = try await client.sign(validRequest)
        XCTAssertEqual(data, Data("PASS_BYTES".utf8))

        let request = try XCTUnwrap(observed)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/pass")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(readBody(request))
        let decoded = try JSONDecoder().decode(PassRequest.self, from: body)
        XCTAssertEqual(decoded, validRequest)
    }

    func testThrowsServerErrorOnNon2xx() async {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("bad request".utf8))
        }

        let client = LivePassClient(
            baseURL: URL(string: "http://example.com")!,
            session: makeSession()
        )

        do {
            _ = try await client.sign(validRequest)
            XCTFail("expected serverError")
        } catch let PassClientError.serverError(status, body) {
            XCTAssertEqual(status, 400)
            XCTAssertEqual(body, Data("bad request".utf8))
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
