# Status

Living snapshot of what's done and what's pending. Update whenever a commit lands, a task starts or finishes, or scope shifts.

Last updated: 2026-05-08

## Done

| Commit  | Date       | Summary                                                                                                         |
| ------- | ---------- | --------------------------------------------------------------------------------------------------------------- |
| 27202cc | 2026-05-08 | chore: initialize monorepo (git, .gitignore, README, `backend/.env.example`)                                    |
| 7a6e4b9 | 2026-05-08 | feat(backend): Fastify + TS + mock signer; 6 vitest tests; manual `curl` smoke verified                         |
| 63c9e70 | 2026-05-08 | feat(ios): SwiftUI scaffold — models, networking, scanner, wallet adder, views; XCTest suite; xcodegen project  |
| fdd40f8 | 2026-05-08 | docs: add TESTING.md                                                                                             |

## Pending — v1 gaps

These were promised in the v1 scope but are not yet finished.

### 1. Verify the iOS scaffold compiles
The Swift code was written from docs without a Mac, so it has never been built.
- On a Mac: `cd ios && xcodegen`
- Run the test suite: `xcodebuild -project Wallet.xcodeproj -scheme Wallet -destination 'platform=iOS Simulator,name=iPhone 15' test`
- Fix any compile errors. Most-likely suspect spots:
  - `barcode.observation.symbology` in `BarcodeScanner.swift` (VisionKit API path)
  - SwiftData enum-typed properties on `Card` (occasionally flaky on early iOS 17)

### 2. Edit-card UI
`CardDetailView` currently only has *Re-add to Wallet* and *Delete*. Add a form to edit label / description / colors / pass type so the re-issue actually changes something.

### 3. End-to-end smoke (mock signer)
Backend running + iOS app on a phone, verify scan → form → POST `/pass` → mock bytes received. The Wallet-sheet failure at `PKPass(data:)` is expected and documented in TESTING.md.

### 4. Real pkpass signing
Blocked on Apple Developer enrollment. When unblocked:
- Implement `backend/src/pass/realSigner.ts` using `passkit-generator`
- Create per-pass-type template dirs in `backend/templates/` with `icon.png` and `logo.png` at @1x/@2x/@3x
- Wire `realSigner` into `server.ts` (replace the "not yet implemented" throw)
- Verify a signed pass actually adds to a real device's Wallet
- Flip `MOCK_SIGNER=false`

## Pending — pre-deploy chores

Not blocking development, blocking ship.

### Backend
- Upgrade Node to 20 + Fastify to v5 (audit reports 1 high vuln on Fastify v4)
- CI: `.github/workflows/backend.yml` running `npm test` and `npm run typecheck`
- Pick a deploy target (Fly.io / Render / Railway) and add deploy config

### iOS
- Replace placeholder bundle ID `com.example.Wallet` with a real one in `ios/project.yml`
- Set Apple team in `ios/project.yml`
- App icon + accent color in the asset catalog
- Real launch screen image (currently empty `UILaunchScreen: {}`)
- Make the backend URL configurable instead of hardcoded `http://localhost:3000` in `WalletApp.swift`
- CI: `.github/workflows/ios.yml` running `xcodebuild test` on `macos-latest`

## Deferred — v2 and beyond

Intentionally out of scope for v1.

- **Pass Update Web Service** for true in-place edits (we use re-issue instead)
- **User-uploaded custom logos** (we ship five pre-made color templates)
- **iCloud / CloudKit sync** of the card list
- **Card sharing / export**
- **Localizations** beyond English

## Decisions log

- 2026-05-08: Stack locked — Swift + SwiftUI iOS 17+, Node + Fastify + TypeScript backend, monorepo with `ios/` and `backend/`.
- 2026-05-08: "Edit" semantics chosen as re-issue (not the Pass Update Web Service) for v1.
- 2026-05-08: Pass visuals are five pre-made color palettes; user-uploaded logos deferred to v2.
- 2026-05-08: Stayed on Fastify v4 + Node 18 for now; v5 + Node 20 upgrade deferred to pre-deploy.
- 2026-05-08: xcodegen owns the Xcode project — `Wallet.xcodeproj/` and `Wallet/Info.plist` are gitignored, regenerated from `ios/project.yml`.
