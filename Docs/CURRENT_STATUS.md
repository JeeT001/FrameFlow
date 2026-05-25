# FrameFlow — Current Status

**Last updated:** 2026-05-25  
**Version:** v0.1.0

## Current Phase

**Phase 1 — App foundation** (blueprint-aligned, Option B)

## Currently Working On

- Project documentation and Cursor setup (Part 1 complete)
- Next: align Xcode folder layout under `App/` (no recording engine yet)

## Completed

- Xcode macOS SwiftUI project (macOS 14.0+)
- Git repository
- `NavigationSplitView` shell with sidebar: **Home, Settings, Account**
- `AppRouter` + `AppRoute` (18 blueprint screens)
- Placeholder screens with planned UI elements
- Toolbar route picker for placeholder-phase navigation testing
- Cursor rules, status docs, and dev log (canonical paths under `Docs/`)

## Next Task

1. **Part 2 (code):** Move Swift sources into `App/Views`, `App/ViewModels`, etc. per architecture rules (refactor only, no new features)
2. **Day 2 (blueprint):** SPM dependencies + `Config.swift` + `.gitignore` for secrets
3. **Phase 3+:** Supabase auth — do not start ScreenCaptureKit or recording engine until foundation is stable

## Important Decisions

| Topic | Decision |
|-------|----------|
| Platform | Native macOS, SwiftUI |
| Architecture | MVVM; `@Observable` for routers/state (macOS 14+) |
| Navigation | **Option B** — follow `FrameFlow_Master_Blueprint.md` (not simplified Record/Projects sidebar) |
| Distribution | DMG first; signed and notarized |
| Backend | Supabase |
| Payments | RevenueCat + Stripe |
| Capture | ScreenCaptureKit (later phases) |
| Captions | WhisperKit (later phases) |
| Docs | `CURRENT_STATUS.md`, `DEV_LOG.md`, `CURSOR_START_HERE.md` are source of truth for agent context |

## Code Layout Note

Target layout is under `FrameFlow/FrameFlow/App/`. Some Phase 1 files still live at `FrameFlow/FrameFlow/Views/` until Part 2 folder migration.

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Cursor Start Here](CURSOR_START_HERE.md)
