import PassKit
import SwiftUI

enum WalletAdderError: Error {
    case unsupportedDevice
}

enum WalletAdderOutcome {
    case added
    case cancelled
    case failed(Error)
}

struct WalletAdderSheet: UIViewControllerRepresentable {
    let passData: Data
    let onComplete: (WalletAdderOutcome) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        do {
            let pass = try PKPass(data: passData)
            guard let controller = PKAddPassesViewController(pass: pass) else {
                onComplete(.failed(WalletAdderError.unsupportedDevice))
                return UIViewController()
            }
            controller.delegate = context.coordinator
            return controller
        } catch {
            onComplete(.failed(error))
            return UIViewController()
        }
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    final class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
        let onComplete: (WalletAdderOutcome) -> Void
        private var libraryDidChange = false
        private var observer: NSObjectProtocol?

        init(onComplete: @escaping (WalletAdderOutcome) -> Void) {
            self.onComplete = onComplete
            super.init()
            // `PKPassLibrary().containsPass(_:)` is unreliable without a matching
            // pass-type-identifiers entitlement (PassSlot passes use their Pass
            // Type ID, not ours). The library-change notification fires only on
            // an actual install, so it gives us a trustworthy Add-vs-Cancel signal.
            observer = NotificationCenter.default.addObserver(
                forName: Notification.Name(rawValue: "PKPassLibraryDidChangeNotification"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.libraryDidChange = true
            }
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        // Don't call `controller.dismiss` here — PKAddPassesViewController has
        // already dismissed itself, so doing it again pops the next sheet up the
        // stack (the scan flow), closing the Add Card form on cancel.
        // SwiftUI dismisses our wrapping sheet when the binding clears.
        func addPassesViewControllerDidFinish(_: PKAddPassesViewController) {
            onComplete(libraryDidChange ? .added : .cancelled)
        }
    }
}
