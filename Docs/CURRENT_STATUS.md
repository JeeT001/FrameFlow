# FrameFlow — Current Status

**Last updated:** 2026-05-26  
**Version:** v0.1.0

## Current Phase

**Phase 4 — Permissions & core screens** (blueprint-aligned, Option B)

## Currently Working On

- Ready for **Blueprint Day 9** — Dashboard with recordings list and empty state

## Completed

- Single Git repo; MVVM layout; auth (Days 5–7)
- **Blueprint Day 8:** `PermissionManager`, `DeviceCapabilityManager`, entitlements, minimal Settings permissions UI

## Next Task

1. **Blueprint Day 9** — `DashboardView`, `RecordingStore`, recording list UI
2. No ScreenCaptureKit recording/streaming yet (Day 12+)

## Important Decisions

| Topic | Decision |
|-------|----------|
| Permissions | Screen recording checked via `SCShareableContent`; camera/mic via AVFoundation |
| Sandbox | **Outgoing Connections (Client)** required for Supabase — do not disable |
| Device caps | MVP defaults: Apple Silicon 4 windows / 60fps / 4K; Intel 2 / 30fps / no 4K |
| Settings | Day 8 permissions section only; full Settings on Day 10 |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
