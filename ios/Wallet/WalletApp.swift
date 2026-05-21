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

    // Pass-type identifiers this build is entitled to sign for. Leave empty
    // when relying on PassSlot (their Pass Type ID isn't ours, so we can't
    // observe library changes for it). Once you've enrolled in the Apple
    // Developer Program and added your Pass Type ID to the app's entitlements,
    // add the identifier here, e.g. ["pass.com.yourname.wallet"].
    private let entitledPassTypeIdentifiers: Set<String> = []

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.passClient, passClient)
                .environment(\.entitledPassTypeIdentifiers, entitledPassTypeIdentifiers)
                .background(Color.stashBackground.ignoresSafeArea())
                .tint(Color.stashCoral)
        }
        .modelContainer(for: Card.self)
    }
}
