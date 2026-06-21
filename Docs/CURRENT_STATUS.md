# FrameFlow — Current Status

**Last updated:** 2026-06-20  
**Version:** v1.0.0

## Current Phase

**Phase 18 complete (Day 49)** — GitHub Actions release pipeline on branch `day49`

## Recently completed

- **Day 49** — Tag-triggered GitHub Actions workflow (archive → notarise app → DMG → notarise DMG → GitHub Release)
- **Day 48** — Sparkle 2 auto-update (weekly check, Settings + menu manual check, appcast template)
- **Day 47** — DMG creation, layout polish, notarisation workflow
- **Day 46** — Developer ID archive/export, app notarisation scripts

## Day 49 deliverables

| Item | Status |
|------|--------|
| `.github/workflows/release.yml` | Done |
| Reuses `Scripts/archive_release.sh` … `notarize_dmg.sh` | Done |
| `SKIP_DMG_POLISH` CI flag in `create_dmg.sh` | Done |
| `Scripts/github-secrets.example` | Done |
| `Docs/RELEASE_SIGNING.md` Day 49 section | Done |

## Next Task

1. Add GitHub Secrets and push first tag (`v1.0.0`) to validate pipeline
2. Host `appcast.xml` + signed DMG on live domain when marketing site is ready
3. **Day 54 / launch** — RevenueCat Production + Stripe production + webhook deploy

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Release Signing](RELEASE_SIGNING.md)
