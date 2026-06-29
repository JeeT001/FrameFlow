# FrameFlow — Current Status

**Last updated:** 2026-06-29  
**Version:** v1.0.6 (CI release in progress)

## Current Phase

**Phase 19 — Final Preparation** (Days 50–55) on branch `testingPhae19` / `phase-19`

## Recently completed

- **Day 54 (in progress)** — `revenuecat-webhook` deployed to Supabase production; CI injects `REVENUECAT_API_KEY` on release builds; dashboard secrets + RC/Stripe Live still required manually
- **Day 53 fixes** — Caption export parity (Classic, Highlighted, TikTok), PiP warmup, SRT on export only, post-export Done toolbar
- **Day 52** — Feedback banner after 3rd export (weekly cap)
- **Day 50** — Drazlo app icon in `AppIcon.appiconset` (all macOS sizes; used in app, DMG, Dock/Finder)
- **Day 49** — GitHub Actions release pipeline validated (`v1.0.4` green, DMG on Releases)
- **v1.0.5** — CI release published: combined audio fix, UI polish, Stripe checkout (`Drazlo-1.0.5.dmg`)

## Day 54 deliverables

| Item | Status |
|------|--------|
| Edge Function `revenuecat-webhook` deployed (`rdqohexzpxrkggcagrmq`) | Done |
| Webhook URL registered in RevenueCat | **Manual** |
| `REVENUECAT_WEBHOOK_SECRET` + `SUPABASE_SERVICE_ROLE_KEY` in Supabase secrets | **Manual** |
| RevenueCat Production + Stripe Live + Default offering | **Manual** |
| CI `REVENUECAT_API_KEY` GitHub secret + release.yml injection | Done (set secret before tag) |
| Local production RC key in gitignored `Config.swift` | **Manual** for launch testing |
| Purchase + webhook → `public.subscriptions` (~30s) | **Verify** after secrets |

**Webhook URL:** `https://rdqohexzpxrkggcagrmq.supabase.co/functions/v1/revenuecat-webhook`

## Next Task

1. **Day 54 finish** — Set Supabase secrets; register webhook in RevenueCat; switch RC + Stripe to Production; verify purchase sync
2. **Day 55** — Website, appcast, marketing launch assets
3. **Day 51** — Privacy Policy + Terms (website)

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Release Signing](RELEASE_SIGNING.md)
- [Releasing Updates](RELEASING_UPDATES.md)
- [Webhook deploy](../supabase/functions/revenuecat-webhook/README.md)
