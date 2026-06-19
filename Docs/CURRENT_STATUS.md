# FrameFlow — Current Status

**Last updated:** 2026-06-18  
**Version:** v0.1.0

## Current Phase

**Day 46 — Code Signing + Notarisation** (Phase 17) on branch `day46`

## Currently Working On

- **Day 46** — Developer ID archive/export scripts, notarisation workflow docs, entitlements audit
- **Next:** Day 47 DMG creation + signing

## Recently merged to main (context)

- Window Picker loading fix; caption preview/export parity; transcription 30s skip fix
- Auth placeholders + AuthFocus; sidebar Help nav; calm Pro footer reminder; Settings “Support the Creator”

## Day 46 deliverables

| Item | Status |
|------|--------|
| `Scripts/ExportOptions.plist` | Added |
| `Scripts/archive_release.sh` | Added |
| `Scripts/notarize_app.sh` | Added (env-var credentials) |
| `Docs/RELEASE_SIGNING.md` | Added |
| Release build (`Drazlo` scheme) | Verified compile |
| Notarisation submit/staple | **User must run locally** with Apple ID + Developer ID cert |

## Next Task

1. **Day 47** — DMG background + `create-dmg` + sign/notarise DMG
2. **Day 48** — Sparkle 2 wiring + appcast
3. **Day 49** — GitHub Actions release pipeline
4. **Day 54 / launch** — RevenueCat Production + Stripe production + webhook deploy

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Release Signing](RELEASE_SIGNING.md)
