# FrameFlow — Current Status

**Last updated:** 2026-05-26  
**Version:** v0.1.0

## Current Phase

**Phase 4 — Permissions & core screens** (blueprint-aligned, Option B)

## Currently Working On

- Ready for **Blueprint Day 11** — Onboarding polish + Help screen

## Completed

- Single Git repo; MVVM layout; auth (Days 5–7)
- **Blueprint Day 8:** `PermissionManager`, `DeviceCapabilityManager`, entitlements, minimal Settings permissions UI
- **Blueprint Day 9:** `DashboardView`, `RecordingStore`, recording list UI + empty state
- **Blueprint Day 10:** `SettingsStore`, full `SettingsView`, `ProfileView`, `UserService`

## Next Task

1. **Blueprint Day 11** — Onboarding polish and Help screen
2. No ScreenCaptureKit recording/streaming yet (Day 12+)

## Important Decisions

| Topic | Decision |
|-------|----------|
| Permissions | Screen recording checked via `SCShareableContent`; camera/mic via AVFoundation |
| Sandbox | **Outgoing Connections (Client)** required for Supabase — do not disable |
| Settings | `SettingsStore` singleton → UserDefaults; appearance via `RootView.preferredColorScheme` |
| Recording metadata | Sandboxed path: `~/Library/Containers/com.Simranjit.FrameFlow/Data/Library/Application Support/FrameFlow/recordings.json` |
| Subscription | `AppState.subscriptionStatus` scaffold only; Manage Subscription → placeholder |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
