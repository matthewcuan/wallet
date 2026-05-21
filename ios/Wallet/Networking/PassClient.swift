import Foundation
import SwiftUI

protocol PassClient {
    func sign(_ request: PassRequest) async throws -> Data
}

enum PassClientError: Error, Equatable {
    case invalidResponse
    case serverError(status: Int, body: Data)
}

struct LivePassClient: PassClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func sign(_ request: PassRequest) async throws -> Data {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("pass"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/vnd.apple.pkpass", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw PassClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PassClientError.serverError(status: http.statusCode, body: data)
        }
        return data
    }
}

private struct PassClientKey: EnvironmentKey {
    static let defaultValue: any PassClient = LivePassClient(
        baseURL: URL(string: "http://localhost:3000")!
    )
}

extension EnvironmentValues {
    var passClient: any PassClient {
        get { self[PassClientKey.self] }
        set { self[PassClientKey.self] = newValue }
    }
}

private struct EntitledPassTypeIdentifiersKey: EnvironmentKey {
    static let defaultValue: Set<String> = []
}

extension EnvironmentValues {
    /// Pass-type identifiers (e.g. `pass.com.yourname.wallet`) for which this
    /// build holds the matching Apple-issued Pass Type ID entitlement. Used by
    /// `WalletAdderSheet` to enable reliable Add/Cancel detection. Leave empty
    /// when relying solely on a third-party signer like PassSlot.
    var entitledPassTypeIdentifiers: Set<String> {
        get { self[EntitledPassTypeIdentifiersKey.self] }
        set { self[EntitledPassTypeIdentifiersKey.self] = newValue }
    }
}
