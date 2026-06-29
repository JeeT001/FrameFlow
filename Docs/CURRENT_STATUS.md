# FrameFlow — Current Status

**Last updated:** 2026-06-29  
**Version:** v1.0.7 (released — Sparkle auto-update fixed)

## Current Phase

**Phase 19 — Final Preparation** (Days 50–55) on branch `day55`

## Recently completed

- **Day 55 (in repo)** — Launch homepage, download redirect, Sparkle appcast v1.0.6, `SUPublicEDKey`, release notes page, `Docs/LAUNCH_DAY55.md`
- **v1.0.6** — CI release: gradient-only DMG (no arrow), notarized (`Drazlo-1.0.6.dmg`)
- **v1.0.5** — Combined audio fix, UI polish, Stripe checkout
- **Day 49** — GitHub Actions release pipeline validated

## Day 55 deliverables

| Item | Status |
|------|--------|
| Marketing homepage (`website/index.html`) | Done |
| Download URL (`/download` → GitHub Release DMG) | Done (deploy to Vercel) |
| Sparkle appcast (`website/appcast.xml`, `Resources/Release/appcast.xml`) | Done |
| `SUPublicEDKey` in Info.plist | Done — ships in **next** app tag |
| Release notes page `/release-notes/1.0.6/` | Done |
| Marketing drafts (Product Hunt, email, social) | Done — `Docs/LAUNCH_DAY55.md` |
| **Manual:** Deploy website to drazlo.app | Pending |
| **Manual:** Publish appcast at production URL | Pending |
| **Manual:** YouTube demo, Product Hunt, email, social | Pending |

**Download:** https://drazlo.app/download (after deploy) or [GitHub v1.0.6](https://github.com/JeeT001/FrameFlow/releases/download/v1.0.6/Drazlo-1.0.6.dmg)

## Day 54 gate (billing — verify before paid launch)

| Item | Status |
|------|--------|
| RevenueCat Production + Stripe Live | **Manual** |
| Webhook + Supabase secrets | **Manual** |
| Purchase → Pro unlock (~30s) | **Verify** |

## Next Task

1. **Deploy** `website/` to Vercel (drazlo.app)
2. **Tag v1.0.7** (or patch) to ship `SUPublicEDKey` in binary + test Sparkle
3. **Finish Day 54** — Production billing verification
4. **Publish** marketing assets from `LAUNCH_DAY55.md`

## Reference Docs

- [Launch Day 55](LAUNCH_DAY55.md)
- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Release Signing](RELEASE_SIGNING.md)
- [Releasing Updates](RELEASING_UPDATES.md)
