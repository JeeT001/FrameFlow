# FrameFlow — Current Status

**Last updated:** 2026-07-07  
**Version:** v1.0.13 (released — editor trim, Free layout grid, range slider UI)  
**Repository:** [public on GitHub](https://github.com/JeeT001/FrameFlow) — anonymous DMG download works

## Current Phase

**Phase 19 — Final Preparation** (Days 50–55) — **launch-ready** (marketing pending)

## Recently completed

- **Day 54 billing** — RevenueCat Production, Stripe Live, webhook + Supabase secrets, test purchase → Pro unlock, CI `REVENUECAT_API_KEY`
- **v1.0.9 (released)** — Editor caption burn-in when sidecar unavailable; dev route picker + debug Settings hidden in Release
- **Phase 1 trim (shipped in 1.0.13)** — Global in/out handles re-wired to preview + export; range slider UI; file-absolute timeline; sidecar unchanged
- **Free layout grid (shipped in 1.0.13)** — 1–4 windows seed TL/TR/BL/BR instead of center overlap
- **v1.0.12 (released)** — Sparkle sandbox fix: in-app Check for Updates install works on sandboxed builds
- **v1.0.11 (released)** — CaptionRenderer offline-export-safe CATextLayer; Classic captions show readable text in QuickTime
- **Public repo** — GitHub public; anonymous DMG download via `/download`
- **v1.0.8** — Sparkle + legal URLs point to `https://drazlo.vercel.app`; Check for Updates verified
- **Day 55 (technical)** — Marketing site on Vercel, GitHub Actions auto-deploy, appcast build 8, `/download` → v1.0.8 DMG
- **v1.0.7** — `SUPublicEDKey` shipped in binary
- **Day 49** — GitHub Actions release pipeline validated

## Day 55 deliverables

| Item | Status |
|------|--------|
| Marketing homepage (`website/index.html`) | Done |
| **GitHub repo public** | Done — releases downloadable without login |
| Vercel deploy + auto-deploy on `main` | Done — `https://drazlo.vercel.app` |
| Download URL (`/download` → GitHub Release DMG) | Done — v1.0.13 |
| Sparkle appcast | Done — build 13 on Vercel |
| Release notes `/release-notes/1.0.13/` | Done |
| Marketing drafts (Product Hunt, email, social) | Done — `Docs/LAUNCH_DAY55.md` |
| **Manual:** YouTube demo, Product Hunt, email, social | **Pending** |
| **Optional:** Register `drazlo.app` → same Vercel project | Deferred |

**Download:** https://drazlo.vercel.app/download · [GitHub v1.0.13](https://github.com/JeeT001/FrameFlow/releases/download/v1.0.13/Drazlo-1.0.13.dmg) (no GitHub account required)

## Day 54 gate (billing)

| Item | Status |
|------|--------|
| RevenueCat Production + Stripe Live | Done |
| Webhook + Supabase secrets | Done |
| Purchase → Pro unlock (~30s) | Done |
| GitHub secret `REVENUECAT_API_KEY` (CI) | Done |

## Next Task

1. **Publish marketing** — demo video, Product Hunt, email, social (use `drazlo.vercel.app` links in drafts)
2. **Optional later** — register `drazlo.app`, add to Vercel Domains

## Reference Docs

- [Launch Day 55](LAUNCH_DAY55.md)
- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Release Signing](RELEASE_SIGNING.md)
- [Releasing Updates](RELEASING_UPDATES.md)
