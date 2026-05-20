# Status

Living snapshot of what's done and what's pending. Update whenever a commit lands, a task starts or finishes, or scope shifts.

Last updated: 2026-05-20

## Done

| Commit  | Date       | Summary                                                                                                          |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------------------- |
| 27202cc | 2026-05-08 | chore: initialize monorepo (git, .gitignore, README, `backend/.env.example`)                                     |
| 7a6e4b9 | 2026-05-08 | feat(backend): scaffold Fastify pkpass signer with mock implementation                                            |
| 63c9e70 | 2026-05-08 | feat(ios): SwiftUI scaffold — models, networking, scanner, wallet adder, views; XCTest suite; xcodegen project   |
| fdd40f8 | 2026-05-08 | docs: add TESTING.md                                                                                              |
| f2d79fa | 2026-05-08 | docs: add STATUS.md to track changelog and pending work                                                           |
| ad727d5 | 2026-05-08 | ci: add GitHub Actions workflow for backend tests                                                                 |
| 18e8969 | 2026-05-08 | feat(ios): add edit-card UI in CardDetailView                                                                     |
| e71a214 | 2026-05-08 | feat(backend): scaffold real pkpass signer behind passkit-generator                                               |
| e5271bb | 2026-05-08 | docs: refresh README cert steps and STATUS.md changelog                                                          |
| dbfc6f4 | 2026-05-13 | feat(backend): add PassSlot hosted signer alongside mock and passkit; refactor MOCK_SIGNER → SIGNER enum         |
| c11c941 | 2026-05-13 | docs: log PassSlot signer in STATUS.md                                                                          |
| 879b941 | 2026-05-13 | fix(backend): use PassSlot API path for pkpass download, not the response url                                   |
| bb22174 | 2026-05-13 | feat(ios): surface friendly message when a scanned barcode isn't Wallet-compatible                              |
| d5d5c25 | 2026-05-19 | feat(ios): apply Stash design — warm theme, 8-palette tiles, custom header, overlay scanner, color-block detail |
| 263d8f7 | 2026-05-19 | docs: log Stash redesign in STATUS                                                                              |
| 5a4677f | 2026-05-20 | feat(ios): manual entry — pick format, type or paste a value, save to wallet                                    |

## Pending — v1 gaps

These were promised in the v1 scope but are not yet finished.

### 1. Verify the iOS scaffold compiles
The Swift code was written from docs without a Mac, so it has never been built.
- On a Mac: `cd ios && xcodegen`
- Run the test suite: `xcodebuild -project Wallet.xcodeproj -scheme Wallet -destination 'platform=iOS Simulator,name=iPhone 15' test`
- Fix any compile errors. Most-likely suspect spots:
  - `barcode.observation.symbology` in `BarcodeScanner.swift` (VisionKit API path)
  - SwiftData enum-typed properties on `Card`

### 2. End-to-end smoke
Backend running + iOS app on a phone, verify scan → form → POST `/pass` → bytes received. With `SIGNER=mock` (default), Wallet-sheet `PKPass(data:)` is expected to fail; with `SIGNER=passslot` (PassSlot App Key + template configured per README) the full add-to-Wallet flow should complete.

### 3. Real pkpass signing — final verification
The signer code itself is in (commit `e71a214`); what remains is the cert + assets work and proving a signed pass loads on a real device.
- Apple Developer enrollment + Pass Type ID + `.p12`
- Extract `signerCert.pem` and `signerKey.pem` (commands in README)
- Download WWDR `.pem` → `backend/certs/wwdr.pem`
- Build `backend/templates/<passType>/` directories with real `pass.json`, `icon.png`/@2x/@3x, `logo.png`/@2x/@3x
- Set `SIGNER=passkit` and verify a signed pass actually adds to a real device's Wallet

## Pending — pre-deploy chores

Not blocking development, blocking ship.

### Backend
- Upgrade Node to 20 + Fastify to v5 (audit reports 1 high vuln on Fastify v4)
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
- 2026-05-08: Backend cert layout uses separate `signerCert.pem` + `signerKey.pem` (extracted from the Apple `.p12` via `openssl pkcs12`), because that's the shape passkit-generator's `CertificatesSchema` expects.
- 2026-05-13: PassSlot added as a third signer alongside `mock` and `passkit`. Selected via the new `SIGNER` env enum (replaces boolean `MOCK_SIGNER`). PassSlot gives a no-Apple-Dev-account path to real Wallet adds, at the cost of using PassSlot's Pass Type ID and template-owned visual design.
- 2026-05-19: Applied the Stash design from `claude.ai/design`. New design tokens (Helvetica Neue, warm `#F7F5F1` background, coral `#C24A2C` accent), 8 named palettes (Forest/Clay/Ink/Mustard/Slate/Plum/Sage/Coral) replacing the prior 5, and a user-facing `CardKind` taxonomy (Loyalty/Ticket/Membership/Gift/Library/Other) mapped onto Apple's `PassType` for the backend. `Card` schema changed (no migration plan — wipe-and-reinstall in dev). Backend untouched. `CFBundleDisplayName` flipped to "Stash"; target/folder names stay "Wallet" to avoid a wholesale rename.
- 2026-05-20: Added a manual code-entry flow alongside the camera scanner — `ManualEntryFlow` + `ManualEntryView` collect a format (QR/PDF417/Aztec/Code 128) and a typed/pasted value, render a live preview via the existing `CodeRenderer`, then hand off a synthetic `ScannedBarcode` to the unchanged `PassFormView`. Entry point is a coral text link directly under the floating Scan pill on Home (Scan stays primary). Clipboard is opt-in via an explicit Paste button rather than auto-peek, to keep iOS's pasteboard banner from firing on screen open.
