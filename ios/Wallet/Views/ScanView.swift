import AVFoundation
import SwiftUI
import VisionKit

struct ScanView: View {
    let onScan: (ScannedBarcode) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var foundBarcode: ScannedBarcode?
    @State private var unsupportedMessage: String?
    @State private var torchOn = false

    private let viewfinderSize: CGFloat = 250

    var body: some View {
        ZStack {
            cameraLayer

            DimMask(viewfinderSize: viewfinderSize)
                .allowsHitTesting(false)

            ViewfinderFrame(
                size: viewfinderSize,
                color: foundBarcode == nil ? .white : Color.stashSuccess
            )
            .allowsHitTesting(false)

            if foundBarcode == nil {
                ScanLine(extent: viewfinderSize - 20)
                    .frame(width: viewfinderSize - 24, height: viewfinderSize)
                    .allowsHitTesting(false)
            }

            if foundBarcode != nil {
                SuccessGlyph()
                    .transition(.scale.combined(with: .opacity))
            }

            VStack {
                topBar
                Spacer()
                instructionStack
                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 22)
        }
        .background(Color.stashScannerBg.ignoresSafeArea())
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .animation(.spring(duration: 0.3), value: foundBarcode != nil)
        .animation(.easeOut(duration: 0.2), value: unsupportedMessage)
        .task(id: unsupportedMessage) {
            guard unsupportedMessage != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled { unsupportedMessage = nil }
        }
        .onDisappear { setTorch(false) }
    }

    @ViewBuilder
    private var cameraLayer: some View {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            BarcodeScannerView(
                onScan: { handleScan($0) },
                onUnsupported: { name in
                    unsupportedMessage = "\(name) isn't supported by Apple Wallet. Try a QR, PDF417, Aztec, or Code 128 barcode."
                }
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "camera.metering.unknown")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Camera unavailable")
                    .font(.stash(15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var topBar: some View {
        HStack {
            CircleIconButton(systemName: "xmark", isFilled: false) { dismiss() }
            Spacer()
            CircleIconButton(systemName: torchOn ? "bolt.fill" : "bolt.slash", isFilled: torchOn) {
                setTorch(!torchOn)
            }
        }
        .padding(.top, 60)
    }

    private var instructionStack: some View {
        VStack(spacing: 6) {
            Text(foundBarcode == nil ? "Point at a code" : "Got it")
                .font(.stash(20, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(.white)
            Text(foundBarcode == nil ? "Hold steady inside the frame" : "Adding to your wallet…")
                .font(.stash(14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            if let unsupportedMessage {
                Text(unsupportedMessage)
                    .font(.stash(13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func handleScan(_ barcode: ScannedBarcode) {
        guard foundBarcode == nil else { return }
        foundBarcode = barcode
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            await MainActor.run { onScan(barcode) }
        }
    }

    private func setTorch(_ on: Bool) {
        torchOn = on
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // best-effort; ignore failures
        }
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let isFilled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isFilled ? Color.stashInk : .white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isFilled ? Color.white : Color.white.opacity(0.16))
                )
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct DimMask: View {
    let viewfinderSize: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.55))
            .reverseMask {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .frame(width: viewfinderSize, height: viewfinderSize)
            }
            .ignoresSafeArea()
    }
}

private extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle()
                .overlay(mask().blendMode(.destinationOut))
                .compositingGroup()
        }
    }
}

private struct ViewfinderFrame: View {
    let size: CGFloat
    let color: Color

    private let armLength: CGFloat = 30
    private let lineWidth: CGFloat = 3

    var body: some View {
        Path { p in
            // Top-left
            p.move(to: CGPoint(x: 0, y: armLength))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: armLength, y: 0))
            // Top-right
            p.move(to: CGPoint(x: size - armLength, y: 0))
            p.addLine(to: CGPoint(x: size, y: 0))
            p.addLine(to: CGPoint(x: size, y: armLength))
            // Bottom-right
            p.move(to: CGPoint(x: size, y: size - armLength))
            p.addLine(to: CGPoint(x: size, y: size))
            p.addLine(to: CGPoint(x: size - armLength, y: size))
            // Bottom-left
            p.move(to: CGPoint(x: armLength, y: size))
            p.addLine(to: CGPoint(x: 0, y: size))
            p.addLine(to: CGPoint(x: 0, y: size - armLength))
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.2), value: color)
    }
}

private struct ScanLine: View {
    let extent: CGFloat
    @State private var animating = false

    var body: some View {
        ZStack {
            Color.clear
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white, location: 0.5),
                            .init(color: .clear, location: 1),
                        ]),
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .shadow(color: .white.opacity(0.9), radius: 8)
                .shadow(color: .white.opacity(0.5), radius: 16)
                .offset(y: animating ? extent / 2 : -extent / 2)
                .animation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: animating
                )
        }
        .onAppear { animating = true }
    }
}

private struct SuccessGlyph: View {
    var body: some View {
        Circle()
            .fill(Color.stashSuccess)
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.stashInk)
            }
    }
}
