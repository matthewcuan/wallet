import PassKit
import SwiftUI

enum WalletAdderError: Error {
    case unsupportedDevice
}

struct WalletAdderSheet: UIViewControllerRepresentable {
    let passData: Data
    let onComplete: (Result<Void, Error>) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        do {
            let pass = try PKPass(data: passData)
            guard let controller = PKAddPassesViewController(pass: pass) else {
                onComplete(.failure(WalletAdderError.unsupportedDevice))
                return UIViewController()
            }
            controller.delegate = context.coordinator
            return controller
        } catch {
            onComplete(.failure(error))
            return UIViewController()
        }
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    final class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
        let onComplete: (Result<Void, Error>) -> Void

        init(onComplete: @escaping (Result<Void, Error>) -> Void) {
            self.onComplete = onComplete
        }

        func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
            controller.dismiss(animated: true)
            onComplete(.success(()))
        }
    }
}
