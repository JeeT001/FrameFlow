# FrameFlow — Current Status

**Last updated:** 2026-05-26  
**Version:** v0.1.0

## Current Phase

**Phase 6 — Window capture & layout** (blueprint-aligned)

## Currently Working On

- Ready for **Blueprint Day 16** — Composite preview canvas groundwork

## Completed

- Auth, Dashboard, Profile, Settings, Onboarding, Help (Days 5–11)
- **Day 12–13:** `WindowCaptureService`, `WindowPickerView`
- **Blueprint Day 14:** `LayoutPickerView`, layout preview canvas, minimal `AudioModePickerView`
- **Blueprint Day 15:** full `AudioModePickerView` with draft volume sliders + live mic level bars

## Next Task

1. **Blueprint Day 16** — SCStream multi-window composite preview
2. Recording/export pipeline remains pending

## Important Decisions

| Topic | Decision |
|-------|----------|
| 9:16 format | Pro only; free users see upgrade sheet |
| Layout preview | Placeholder rectangles only (no SCStream until Day 16) |
| Audio sheet Day 15 | 4 mode cards + draft mic/system sliders + mic-only live meter |
| Volume persistence | UI uses 0–100%; saved as Float 0.0–1.0 on Confirm |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
