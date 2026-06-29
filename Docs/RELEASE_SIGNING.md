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

Settings → **Check for Updates** uses Sparkle 2 (`AppUpdaterController`). Placeholder alert removed in Day 48.

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
2. Install **dmgbuild**: `pip install -r Scripts/requirements-dmg.txt`
3. Same notarisation credentials as Day 46 (`NOTARY_*` env vars).

### DMG assets

| Path | Role |
|------|------|
| `Resources/DMG/dmg-background-light.png` | Default Finder background (1320×800 @ 144 DPI) |
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
| `Scripts/create_dmg.sh` | Validate stapled app → **dmgbuild** → unsigned DMG |
| `Scripts/notarize_dmg.sh` | Sign DMG → `notarytool submit --wait` → staple |
| `Scripts/release_dmg.sh` | Orchestrates create + notarise (credentials required for latter) |
| `Scripts/release_common.sh` | Shared version lookup + app validation |

### DMG troubleshooting

| Issue | What to check |
|-------|----------------|
| `dmgbuild` not installed | `pip install -r Scripts/requirements-dmg.txt` |
| App not stapled | Run `./Scripts/notarize_app.sh` first |
| DMG sign fails | Developer ID Application cert in Keychain; `SIGNING_IDENTITY` env override |
| Notary rejects DMG | App inside must already be notarised; DMG signed with `--options runtime` |
| `stapler` fails on DMG | Ensure `notarytool submit --wait` succeeded for the `.dmg` file |

**Out of scope:** GitHub Actions (Day 49), live appcast hosting (Day 49+).

---

## Day 48 — Sparkle 2 auto-update

Wire in-app update checks for direct-download **Drazlo** builds (not Mac App Store).

| Item | Value |
|------|--------|
| SPM package | Sparkle 2.9.x (already linked) |
| Appcast URL (placeholder) | `https://drazlo.app/appcast.xml` |
| Feed constant | `AppBranding.appcastFeedURL` (keep in sync with Info.plist `SUFeedURL`) |
| Auto-check interval | 604800 s (7 days) |
| Manual check | App menu → Check for Updates; Settings → About → Check for Updates |

### Info.plist keys (`FrameFlow/Info.plist`)

| Key | Purpose |
|-----|---------|
| `SUFeedURL` | Appcast RSS URL |
| `SUPublicEDKey` | Sparkle EdDSA **public** key (from `generate_keys`) |
| `SUEnableAutomaticChecks` | `true` |
| `SUScheduledCheckInterval` | `604800` (weekly) |

**Never commit** the EdDSA private key. Gitignored: `Scripts/sparkle.env`, `*.sparkle_private_key`, `~/.sparkle/`.

### One-time key generation

```bash
# 1. Download Sparkle release tarball (bin/generate_keys + bin/sign_update)
#    https://github.com/sparkle-project/Sparkle/releases

export SPARKLE_BIN_DIR="$HOME/Tools/Sparkle/bin"   # adjust path

# 2. Generate EdDSA key pair (private key → Keychain or file — follow Sparkle prompts)
"${SPARKLE_BIN_DIR}/generate_keys"

# 3. Copy printed PUBLIC key into FrameFlow/Info.plist → SUPublicEDKey
#    Also verify SUFeedURL matches AppBranding.appcastFeedURL
```

### Sign a release DMG for appcast

After Day 47 DMG is built and notarised:

```bash
cp Scripts/sparkle.env.example Scripts/sparkle.env   # edit locally
chmod +x Scripts/sign_sparkle_update.sh
./Scripts/sign_sparkle_update.sh build/Drazlo-1.0.dmg
```

Copy `sparkle:edSignature` and `length` into `Resources/Release/appcast.xml`, upload DMG + appcast to your host.

### App code

| File | Role |
|------|------|
| `App/Services/AppUpdaterController.swift` | Owns `SPUStandardUpdaterController` (app lifetime) |
| `FrameFlowApp.swift` | Starts updater; app menu Check for Updates; injects environment |
| `SettingsView.swift` | About → Check for Updates → Sparkle manual check |

### User verification

```bash
# Build & run
cd FrameFlow
xcodebuild -scheme Drazlo -configuration Debug build

# 1. Put SUPublicEDKey in Info.plist (from generate_keys)
# 2. Settings → Check for Updates → Sparkle sheet (not placeholder alert)
# 3. App menu → Drazlo → Check for Updates (same)
# 4. After hosting appcast + signed DMG:
#    Bump version in appcast.xml → Sparkle should offer the update
```

### Sparkle troubleshooting

| Issue | What to check |
|-------|----------------|
| “Update Error!” invalid signature | `SUPublicEDKey` matches key pair used to sign DMG |
| No updates found | `SUFeedURL` reachable; appcast version > installed `CFBundleVersion` |
| Automatic checks disabled | `SUEnableAutomaticChecks` = true; user hasn’t disabled in Sparkle UI |
| sign_update not found | Set `SPARKLE_BIN_DIR` or download Sparkle release `bin/` tools |

**Out of scope:** CI appcast publish (Day 49), live domain setup.

---

## Day 49 — GitHub Actions release pipeline

Tag-triggered workflow builds a signed, notarised **Drazlo** DMG and attaches it to a GitHub Release.

| Item | Value |
|------|--------|
| Workflow | `.github/workflows/release.yml` |
| Trigger | Push tag `v*` (e.g. `v1.0.0`); optional `workflow_dispatch` |
| Runner | `macos-15` |
| Output | `build/Drazlo-<version>.dmg` on GitHub Releases |
| Scripts reused | `archive_release.sh`, `notarize_app.sh`, `create_dmg.sh`, `notarize_dmg.sh` |

### Required GitHub Secrets

Configure in **Repository → Settings → Secrets and variables → Actions**:

| GitHub Secret | Maps to (in scripts) | Notes |
|---------------|----------------------|--------|
| `CERTIFICATES_P12` | `apple-actions/import-codesign-certs` | Base64-encoded Developer ID Application `.p12` |
| `CERTIFICATES_P12_PASSWORD` | import-codesign-certs | Password used when exporting the `.p12` |
| `APPLE_ID` | `NOTARY_APPLE_ID` | Apple ID email for notarytool |
| `TEAM_ID` | `NOTARY_TEAM_ID` | `6XP66CQ82V` |
| `APPLE_APP_PASSWORD` | `NOTARY_APP_PASSWORD` | App-specific password from [appleid.apple.com](https://appleid.apple.com) |

Template (no secrets): `Scripts/github-secrets.example`  
Local notarisation env: `Scripts/notary.env.example`

### Export Developer ID certificate as base64

```bash
# Keychain Access → My Certificates → Developer ID Application → Export .p12
base64 -i DeveloperID.p12 | pbcopy   # paste into CERTIFICATES_P12 secret
```

Create an app-specific password: Apple ID → Sign-In and Security → App-Specific Passwords.

### Release a version

```bash
git tag v1.0.0
git push origin v1.0.0
```

1. GitHub Actions runs `.github/workflows/release.yml` (~10–15 min).
2. Download **Drazlo-1.0.0.dmg** from **Releases** when the workflow completes.
3. Verify locally:

```bash
spctl -a -vv -t open --context context:primary-signature Drazlo-1.0.0.dmg
xcrun stapler validate Drazlo-1.0.0.dmg
```

### Post-release (manual)

1. Upload DMG to your website CDN (when live).
2. Update Sparkle appcast (Day 48):

```bash
./Scripts/sign_sparkle_update.sh build/Drazlo-1.0.0.dmg
# Copy edSignature + length into Resources/Release/appcast.xml → publish appcast.xml
```

### CI notes

- **DMG layout** — `create-dmg --skip-jenkins` packages the volume; `Scripts/write_ds_store.py` writes `.DS_Store` via Python (`ds_store` + `mac_alias`). Install deps: `pip install -r Scripts/requirements-dmg.txt`
- **`VERSION`** — derived from git tag (`v1.0.0` → `1.0.0`) so DMG filename matches the release tag.
- **Manual dispatch** — Actions → workflow → Run workflow; uploads artifact but creates a GitHub Release **only** on tag push.
- **Optional future:** attach signed `appcast.xml` via `SPARKLE_EDDSA_PRIVATE_KEY` secret (not implemented).

### CI troubleshooting

| Issue | What to check |
|-------|----------------|
| Certificate import fails | Valid base64 `.p12`; correct password secret |
| Archive fails | SPM resolved; scheme `Drazlo`; team `6XP66CQ82V` in project |
| Notary rejected | Same entitlements audit as Day 46; hardened runtime enabled |
| DMG layout fails | Ensure `pip install -r Scripts/requirements-dmg.txt`; eject stale `/Volumes/Drazlo` mounts before rebuild |
| Release not created | Only tag pushes create Releases; use `workflow_dispatch` for test builds + artifact |

**Out of scope:** CDN deploy, live appcast hosting, Mac App Store.
