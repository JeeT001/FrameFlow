# Drazlo — Developer ID Release Signing & Notarisation

**Phase 17, Day 46** — prepare a signed, notarised `.app` for distribution outside the Mac App Store.

| Item | Value |
|------|--------|
| Xcode scheme | `Drazlo` |
| Target | `Drazlo` |
| Display name | Drazlo |
| Bundle ID | `com.Simranjit.FrameFlow` |
| Team ID | `6XP66CQ82V` |
| Min macOS | 14.0 |

Out of scope for Day 46: DMG (Day 47), Sparkle auto-update (Day 48), GitHub Actions release (Day 49).

---

## Prerequisites

1. **Apple Developer Program** membership with access to Team `6XP66CQ82V`.
2. **Developer ID Application** certificate in Keychain (Xcode → Settings → Accounts → Manage Certificates).
3. **App-specific password** for notarisation ([appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords).
4. Xcode 15+ with command-line tools: `xcode-select -p`.

---

## One-time Xcode setup

1. Open `FrameFlow/FrameFlow.xcodeproj`.
2. Select target **Drazlo** → **Signing & Capabilities**.
3. **Team:** your team (`6XP66CQ82V`).
4. **Signing:** Automatic.
5. Confirm **Release** configuration (Project → Drazlo → Build Settings):
   - `CODE_SIGN_STYLE = Automatic`
   - `DEVELOPMENT_TEAM = 6XP66CQ82V`
   - `ENABLE_HARDENED_RUNTIME = YES`
   - `CODE_SIGN_ENTITLEMENTS = FrameFlow/FrameFlow.entitlements`
   - `PRODUCT_BUNDLE_IDENTIFIER = com.Simranjit.FrameFlow`
   - `PRODUCT_NAME = Drazlo`

Archive uses scheme **Drazlo** with **Release** (see `Drazlo.xcscheme` → ArchiveAction).

---

## Entitlements audit

File: `FrameFlow/FrameFlow/FrameFlow.entitlements`

| Entitlement | Purpose | Notarisation |
|-------------|---------|--------------|
| `com.apple.security.app-sandbox` | App Sandbox | Required for hardened runtime distribution |
| `com.apple.security.network.client` | Supabase, RevenueCat, analytics | OK |
| `com.apple.security.device.camera` | PiP / camera capture | OK + `NSCameraUsageDescription` |
| `com.apple.security.device.audio-input` | Microphone | OK + `NSMicrophoneUsageDescription` |
| `com.apple.security.files.user-selected.read-write` | Save folder export (user picks directory) | OK |
| `com.apple.security.files.bookmarks.app-scope` | Persist save-folder bookmark | OK |

**Runtime permissions (not entitlements):**

- **Screen Recording** — ScreenCaptureKit; user grants in System Settings.
- **Accessibility** — global recording shortcuts; user grants in System Settings.
- **Camera / Microphone** — TCC prompts via usage strings in Info.plist.

**Not required / not added:**

- Screen Recording entitlement (none exists; permission is TCC-only).
- Push notifications, iCloud, Apple Events, temporary exception entitlements.

**Note:** Xcode build setting `ENABLE_USER_SELECTED_FILES = readonly` may show in the UI; the embedded entitlements plist includes **read-write**, which matches export-to-save-folder behavior. If notarisation rejects sandbox file access, confirm the exported `.app` entitlements with `codesign -d --entitlements :- Drazlo.app`.

---

## Local release workflow

From repo root:

```bash
# 1. Release compile check (no archive)
cd FrameFlow
xcodebuild -scheme Drazlo -configuration Release -destination 'platform=macOS' build

# 2. Archive + export signed Developer ID app → build/export/Drazlo.app
chmod +x Scripts/archive_release.sh Scripts/notarize_app.sh
./Scripts/archive_release.sh

# 3. Notarise + staple (credentials via env — never commit)
export NOTARY_APPLE_ID="you@example.com"
export NOTARY_TEAM_ID="6XP66CQ82V"
export NOTARY_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
# Or: cp Scripts/notary.env.example Scripts/notary.env  # then edit locally
./Scripts/notarize_app.sh build/export/Drazlo.app
```

`Scripts/ExportOptions.plist` uses `method: developer-id` and `signingStyle: automatic`.

---

## Verification

```bash
# Signature details
codesign -dv --verbose=4 build/export/Drazlo.app

# Entitlements embedded in signature
codesign -d --entitlements :- build/export/Drazlo.app

# Gatekeeper (after staple)
spctl -a -vv build/export/Drazlo.app

# Expected: accepted / Notarized Developer ID
```

**Clean Mac test:** Copy stapled `Drazlo.app` to a Mac **not** logged into the developer Apple ID. Double-click — no “unidentified developer” warning.

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| Archive fails: no signing certificate | Install **Developer ID Application** cert; Xcode → Accounts → Download Manual Profiles |
| Team mismatch | `DEVELOPMENT_TEAM` and `ExportOptions.plist` `teamID` = `6XP66CQ82V` |
| Notary rejection: hardened runtime | `ENABLE_HARDENED_RUNTIME = YES` on Release |
| Notary rejection: entitlements | Compare with audit above; avoid unused dangerous entitlements |
| `stapler` fails | Ensure `notarytool submit --wait` succeeded; staple the same `.app` that was zipped |
| Save folder fails after install | User must re-pick folder (bookmark); sandbox + user-selected read-write |
| Screen capture fails | User must grant Screen Recording in System Settings |

---

## Settings → Check for Updates

Settings shows a placeholder alert (“Updates Coming Soon”). **Sparkle 2** is in SPM but not wired in `FrameFlowApp.swift` — planned for **Day 48**.

---

## Files added (Day 46)

| Path | Role |
|------|------|
| `Scripts/ExportOptions.plist` | Developer ID export options |
| `Scripts/archive_release.sh` | Archive + export signed `.app` |
| `Scripts/notarize_app.sh` | Zip → notarytool → stapler |
| `Scripts/notary.env.example` | Env var template (no secrets) |

Build artifacts (`build/`, `*.xcarchive`, `build/Drazlo-*.dmg`) are gitignored.

---

## Day 47 — DMG creation + notarisation

Package a **signed, stapled** `Drazlo.app` into a drag-to-Applications DMG for website download.

### Prerequisites

1. Complete **Day 46** locally: stapled app at `build/export/Drazlo.app` (`spctl: accepted`).
2. Install **create-dmg**: `brew install create-dmg`
3. Same notarisation credentials as Day 46 (`NOTARY_*` env vars).

### DMG assets

| Path | Role |
|------|------|
| `Resources/DMG/dmg-background-light.png` | Default Finder background (1600×800) |
| `Resources/DMG/dmg-background-dark.png` | Dark variant (`DMG_BACKGROUND=dark`) |
| `Resources/DMG/DrazloVolume.icns` | DMG volume icon |

### End-to-end commands

```bash
# Day 46 — signed + stapled app (required first)
./Scripts/archive_release.sh
export NOTARY_APPLE_ID="you@example.com"
export NOTARY_TEAM_ID="6XP66CQ82V"
export NOTARY_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./Scripts/notarize_app.sh

# Day 47 — DMG
./Scripts/create_dmg.sh
./Scripts/notarize_dmg.sh

# Or orchestrate (skips DMG notarise if NOTARY_* unset):
./Scripts/release_dmg.sh
```

Optional: `DMG_BACKGROUND=dark ./Scripts/create_dmg.sh` for dark background art.

Output: `build/Drazlo-<version>.dmg` (version from `MARKETING_VERSION`, default `1.0`).

### DMG verification

```bash
codesign --verify --verbose=2 build/Drazlo-1.0.dmg
spctl -a -vv -t open --context context:primary-signature build/Drazlo-1.0.dmg
xcrun stapler validate build/Drazlo-1.0.dmg
```

Expected: `accepted` / `Notarized Developer ID` / `The validate action worked!`

### Clean Mac test checklist

On a Mac **not** logged into the developer Apple ID:

1. Download or copy `Drazlo-1.0.dmg`
2. Double-click to mount — no Gatekeeper block on the disk image
3. Drag **Drazlo** to **Applications**
4. Eject DMG, open **Drazlo** from Applications
5. First launch: no “unidentified developer” warning
6. Smoke: sign in, open Settings, confirm save-folder picker works (sandbox bookmark)

### Day 47 scripts

| Script | Role |
|--------|------|
| `Scripts/create_dmg.sh` | Validate stapled app → `create-dmg` → unsigned DMG |
| `Scripts/notarize_dmg.sh` | Sign DMG → `notarytool submit --wait` → staple |
| `Scripts/release_dmg.sh` | Orchestrates create + notarise (credentials required for latter) |
| `Scripts/release_common.sh` | Shared version lookup + app validation |

### DMG troubleshooting

| Issue | What to check |
|-------|----------------|
| `create-dmg: command not found` | `brew install create-dmg` |
| App not stapled | Run `./Scripts/notarize_app.sh` first |
| DMG sign fails | Developer ID Application cert in Keychain; `SIGNING_IDENTITY` env override |
| Notary rejects DMG | App inside must already be notarised; DMG signed with `--options runtime` |
| `stapler` fails on DMG | Ensure `notarytool submit --wait` succeeded for the `.dmg` file |

**Out of scope:** Sparkle appcast (Day 48), GitHub Actions (Day 49).
