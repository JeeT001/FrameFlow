# FrameFlow — Current Status

**Last updated:** 2026-05-26  
**Version:** v0.1.0

## Current Phase

**Phase 3 — Authentication** (blueprint-aligned, Option B)

## Currently Working On

- Ready for **Blueprint Day 8** — permissions and device detection

## Completed

- Single Git repo at project root
- MVVM layout + `NavigationSplitView` shell (Option B)
- **Blueprint Day 2–6:** SPM, auth service, auth UI
- **Blueprint Day 7:** `AppState`, session restore on launch, root auth routing (onboarding → login → main shell)

## Next Task

1. **Blueprint Day 8** — screen recording / camera / mic permission status and guides
2. Do not start ScreenCaptureKit recording engine until permissions foundation is in place

## Important Decisions

| Topic | Decision |
|-------|----------|
| Auth guard | `AppState.authStatus` drives `RootView`; sidebar only when `.authenticated` |
| Onboarding flag | UserDefaults key `hasCompletedOnboarding` |
| Session restore | `AuthService.restoreSession()` on bootstrap (refresh if needed) |
| Sign out (Day 7) | Temporary **Sign Out** on Profile placeholder for testing |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Cursor Start Here](CURSOR_START_HERE.md)
