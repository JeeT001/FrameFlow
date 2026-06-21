# Releasing Drazlo Updates

How to ship new features and bug fixes to users who already have Drazlo installed, and to new downloaders.

**Product:** Drazlo (`com.Simranjit.FrameFlow`)  
**Distribution:** Direct download (DMG) — not Mac App Store  
**Auto-update:** Sparkle 2 (weekly check + manual “Check for Updates”)

Related docs:
- [RELEASE_SIGNING.md](RELEASE_SIGNING.md) — certificates, notarisation, Sparkle keys, CI secrets
- [CHANGELOG.md](CHANGELOG.md) — user-facing release notes
- [DEV_LOG.md](DEV_LOG.md) — internal build log

---

## How users get updates

| User type | How they update |
|-----------|-----------------|
| **Existing install** | Sparkle prompts in-app (automatic check every 7 days, or **Settings → About → Check for Updates**) |
| **New user** | Download latest DMG from GitHub Releases or your website |
| **You (testing)** | Install DMG over old app, or let Sparkle offer the update |

Sparkle only works when **all** of these are true:

1. `Info.plist` → `SUFeedURL` points to a live appcast (`https://drazlo.app/appcast.xml`)
2. `SUPublicEDKey` is set (Sparkle EdDSA public key — not the placeholder)
3. You publish an updated `appcast.xml` with a **newer** version than what the user has installed
4. The DMG in the appcast is signed with Sparkle’s `sign_update` (EdDSA signature in the appcast)

GitHub Releases alone does **not** push updates to installed apps — you must update the appcast after each release.

---

## Version numbers (two fields)

In Xcode → **Drazlo** target → **General** (or `project.pbxproj`):

| Field | Xcode name | Example | Purpose |
|-------|------------|---------|---------|
| **Marketing version** | `MARKETING_VERSION` | `1.0.5` | User-visible “1.0.5” in About, DMG name, git tag |
| **Build number** | `CURRENT_PROJECT_VERSION` | `5` | Must increase every upload; Sparkle compares this |

**Rules:**

- **Bug fix** → bump build only *or* patch marketing version: `1.0.4` → `1.0.5`, build `5`
- **New feature** → bump minor: `1.0.x` → `1.1.0`, reset or increment build
- **Breaking change** → bump major: `1.x` → `2.0.0`
- Git tag must match marketing version: tag `v1.0.5` → DMG `Drazlo-1.0.5.dmg`
- Update **both** Debug and Release target settings in the project if they diverge

Also keep in sync when publishing Sparkle:

- `Resources/Release/appcast.xml` — `sparkle:version`, `sparkle:shortVersionString`, title, enclosure URL
- Optional: `AppBranding.appcastFeedURL` and `Info.plist` `SUFeedURL` (should already match)

---

## Release checklist (every time)

Use this for features **and** bug fixes.

### 1. Develop and test locally

```bash
cd FrameFlow
xcodebuild -scheme Drazlo -configuration Debug build
```

- Fix the feature or bug on your working branch (e.g. `phase-19` or `fix/…`)
- Smoke-test: record → edit → export → sign in → subscription screen
- Update [CHANGELOG.md](CHANGELOG.md) under `[Unreleased]` (or add a new version section)

### 2. Bump version in Xcode

1. Open `FrameFlow/FrameFlow.xcodeproj`
2. Select **Drazlo** target → **General**
3. Set **Version** (`MARKETING_VERSION`) and **Build** (`CURRENT_PROJECT_VERSION`)
4. Confirm **About** in the app shows the new version after rebuild

### 3. Merge to `main`

Production releases come from `main` (see [Master Blueprint](FrameFlow_Master_Blueprint.md) git workflow).

```bash
git checkout main
git pull origin main
git merge your-feature-branch   # or open a PR and merge on GitHub
```

### 4. Tag and push (triggers CI release)

```bash
git tag v1.0.5
git push origin main
git push origin v1.0.5
```

- Tag format: **`v` + marketing version** (e.g. `v1.0.5`)
- GitHub Actions workflow: `.github/workflows/release.yml`
- Wait ~5–15 minutes; check **Actions** tab for green build
- Download **`Drazlo-1.0.5.dmg`** from **GitHub → Releases**

### 5. Publish Sparkle appcast (so existing users update)

After the DMG is built:

```bash
# Download DMG from GitHub Releases to build/ (or use local build)
./Scripts/sign_sparkle_update.sh build/Drazlo-1.0.5.dmg
```

Copy the printed **`edSignature`** and **`length`** into `Resources/Release/appcast.xml`:

- Add a new `<item>` (or update the existing one) with the new version
- Set `enclosure url` to where the DMG is hosted (GitHub asset URL or `https://drazlo.app/downloads/…`)
- Set `pubDate` to RFC 822 format
- Ensure `sparkle:version` / build number is **greater** than the previous release

Upload:

1. **DMG** — GitHub Releases (automatic) and/or your website CDN
2. **`appcast.xml`** — `https://drazlo.app/appcast.xml` (must match `SUFeedURL`)

### 6. Verify update path

On a Mac with an **older** Drazlo installed:

1. **Settings → About → Check for Updates** — Sparkle should offer the new version
2. Install update → confirm version in About
3. Optional: fresh Mac test — download DMG, drag to Applications, no Gatekeeper block

### 7. Document the release

- Move items in [CHANGELOG.md](CHANGELOG.md) from `[Unreleased]` to `[1.0.5] - YYYY-MM-DD`
- Add a short entry to [DEV_LOG.md](DEV_LOG.md) if it was significant work
- Update [CURRENT_STATUS.md](CURRENT_STATUS.md) if phase/milestone changed

---

## Quick reference: tag release (most common path)

```bash
# 1. Version bumped in Xcode, changes merged to main
git checkout main && git pull

# 2. Tag matches MARKETING_VERSION
git tag v1.0.5
git push origin v1.0.5

# 3. When CI finishes — sign for Sparkle and update appcast
./Scripts/sign_sparkle_update.sh build/Drazlo-1.0.5.dmg
# Edit Resources/Release/appcast.xml → upload to drazlo.app

# 4. Test Sparkle on a machine with the previous version
```

---

## Local release (without GitHub Actions)

Use when CI is down or you want a build on your machine only. Full detail in [RELEASE_SIGNING.md](RELEASE_SIGNING.md).

```bash
# From repo root — requires Developer ID cert + notary credentials
./Scripts/archive_release.sh

export NOTARY_APPLE_ID="you@example.com"
export NOTARY_TEAM_ID="6XP66CQ82V"
export NOTARY_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"

./Scripts/notarize_app.sh
./Scripts/release_dmg.sh
# Output: build/Drazlo-<version>.dmg
```

Then sign for Sparkle and update appcast as in step 5 above.

---

## CI notes

| Topic | Detail |
|-------|--------|
| **Trigger** | Push tag `v*` only creates a GitHub Release with DMG attached |
| **Secrets** | `CERTIFICATES_P12`, `CERTIFICATES_P12_PASSWORD`, `APPLE_ID`, `TEAM_ID`, `APPLE_APP_PASSWORD` |
| **Config.swift** | CI copies `Config.example.swift` if missing — production keys for PostHog, feedback URL, etc. must be in repo secrets or baked into a CI-safe Config strategy before launch |
| **DMG polish** | CI sets `SKIP_DMG_POLISH=1` (no Finder AppleScript on headless runner) |

---

## What to include in release notes

Sparkle can link to release notes (`sparkle:releaseNotesLink` in appcast). Good content:

- **Fixed:** …
- **Added:** …
- **Changed:** …

Keep notes short; link to a blog or changelog page for long lists.

Example appcast release notes URL: `https://drazlo.app/release-notes/1.0.5`

---

## Bug fix vs feature (same process)

There is **one release pipeline** for both:

| Change type | Version bump | Everything else |
|-------------|--------------|-----------------|
| Bug fix | Patch + build (`1.0.4` → `1.0.5`) | Same tag → CI → appcast flow |
| Small fix | Build only sometimes works, but patch is clearer for users | Same |
| New feature | Minor (`1.0` → `1.1`) | Same |
| Hotfix | Branch `fix/…`, merge fast, tag immediately | Same |

Do **not** skip the appcast step for bug fixes — otherwise installed users never receive the fix.

---

## Sparkle one-time setup (if not done yet)

1. Download [Sparkle release utilities](https://github.com/sparkle-project/Sparkle/releases)
2. Run `generate_keys` → paste **public** key into `Info.plist` → `SUPublicEDKey`
3. Store **private** key locally (`~/.sparkle/` or `Scripts/sparkle.env` — never commit)
4. Host `appcast.xml` at `https://drazlo.app/appcast.xml`

Until `SUPublicEDKey` is real and appcast is live, “Check for Updates” will not offer downloads.

---

## Troubleshooting

| Problem | Likely cause |
|---------|----------------|
| CI failed on tag push | Check Actions log — often signing, notary, or SPM resolve |
| Users see “You’re up to date” | Appcast version ≤ installed build; or appcast URL unreachable |
| Gatekeeper blocks DMG | DMG or app not notarised; run `spctl` / `stapler validate` |
| Sparkle signature error | Re-run `sign_sparkle_update.sh`; update `edSignature` + `length` in appcast |
| Wrong DMG version in filename | Tag must be `v` + `MARKETING_VERSION`; rebuild after bumping Xcode version |

More detail: [RELEASE_SIGNING.md](RELEASE_SIGNING.md) troubleshooting tables.

---

## Suggested commit before tagging

```
chore: bump version to 1.0.5 for release
```

Separate commit from feature work when possible — makes rollback and release notes easier.

---

## Summary

1. **Build & test** → bump **Version + Build** in Xcode  
2. **Merge to `main`** → **`git tag vX.Y.Z`** → **`git push origin vX.Y.Z`**  
3. **Download DMG** from GitHub Releases  
4. **`sign_sparkle_update.sh`** → update **`appcast.xml`** → upload to **drazlo.app**  
5. **Verify** Sparkle update on a machine with the previous version  
6. **Update** CHANGELOG + DEV_LOG  

That’s the full loop for every feature release and bug fix.
