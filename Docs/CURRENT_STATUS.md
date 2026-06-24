# FrameFlow — Current Status

**Last updated:** 2026-05-29  
**Version:** v1.0.4

## Current Phase

**Phase 19 — Final Preparation** (Days 50–55) on branch `phase-19`

## Recently completed

- **Day 53 fix** — Caption preview/export A/V stretch alignment, burn-in mapping, PiP stale-frame guard (build green; manual retest pending)
- **Day 52** — Feedback banner after 3rd export (weekly cap)
- **Day 50** — Drazlo app icon in `AppIcon.appiconset` (all macOS sizes; used in app, DMG, Dock/Finder)
- **Day 49** — GitHub Actions release pipeline validated (`v1.0.4` green, DMG on Releases)
- **Day 48** — Sparkle 2 auto-update (weekly check, Settings + menu manual check, appcast template)
- **Day 47** — DMG creation, layout polish, notarisation workflow
- **Day 46** — Developer ID archive/export, app notarisation scripts

## Day 50 deliverables

| Item | Status |
|------|--------|
| `Assets.xcassets/AppIcon.appiconset` (16–512 @1x/@2x) | Done |
| `Resources/DMG/DrazloVolume.icns` (DMG volume icon) | Done |
| Icon in shipped `v1.0.4` DMG / Releases build | Done |
| Copyright + version metadata (`1.0.4` build `4`) | Done |

## Next Task

1. **Day 53 retest** — 9:16 + PiP + captions preview/export smoke test
2. **Day 51** — Privacy Policy + Terms (website)
3. **Day 54 / launch** — RevenueCat Production + Stripe production + webhook deploy

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Release Signing](RELEASE_SIGNING.md)
- [Releasing Updates](RELEASING_UPDATES.md) — ship features & bug fixes (Sparkle + GitHub Releases)
