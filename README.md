# Wallet

iOS app that scans barcodes and adds them to Apple Wallet as signed `.pkpass` files, backed by a small Node service that does the signing.

## Status

Early scaffolding. The app and backend are wired together against a **mock signer** that returns a placeholder `.pkpass`. Real signing turns on once an Apple Developer Program membership and Pass Type ID certificate are in place.

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

## Apple Developer prerequisites

Before real `.pkpass` signing works on a device:

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
8. Set `MOCK_SIGNER=false` in `backend/.env`.
