import SwiftData
import SwiftUI

@main
struct WalletApp: App {
    // Update to your Mac's LAN IP when running on a physical device.
    // Localhost works on the iOS simulator; ATS allows it via
    // NSAllowsLocalNetworking in Info.plist (see ios/project.yml).
    private let passClient: any PassClient = LivePassClient(
        baseURL: URL(string: "http://localhost:3000")!
    )

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.passClient, passClient)
                .background(Color.stashBackground.ignoresSafeArea())
                .tint(Color.stashCoral)
        }
        .modelContainer(for: Card.self)
    }
}
