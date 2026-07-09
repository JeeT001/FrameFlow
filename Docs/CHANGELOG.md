# Changelog

All notable changes to FrameFlow are documented in this file.

## [Unreleased]

## [1.0.17] — 2026-07-09

### Changed
- Captions hidden for launch (`AppFeatureFlags.captionsEnabled = false`) — record, trim, and video-only export unchanged; caption engine code retained for re-enable
- Marketing site and subscription copy updated to match (no caption feature promises)

### Fixed
- Recording startup — reuse layout preview SCStreams and warm camera, cache screen-recording permission, parallel audio/camera warmup (fixes 15–20s “Starting capture…” delay)

## [1.0.16] — 2026-07-09

### Fixed
- Editor caption export on notarized DMG — always re-probe leading A/V gap from file before burn-in, force caption burn when segments exist, and fail loudly if mapped burn-in segments are empty (fixes v1.0.15 stale-gap regression on 9:16/PiP recordings)

## [1.0.15] — 2026-07-09

### Fixed
- Editor caption export on installed Release/CI builds — probe media timing before export and restore v1.0.12 full-source export routing so burn-in matches preview (v1.0.14 partial fix was insufficient on notarized DMG)

## [1.0.14] — 2026-07-08

### Fixed
- Editor caption export on full-source recordings (no trim) — restores pre-trim export path; trim exports still work when handles are used

## [1.0.13] — 2026-07-07

### Added
- Editor trim: drag in/out handles after recording; export trimmed range; captions outside trim excluded from export

### Fixed
- Free layout: 1–4 windows seed to top-left grid (TL / TR / BL / BR) instead of overlapping center cluster

### Changed
- Trim UI: range slider with primary accent (replaces yellow NLE bar)

## [1.0.12] — 2026-07-07

### Fixed
- In-app Sparkle updates now install correctly on sandboxed builds — enabled Installer Launcher Service and Sparkle XPC mach-lookup entitlements (fixes “An error occurred while launching the installer”)

## [1.0.11] — 2026-07-07

### Fixed
- Caption burn-in export now renders **readable text** in Classic, Minimal, TikTok, and Highlighted styles — not just the background bar — using Core Animation text settings compatible with AVFoundation offline export

## [1.0.10] — 2026-07-07

### Fixed
- Export screen (Dashboard / Recording Detail → Export) now syncs in-memory captions from `CaptionGenerationState` and staged handoff — not only disk sidecar — so caption burn-in works on installed Developer ID builds when the v1.0.9 editor-only fix did not apply
- Export no longer clears editor-prepared caption segments at export time
- Leading video gap probed on Export screen path when metadata gap is missing (reduces A/V drift on export without editor)


### Fixed
- Export now burns in captions when segments exist in the post-record editor but the caption sidecar is not yet on disk (common with Developer ID installs and security-scoped save folders)
- Hide developer route picker and Settings “Device Capabilities (Debug)” section in Release builds

## [1.0.8] — 2026-06-30

### Fixed
- Sparkle feed URL and in-app legal links now point at `https://drazlo.vercel.app` (Vercel) instead of `drazlo.app`, which is not yet registered in DNS

## [1.0.7] — 2026-06-29

### Fixed
- Sparkle auto-update: ship real EdDSA public key in app (`SUPublicEDKey`) so Check for Updates works from v1.0.6

## [1.0.6] — 2026-06-29

### Changed
- DMG installer background is a clean gradient only (blue arrow removed from background art)

## [1.0.5] — 2026-06-29

### Fixed
- Combined recording mode exports mic + system audio together (AirPods mic startup)
- Light-theme play button visibility and window picker stacking tips

### Added
- Stripe web checkout, post-payment deep link, and legal site links

## [Unreleased prior]

### Planned (Blueprint Day 40.1)
- **Post-Record Editor** — unified screen after Stop with Edit / Captions (Pro) / Export tabs
- Replaces post-record `Caption Editor → Export` hop; keeps standalone `ExportView` for Dashboard re-export
- Phase A: flow refactor *(shipped)*
- Phase B: basic in/out trim *(shipped)*
- Phase C: draggable captions + segment time edit + optional SRT *(shipped)*
- Phase D: middle-chunk delete *(shipped)*

### Fixed (Blueprint Day 41.5 — timeline alignment)
- Unified timeline grid: playhead and overlay/audio clips use same `trackWidth` and 52pt label gutter
- `EditorTimelineLayout` + `TimelineGeometry`; single playhead spanning all lanes
- IMG clip highlights when playhead is inside source-time range

### Added (Blueprint Day 41.5 — clip timing)
- `EditorTimelineClipView` — draggable clip blocks with in/out handles on overlay and audio lanes
- Image overlay: default ~5s clip at playhead (source timeline); preview shows only inside interval; export uses per-kept-range CALayer timing
- Imported audio: default ~10s clip on export timeline; start + end on audio lane; insert duration matches clip
- Trim/cut clamps clip timing without wiping user edits; export summary shows in/out ranges

### Added (Blueprint Day 41 — Editor 3.0)
- Contextual inspector driven by `EditorSelection` (timeline, image, audio, captions)
- 2-column editor layout — preview + inspector; full-width tracks; no permanent project bin
- **Export…** sheet replaces Export tab (resolution, captions, SRT, progress, “What’s included” summary)
- Captions mode always visible; Free users see Pro upgrade (not hidden tab)
- Per-cut remove in inspector; “Clear all cuts” (honest label)
- Dashboard **Re-export original…** with confirmation dialog (full clip, no editor changes)
- Caption drag when overlay visible (not gated to Captions mode only)

### Fixed (Blueprint Day 40.3 — Editor polish)
- Caption burn-in export placement now matches preview (Top/Middle/Bottom + drag offset) — fixed inverted Y math in `captionOriginY` for geometry-flipped CALayer
- Image overlay: drag directly on preview (Edit tab) with dashed selection chrome; sliders stay in sync
- Imported audio: draggable clip block on timeline audio lane updates start time
- Caption drag limited to Captions tab (Pro); image overlay does not steal hit tests when editing captions

### Added (Blueprint Day 40.2 — Editor 2.0)
- Filmora-inspired editor shell: project bin, preview, inspector tabs, multi-track timeline panel
- Multi-cut timeline (`removedRanges[]`), split at playhead, export stitch with duration verification
- Import one image overlay (opacity/position) and one audio track (volume/start) per edit session
- `EditorProjectModel`, `EditorCompositionBuilder`; recording/Dashboard flows unchanged

### Added
- Swift Package Manager dependencies: Supabase, RevenueCat, WhisperKit, Sparkle, Sentry (linked to FrameFlow target)
- `Config.example.swift` template for local `Config.swift` (secrets gitignored)
- `.gitignore` for secrets, Xcode user data, and build artifacts
- `SupabaseClientProvider` shared Supabase client (Supabase Swift SDK 2.x)
- `AuthService` with sign-up, sign-in, sign-out, password reset, and session accessor
- `AuthServiceError` for user-facing auth error messages
- Login, Sign Up, and Forgot Password screens with `@Observable` ViewModels
- `AuthFormLayout` shared auth form styling
- `AppState` with root auth routing and session restore on launch
- First-run `OnboardingView` (replaced Day 7 single-page welcome with 3-page carousel)
- `AuthService.restoreSession()` for bootstrap
- `PermissionManager` and `DeviceCapabilityManager`
- Settings permissions UI (Day 8 testing section)
- `FrameFlow.entitlements` with sandbox, network client, camera, and mic
- `RecordingMetadata` model and local `RecordingStore` (Application Support `recordings.json`)
- `DashboardView` with recording grid, empty state, and New Recording navigation
- `RecordingListItemView` for dashboard recording cards
- `AppState.SubscriptionStatus` scaffold and `isPro` for upgrade/banner UI (no RevenueCat yet)
- `SettingsStore` with UserDefaults-backed recording, audio, cursor, caption, and appearance preferences
- Full `ProfileView` with display name edit, password reset, and subscription management navigation
- `UserService` for Supabase user metadata display name updates
- 3-page onboarding carousel with Sign Up / Log In on final page
- `HelpView` with eight FAQ disclosure groups and mailto support link
- `WindowCaptureService` and `WindowItem` for ScreenCaptureKit window enumeration and thumbnails
- `WindowPickerView` with 3-column grid, selection limits, and permission empty state
- `AppState.selectedWindowIDs` for layout picker handoff
- `LayoutPickerView` with format/layout/camera controls and placeholder preview canvas
- `AudioModePickerView` sheet (four modes, Confirm; volumes/meter deferred to Day 15)
- `LayoutPresetCard` and `LayoutPreviewCanvas` components
- `AudioLevelMonitor` and `AudioLevelBars` for live microphone level feedback in Audio Mode sheet
- `WindowStreamManager`, `CompositeEngine`, and live `CompositePreviewView` on Layout Picker
- `AppState.selectedFormat` and `selectedLayoutPreset` for recording session handoff
- `RecordingEngine` (AVAssetWriter) and Recording HUD to save MP4s locally (video-only for now)
- Security-scoped bookmark persistence for export save folder selection
- `AudioCaptureService` with microphone capture lifecycle, mode handling, and live level output
- Recording audio writer path (AAC) with `RecordingEngine.appendAudioSampleBuffer(_:)`
- ScreenCaptureKit audio callback plumbing in `WindowStreamManager` for system-audio ingress
- Dedicated system-audio ScreenCaptureKit stream lifecycle (`startSystemAudioCapture` / `stopSystemAudioCapture`)
- `CursorTracker`, `ZoomController`, and `ClickEffectRenderer` services for recording-time cursor zoom/click emphasis
- `ActiveWindowMonitor` service for frontmost-app-driven auto-focus mapping to selected recording windows
- Sandbox save-folder entitlements for user-selected read/write access and app-scope bookmarks
- `CameraCapture`, `PiPController`, and `PiPOverlayView` for Day 21 camera PiP capture and interactive positioning
- Pause and resume recording with timestamp offset compensation (`totalPausedDuration`) in `RecordingEngine`
- Recording screen Pause/Resume control with paused visual state
- `RecordingHUDView` with auto-hide, pre-roll countdown overlay, and full-window recording preview layout
- WhisperKit caption pipeline: `TranscriptionService`, `CaptionEngine`, `CaptionRenderer` (SRT + burn-in MP4)
- `CaptionSegment`, `CaptionStyleConfig`, and `CaptionGenerationState` for Pro post-record transcription
- Thin `CaptionEditorView` (Day 24 progress UI; full editor deferred to Day 25)
- Full `CaptionEditorView` with `CaptionEditorViewModel`, `CaptionPreviewView`, `CaptionSegmentRow`, `CaptionStyleCard`
- `ExportService` and `ExportView` with resolution picker, export progress, caption burn-in, and free-tier watermark
- `AppState.exportRecordingID` for navigation to export from Dashboard, post-record alert, and Caption Editor
- `RecordingDetailView` with rename on disk, thumbnail preview, metadata, Re-export, Delete, and Reveal in Finder
- `AppState.detailRecordingID`; Dashboard recording cards open Recording Detail (context menu Export unchanged)
- Day 28: polished free-tier export watermark (`WatermarkCompositor`) on full canvas for 16:9 and 9:16; export no longer replaces recording `filePath`
- `RecordingStaging` + `RecordingFileCleanup`; Stop stages internally; Export is sole write to user save folder
- `AppState.pendingRecording`; Dashboard shows recordings only after successful export
- Supabase migration `supabase/migrations/20260529_users_subscriptions_rls.sql` — `users`, `subscriptions`, RLS, `updated_at` triggers
- `supabase/README.md` — apply migration and verify RLS in Dashboard
- `FrameFlowUser` model and `UserService` sync with `public.users` (create, fetch, backfill, display name)
- `AppState.syncedProfile` populated on bootstrap; DEBUG subscription row logging
- Edge Function `supabase/functions/revenuecat-webhook` — RevenueCat events → `public.subscriptions` via service role
- `SubscriptionManager` — RevenueCat Purchases SDK; entitlement `pro` drives `AppState.isPro`; Supabase UUID as `app_user_id`
- `SubscriptionView` with Free vs Pro feature table, Annual/Monthly/Lifetime plan cards, and Test Store purchase flow
- `ProGateModifier` / `ProUpgradeSheet` — consistent upgrade sheet on gated Pro features
- `SettingsStore.showLifetimeDeal` — hides Lifetime card by default; DEBUG toggle in Settings
- `ExpiryBannerView` on Dashboard — dismissible until next launch; Renew navigates to Subscription screen
- Profile Manage Subscription — RevenueCat billing portal with graceful fallback alert
- `KeyboardShortcutManager` — global recording shortcuts (Cmd+R/P/=/−/0/F/H/K, Cmd+Escape discard)
- Manual zoom controls during recording via `ZoomController` (1.0×–4.0×, 0.25 step)
- Semantic color tokens in Asset Catalog + `AppColors` enum for Views/Components
- `AccentColor` aligned with brand `appPrimary` for system accent-driven controls

### Changed
- Moved `Services`, `Resources`, and `Utils` stubs into dedicated subfolders under `App/`
- Excluded `Config.example.swift` from compile when local `Config.swift` is present
- Replaced auth screen placeholders with functional Supabase-backed forms
- `FrameFlowApp` launches `RootView` instead of always showing `MainAppView`
- Expanded `SettingsView` with full preferences form; removed “Coming Soon” placeholders
- `RootView` applies appearance override from `SettingsStore`
- `ForgotPasswordView` disables form after successful reset email request
- Dashboard DEBUG menu includes **Test window fetch** for `WindowCaptureService`
- `WindowCaptureService` skips thumbnail capture for windows smaller than 120×120
- Toolbar **Audio Mode** route shows standalone hint (sheet opened from Layout Picker)
- `AudioModePickerView` now includes draft mic/system sliders and confirms values to `SettingsStore`
- Layout Picker preview uses live multi-window composite when streams succeed; placeholder fallback otherwise
- Recording flow now produces a saved MP4 and adds local recording metadata (Dashboard list)
- Recording export now resolves security-scoped bookmarks before moving to user-selected folders, with app-container fallback when access is unavailable
- Recording session startup now enforces free-tier fallback from system/combined audio modes to mic-only capture
- Per-window capture streams are now video-only; system audio is sourced from one display-based stream for stability
- Recording composite pipeline now supports settings-driven auto-zoom transform and click/cursor overlay compositing
- Recording composite pipeline now supports animated active-window focus border overlays when auto-focus is enabled
- Save-folder fallback diagnostics now include explicit reasons (`bookmark missing`, `bookmark stale`, `scope access denied`)
- Layout Picker now supports draggable/resizable camera PiP with preset placement options
- Recording composite pipeline now applies camera PiP overlay after base/zoom/click/focus stages
- Free users: Record → Stop → Export screen directly (no saved alert)
- Pro users with audio after stop navigate to Caption Editor and start background caption generation (free users unchanged)
- `hasCaptions` on recording metadata is set when user exports from Caption Editor or Export screen
- Free users can export after recording via Export screen; Dashboard card tap opens Recording Detail
- Export writes one MP4 to save folder (`FrameFlow_<timestamp>_<720p|1080p|4K>.mp4`); Discard removes staging only
- Free-tier export watermark anchored to full letterboxed canvas bottom-left (16:9 and 9:16)
- Sign-up inserts `public.users` row; login and session restore backfill profile via `ensureUserProfile`
- Profile display name updates both `public.users.display_name` and Supabase auth user metadata
- Pro access driven by RevenueCat entitlement `pro` after sign-in and session restore
- Pro upgrade sheet on gated features (9:16, multi-window, system audio, PiP, captions, HD export)
- Inactive RevenueCat entitlement correctly maps to past_due / expired for banner and Pro gates
- Help FAQ documents recording keyboard shortcuts and Accessibility requirement for global hotkeys
- Asset Catalog semantic color tokens with light/dark variants; `AppColors` enum for Views/Components
- Export screen pre-selects resolution from Settings default (Pro/hardware clamped); zoom strength slider in Settings
- Profile header shows app icon, version, and display name; save checkmark animation; delete account with confirmation

### Fixed
- Recording A/V desync from mismatched video frame-counter timestamps vs ~30 Hz writer cadence; video and audio now share a host session clock in `RecordingEngine`
- Mic CMSampleBuffer duration now uses `frameLength/sampleRate` for correct writer retiming in `AudioCaptureService`
- `.combined` mode writer path is currently mic-only (until proper PCM mic+system mixing is added) to avoid unsafe single-track concatenation drift
- Audio writer append is gated until the first video frame establishes the session clock (fixes audio-leading-video on mic recordings)
