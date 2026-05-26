# FrameFlow — Current Status

**Last updated:** 2026-05-26  
**Version:** v0.1.0

## Current Phase

**Phase 6 — Window capture & layout** (blueprint-aligned)

## Currently Working On

- Ready for **Blueprint Day 15** — Audio mode picker with volume sliders + live meter

## Completed

- Auth, Dashboard, Profile, Settings, Onboarding, Help (Days 5–11)
- **Day 12–13:** `WindowCaptureService`, `WindowPickerView`
- **Blueprint Day 14:** `LayoutPickerView`, layout preview canvas, minimal `AudioModePickerView` sheet

## Next Task

1. **Blueprint Day 15** — Full audio sheet (volumes, live level meter)
2. **Blueprint Day 16+** — `SCStream` composite preview / recording engine

## Important Decisions

| Topic | Decision |
|-------|----------|
| 9:16 format | Pro only; free users see upgrade sheet |
| Layout preview | Placeholder rectangles only (no SCStream until Day 16) |
| Audio sheet Day 14 | 4 mode cards + Confirm; no live meter yet |
| Session layout | Format/preset/camera in `LayoutPickerViewModel`; audio/toggles in `SettingsStore` |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
