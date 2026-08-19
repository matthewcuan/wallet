# Status

Living snapshot of what's done and what's pending. Update whenever a commit lands, a task starts or finishes, or scope shifts.

Last updated: 2026-08-19

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
| 3996760 | 2026-05-14 | fix(ios): keep Add Card form open when Wallet preview is cancelled (WalletAdderOutcome enum)                    |
| 4a217d4 | 2026-05-14 | feat(ios): swipe-to-delete cards (List-era; translated to tile context menu after redesign)                     |
| 22bea07 | 2026-05-19 | feat(ios): apply Stash design — warm theme, 8-palette tiles, custom header, overlay scanner, color-block detail |
| fbd48b3 | 2026-05-19 | docs: log Stash redesign in STATUS                                                                              |
| a53ef65 | 2026-05-20 | feat(ios): manual entry — pick format, type or paste a value, save to wallet                                    |
| bb225d2 | 2026-05-20 | docs: log manual code entry in STATUS                                                                           |
| e6d7d4e | 2026-05-20 | docs: refresh STATUS hashes after rebase                                                                        |
| f60060d | 2026-05-21 | fix(ios): drop @inlinable from fileprivate reverseMask helper (first real-Mac build)                            |
| bb4bf7a | 2026-05-21 | fix(ios): declare NSLocalNetworkUsageDescription so LAN requests work on device                                 |
| dc3aa3d | 2026-05-21 | chore(ios): rename display from Stash back to Wallet                                                            |
| d68f996 | 2026-05-21 | fix(ios): gate Add/Cancel detection on entitled pass-type IDs                                                   |
| 0e3d72a | 2026-05-21 | fix(ios): use raw notification name for PKPassLibraryDidChange                                                  |
| 274e9c0 | 2026-07-10 | docs: bring STATUS up to date through the 05-21 device fixes                                                    |
| 641794b | 2026-08-19 | feat(backend): add setup-certs.sh to bootstrap the passkit signer                                               |

## Pending — v1 gaps

These were promised in the v1 scope but are not yet finished.

Resolved 2026-05-21: the former gaps 1 (verify the iOS scaffold compiles) and 2 (end-to-end smoke) are done — the app was built on a real Mac and run on a device against a LAN backend, flushing out the compile fix (f60060d), the local-network permission (bb4bf7a), and the PassSlot Add/Cancel handling (d68f996, 0e3d72a).

### 1. Real pkpass signing — final verification
The signer code is in (`e71a214`) and the cert plumbing is now scripted (`641794b`, `npm run setup:certs`). What's left is the part only a human with a developer account can do, plus proof on a device.
- Apple Developer enrollment ($99/yr) — **blocking everything below**
- Create the Pass Type ID, upload `certs/pass.certSigningRequest`, save the issued cert to `certs/pass.cer`
- Run `npm run setup:certs finalize` (PEMs + WWDR + templates + `.env`), then fill `PASS_TYPE_IDENTIFIER` and `TEAM_IDENTIFIER`
- Replace the scaffolded placeholder `pass.json` / icon / logo art with real branding
- Add the Pass Type ID to `entitledPassTypeIdentifiers` in the iOS app so Add/Cancel detection stops falling back to `.added`
- Flip `SIGNER` from `passslot` to `passkit` and verify a signed pass adds to a real device's Wallet

## Pending — pre-deploy chores

Not blocking development, blocking ship.

### Backend
- Upgrade Node to 20 + Fastify to v5 — `npm audit` is now 11 vulns (1 critical, 6 high, 4 moderate): fastify, fast-uri, find-my-way, nanoid, postcss, vite/vitest (critical, dev-only)
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
- 2026-05-21: Display name reverted from "Stash" back to "Wallet" (dc3aa3d); target/folder names had never changed.
- 2026-05-21: Add/Cancel detection in the Wallet sheet is gated on `entitledPassTypeIdentifiers` (empty by default). `PKPassLibraryDidChange` only fires for pass types matching our entitlement, so for non-entitled passes — including all PassSlot passes — any sheet finish is reported as `.added`, dismissing the form and persisting the card. Populate the set once we own an Apple Pass Type ID.
- 2026-08-19: Cert provisioning is scripted as `backend/scripts/setup-certs.sh` (`npm run setup:certs`), generating the key and CSR directly with `openssl` instead of the Keychain `.p12` round-trip — fewer manual steps, and the key never leaves `backend/certs/` (gitignored). The `.p12` route stays in the README as a fallback. `finalize` also scaffolds placeholder templates for all five pass types and refuses to clobber an existing `.env`.
