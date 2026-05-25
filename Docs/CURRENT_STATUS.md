# FrameFlow — Current Status

**Last updated:** 2026-05-26  
**Version:** v0.1.0

## Current Phase

**Phase 3 — Authentication** (blueprint-aligned, Option B)

## Currently Working On

- Ready for **Blueprint Day 7** — session persistence + `AppState` auth guard

## Completed

- Xcode macOS SwiftUI project (macOS 14.0+ target on app)
- Single Git repo at project root
- MVVM folder layout under `FrameFlow/FrameFlow/App/`
- `NavigationSplitView` shell: sidebar **Home, Settings, Account** (Option B)
- `AppRouter` + `AppRoute` (18 routes; auth screens now functional)
- **Blueprint Day 2:** SPM dependencies + `Config.example.swift` + `.gitignore`
- **Blueprint Day 5:** `SupabaseClientProvider` + `AuthService`
- **Blueprint Day 6:** Login, Sign Up, Forgot Password views + `@Observable` ViewModels

## Next Task

1. **Blueprint Day 7** — `AppState` session check on launch, onboarding guard, root auth routing
2. Do not start ScreenCaptureKit or recording engine until auth flow is stable

## Important Decisions

| Topic | Decision |
|-------|----------|
| Platform | Native macOS, SwiftUI |
| Architecture | MVVM; `@Observable` for routers and auth ViewModels |
| Navigation | **Option B** — sidebar + `AppRouter`; auth screens navigate via `router.navigate(to:)` |
| Auth UI | Day 6 complete; no root auth guard until Day 7 |
| Secrets | `Config.swift` gitignored; never committed |
| Capture / captions | Later phases only |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Cursor Start Here](CURSOR_START_HERE.md)
