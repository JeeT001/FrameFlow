# FrameFlow — Current Status

**Last updated:** 2026-05-30  
**Version:** v0.1.0

## Current Phase

**Phase 12 — Dark mode + polish** (blueprint-aligned)

## Currently Working On

- **Blueprint Day 36** — Settings wiring verification / polish (SettingsStore already exists)

## Completed

- Auth, Dashboard, Profile, Settings, Onboarding, Help (Days 5–11)
- **Day 12–15:** Window capture, picker, layout picker, full audio sheet
- **Blueprint Day 16:** `WindowStreamManager`, `CompositeEngine`, live `CompositePreviewView` on Layout Picker
- **Blueprint Day 17:** `RecordingEngine` (AVAssetWriter H.264), `RecordingView` HUD, RecordingStore integration
- **Blueprint Day 18:** `AudioCaptureService` mic path, writer audio input, ScreenCaptureKit system-audio ingress wiring with safe fallback
- **Blueprint Day 18.5:** `WindowStreamManager` now keeps per-window streams video-only and runs one dedicated display-based system-audio stream
- **Blueprint Day 19:** cursor tracking, click ripples, and auto-zoom transform integration in recording composite path
- **Blueprint Day 20:** active-app monitor maps frontmost app to selected windows and animates a blue focus border in composite output
- **Blueprint Day 21:** camera capture service + draggable/resizable PiP overlay and recording-time PiP compositing
- **A/V sync hotfix:** recording writer timestamps now use one shared host session clock for video + audio (and mic duration/combined mic-only safety improves remaining drift)
- **Blueprint Day 22:** pause/resume with `totalPausedDuration` offset — paused wall time excluded from writer PTS and HUD timer
- **Blueprint Day 23:** full-window recording preview, `RecordingHUDView` (auto-hide), pre-roll countdown
- **Blueprint Day 24:** WhisperKit on-device transcription, caption sidecar/SRT, burn-in export (Classic/TikTok/Minimal), Pro post-record flow + thin Caption Editor progress UI
- **Blueprint Day 25:** Full Caption Editor — split preview + segment editor, 5 style cards, position/export pickers, live SwiftUI caption overlay, export SRT/Burned In/Both
- **Blueprint Day 26:** `ExportView` + `ExportService` — resolution picker (720p free / 1080p+4K Pro), caption burn-in, free watermark, save-folder bookmarks, export notification
- **Blueprint Day 27:** `RecordingDetailView` — thumbnail, rename on disk, metadata, play/Reveal/Re-export/Delete; Dashboard card → detail, context menu Export
- **Blueprint Day 28:** `WatermarkCompositor` — bottom-left canvas watermark (10pt @ 1080p), pill + shadow; 16:9/9:16 letterbox; Pro skips watermark; export no longer overwrites `filePath`
- **Save-flow alignment:** Stop → App Support staging; Export → single MP4 in save folder; `pendingRecording` until export or discard
- **Blueprint Day 29:** Supabase `users` + `subscriptions` tables, RLS, migration in `supabase/migrations/`
- **Blueprint Day 30:** `FrameFlowUser` model; `UserService` sync with `public.users` (create/fetch/backfill/update); sign-up insert + session restore `ensureUserProfile`; Edge Function `revenuecat-webhook` (service role → `public.subscriptions`)
- **Blueprint Day 31:** `SubscriptionManager` — RevenueCat SDK configure/logIn/logOut/fetchStatus; `app_user_id` = Supabase UUID; `AppState.isPro` from entitlement `pro`; Test Store `customerInfo` only (no offerings/purchase)
- **Blueprint Day 32:** `SubscriptionView` (feature table + plan cards + Test Store purchase); `ProGateModifier` / `ProUpgradeSheet`; `SettingsStore.showLifetimeDeal`; offerings + purchase on `SubscriptionManager`
- **Blueprint Day 33:** `ExpiryBannerView` on Dashboard (dismiss until next launch); Renew → SubscriptionView; Profile Manage Subscription with RC portal + fallback alert; inactive entitlement maps to `past_due` / `expired`
- **Blueprint Day 34:** `KeyboardShortcutManager` — global + local Cmd shortcuts during recording; manual zoom on `ZoomController`; Help FAQ for shortcuts + Accessibility
- **Blueprint Day 35:** Asset Catalog semantic colors (10 tokens + AccentColor aligned); `AppColors` enum; View/Component migration (not Services/CI pipeline)

## Next Task

1. **Blueprint Day 36** — Verify SettingsStore wiring to app behaviour (already largely done)

## Important Decisions

| Topic | Decision |
|-------|----------|
| Preview FPS | Capture at 60 (Apple Silicon) / 30 (Intel); UI refresh ~30 Hz |
| Preview canvas | Composite output matches selected resolution (720p/1080p/4K) and format |
| Session state | `AppState.selectedFormat`, `selectedLayoutPreset`, `selectedWindowIDs` |
| Stream lifecycle | Start on Layout Picker appear; **stop on disappear** (no background leak) |
| Fallback | Placeholder `LayoutPreviewCanvas` + error text if streams fail |
| Export permissions | Save folder uses security-scoped bookmark; fallback to app container Recordings when bookmark missing/stale |
| Recording duration | Captured before writer finalize; persisted via `lastRecordedDurationSeconds` |
| Save folder UX | Settings shows orange hint when bookmark missing — user must tap **Choose…** again |
| Audio capture | Recording writes AAC audio track from microphone tap; dedicated display-based SCK stream handles system audio |
| Zoom behavior | Auto-zoom on click uses settings-driven scale/hold timing and eases back to identity |
| Click emphasis | Cursor highlight + ripple overlays are composited into recording preview/output frames |
| Auto-focus mode | Active app changes map to selected windows and animate a ~3pt blue border across panel transitions |
| Save-folder entitlements | Sandbox now includes user-selected read/write + app-scope bookmarks; users should re-pick save folder once after update |
| PiP camera | PiP uses AVCaptureSession camera frames, draggable/resizable config in Layout Picker, and final overlay composited after focus border |
| Writer timestamps | Video-led host clock (timescale 600): anchors on first video frame; audio gated until video timeline starts |
| Pause/resume | `totalPausedDuration` subtracted from append PTS; capture stays warm; no timeline gap in exported MP4 |
| Captions (Pro) | After save: Caption Editor; WhisperKit transcription in background; `hasCaptions` set only after user exports |
| Caption editor | 40/60 split: `CaptionPreviewView` + style cards + editable segments; export SRT / burn-in / both via `CaptionRenderer` |
| Caption styles | Five presets in editor; Highlighted Word burn-in + preview; Custom uses bordered classic preview |
| Export flow | Stop stages to App Support only; **Export** writes one MP4 to save folder; `pendingRecording` until export or discard |
| Recording detail | Dashboard card → detail; Re-export from exported file in save folder |
| Supabase schema | `users` + `subscriptions` in `public`; RLS own-row only; subscription writes via service role (Day 30 webhook) |
| User profile sync | Sign-up inserts `public.users`; login/bootstrap backfills via `ensureUserProfile`; display name updates DB + auth metadata |
| Pro gating | RevenueCat entitlement `pro` via `SubscriptionManager` → `AppState.subscriptionStatus`; DEBUG override only when RC key empty |
| RevenueCat (Day 31) | Test Store `test_...` key in `Config.swift`; DMG distribution — no App Store offerings fetch |
| Subscription UI (Day 32) | `SubscriptionView` + Test Store purchase; lifetime card gated by `showLifetimeDeal` (DEBUG toggle in Settings) |
| Pro gates | `ProUpgradeSheet` on 9:16, 3rd/4th window, system audio, PiP, captions, 1080p/4K |
| Expiry banner (Day 33) | Dismiss hides until next cold launch; re-shows if still `past_due`/`expired`; **Renew** → SubscriptionView; **Manage** (Profile) → RC billing portal |
| Recording shortcuts (Day 34) | Global + local NSEvent monitors while recording; Accessibility permission for unfocused app; manual zoom × auto-click multiplier |
| Semantic colors (Day 35) | `AppColors` enum + Asset Catalog light/dark; Views/Components only; `AccentColor` aligned with `appPrimary`; HUD/video black unchanged |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
