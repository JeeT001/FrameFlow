# FrameFlow — Current Status

**Last updated:** 2026-05-26  
**Version:** v0.1.0

## Current Phase

**Phase 6 — Window capture** (blueprint-aligned)

## Currently Working On

- Ready for **Blueprint Day 14** — Layout Picker UI

## Completed

- Auth, Dashboard, Profile, Settings, Onboarding, Help (Days 5–11)
- **Blueprint Day 12:** `WindowCaptureService`, `WindowItem`
- **Blueprint Day 13:** `WindowPickerView` + selection limits + permission empty state

## Next Task

1. **Blueprint Day 14** — `LayoutPickerView` (format, layouts, camera, audio sheet)
2. No `SCStream` / recording engine yet (Day 16+)

## Important Decisions

| Topic | Decision |
|-------|----------|
| Selection limits | Free: 2 windows; Pro: `min(4, maxWindows)` |
| Picker persistence | `AppState.selectedWindowIDs` set on **Next** |
| Thumbnails | Windows &lt; 120×120 listed without thumbnail capture |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
