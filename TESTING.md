# Testing

How to verify every layer of the Wallet app — backend, iOS unit tests, simulator, physical device, and end-to-end.

The backend is fully testable on any machine with Node. The iOS app requires macOS with Xcode.

## Prerequisites

| Component         | Requirement                                                                |
| ----------------- | -------------------------------------------------------------------------- |
| Backend           | Node 18.18+, npm                                                           |
| iOS               | macOS with Xcode 15+, Homebrew, [xcodegen](https://github.com/yonaskolb/XcodeGen) |
| iOS device tests  | iPhone running iOS 17+                                                     |

Install xcodegen once:

```sh
brew install xcodegen
```

## Backend

### Setup

```sh
cd backend
cp .env.example .env
npm install
```

Default `.env` runs the **mock signer**, which echoes the request as a JSON buffer. Real signing isn't wired yet (see *Apple Developer prerequisites* in `README.md`).

### Unit tests

```sh
npm test           # vitest run
npm run typecheck  # tsc --noEmit
```

Tests use Fastify's `inject()` API — no real port is opened, so they run cleanly in CI. Coverage:

- Happy-path `POST /pass` returns the mock buffer with the right content type
- Validation rejects missing fields, invalid hex colors, unknown pass type, unknown barcode format
- `GET /health` returns ok

### Manual smoke

```sh
npm run dev        # boots on http://localhost:3000
```

In another terminal:

```sh
# Health check
curl http://localhost:3000/health

# Valid pass request
curl -X POST http://localhost:3000/pass \
  -H 'Content-Type: application/json' \
  -d '{"type":"storeCard","label":"Coffee","description":"Loyalty","colors":{"background":"#0A2540","foreground":"#FFFFFF","label":"#7AC0FF"},"barcode":{"format":"qr","message":"abc-123"}}'

# Invalid request (expect 400)
curl -i -X POST http://localhost:3000/pass \
  -H 'Content-Type: application/json' \
  -d '{"type":"storeCard"}'
```

## iOS

### One-time setup

Generate the Xcode project from `project.yml`:

```sh
cd ios
xcodegen
open Wallet.xcodeproj
```

Both `Wallet.xcodeproj/` and `Wallet/Info.plist` are gitignored — re-run `xcodegen` after editing `project.yml`.

In Xcode:

1. **Settings → Accounts**: add your Apple ID (free or paid).
2. Select the **Wallet** target → **Signing & Capabilities** → tick *Automatically manage signing* and pick your team.
3. Change the **Bundle Identifier** from `com.example.Wallet` to a unique value.
4. Mirror the new bundle ID in `ios/project.yml` so re-running `xcodegen` doesn't reset it.

### Unit tests

From the command line:

```sh
cd ios
xcodebuild -project Wallet.xcodeproj -scheme Wallet \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Or in Xcode: Cmd-U. Coverage:

- `PassRequest` Codable round-trip and key/value encoding
- `LivePassClient` posts the right JSON body and surfaces server errors via a stubbed `URLSession` (`MockURLProtocol`)
- `BarcodeFormat` ↔ `VNBarcodeSymbology` mapping, including the unsupported-symbology nil case
- Raw-value round-trip for every `BarcodeFormat`

### Run on simulator

Cmd-R targeting any iOS 17 simulator (e.g. iPhone 15). The simulator has no camera, so tapping the scanner button shows a *Camera unavailable* fallback. Everything else — list, navigation, form, networking against `http://localhost:3000` — works.

### Run on a physical iPhone

The simulator can't exercise barcode scanning; you need a real device.

1. Plug the iPhone into your Mac. Tap **Trust** when prompted.
2. On the iPhone: **Settings → Privacy & Security → Developer Mode → On**, then reboot.
3. In Xcode's run-destination dropdown, pick your phone.
4. Cmd-R. First run installs but doesn't launch — open **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**, then tap the app icon.
5. Grant camera permission on first scan.

## End-to-end (mock signer)

With the backend running and the iOS app installed, the round-trip exercises every layer:

| Step                      | Where it runs | What gets exercised                                      |
| ------------------------- | ------------- | -------------------------------------------------------- |
| Tap scanner button        | iPhone        | `HomeView` toolbar, `ScanFlow` sheet                     |
| Scan a barcode            | iPhone        | `BarcodeScannerView` (VisionKit), `BarcodeFormat` mapping |
| Fill form, tap Add        | iPhone        | `PassFormView`, form validation                          |
| Backend signs             | Mac           | `POST /pass`, schema validation, mock signer             |
| App receives pkpass bytes | iPhone        | `LivePassClient.sign(_:)`                                |
| Save to local list        | iPhone        | SwiftData insert via `@Environment(\.modelContext)`      |
| Wallet sheet opens        | iPhone        | `WalletAdderSheet` (fails — see *Mock-signer caveats*)   |

### iPhone reaching the backend over LAN

The phone can't reach `localhost` on the Mac. Find the Mac's LAN IP:

```sh
ipconfig getifaddr en0     # Wi-Fi
ipconfig getifaddr en1     # if Wi-Fi is on en1 instead
```

In `ios/Wallet/WalletApp.swift`, change:

```swift
baseURL: URL(string: "http://localhost:3000")!
```

to your Mac's IP, e.g. `http://192.168.1.42:3000`. Both devices must be on the same Wi-Fi. macOS may prompt to allow `node` to accept incoming connections — say yes. ATS already permits HTTP on the local network via `NSAllowsLocalNetworking` in `Info.plist`.

## Mock-signer caveats

| Feature                  | Works? | Notes                                                                                                                                                                              |
| ------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Backend API              | Yes    | Returns JSON envelope tagged `application/vnd.apple.pkpass`                                                                                                                        |
| Scanner                  | Yes    | Device only — simulator has no camera                                                                                                                                              |
| SwiftData persistence    | Yes    | Cards survive relaunches                                                                                                                                                           |
| `POST /pass` round-trip  | Yes    | iOS receives the mock bytes                                                                                                                                                        |
| **Add to Wallet**        | **No** | `PKPass(data:)` rejects the mock buffer — the form surfaces the error in red. Real signing arrives once an Apple Pass Type ID certificate is wired up (project task `#5`).         |

## Troubleshooting

**`xcodegen: command not found`** — `brew install xcodegen`.

**`No such module 'Wallet'` in tests** — Re-run `xcodegen` after pulling new files; the project file is generated, not committed.

**`Could not connect to the server`** in the iOS app — backend isn't running, or you're on a phone hitting `localhost`. See *iPhone reaching the backend over LAN*.

**Untrusted developer** on first phone install — **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**.

**Camera black or permission denied** — first scan after install fails silently if you tapped *Don't Allow*. Reset under **Settings → Privacy & Security → Camera → Wallet**.

**`PKPass(data:) threw`** — expected in mock-signer mode. The mock returns JSON, not a signed pkpass. The wire-up still proves the network round-trip works.
