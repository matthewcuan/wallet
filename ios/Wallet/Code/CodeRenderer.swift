import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

// Renders a real (not faux) barcode or QR using CIFilter. Returns a SwiftUI
// Image with nearest-neighbour interpolation so the bars/cells stay crisp at
// any size. Returns nil only if CoreImage fails to encode the message.
enum CodeRenderer {
    private static let context = CIContext()

    static func image(for format: BarcodeFormat, message: String, scale: CGFloat = 10) -> Image? {
        guard let cgImage = cgImage(for: format, message: message, scale: scale) else {
            return nil
        }
        return Image(uiImage: UIImage(cgImage: cgImage))
            .interpolation(.none)
            .resizable()
    }

    private static func cgImage(for format: BarcodeFormat, message: String, scale: CGFloat) -> CGImage? {
        let data = Data(message.utf8)
        let output: CIImage?
        switch format {
        case .qr:
            let f = CIFilter.qrCodeGenerator()
            f.message = data
            f.correctionLevel = "M"
            output = f.outputImage
        case .aztec:
            let f = CIFilter.aztecCodeGenerator()
            f.message = data
            output = f.outputImage
        case .pdf417:
            let f = CIFilter.pdf417BarcodeGenerator()
            f.message = data
            output = f.outputImage
        case .code128:
            let f = CIFilter.code128BarcodeGenerator()
            f.message = data
            f.quietSpace = 7
            output = f.outputImage
        }
        guard let ci = output else { return nil }
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return context.createCGImage(scaled, from: scaled.extent)
    }
}
