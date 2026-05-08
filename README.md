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

Open `ios/Wallet.xcodeproj` in Xcode 15+ and run on the iOS 17 simulator or a device.

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

1. Enrol in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/yr).
2. Create a **Pass Type ID** in the developer portal.
3. Generate the Pass Type ID certificate; export it as a `.p12`.
4. Download Apple's WWDR intermediate certificate.
5. Place the `.p12` and WWDR `.pem` under `backend/certs/` (gitignored) and fill in `backend/.env`.
6. Set `MOCK_SIGNER=false` in `backend/.env`.
