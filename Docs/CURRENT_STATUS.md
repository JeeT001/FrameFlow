# FrameFlow — Current Status

**Last updated:** 2026-06-19  
**Version:** v1.0.0

## Current Phase

**Day 49 — GitHub Actions release pipeline** (Phase 18) on branch `day49`

## Recently completed

- **Day 48** — Sparkle 2 auto-update (weekly check, Settings + menu manual check, appcast template, sign script)
- **Day 47** — DMG creation, layout polish, notarisation workflow (verified locally)
- **Day 46** — Developer ID archive/export, app notarisation scripts, `Docs/RELEASE_SIGNING.md`

## Day 48 deliverables

| Item | Status |
|------|--------|
| `AppUpdaterController` + `FrameFlowApp` Sparkle wiring | Done |
| Settings + app menu Check for Updates | Done |
| Info.plist `SUFeedURL`, `SUPublicEDKey`, weekly auto-check | Done |
| `Resources/Release/appcast.xml` template | Done |
| `Scripts/sign_sparkle_update.sh` + `sparkle.env.example` | Done |
| `Docs/RELEASE_SIGNING.md` Day 48 section | Done |

## Next Task

1. **Day 49** — GitHub Actions release pipeline (`.github/workflows/release.yml`)
2. Host `appcast.xml` + signed DMG on live domain when marketing site is ready
3. **Day 54 / launch** — RevenueCat Production + Stripe production + webhook deploy

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Release Signing](RELEASE_SIGNING.md)
