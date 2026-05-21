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
    /// Pass-type identifiers the app holds entitlements for. When the parsed
    /// pass's type ID matches one of these, the coordinator uses
    /// PKPassLibraryDidChange to distinguish Add from Cancel. For everything
    /// else (e.g. PassSlot's `pass.slot.generic`) we can't observe the library,
    /// so any finish is reported as `.added`.
    let entitledPassTypeIdentifiers: Set<String>
    let onComplete: (WalletAdderOutcome) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        do {
            let pass = try PKPass(data: passData)
            guard let controller = PKAddPassesViewController(pass: pass) else {
                onComplete(.failed(WalletAdderError.unsupportedDevice))
                return UIViewController()
            }
            controller.delegate = context.coordinator
            context.coordinator.observesLibrary =
                entitledPassTypeIdentifiers.contains(pass.passTypeIdentifier ?? "")
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
        var observesLibrary = false
        private var libraryDidChange = false
        private var observer: NSObjectProtocol?

        init(onComplete: @escaping (WalletAdderOutcome) -> Void) {
            self.onComplete = onComplete
            super.init()
            observer = NotificationCenter.default.addObserver(
                forName: PKPassLibrary.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.libraryDidChange = true
            }
        }

        deinit {
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }

        func addPassesViewControllerDidFinish(_: PKAddPassesViewController) {
            if observesLibrary {
                onComplete(libraryDidChange ? .added : .cancelled)
            } else {
                onComplete(.added)
            }
        }
    }
}
