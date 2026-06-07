# FrameFlow — Current Status

**Last updated:** 2026-06-02  
**Version:** v0.1.0

## Current Phase

**Phase 15 — Testing (Days 39–42)** + **Day 40.1 Phase C complete**

## Currently Working On

- **Blueprint Day 40** — Recording flow testing (in progress on branch `feature/uiFix`)
- **Blueprint Day 41** — Editor + export test checklist (planned next)

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
- **Blueprint Day 31:** `SubscriptionManager` — RevenueCat SDK configure/logIn/logOut/fetchStatus; `app_user_id` = Supabase UUID; `AppState.isPro` from entitlement `pro`; Test Store key + `customerInfo` (offerings/purchase added Day 32)
- **Blueprint Day 32:** `SubscriptionView` (feature table + plan cards + Test Store purchase); `ProGateModifier` / `ProUpgradeSheet`; `SettingsStore.showLifetimeDeal`; offerings + purchase on `SubscriptionManager`
- **Blueprint Day 33:** `ExpiryBannerView` on Dashboard (dismiss until next launch); Renew → SubscriptionView; Profile Manage Subscription with RC portal + fallback alert; inactive entitlement maps to `past_due` / `expired`
- **Blueprint Day 34:** `KeyboardShortcutManager` — global + local Cmd shortcuts during recording; manual zoom on `ZoomController`; Help FAQ for shortcuts + Accessibility
- **Blueprint Day 35:** Asset Catalog semantic colors (10 tokens + AccentColor aligned); `AppColors` enum; View/Component migration (not Services/CI pipeline)
- **Blueprint Day 36:** SettingsStore wiring audit — export default resolution from settings; zoom strength slider in Settings; live auto-focus sync during recording; full property audit table in DEV_LOG
- **Blueprint Day 37:** Profile header (app icon + version); display name save checkmark + disabled when unchanged; delete account via RPC `delete_user` (client-safe, CASCADE to public.users/subscriptions); RevenueCat + session cleanup
- **Blueprint Day 38:** `AnalyticsService` (PostHog events); Sentry init in `FrameFlowApp`; identify/reset on auth; events wired in ViewModels + Pro gates
- **Blueprint Day 39:** Password reset deep link — URL scheme `com.simranjit.frameflow`, `redirectTo` on reset email, `ResetPasswordView` + recovery session via `session(from:)`
- **Blueprint Day 40:** PiP camera crash fix; mic A/V sync (native sample rate, mixQueue, nonisolated writer append); PiP preview/recording alignment
- **Blueprint Day 40.1 Phase A:** Unified `EditorView` (Edit / Captions / Export tabs); Stop → Editor for all users; toolbar Export; standalone `ExportView` kept for Dashboard re-export
- **Blueprint Day 40.1 Phase B:** `EditorTimelineView` in/out trim handles; preview playback constrained to trim range; `ExportService` applies trim at encode
- **Blueprint Day 40.1 Phase C:** Draggable caption placement on preview; editable segment times; optional SRT export on Editor Export tab (Pro)

## Next Task

1. **Finish Day 40** — recording flow test checklist
2. **Day 41** — updated Editor + export test checklist (trim, captions, SRT)

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
| **Post-record flow (Day 40.1)** | **Stop → Editor** (not Caption Editor → Export). Free: Edit + Export (720p) + trim. Pro: + Captions tab. Dashboard re-export keeps standalone `ExportView` (full clip). |
| Captions (Pro) | Generate/edit in Editor Captions tab; drag placement; edit segment times; burn-in via Export; optional SRT on Export tab |
| Caption editor (legacy) | `CaptionEditorView` panels absorbed into Editor; remove in-editor SRT/burn-in export |
| Export flow | Staging until export; `ExportService` from Editor Export tab; resolution + watermark on Export tab |
| Recording detail | Dashboard card → detail; Re-export opens standalone Export screen |
| Supabase schema | `users` + `subscriptions` in `public`; RLS own-row only; subscription writes via service role (Day 30 webhook) |
| User profile sync | Sign-up inserts `public.users`; login/bootstrap backfills via `ensureUserProfile`; display name updates DB + auth metadata |
| Pro gating | RevenueCat entitlement `pro` via `SubscriptionManager` → `AppState.subscriptionStatus`; DEBUG override only when RC key empty |
| RevenueCat (Day 31) | Test Store `test_...` key in `Config.swift`; DMG distribution — no App Store IAP |
| Subscription UI (Day 32) | `SubscriptionView` + Test Store purchase; lifetime card gated by `showLifetimeDeal` (DEBUG toggle in Settings) |
| Payments timeline | **Now (Days 31–37):** RC Test Store for dev. **Before Day 42:** connect Stripe (test mode) + RC Web Billing in dashboard — same Day 32 purchase UI, no new billing screens. **Day 54 / launch:** production RC API key, Stripe in production, deploy `revenuecat-webhook` to Supabase prod. **Not Day 38.** |
| Pro gates | `ProUpgradeSheet` on 9:16, 3rd/4th window, system audio, PiP, captions, 1080p/4K |
| Expiry banner (Day 33) | Dismiss hides until next cold launch; re-shows if still `past_due`/`expired`; **Renew** → SubscriptionView; **Manage** (Profile) → RC billing portal |
| Recording shortcuts (Day 34) | Global + local NSEvent monitors while recording; Accessibility permission for unfocused app; manual zoom × auto-click multiplier |
| Semantic colors (Day 35) | `AppColors` enum + Asset Catalog light/dark; Views/Components only; `AccentColor` aligned with `appPrimary`; HUD/video black unchanged |
| Settings wiring (Day 36) | Every `SettingsStore` key drives UI + runtime behavior; export resolution pre-selects from settings (Pro/hardware clamped); zoom/auto-focus/cursor live or next-session documented |
| Delete account (Day 37) | RPC `delete_user` (not admin API); CASCADE FKs; `hasCompletedOnboarding` preserved; only `expiryBannerDismissed` cleared |
| Analytics (Day 38) | PostHog via `AnalyticsService`; Sentry in app init; empty keys no-op; identify Supabase UUID on auth |

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
