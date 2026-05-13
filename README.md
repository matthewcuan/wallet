# Wallet

iOS app that scans barcodes and adds them to Apple Wallet as signed `.pkpass` files, backed by a small Node service that does the signing.

## Status

Early scaffolding. The backend can run against three signers, picked via `SIGNER` in `backend/.env`:

- `mock` (default) — returns a JSON envelope. iOS `PKPass(data:)` rejects these; the round-trip works, the final Wallet hand-off doesn't.
- `passslot` — uses [PassSlot](https://www.passslot.com/) as a hosted signing service. **No Apple Developer Program required.** Free tier covers 1,000 passes / 1 Pass Type ID. See [Using PassSlot for testing](#using-passslot-for-testing).
- `passkit` — uses your own Apple-issued Pass Type ID certificate via passkit-generator. Required for shipping under your own branding. See [Apple Developer prerequisites](#apple-developer-prerequisites).

## Layout

```
ios/        Swift + SwiftUI app, iOS 17+
backend/    Node + Fastify + TypeScript pkpass signer
```

## Quickstart

### Backend

```sh
cd backend
cp .env.example .env
npm install
npm run dev
```

### iOS

The Xcode project is generated from `ios/project.yml` via [xcodegen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen   # one-off
cd ios
xcodegen                # produces Wallet.xcodeproj + Wallet/Info.plist
open Wallet.xcodeproj
```

Both `Wallet.xcodeproj/` and the generated `Info.plist` are gitignored — re-run `xcodegen` whenever `project.yml` changes.

Run on the iOS 17 simulator (no camera, scanner UI shows a fallback) or a real device (camera permission prompts on first scan).

## Tests

```sh
# Backend
cd backend && npm test

# iOS
xcodebuild -project ios/Wallet.xcodeproj -scheme Wallet \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Using PassSlot for testing

The cheapest way to see a real signed pass open in Wallet on a device, without enrolling in the Apple Developer Program:

1. Create a free account at https://www.passslot.com/.
2. **Templates → New** — design a template for the pass type you want (e.g. *Store Card*). Add a barcode.
3. In the template designer, define text placeholders with these exact names so the backend's field mapping lines up:
   - `label`
   - `description`
   - `passType`
   - `barcodeMessage`
   - `barcodeAltText`
4. Wire `barcodeMessage` into the template's barcode value.
5. Save. Note the template ID (in the URL).
6. **Account → App Keys** — create an App Key with permission to use that template.
7. Fill `backend/.env`:

   ```
   SIGNER=passslot
   PASSSLOT_APP_KEY=<your-app-key>
   PASSSLOT_TEMPLATE_ID=<your-template-id>
   ```

8. Restart `npm run dev`. The iOS app's "Add to Wallet" flow now ends with a real Wallet prompt on the phone.

Caveats: the resulting pass shows PassSlot's Pass Type ID, not yours. The colour palettes in the iOS UI are decorative under PassSlot — the template's design owns the colours; the backend only fills text and barcode values.

## Apple Developer prerequisites

For shipping a real product under your own branding (instead of routing through PassSlot):

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/yr).
2. Create a **Pass Type ID** in the developer portal.
3. Generate the Pass Type ID certificate and export it as a `.p12`.
4. Extract the cert and key as PEMs (passkit-generator needs them separate):

   ```sh
   openssl pkcs12 -in pass.p12 -clcerts -nokeys -out backend/certs/signerCert.pem
   openssl pkcs12 -in pass.p12 -nocerts        -out backend/certs/signerKey.pem
   ```

5. Download Apple's [WWDR intermediate certificate](https://www.apple.com/certificateauthority/) to `backend/certs/wwdr.pem`.
6. Fill in `backend/.env` with the cert paths, your Pass Type ID, and your Team ID.
7. Provide pass templates under `backend/templates/<passType>/` (one folder per pass type, each containing `pass.json`, `icon.png`/@2x/@3x, `logo.png`/@2x/@3x).
8. Set `SIGNER=passkit` in `backend/.env`.
