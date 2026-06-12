# FrameFlow Dev Log

Canonical path: `Docs/DEV_LOG.md` (referenced by Cursor rules and `CURSOR_START_HERE.md`).

---

## Day 1 — Project Foundation

### Completed
- Created Xcode macOS SwiftUI project
- Set deployment target to macOS 14.0
- Built `NavigationSplitView` shell (sidebar: **Home, Settings, Account** — blueprint Option B)
- Set window minimum size to 900×600 and default size to 1100×700

### Decisions
- SwiftUI + MVVM; `@Observable` for `AppRouter`
- **Option B** — blueprint navigation, not simplified Record/Projects sidebar
- DMG distribution before Mac App Store

---

## Day 2 — Navigation & Placeholders (early)

### Completed
- `AppRoute` enum (18 routes), `AppRouter`, placeholder screens, toolbar route picker

### Files (later moved under `App/`)
- `App/Views/`, `App/ViewModels/`, `App/Models/`, `App/Components/`

---

## Day 2 (docs) — Cursor & documentation setup

### Completed
- `.cursor/rules/frameflow_rules.mdc`, `CURRENT_STATUS.md`, `CURSOR_START_HERE.md`, canonical `DEV_LOG.md`

---

## Part 2 — Folder reorganization

### Completed
- Moved Swift sources into `App/Views`, `App/ViewModels`, `App/Models`, `App/Components`
- `FrameFlowApp.swift` remains at target root
- Build succeeded after move

---

## Blueprint Day 2 — Folder structure + dependencies (2026-05-25)

### Completed
- Verified MVVM folders; moved `Services.swift`, `Resources.swift`, `Utils.swift` into `App/Services/`, `App/Resources/`, `App/Utils/`
- Added SPM packages to **FrameFlow** target (app only, not tests):
  - Supabase → `Supabase` (2.46.0 resolved)
  - RevenueCat → `RevenueCat` (5.74.0)
  - WhisperKit → `WhisperKit` (0.18.0)
  - Sparkle → `Sparkle` (2.9.2)
  - Sentry → `Sentry` (8.58.2)
- Created `App/Utils/Config.swift` with empty placeholder strings
- Added `.gitignore` at repo root and `FrameFlow/FrameFlow/.gitignore`
- `Package.resolved` generated under `FrameFlow.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`
- **Build:** `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **SUCCESS**

### Decisions
- No SDK imports or initialization in app code yet (dependency wiring only)
- `Config.swift` gitignored; developers maintain keys locally
- Blueprint Days 3–4 (navigation shell + placeholders) treated as **already complete**

### Files
- `FrameFlow/FrameFlow/App/Utils/Config.swift` (local, gitignored)
- `FrameFlow/FrameFlow.xcodeproj/project.pbxproj`
- `FrameFlow/FrameFlow.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `.gitignore`, `FrameFlow/FrameFlow/.gitignore`

### Next
- **Blueprint Day 5** — Supabase dashboard + `SupabaseClient` + `AuthService`
- Do not start ScreenCaptureKit, recording, or SDK initialization until auth foundation is planned

### Suggested commit
```
chore: add SPM dependencies, Config.swift, and .gitignore
```

---

## Blueprint Day 5 — Supabase Setup + AuthService (2026-05-25)

### Completed
- Created `Config.example.swift` (committed template; excluded from target when `Config.swift` exists)
- Created `SupabaseClientProvider` — shared `SupabaseClient` using `Config.supabaseURL` / `Config.supabaseAnonKey`
- DEBUG warning when credentials missing; safe placeholder client (no crash)
- Created `AuthService` with async methods aligned to supabase-swift 2.x
- Created `AuthServiceError` (`LocalizedError`) for user-facing messages
- Moved `Utils.swift`, `Services.swift`, `Resources.swift` into subfolders
- **Build:** `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **SUCCESS**

### AuthService API
- `signUp(email:password:name:) async throws -> User`
- `signIn(email:password:) async throws -> User`
- `signOut() async throws`
- `resetPassword(email:) async throws`
- `getCurrentSession() -> Session?`

### Files
- `App/Utils/Config.example.swift`
- `App/Services/SupabaseClient.swift`
- `App/Services/AuthService.swift`
- `FrameFlow.xcodeproj/project.pbxproj` (Config.example compile exception)

### Decisions
- Wrapper type `SupabaseClientProvider` avoids naming clash with SDK `SupabaseClient`
- Service layer only — no auth UI or AppState changes (Day 6–7)
- Sign-up stores `full_name` and `display_name` in user metadata

### Next
- **Blueprint Day 6** — Login, Sign Up, Forgot Password views + ViewModels
- **Blueprint Day 7** — Session persistence and auth guard

### Suggested commit
```
feat: Supabase client and AuthService
```

---

## Repo consolidation (2026-05-26)

### Completed
- Removed nested git repo at `FrameFlow/FrameFlow/.git` (inner commit `588f3e3` preserved in history until merge commit)
- Converted outer gitlink (`160000`) to normal tracked files under `FrameFlow/`
- Single repository root: `/Users/simranjit/Desktop/FrameFlow`
- Merged to one root `.gitignore`; removed `FrameFlow/.gitignore`
- Stopped tracking `.derivedData/` build artifacts in outer repo
- `Config.swift` remains gitignored via root `.gitignore`

### Suggested commit
```
chore: merge nested FrameFlow repo into single root repository
```

---

## Blueprint Day 6 — Login, Sign Up, Forgot Password (2026-05-26)

### Completed
- `LoginViewModel`, `SignUpViewModel`, `ForgotPasswordViewModel` (`@Observable`)
- Replaced placeholder `LoginView`, `SignUpView`, `ForgotPasswordView` with functional forms
- Shared `AuthFormLayout`, `AuthErrorBanner`, `AuthSuccessBanner` components
- Client validation, loading states, error/success messages
- Navigation via `AppRouter.navigate(to:)` on success and footer links
- Sign-up handles `emailConfirmationRequired` with success banner (no dashboard redirect)
- **Build:** `xcodebuild -scheme FrameFlow -project FrameFlow/FrameFlow.xcodeproj -destination 'platform=macOS' build` — **SUCCESS**

### Files
- `App/ViewModels/LoginViewModel.swift`, `SignUpViewModel.swift`, `ForgotPasswordViewModel.swift`
- `App/Views/Screens/LoginView.swift`, `SignUpView.swift`, `ForgotPasswordView.swift`
- `App/Components/AuthFormLayout.swift`

### Next
- **Blueprint Day 7** — `AppState`, session persistence, auth guard at app root

### Suggested commit
```
feat: login and sign up screens with form validation
```

---

## Blueprint Day 7 — Session persistence + AppState (2026-05-26)

### Completed
- `AppState` (`@Observable`) with `AuthStatus`: `.firstLaunch`, `.unauthenticated`, `.authenticated`
- UserDefaults key: **`hasCompletedOnboarding`** (false until onboarding completed)
- `bootstrap(router:)` restores session via `AuthService.restoreSession()` or routes to login
- `RootView` switches: onboarding → `AuthContainerView` → `MainAppView`
- `AuthContainerView` shows Login / Sign Up / Forgot Password without sidebar
- Login & Sign Up call `appState.markAuthenticated(user:)` on success
- Minimal `OnboardingView` with **Get Started** → `completeOnboarding()`
- Temporary **Sign Out** on Profile placeholder
- **Build:** SUCCESS

### Test steps
1. First launch → onboarding → Get Started → Login
2. Log in → main shell / dashboard
3. Quit (⌘Q), relaunch → main shell (session restored)
4. Account → Sign Out → Login screen
5. Relaunch → Login (no session)

### Suggested commit
```
feat: session persistence and auth guard via AppState
```

---

## Blueprint Day 8 — Permission Manager + Device Capability (2026-05-26)

### Completed
- `PermissionManager` — screen recording (SCShareableContent), camera/mic (AVFoundation), System Settings URLs
- `DeviceCapabilityManager` — Apple Silicon detection via `sysctlbyname("hw.optional.arm64")`
- `FrameFlow.entitlements` — sandbox, network client, camera, audio-input
- Info.plist usage strings for camera and microphone (`INFOPLIST_KEY_*`)
- `SettingsView` + `SettingsViewModel` — permission status rows, Check Status, Open System Settings
- Debug device capability section in Settings
- **Build:** SUCCESS

### Sandbox note
App Sandbox must keep **Outgoing Connections (Client)** enabled (`com.apple.security.network.client` + `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES`) or Supabase auth fails silently.

### Manual test steps
1. Log in → Sidebar **Settings**
2. Permissions section shows Screen Recording / Camera / Microphone status
3. Tap **Open System Settings** → correct Privacy pane opens
4. Grant permission in macOS → return → **Check Status** → status updates
5. Device Capabilities section shows Apple Silicon / max windows / 4K / FPS

### Suggested commit
```
feat: permission manager and device capability detection
```

---

## Blueprint Day 9 — Dashboard + RecordingStore (2026-05-26)

### Completed
- `RecordingMetadata` — Codable model with blueprint fields + display helpers (duration, date, file size, resolution badge)
- `RecordingStore` — `@Observable` singleton; persists to Application Support `recordings.json`
- `RecordingListItemView` — card cell with thumbnail placeholder, name, date, duration, resolution badge
- `DashboardView` — top bar (FrameFlow title, user initials, Upgrade), subscription banner, New Recording CTA, grid or empty state
- `AppState` — `SubscriptionStatus` enum, `subscriptionStatus`, computed `isPro`
- `UserDisplayHelpers` — initials from Supabase user metadata (`full_name` / email fallback)
- Removed `DashboardView` placeholder from `PlaceholderScreens.swift`
- **Build:** SUCCESS

### recordings.json path
Non-sandbox (reference): `~/Library/Application Support/FrameFlow/recordings.json`  
**Sandbox (Debug build):** `~/Library/Containers/com.Simranjit.FrameFlow/Data/Library/Application Support/FrameFlow/recordings.json`  
Created as `[]` on first load if missing.

### Manual test steps
1. Log in → Sidebar **Home** → Dashboard loads
2. Empty state: icon, “No recordings yet”, **New Recording** button
3. Tap **New Recording** → navigates to Window Picker placeholder
4. **Upgrade** visible when `subscriptionStatus != .active`; hidden when Pro (DEBUG menu → Active)
5. DEBUG toolbar **Debug** menu → set Past Due / Expired → subscription banner + **Manage Subscription** → Subscription placeholder
6. Optional mocks: set scheme env `FRAME_FLOW_MOCK_RECORDINGS=1` → relaunch → two sample cards in grid; right-click → Delete removes entry from JSON
7. Verify `recordings.json` exists after first dashboard load

### Suggested commit
```
feat: dashboard with recording list and empty state
```

---

## Blueprint Day 10 — Profile + SettingsStore (2026-05-26)

### Completed
- `SettingsStore` — `@Observable` singleton; all blueprint UserDefaults keys with defaults; `expandedSaveFolder` via tilde expansion
- `UserService` — `updateDisplayName` via Supabase `auth.update(user:)`; updates `AppState.currentUser`
- `ProfileView` + `ProfileViewModel` — avatar initials, editable display name, email, subscription badge, Manage Subscription, Change Password (reset email), Log Out
- `SettingsView` expanded — Recording & Export, Audio, Cursor & Zoom, Captions & Notifications, Appearance, About (version + stub updates); kept Permissions + Device Capabilities (Debug)
- `RootView` — `.preferredColorScheme` from `SettingsStore.darkModeOverride`
- Removed `ProfileView` placeholder from `PlaceholderScreens.swift`
- **Build:** SUCCESS

### Manual test steps
1. Log in → Sidebar **Account** → Profile shows initials, email, Free/Pro badge
2. Edit display name → **Save** → success alert; relaunch → name persists (Supabase metadata)
3. **Change Password** → reset email sent alert (check inbox if configured)
4. **Manage Subscription** → subscription placeholder
5. Sidebar **Settings** → change resolution, countdown, audio mode, sliders, toggles → relaunch → values persist (UserDefaults)
6. **Choose…** save folder → pick directory → path updates in UI
7. Permissions section still works: Check Status / Open System Settings
8. Appearance → Light/Dark → app theme updates immediately
9. About → **Check for Updates** → stub alert
10. Profile **Log Out** → Login screen

### Suggested commit
```
feat: profile screen and settings store with full preferences form
```

---

## Blueprint Day 11 — Onboarding, Help, Forgot Password (2026-05-26)

### Completed
- `OnboardingView` — 3-page `TabView` with page dots; pages 1–2 **Next**; page 3 **Sign Up** / **Log In**
- Onboarding completion: `appState.completeOnboarding()` only when user taps Sign Up or Log In (then `router.navigate` to auth)
- `HelpView` — 8 `DisclosureGroup` FAQ items, **Email Support** (`mailto:support@frameflow.app`), app version
- Removed `HelpView` placeholder from `PlaceholderScreens.swift`
- `ForgotPasswordView` — disable email/send after success message (no logic change)
- **Build:** SUCCESS

### Onboarding flow (documented)
- First launch: `authStatus == .firstLaunch` → carousel only; `hasCompletedOnboarding` stays false until auth CTA.
- Page 3 **Sign Up** → `completeOnboarding()` + navigate `.signUp` → `AuthContainerView` shows Sign Up.
- Page 3 **Log In** → `completeOnboarding()` + navigate `.login` → Login screen.
- Swipe or **Next** advances pages 1→2→3 without marking onboarding complete.

### Reset onboarding for testing
Key: `hasCompletedOnboarding` (see `AppState.hasCompletedOnboardingKey`).

**Option A — defaults (often works for Debug):**
```bash
defaults delete com.Simranjit.FrameFlow hasCompletedOnboarding
```
Then quit FrameFlow (⌘Q) and relaunch.

**Option B — sandbox container plist:**
```bash
plutil -remove hasCompletedOnboarding \
  ~/Library/Containers/com.Simranjit.FrameFlow/Data/Library/Preferences/com.Simranjit.FrameFlow.plist
```
Quit and relaunch. If the container path differs, locate `com.Simranjit.FrameFlow.plist` under `~/Library/Containers/`.

### Manual test steps
1. Reset onboarding (command above) → relaunch → 3-page carousel appears
2. Page 1 → **Next** → page 2 → **Next** → page 3
3. **Sign Up** → Sign Up form (onboarding flag set; won’t show carousel again)
4. Reset again → page 3 **Log In** → Login form
5. Log in → main shell → toolbar route picker → **Help** → expand FAQs, **Email Support** opens Mail
6. Forgot Password from Login → send reset → success banner; fields disabled; **Back to Log In** works

### Suggested commit
```
feat: onboarding, help, and forgot password screens
```

---

## Blueprint Day 12 — WindowCaptureService (2026-05-26)

### Completed
- `WindowItem` — UI model (`CGWindowID`, title, app name, bundle ID, optional thumbnail + app icon)
- `WindowCaptureService` — `@MainActor` singleton; `checkPermission()`, `fetchWindows()`, `scWindow(for:)`
- `WindowCaptureError` — `permissionDenied`, `fetchFailed`
- Thumbnails via `SCScreenshotManager.captureImage` + `SCContentFilter(desktopIndependentWindow:)`; batches of 4
- DEBUG: Dashboard **Debug → Test window fetch** logs count to Xcode console
- **Build:** SUCCESS

### SCWindow retention
`fetchWindows()` stores `[CGWindowID: SCWindow]` in `scWindowsByID`. Day 13 picker uses `WindowItem`; Day 16 streams resolve via `scWindow(for:)`.

### Manual test steps
1. Grant **Screen Recording** for FrameFlow (Settings → Permissions or System Settings)
2. Log in → Dashboard → **Debug → Test window fetch**
3. In Xcode console: expect `fetchWindows: N window(s)` with **N > 0** when other apps have visible titled windows
4. Confirm log lines do **not** list FrameFlow’s own windows
5. Deny screen recording → console shows permission error (or `permissionDenied` if called from code)
6. **New Recording** still opens Window Picker **placeholder** (unchanged)

### Suggested commit
```
feat: window enumeration with ScreenCaptureKit
```

---

## Blueprint Day 13 — Window Picker UI (2026-05-26)

### Completed
- `WindowPickerViewModel` — load/refresh, selection with free/pro limits, upgrade sheet
- `WindowPickerView` — 3-column grid, permission empty state, loading copy (30–60s), toolbar Refresh/Next
- `ImageDisplayHelpers` — `CGImage`/`NSImage` → SwiftUI `Image`, title truncation
- `AppState.selectedWindowIDs` — persisted when user taps **Next**
- `WindowCaptureService` — skip thumbnail capture for frames &lt; 120×120; log window count on fetch
- Removed `WindowPickerView` placeholder
- **Build:** SUCCESS

### Selection limits
- **Free:** 2 windows; third tap → upgrade sheet → Subscription route
- **Pro:** `min(4, DeviceCapabilityManager.maxWindows)` (4 Apple Silicon, 2 Intel)

### Manual test steps
1. Grant Screen Recording; log in → Dashboard → **New Recording**
2. Loading screen appears; wait for grid (may take 30–60s)
3. Tap windows — checkmark overlay; toolbar shows `N selected (max M)`
4. Free: select 2, tap third → upgrade sheet; Pro (DEBUG → Active): select up to cap
5. **Next** → Layout Picker placeholder; `selectedWindowIDs` stored in `AppState`
6. **Refresh** reloads grid; deny permission → empty state + Open System Settings
7. Tiny windows show gray placeholder (no thumbnail errors blocking UI)

### Suggested commit
```
feat: window picker UI with selection and free/pro limit
```

---

## Blueprint Day 14 — Layout Picker + minimal Audio sheet (2026-05-26)

### Completed
- `RecordingFormat`, `LayoutPreset`, `AudioModeOption` models
- `LayoutPickerViewModel` — format, layout, camera, SettingsStore sync, Pro gates
- `LayoutPickerView` — split left controls / right preview canvas, Start Recording → `.recording`
- `LayoutPresetCard`, `LayoutPreviewCanvas` — diagram cards + placeholder window rects
- `AudioModePickerView` — sheet with 4 cards, Confirm, Pro gate on system/combined
- `AudioModePickerStandaloneView` for toolbar route
- Removed layout/audio placeholders
- **Build:** SUCCESS

### Manual test steps
1. Window Picker → select windows → **Next** → Layout Picker
2. Change format (16:9); free user taps 9:16 → upgrade sheet; stays 16:9
3. Tap layout preset cards → preview updates
4. Toggle camera → pick device; tap Audio row → sheet → change mode → Confirm
5. Free: System/Combined → upgrade sheet
6. Adjust countdown / auto-focus / cursor highlight
7. **Start Recording** → Recording placeholder
8. Clear `selectedWindowIDs` (debug) or skip picker → banner + alert on Start

### Suggested commit
```
feat: layout picker with format, presets, camera, and audio controls
```


---

## Blueprint Day 15 — Audio Mode Picker (2026-05-26)

### Completed
- `AudioLevelMonitor` service with `AVAudioEngine` input tap and normalized level output
- `AudioLevelBars` component (5 animated bars)
- `AudioModePickerView` extended with draft mic/system volume sliders and live mic meter
- Meter lifecycle wired to sheet `onAppear` / `onDisappear` and mode changes
- Mode + volumes persist only on **Confirm**
- **Build:** SUCCESS

### Slider mapping
- UI sliders are `0...100` percentages
- On Confirm:
  - `settings.defaultMicVolume = Float(draftMicVolumePercent / 100)`
  - `settings.defaultSystemVolume = Float(draftSystemVolumePercent / 100)`

### Manual test steps
1. Window Picker → Next → Layout Picker
2. Open **Audio** sheet
3. Select **Microphone Only** or **Combined** → speak into mic → bars animate
4. Move **Microphone volume** slider; displayed percent updates
5. Select **System Audio Only** or **Combined** (Pro) → move system slider
6. Tap **Confirm**; reopen sheet and verify mode + percentages restored from settings
7. Deny microphone permission in System Settings → open sheet with mic mode; bars stay flat and message appears

### Suggested commit
```
feat: audio mode picker with volume controls and live level meter
```

---

## Blueprint Day 16 — Live Composite Preview (2026-05-26)

### Completed
- `WindowStreamManager` — per-window `SCStream` + `SCStreamOutput`; latest `CIImage` per `CGWindowID`
- `CompositeEngine` — layout compositing (stacked, side-by-side, PiP) into 1280×720 or 720×1280 canvas
- `CompositePreviewCoordinator` — start/stop streams, 30 Hz UI composite timer
- `CompositePreviewView` — `NSViewRepresentable` displaying composited `CGImage` via `CALayer`
- `AppState.selectedFormat` + `selectedLayoutPreset` synced from Layout Picker
- Layout Picker right panel: live preview with placeholder fallback on failure
- Streams stop on Layout Picker `onDisappear`
- **Build:** SUCCESS

### Stream lifecycle
- **Start:** Layout Picker `.task` → `startLivePreview` → `WindowStreamManager.startAll`
- **Update layout/format:** re-composite only (no stream restart)
- **Change window set:** restart streams via `refreshLivePreview`
- **Stop:** `onDisappear` → `stopAll` (no background capture)

### FPS
- `SCStreamConfiguration.minimumFrameInterval` from `DeviceCapabilityManager.compositeFrameRate` (60 Apple Silicon, 30 Intel)
- UI timer ~30 Hz for `CompositeEngine.renderComposite`

### Manual test steps
1. Grant Screen Recording; Window Picker → select 2 windows → **Next**
2. Layout Picker shows “Starting live preview…” then live video composite
3. Switch layout preset (stacked ↔ side-by-side) — arrangement updates
4. Switch format 16:9 ↔ 9:16 (Pro for 9:16) — canvas aspect updates
5. Leave Layout Picker — streams stop (no ongoing capture in background)
6. If `SCWindow` stale/missing — fallback placeholder + error message

### Known console notes
- ScreenCaptureKit may log filter/thumbnail warnings for tiny or protected windows; UI falls back gracefully

### Suggested commit
```
feat: live composite preview canvas with multi-window SCStream
```

---

## Blueprint Day 17 — AVAssetWriter Recording (2026-05-26)

### Completed
- `RecordingEngine` — AVAssetWriter H.264 MP4 (video-only for now), `start(outputURL:outputSize:)`, `appendFrame(ciImage:)`, `stop()`
- `RecordingSessionCoordinator` — keeps `SCStream` running, composites frames, appends to writer, updates live preview
- `RecordingView` + `RecordingViewModel` — recording HUD, live composite preview, duration, Stop → save + metadata
- Temp file writes to `FileManager.default.temporaryDirectory` and moves to `SettingsStore.expandedSaveFolder` with `FrameFlow_YYYY-MM-DD_HH-mm-ss.mp4`
- Adds `RecordingMetadata` via `RecordingStore.shared.add(_)` so Dashboard updates
- **Build:** SUCCESS

### Manual test steps
1. Settings → set resolution (720p / 1080p; 4K only on Apple Silicon)
2. Dashboard → New Recording → select 1–2 windows → Next → confirm live layout preview
3. Tap **Start Recording** → Recording HUD appears; timer increments; live preview continues
4. Record ~10 seconds → **Stop**
5. Confirm file exists in the Save folder with `FrameFlow_*.mp4`
6. Return to Dashboard → new recording card appears (duration/resolution/date)

### Notes
- **Audio is not recorded yet** (Day 18).
- Save-folder export now uses security-scoped bookmarks; if missing/stale, recording falls back to `Application Support/FrameFlow/Recordings` and prompts user to reselect folder in Settings.

### Sandbox save-folder test steps
1. Open Settings → Recording & Export → **Choose…** and select Desktop.
2. Start a recording and tap Stop.
3. Verify the `FrameFlow_*.mp4` file appears on Desktop.
4. Quit and relaunch FrameFlow.
5. Record again and stop; verify a second file appears on Desktop (bookmark persisted across launches).

### Fix — duration + save-folder hint (2026-05-26)
- **Duration 0s on Dashboard:** `stopAndSave` now reads `currentDurationSeconds()` before `finalizeAndStop()`. `RecordingEngine` stores `lastRecordedDurationSeconds` in `stop()` before clearing `startDate`.
- **Settings hint:** Orange caption under Save folder when `defaultSaveFolderBookmarkData` is nil — prompts user to tap **Choose…** again for Desktop/external folders.

### Manual test (duration + bookmark)
1. Settings → Save folder → **Choose…** → select Desktop (orange hint should disappear).
2. Record ~10s → **Stop** → Dashboard card shows ~`00:10`, not `0s`.
3. Confirm MP4 on Desktop (not only Application Support fallback).
4. Quit and relaunch → record again → Desktop save + correct duration persist.

### Suggested commit
```
feat: AVAssetWriter recording pipeline with H.264 video
```

---

## Blueprint Day 18 — Audio capture + writer audio track (2026-05-27)

### Completed
- Added `AudioCaptureService` with `start()`/`stop()`, mode-aware handling (`mic`, `system`, `combined`, `none`), and live level publishing for future HUD use.
- Wired real microphone capture via `AVAudioEngine` input tap and normalized PCM conversion into `CMSampleBuffer` for writer append.
- Extended `RecordingEngine` with AAC `AVAssetWriterInput` (`.audio`) and `appendAudioSampleBuffer(_:)`.
- Updated `RecordingSessionCoordinator` to start/stop audio capture alongside recording lifecycle and route mode/volume/mic-device settings from `SettingsStore`.
- Added ScreenCaptureKit audio ingress plumbing in `WindowStreamManager` (`includeSystemAudio`, `.audio` stream output callback) and connected it into `AudioCaptureService`.
- Added free-tier safety gate in recording start path: system/combined requests downgrade to mic-only for free users.

### Fallback behavior
- Mic permission denied: recording continues, non-blocking status message set.
- System audio unavailable or not yet mix-ready in current multi-window architecture: safe no-crash fallback; video + mic recording still succeeds.

### Manual test steps (Day 18)
1. **Mic only**: select Microphone mode, record, verify voice is present in MP4.
2. **Combined/System**: on Pro, verify mode starts and recording succeeds; on free-tier, verify it falls back to mic-only behavior without crash.
3. **None**: select No Audio, record, verify output is silent.
4. **Stop/save**: record ~10s and stop, verify save flow still works and Dashboard duration is correct.

### Not done yet
- True frame-accurate mic+system PCM mixing remains TODO while multi-window ScreenCaptureKit audio stream selection is stabilized.

### Suggested commit
```
feat: add audio capture and mixing pipeline for recordings
```

---

## Blueprint Day 18.5 — Dedicated system audio stream (2026-05-27)

### Completed
- Refined `WindowStreamManager` so per-window streams are now strictly **video-only** (`capturesAudio = false`).
- Added dedicated system-audio lifecycle in `WindowStreamManager`:
  - `startSystemAudioCapture()`
  - `stopSystemAudioCapture()`
  - display-based `SCContentFilter` source for stable system audio callback flow
- Dedicated audio stream configuration uses:
  - `capturesAudio = true`
  - `excludesCurrentProcessAudio = true`
  - `sampleRate = 48000`
  - `channelCount = 2`
- Updated `RecordingSessionCoordinator` start order:
  1. start video window streams
  2. start dedicated system-audio stream (when mode requires it and user is Pro)
  3. start `RecordingEngine` + `AudioCaptureService`
- Updated stop/error cleanup to stop system audio + video streams and clear `onSystemAudioSampleBuffer` callback.
- `AudioCaptureService.ingestSystemAudioSampleBuffer(_:)` now consumes dedicated system buffers directly while preserving mode checks and safe fallback behavior.

### Manual test steps (Day 18.5)
1. **Mic mode:** record and verify mic audio is present.
2. **System mode (Pro):** record and verify system audio source is present.
3. **Combined mode (Pro):** record and verify both mic + system behavior.
4. **Free tier:** system/combined requests remain downgraded/gated to safe mic path.
5. **None mode:** output remains silent.

### Suggested commit
```
refactor: use dedicated system audio stream and video-only window streams
```

---

## Blueprint Day 19 — Zoom controller + cursor tracker (2026-05-27)

### Completed
- Added `CursorTracker` service with global/local mouse movement and click monitors.
- Added `ZoomController` with settings-driven auto-zoom state machine:
  - click zoom-in animation
  - hold duration
  - smooth zoom-out back to identity
- Added `ClickEffectRenderer` to render cursor highlight and click ripple overlays as CIImage layers.
- Extended `CompositeEngine` to apply:
  - zoom transform (scale + focal point)
  - optional click/cursor overlay
- Wired `RecordingSessionCoordinator` lifecycle:
  - start cursor tracking on recording start
  - update zoom + ripple state per frame
  - stop/cleanup monitors on stop/finalize/error paths
- Kept Day 18/18.5 audio pipeline unchanged (dedicated system-audio stream + writer path preserved).

### Manual test steps (Day 19)
1. Start recording with auto-zoom enabled.
2. Click different preview regions and confirm zoom focuses near click location.
3. Confirm zoom returns to identity after configured hold duration.
4. Confirm click ripple appears and fades.
5. Disable auto-zoom in Settings and verify recording still works without zoom animation.
6. Confirm stop/save duration + audio modes continue working.

### Suggested commit
```
feat: add cursor tracking and auto-zoom click effects
```

---

## Blueprint Day 20 — Auto-focus mode (2026-05-27)

### Completed
- Added `ActiveWindowMonitor` service:
  - observes `NSWorkspace.didActivateApplicationNotification`
  - maps frontmost app bundle ID to selected recording window IDs
  - publishes `activeWindowID` and non-blocking status text
- Deterministic mapping:
  - prefer matching selected window IDs that are currently visible in stream frames
  - fallback to lowest matching `CGWindowID`
  - clear focus when active app has no selected windows
- Extended `CompositeEngine` to accept `activeWindowID` + `autoFocusEnabled` and render animated focus border.
- Focus border implementation:
  - ~3pt blue stroke around active panel rect
  - ~0.4s transition lerp between old/new panel rects
  - compositing order now: base layout -> zoom -> click/cursor overlay -> focus border
- Updated `RecordingSessionCoordinator` lifecycle:
  - starts monitor when `SettingsStore.autoFocusEnabled` is true
  - updates visible frame IDs each tick
  - passes active focus state into `CompositeEngine`
  - cleans up monitor on stop/finalize/error
- Kept Day 17–19 recording/audio/zoom paths intact.

### Manual test steps (Day 20)
1. Enable Auto-Focus in Settings/Layout path.
2. Start recording with 2+ windows from different apps.
3. Switch active app (Cmd+Tab/click windows).
4. Verify blue focus border moves to matching panel with smooth transition.
5. Disable Auto-Focus and verify no border appears.
6. Verify stop/save, duration, and audio modes still work.

### Suggested commit
```
feat: add active-window auto-focus highlight in composite
```

---

## Save-folder entitlement verification patch (2026-05-27)

### Completed
- Updated `FrameFlow.entitlements` with:
  - `com.apple.security.files.user-selected.read-write = true`
  - `com.apple.security.files.bookmarks.app-scope = true`
- Added explicit save-folder diagnostic reasons in `RecordingSessionCoordinator` fallback path:
  - `bookmark missing`
  - `bookmark stale`
  - `scope access denied`
- Kept fallback behavior unchanged (`Application Support/FrameFlow/Recordings`).

### Important note
- After entitlement change, users should re-pick save folder once in Settings (`Choose…`) so a fresh bookmark is used.

### Verification checklist
1. Launch app after entitlement change.
2. Settings → Save folder → **Choose…** → Desktop.
3. Record 5–10s and stop.
4. Confirm MP4 appears on Desktop.
5. Relaunch app and record again; confirm it still saves to Desktop.
6. Confirm no fallback message appears in normal flow.

### Suggested commit
```
fix: enable sandbox file entitlements for user-selected save folder
```

---

## Blueprint Day 21 — PiP camera overlay (2026-05-27)

### Completed
- Added `CameraCapture` service using `AVCaptureSession` + `AVCaptureVideoDataOutput` to produce camera `CIImage` frames.
- Added `PiPController` + `PiPConfig` with observable PiP state:
  - normalized position + size
  - shape (`roundedRect`, `circle`)
  - border style + width
  - presets: Bottom-Right, Bottom-Left, Top-Right, Face-Top (9:16), Face-Left, No Camera
- Added interactive `PiPOverlayView` in Layout Picker preview:
  - drag to reposition
  - corner-handle resize
  - edge snapping (~20pt normalized threshold)
- Wired recording lifecycle:
  - `RecordingSessionCoordinator` starts camera capture when PiP is enabled
  - camera frame + PiP config are fed into `CompositeEngine` each tick
  - camera capture stops on stop/finalize/error cleanup paths
- Extended `CompositeEngine` compositing order to include PiP after focus overlay:
  - base layout -> zoom -> click/cursor -> auto-focus border -> camera PiP

### Fallback behavior
- If camera permission is denied/unavailable, recording continues and PiP is safely skipped (non-blocking message only).
- If no camera frame is available for a tick, composite output renders without PiP for that frame (no crash).

### Manual test steps (Day 21)
1. Enable camera/PiP in Layout Picker and verify PiP preview appears.
2. Drag PiP to corners and verify snapping behavior.
3. Resize PiP via corner handle and verify size bounds/stability.
4. Switch presets (Bottom-Right, Top-Right, Face-Top, etc.) and verify placement updates.
5. Record a short clip and verify PiP camera is burned into exported output.
6. Disable camera/PiP and verify recording still works without PiP overlay.
7. Recheck Days 18–20 behavior (audio modes, zoom/click effects, auto-focus, duration/save).

### Suggested commit
```
feat: add PiP camera overlay with drag, resize, and presets
```

---

## A/V sync hotfix — shared session clock (2026-05-27)

### Completed
- Updated `RecordingEngine` to anchor writer timestamps to one host session clock:
  - `recordingStartHostTime` captured at `start()`
  - writer timescale fixed at **600**
- Fixed mic CMSampleBuffer durations in `AudioMixerEngine.makeSampleBuffer`:
  - duration now uses `frameLength/sampleRate` (was previously `1/sampleRate`), improving audio retiming accuracy.
- Video append PTS now uses elapsed host time (not `frameIndex / compositeFrameRate`).
- Audio append now retimes incoming buffers onto the same session timeline:
  - first buffer anchored to elapsed host time
  - subsequent buffers advance by buffer duration with monotonic PTS guard
- Added DEBUG-only first-append diagnostics for video/audio PTS vs wall elapsed seconds.
- Documented coordinator writer tick (~30 Hz) as compositor cadence independent from capture FPS.
- In `.combined` mode, the writer append path is currently **mic-only** (system buffers are not interleaved into the single audio timeline yet) to avoid single-track mic/system concatenation drift until proper PCM mixing lands.

### Why
- Compositor tick is ~30 Hz while video PTS previously assumed 60 Hz on Apple Silicon, causing fast-motion video and drift vs real-time audio.

### Manual verification checklist
1. Settings → choose Desktop save folder.
2. Record ~10s in **mic** mode; clap once near ~5s.
3. QuickTime: duration ~10s; clap audio/visual alignment within ~200ms.
4. Record **combined/system** (Pro; writer uses mic-only for sync hotfix) and confirm no obvious drift.
5. Record with PiP enabled; camera motion should no longer look sped up.
6. Dashboard duration still correct; MP4 saves to Desktop.

### Suggested commit
```
fix: align recording audio and video timestamps to shared session clock
```

---

## A/V sync follow-up — video-led session clock (2026-05-27)

### Completed
- `RecordingEngine` now anchors `recordingStartHostTime` on the **first successful video frame append** only.
- Early mic audio buffers are dropped until `hasStartedVideoTimeline` is true (reduces audio-leading-video by ~100–300ms from compositor latency).
- DEBUG logs once when audio is gated: `Dropping audio until first video frame is appended.`

### Manual test
1. Mic mode, record 10s, clap at 5s.
2. QuickTime: clap should align better (audio no longer noticeably ahead).
3. Confirm MP4 duration and Desktop save still work.

### Suggested commit
```
fix: align audio start to first video frame
```

---

## Blueprint Day 22 — Pause / resume recording (2026-05-27)

### Completed
- `RecordingEngine.pauseRecording()` / `resumeRecording()` with timestamp offset compensation:
  - `pauseStartHostTime` + accumulated `totalPausedDuration` (timescale 600)
  - append methods no-op while paused (no frozen gap in MP4)
  - effective PTS = host elapsed − `totalPausedDuration`
- HUD timer uses active recording elapsed (excludes pause intervals).
- `RecordingSessionCoordinator` exposes pause/resume; streams/camera/audio stay warm.
- `RecordingView` Pause/Resume control, paused state indicator (orange dot + “Paused”).

### Manual test steps (Day 22)
1. Record 15s wall time; pause at ~5s for ~3s; resume; stop at ~15s wall.
2. Exported MP4 duration ~12s (15 − 3 pause), no visible freeze gap in timeline.
3. Clap before pause and after resume — rough sync check only.
4. Stop/save to Desktop; Dashboard metadata duration matches ~12s.

### Suggested commit
```
feat: pause and resume recording with timestamp offset compensation
```

---

## Blueprint Day 23 — Recording screen + HUD (2026-05-27)

### Completed
- `RecordingHUDView` pill overlay: status dot + timer, zoom label, audio mode icon, Pause/Resume + Stop.
- `RecordingView` layout refresh: full-window `CompositePreviewView` (`fillsWindow`), HUD overlay, slim chrome (no legacy header/footer controls).
- Pre-roll countdown from `SettingsStore.countdownDuration` before `startRecording` (3-2-1 style with scale animation); `0` skips overlay.
- HUD auto-hide after 3s idle; reappears on preview hover/interaction; stays visible while paused.
- PiP remains fixed during recording (configured in Layout Picker only; composited in coordinator tick).

### Manual test steps (Day 23)
1. Countdown 3-2-1 when setting = 3, then capture starts.
2. HUD shows timer/zoom/audio/pause/stop; hides after ~3s idle; returns on mouse move.
3. Pause shows yellow state; Day 22 duration behavior unchanged.
4. Countdown 0 → immediate start.
5. Stop → Desktop save + Dashboard entry.

### Suggested commit
```
feat: recording screen with HUD, countdown, and PiP positioning
```

---

## Blueprint Day 24 — WhisperKit captions (2026-05-27)

### Completed
- `CaptionSegment`, `CaptionSidecar`, `CaptionStyleConfig` (presets: classic, tiktokBold, highlightedWord, minimal, custom).
- `TranscriptionService`: MP4 → M4A extract (`AVAssetExportSession`), WhisperKit transcribe with word timestamps, phrase merge (~3–6 words).
- `CaptionEngine`: orchestrates extract → transcribe → sidecar JSON (`{name}_captions.json` + App Support fallback) → SRT → burn-in MP4.
- `CaptionRenderer`: SRT writer; `AVMutableVideoComposition` + `CATextLayer` burn-in (Classic, TikTokBold word-by-word, Minimal); HighlightedWord/Custom fall back to Classic visuals.
- `CaptionGenerationState` + thin `CaptionEditorView` (progress, preview lines, retry, Skip → Dashboard).
- Pro post-record: `RecordingView` navigates to `.captionEditor` and starts background generation when `isPro`, audio mode ≠ none, and file has audio track.
- `RecordingStore.update` for `hasCaptions` after success.

### Performance notes
- First WhisperKit run may download models (status message in UI).
- Burn-in export is synchronous after transcription; long clips may take additional time on top of Whisper decode.

### Deferred
- Day 25: full caption editor (timeline, drag timings, per-word highlight editing).
- Day 26–28: export screen, watermark pipeline.

### Manual test steps (Day 24)
1. Pro + speech clip → stop → Caption Editor → transcription completes.
2. `{recording}_captions.json` beside MP4 with plausible timestamps.
3. `.srt` opens in TextEdit with valid blocks.
4. `{recording}_captioned.mp4` shows burned captions (Classic from Settings).
5. Free user → saved alert + Dashboard (no auto transcription).
6. Silent / no-audio → graceful error, no crash.
7. Record/pause/HUD/save regression.

### Suggested commit
```
feat: WhisperKit captions with style presets and video burn-in
```

---

## Blueprint Day 25 — Caption Editor screen (2026-05-27)

### Completed
- `CaptionEditorViewModel` — editable segments, style/position/export format, `AVPlayer` + time observer, `exportCaptions()` via `CaptionEngine` + `CaptionRenderer`.
- `CaptionPreviewView` — `VideoPlayer`, scrubber, `CaptionOverlayView` mimicking preset styles at playback time.
- `CaptionSegmentRow` — `m:ss` labels + editable `TextField`; tap seeks preview.
- `CaptionStyleCard` — five preset cards with blue selection border.
- `CaptionEditorView` — full HStack layout; transcription progress → editor transition; Pro gate + Skip; export success alert (Finder / Dashboard).
- `CaptionGenerationState.applySegments`; removed auto `hasCaptions` on transcription complete (export only).
- `CaptionRenderer` — Highlighted Word burn-in (per-word yellow highlight layers).

### Deferred
- Day 26: dedicated Export screen, resolution picker, watermark, `ExportService`.

### Manual test steps (Day 25)
1. Pro + speech → wait for transcription → full editor.
2. Edit segment → Export SRT → valid file.
3. Change style card → overlay updates.
4. Export Burned In → `*_captioned.mp4` plays with captions.
5. Export Both → SRT + MP4 exist.
6. Skip → Dashboard.
7. Segment row tap → preview seeks near start.

### Suggested commit
```
feat: caption editor screen with live preview and segment editing
```

---

## Blueprint Day 26 — Export screen + ExportService (2026-05-27)

### Completed
- `ExportService` — `ExportOptions` / `ExportResolution`; caption burn-in via `CaptionRenderer`; scale to 720p/1080p/4K; free-tier `Made with FrameFlow` CATextLayer watermark; security-scoped save folder + App Support fallback; `UNUserNotificationCenter` on completion (respects `notificationsEnabled`).
- `ExportViewModel` + `ExportView` — preview player, resolution locks (Pro / Apple Silicon for 4K), captions toggle, progress, success alert + Reveal in Finder.
- `AppState.exportRecordingID` handoff from Dashboard, free post-record alert (**Export** / Dashboard), Caption Editor **Export Video** toolbar.
- `RecordingListItemView` tap → export; placeholder `ExportView` removed.

### Deferred
- Day 28: dedicated watermark polish (Day 26 implements basic bottom-left text per blueprint).
- Day 27: Recording Detail screen.

### Manual test steps (Day 26)
1. Free: record → alert **Export** → 720p export with watermark.
2. Pro: 1080p/4K (Silicon) export without watermark.
3. Recording with sidecar → toggle captions → burned export.
4. Dashboard card tap → Export with correct recording.
5. Notification when enabled in Settings.
6. Intel: 4K row locked with Apple Silicon message.

### Suggested commit
```
feat: export screen with resolution picker, watermark, and progress
```

---

## Blueprint Day 27 — Recording Detail screen (2026-05-27)

### Completed
- `RecordingDetailViewModel` — load from `RecordingStore`, `AVAssetImageGenerator` thumbnail (~1s), rename via `FileManager.moveItem` + sanitized filename, delete with sidecar/SRT/captioned/export variants cleanup, play/reveal helpers.
- `RecordingDetailView` — 16:9 thumbnail (tap → `NSWorkspace.open`), name field + Save, metadata grid, Reveal / Re-export / Delete.
- `AppState.detailRecordingID`; Dashboard **card tap** → `.recordingDetail`; context menu **Export…** unchanged.
- Removed `RecordingDetailView` placeholder.

### Deferred
- Day 28: watermark polish (basic watermark already in `ExportService`).

### Manual test steps (Day 27)
1. Dashboard tap → Detail with correct metadata.
2. Thumbnail tap → system player.
3. Rename → Finder + Dashboard name update.
4. Re-export → Export screen.
5. Reveal in Finder.
6. Delete → file + grid entry removed.
7. Context menu Export from Dashboard.

### Suggested commit
```
feat: recording detail screen with rename, re-export, and delete
```

---

## Blueprint Day 28 — Watermark system polish (2026-05-27)

### Completed
- Extracted `WatermarkCompositor` in `ExportService.swift` — exact text **Made with FrameFlow**; bottom-left of full `targetSize` canvas (letterbox included); padding `10 * (canvasHeight / 1080)`; white @ 80% opacity; subtle pill + text shadow for 9:16 readability.
- Fixed prior bug: watermark used `y = padding` (top-left under flipped geometry); now `y = canvasHeight - padding - pillHeight`.
- Pro: unchanged — `applyWatermark: !options.isPro` only.
- `ExportViewModel`: stop overwriting `RecordingMetadata.filePath` on export (sibling `_export_*.mp4` only in success alert).

### Verified (manual)
- 16:9 and 9:16 free 720p exports: watermark on canvas bottom-left, not on video sub-rect only.
- Pro export: no watermark layer added.

### Suggested commit
```
feat: watermark compositing for free tier exports
```

---

## Save flow alignment — stage on Stop, export to save folder (2026-05-28)

### Completed
- **Stop** finalizes to `~/Library/Application Support/FrameFlow/Staging/<uuid>.mp4` — no save-folder bookmark on stop.
- `RecordingViewModel.stopAndStage`; removed “Saved Recording” alert; free → Export directly; Pro+audio → Caption Editor → Export.
- `AppState.pendingRecording` — not in `RecordingStore` until export succeeds.
- **Export** writes single deliverable: `FrameFlow_yyyy-MM-dd_HH-mm-ss_720p.mp4` (resolution suffix); re-export uses fresh timestamp.
- **Discard** deletes staging MP4 + caption sidecars via `RecordingFileCleanup`.
- `ExportService.withSourceReadAccess` reads app-container staging without bookmark.
- Caption Editor **Skip Captions** → Export (not Dashboard).
- Recording Detail delete uses simplified cleanup (no `_export_*` siblings).

### Suggested commit
```
feat: save recordings to user folder only on export, not on stop
```

---

## Blueprint Day 29 — Supabase tables + RLS (2026-05-29)

### Completed
- Migration `supabase/migrations/20260529_users_subscriptions_rls.sql`:
  - `public.users` (PK → `auth.users`, CASCADE delete)
  - `public.subscriptions` (FK → users, plan/status defaults, RevenueCat/Stripe fields)
  - Index `subscriptions_user_id_idx`
  - RLS: users SELECT/UPDATE/INSERT own row; subscriptions SELECT own rows only
  - `set_updated_at` triggers on both tables
  - `GRANT` for `authenticated` role
- `supabase/README.md` — SQL Editor steps, RLS verification, rollback notes

### Deferred
- Day 31: RevenueCat SDK / SubscriptionManager

### Manual steps
1. Supabase Dashboard → SQL Editor → run migration file.
2. Confirm tables in Table Editor.
3. Verify RLS with two test users (see `supabase/README.md`).

### Suggested commit
```
chore: Supabase users and subscriptions tables with RLS
```

---

## Blueprint Day 30 — UserService + RevenueCat webhook (2026-05-29)

### Completed
- **`FrameFlowUser.swift`** — Codable model matching `public.users` (`FrameFlowUserInsert` / `FrameFlowUserUpdate` for writes; DEBUG `FrameFlowSubscription` for bootstrap logging)
- **`UserService`** extended:
  - `createUser(id:email:name:)` — INSERT via Supabase; idempotent on duplicate key (fetch existing)
  - `fetchUser(userId:)` — SELECT own row
  - `ensureUserProfile(for:)` — backfill from auth email + `UserDisplayHelpers.displayName` when row missing
  - `updateDisplayName(userId:name:)` — UPDATE `display_name` + auth metadata; `updateDisplayName(_:)` delegates to session user
  - Graceful no-op when `SupabaseClientProvider.isConfigured` is false
- **Call sites:** `SignUpViewModel` (non-blocking `createUser` after sign-up); `LoginViewModel` + `AppState.bootstrap` (`ensureUserProfile` + `fetchUser` → `syncedProfile`); Profile unchanged (`updateDisplayName(_:)`)
- **Edge Function** `supabase/functions/revenuecat-webhook/index.ts`:
  - Validates `Authorization` vs `REVENUECAT_WEBHOOK_SECRET`
  - Service role upsert to `public.subscriptions` (one row per `user_id`)
  - Events: `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `EXPIRATION`, `BILLING_ISSUE`
  - Product-id → plan placeholders (`monthly` / `annual` / `lifetime`)
  - Missing `public.users` row → **400** (user must sign in / backfill first)
- **`supabase/README.md`** — Day 30 deploy, secrets, verification steps
- **`supabase/functions/revenuecat-webhook/README.md`** — curl test, mapping table

### Not in scope (Day 31+)
- RevenueCat Purchases SDK / `SubscriptionManager`
- Paywall UI / Pro gates from DB

### Backfill strategy
- **Sign-up:** immediate `createUser` when session returned (errors logged, sign-up UX not blocked)
- **Login / bootstrap:** `ensureUserProfile` if `fetchUser` nil — covers pre-Day-30 accounts
- **Webhook:** requires existing `public.users` FK; returns 400 if profile never synced

### Manual verification
- App: sign up → row in Table Editor; relaunch → `fetchUser`; Profile save → DB + metadata; pre-Day-30 account → backfill on sign-in
- Webhook: deploy with `--no-verify-jwt`; wrong secret → 401; mock `INITIAL_PURCHASE` → `public.subscriptions` row; RLS blocks cross-user SELECT

### Build
- `xcodebuild -scheme FrameFlow -project FrameFlow/FrameFlow.xcodeproj -destination 'platform=macOS' build` — **BUILD SUCCEEDED**

### Suggested commit
```
feat: UserService public.users sync and RevenueCat webhook edge function
```

---

## Blueprint Day 31 — RevenueCat SDK + SubscriptionManager (2026-05-30)

### Completed
- **`SubscriptionManager.swift`** — `@MainActor` `@Observable` singleton:
  - `configureIfNeeded()` — `Purchases.configure(withAPIKey:)`; skips empty key; DEBUG log level
  - `logIn(appUserID:)` / `logOut()` / `fetchStatus()` — `customerInfo` only (no `getOfferings` / purchase)
  - `applyCustomerInfo` — entitlement `pro` → `isPro`, status, plan name, renewal date
  - `syncToAppState` — trialing/active/cancelled-but-active → `.active`; past_due → `.past_due`
  - `PurchasesDelegate` + `customerInfoStream` for live entitlement updates
  - `showManageSubscriptions()` with `managementURL` fallback (Day 32 billing portal)
- **`FrameFlowApp.swift`** — configure on launch; `.environment(SubscriptionManager.shared)`
- **`AppState`** — `syncSubscriptionAfterAuth`; async `markAuthenticated` wires RC; `signOut` calls `logOut` + `.free`
- **`RootView`** — `onChange` syncs RC updates to `AppState`
- **UI hooks:** Dashboard + Profile “Manage Subscription” → `showManageSubscriptions()`; DEBUG subscription override only when `!isConfigured`

### Testing notes
- Dev: RevenueCat **Test Store** API key (`test_...`) in local `Config.swift` (gitignored)
- Entitlement identifier: **`pro`**
- Grant promotional entitlement in RevenueCat → Customers for a signed-in Supabase UUID
- Mac App Store product setup skipped (DMG + Stripe/web billing in Day 32)

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: RevenueCat SDK and SubscriptionManager
```

---

## Blueprint Day 32 — Subscription screen + Pro gates (2026-05-30)

### Completed
- **`SubscriptionView.swift`** + **`SubscriptionViewModel.swift`** — feature comparison table (Free vs Pro); Annual / Monthly / Lifetime plan cards; Test Store purchase via `SubscriptionManager.purchase(package:)`; success → Dashboard + `isPro`; empty/error state when RC not configured or offerings missing
- **`ProGateModifier.swift`** — `ProGate.perform`, `ProUpgradeSheet`, `.proUpgradeSheet()` extension
- **`SubscriptionManager`** — `fetchOfferings()`, `purchase(package:)`, `package(for:)`, `availablePackages`
- **`SettingsStore.showLifetimeDeal`** — default `false`; DEBUG toggle in Settings to show Lifetime card
- **Gated features:** 9:16 format, 3rd/4th window, system/combined audio, PiP camera, captions entry, 1080p/4K export rows
- Removed `SubscriptionView` placeholder from `PlaceholderScreens.swift`

### RevenueCat Dashboard setup (Test Store — run before purchase testing)

1. **Products** (Product catalog → Test Store):
   | Product ID | Type | Display |
   |------------|------|---------|
   | `frameflow_pro_monthly` | Subscription | ~$19/mo, 7-day trial |
   | `frameflow_pro_annual` | Subscription | ~$108/yr ($9/mo), 7-day trial |
   | `frameflow_pro_lifetime` | One-time | ~$79 |

2. **Entitlements** — attach all three products to entitlement **`pro`**

3. **Offerings** — Default (current) offering with packages:
   | Package | RC identifier (typical) | Maps to product |
   |---------|-------------------------|-----------------|
   | Monthly | `$rc_monthly` or custom `monthly` | `frameflow_pro_monthly` |
   | Annual | `$rc_annual` or custom `annual` | `frameflow_pro_annual` |
   | Lifetime | custom `lifetime` | `frameflow_pro_lifetime` |

   Code matches by **product id substring** (`monthly` / `annual` / `lifetime`) or `Package.packageType`.

4. **API key** — Test Store public key (`test_...`) in local `Config.swift`

5. **App user ID** — sign in first; RC Customers shows Supabase auth UUID (Day 31 `logIn`)

### Purchase test steps
1. Sign in → open Subscription from Dashboard Upgrade or Profile
2. With products configured → tap **Start Free Trial** → RevenueCat Test Store dialog
3. Complete purchase → returns to Dashboard → Pro features unlock
4. Without products → friendly setup message, no crash
5. Settings (DEBUG) → enable **Show Lifetime plan** → Lifetime card appears

### Not in scope (Day 32)
- Day 33 expiry banner dismiss polish
- Mac App Store Connect IAP

### Deferred — Stripe / production billing

There is **no dedicated blueprint coding day** for switching from Test Store to Stripe. Timeline:

| When | What |
|------|------|
| **Now (Days 31–37)** | RC **Test Store** + `test_...` API key in local `Config.swift` — intentional for dev |
| **Before Day 42** | Connect **Stripe** (test mode) to RevenueCat; add **Web Billing** config (not App Store); map same product IDs to Stripe-backed packages. App code from Day 32 unchanged — dashboard/config only |
| **Day 42 testing** | Blueprint expects Stripe test cards (`4242…`, failure card `4000…`), manage-subscription → Stripe portal |
| **Day 54** | Deploy webhook to Supabase production; RC Sandbox → **Production**; verify purchase + webhook sync |
| **Launch checklist** | RC Production mode, Stripe connected in Production, production API keys in release builds (not `test_`) |

Mac App Store IAP skipped — DMG distribution uses RevenueCat + Stripe via Web Billing per blueprint.

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: subscription pricing screen and Pro gate modifier
```

---

## Blueprint Day 33 — Expiry banner + manage subscription (2026-05-30)

### Completed
- **`ExpiryBannerView.swift`** — amber HStack; blueprint copy for expired / past_due; **Renew** + dismiss (X)
- **`SettingsStore.expiryBannerDismissed`** — UserDefaults; cleared on cold launch via `resetExpiryBannerDismissedForLaunch()` in `FrameFlowApp`; cleared when status recovers to active/free
- **`DashboardView`** — uses `ExpiryBannerView`; Renew → `.subscription`; DEBUG override menu unchanged
- **`ProfileView`** — Manage Subscription → async `showManageSubscriptions()`; alert + **View Plans** fallback when RC/Test Store has no portal; Past Due / Expired badges when not Pro
- **`SubscriptionManager`** — inactive `pro` entitlement now maps to `past_due` / `expired` / `cancelled` (not `free`); `syncToAppState` maps inactive `past_due`; `showManageSubscriptions()` returns `Bool`

### Dismiss semantics
- User taps **Dismiss** → `expiryBannerDismissed = true` → banner hidden for remainder of app session
- **Cold launch** (`FrameFlowApp.onAppear`) → dismiss flag reset → banner re-appears if still `past_due` or `expired`
- Status improves to active/free → dismiss flag cleared automatically

### Renew vs Manage Subscription
| Action | Where | Behavior |
|--------|-------|----------|
| **Renew** | Dashboard expiry banner | Navigate to `SubscriptionView` (purchase / re-subscribe) |
| **Manage Subscription** | Profile | RevenueCat `showManageSubscriptions()` or Apple `managementURL`; fallback alert → View Plans |

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: expiry banner and manage subscription flow
```

---

## Blueprint Day 34 — Keyboard shortcuts (2026-05-30)

### Completed
- **`KeyboardShortcutManager.swift`** — global + local `NSEvent` keyDown monitors; `start(handler:)` / `stop()` cleanup; ignores key repeats; Cmd-only shortcuts while `isEnabled`
- **`RecordingKeyboardShortcutHandling`** protocol — decoupled callbacks to `RecordingViewModel`
- **`ZoomController`** — manual zoom `1.0…4.0` step `0.25`; `zoomIn` / `zoomOut` / `resetZoom`; final scale = `manualScale × autoClickMultiplier`
- **`RecordingSessionCoordinator`** — zoom + toggle auto-focus / cursor highlight / PiP (Pro) during recording
- **`RecordingView`** — starts/stops monitors when recording live; Cmd+Escape discard → dashboard; Cmd+K Pro gate sheet
- **`HelpView`** — FAQ entry with full shortcut table

### Shortcuts (Section 8F)

| Shortcut | Action |
|----------|--------|
| Cmd+R | Stop recording |
| Cmd+P | Pause / Resume |
| Cmd+= | Zoom in +0.25× |
| Cmd+- | Zoom out −0.25× |
| Cmd+0 | Reset zoom to 1.0× |
| Cmd+F | Toggle auto-focus |
| Cmd+H | Toggle cursor highlight |
| Cmd+K | Toggle PiP camera (Pro) |
| Cmd+Escape | Discard recording (no save) |

### Accessibility permission
Global shortcuts when another app is focused require **System Settings → Privacy & Security → Accessibility → FrameFlow** enabled. Local monitors still work when FrameFlow is focused without Accessibility.

### Zoom model
Manual base scale (`manualScale`) is multiplied by the auto-click animation multiplier. Manual adjustments reset the click animation to avoid conflicting transforms.

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: global keyboard shortcuts for all recording controls
```

---

## Blueprint Day 35 — Semantic colour system (2026-05-30)

### Completed
- **Asset Catalog** — 10 Color Sets with light/dark sRGB (`appPrimary`, `appBackground`, `appSurface`, `appBorder`, `appTextPrimary`, `appTextSecondary`, `recRed`, `proGold`, `successGreen`, `pauseYellow`)
- **`AccentColor.colorset`** — aligned with `appPrimary` light/dark (`.borderedProminent` matches brand)
- **`App/Utils/AppColors.swift`** — `enum AppColors` with `Color("token")` accessors (avoids conflict with Xcode-generated asset symbol extensions)
- **View/Component migration** — 25 files in `App/Views` + `App/Components`; replaced hardcoded accent/secondary/orange/green/red with semantic tokens
- **Dark mode override** — verified existing `SettingsStore.darkModeOverride` + `RootView.preferredColorScheme` (no duplicate UI)

### Color token table

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| appPrimary | #1A56DB | #4B8EF1 | CTAs, selection, Pro badges |
| appBackground | #FFFFFF | #1C1C1E | (reserved for future shell backgrounds) |
| appSurface | #F3F4F6 | #2C2C2E | Cards, panels, subtle fills |
| appBorder | #E5E7EB | #3A3A3C | Dividers, strokes |
| appTextPrimary | #1F2A37 | #F2F2F7 | Body/headline text |
| appTextSecondary | #4B5563 | #AEAEB2 | Hints, metadata |
| recRed | #DC2626 | #FF453A | Recording HUD dot, errors |
| proGold | #D97706 | #FFD60A | Warnings, Pro accents |
| successGreen | #0E9F6E | #30D158 | Success states |
| pauseYellow | #F59E0B | #FFD60A | Paused HUD dot |

### Migration scope (intentionally unchanged)
- Recording preview `Color.black` canvas
- Recording HUD dark rgba shell (blueprint 8F)
- `CompositeEngine` / `ClickEffectRenderer` / CIColor pipeline
- Caption style preview mock colors on dark thumbnails

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: semantic colour system with dark mode via Asset Catalog
```

---

## Blueprint Day 36 — SettingsStore wiring audit (2026-05-30)

### Completed
- **`ExportViewModel.applyDefaultResolution(isPro:)`** — maps `SettingsStore.defaultResolution` (`720p` / `1080p` / `4k`) to `ExportResolution`; free users clamp to 720p; 4K falls back to 1080p when hardware unsupported; called from `load(…, isPro:)`
- **`ExportView`** — removed blunt `onAppear` override that always forced 720p for free users
- **`SettingsView`** — added **Zoom strength** slider (`0…3`, displays resulting scale %)
- **`RecordingSessionCoordinator.syncAutoFocusFromSettings()`** — re-reads `autoFocusEnabled` each composite tick so Settings / Layout Picker changes apply live during recording (keyboard shortcut path unchanged)

### Live vs next-session behavior

| Setting | When it applies |
|---------|-----------------|
| Auto-focus, cursor highlight | **Live** during recording (tick reads SettingsStore) |
| Zoom strength / hold / auto-zoom on click | **Next recording** (`ZoomController.configure` at session start) |
| Default resolution (recording output) | **Next recording** (`RecordingSessionCoordinator` output size) |
| Default resolution (export picker) | **Each Export screen open** (`ExportViewModel.load`) |
| Audio mode / mic device / volumes | **Next recording** (coordinator reads at start) |
| Countdown | **Next recording** (`RecordingViewModel`) |
| Caption style | **Next caption load/export** (`CaptionStyleConfig.fromSettings()` fallback) |
| Notifications | **Each export** (`ExportService.notifyExportComplete` guard) |
| Dark mode | **Immediate** (`RootView.preferredColorScheme`) |

### Settings wiring audit

| Key | Read site(s) | Status |
|-----|--------------|--------|
| `defaultResolution` | `RecordingSessionCoordinator` (output size), `RecordingViewModel.resolutionString`, `ExportViewModel.applyDefaultResolution`, Settings picker | **Fixed** (export pre-select) |
| `defaultSaveFolder` | `ExportService` resolved path, Settings UI | OK |
| `defaultSaveFolderBookmarkData` | `ExportService` security-scoped access | OK |
| `defaultAudioMode` | `RecordingSessionCoordinator.startRecording`, `LayoutPickerViewModel`, `AudioModePickerView` | OK |
| `defaultMicDevice` | `RecordingSessionCoordinator` → `AudioCaptureService`, Settings mic picker | OK |
| `defaultMicVolume` | `AudioCaptureService.configure`, Settings slider | OK |
| `defaultSystemVolume` | `AudioCaptureService.configure`, Settings slider | OK |
| `autoFocusEnabled` | `RecordingSessionCoordinator` (start + live tick sync), Layout Picker + Settings toggles, Cmd+F | **Fixed** (live sync) |
| `cursorHighlightEnabled` | `RecordingSessionCoordinator.currentClickOverlay` (live), Layout Picker + Settings, Cmd+H | OK |
| `autoZoomOnClick` | `ZoomController.configure` at record start, Settings toggle | OK |
| `zoomStrength` | `ZoomController.configure` at record start, Settings slider | **Fixed** (UI added) |
| `zoomHoldDuration` | `ZoomController.configure` at record start, Settings stepper | OK |
| `cursorHighlightColor` | `RecordingSessionCoordinator` → `ClickEffectRenderer` (live), Settings picker | OK |
| `countdownDuration` | `RecordingViewModel` pre-roll, Layout Picker + Settings stepper | OK |
| `captionStyle` | `CaptionStyleConfig.fromSettings()`, `ExportService.captionStyle` fallback, `CaptionEditorViewModel`, Settings picker | OK |
| `notificationsEnabled` | `ExportService.notifyExportComplete` guard, Settings toggle | OK |
| `darkModeOverride` | `RootView.preferredColorScheme`, Settings picker | OK |
| `showLifetimeDeal` | `SubscriptionView` lifetime card visibility, DEBUG Settings toggle | OK |
| `expiryBannerDismissed` | `ExpiryBannerView` / Dashboard banner dismiss | OK |

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: wire SettingsStore defaults to export and recording behavior
```

---

## Blueprint Day 37 — Profile edit + delete account (2026-05-30)

### Completed
- **Profile header** — `NSApp.applicationIconImage` (64pt), “FrameFlow” title, version + build from bundle, user avatar + display name below
- **Display name UX** — Save disabled when empty or unchanged; success checkmark animation (~1s) instead of alert on save; errors still use alert
- **`AuthService.deleteAccount()`** — calls RPC `delete_user` (authenticated self-delete); **not** `auth.admin.deleteUser()` (service role must stay server-side)
- **`AppState.deleteAccount()`** — RPC delete → RevenueCat `logOut()` → `signOut()` → clear session + user-specific prefs
- **ProfileView** — destructive Delete Account button + confirmation alert in Security section
- **Migration** — `supabase/migrations/20260530_delete_own_account_rpc.sql` (`SECURITY DEFINER`, deletes `auth.users` where `id = auth.uid()`)

### Delete account flow

```
User taps Delete Account
  → Confirmation alert
  → AuthService.deleteAccount()  [RPC delete_user → DELETE auth.users CASCADE]
  → SubscriptionManager.logOut()
  → AuthService.signOut()        [clear local session]
  → AppState.clearAuthenticatedSession()
  → clearUserSpecificDefaults()
  → router.navigate(.login)
```

### SDK note
supabase-swift **2.46** has no public `AuthClient.deleteUser()` (admin-only). RPC `delete_user` matches the pattern in [supabase-swift integration tests](https://github.com/supabase/supabase-swift/blob/main/Tests/IntegrationTests/AuthClientIntegrationTests.swift) (`testDeleteAccountAndSignOut`).

### DB CASCADE
Migration `20260529_users_subscriptions_rls.sql`:
- `public.users.id` → `REFERENCES auth.users(id) ON DELETE CASCADE`
- `public.subscriptions.user_id` → `REFERENCES public.users(id) ON DELETE CASCADE`

Deleting the auth user removes `public.users` and `public.subscriptions` rows automatically. RevenueCat customer record is not deleted (RC `logOut()` only).

### UserDefaults cleared on delete

| Key | Cleared? | Reason |
|-----|----------|--------|
| `expiryBannerDismissed` | Yes | User-specific banner state |
| `hasCompletedOnboarding` | **No** | Device-level; user may re-register without re-onboarding |
| All other `SettingsStore` keys | **No** | Device preferences (resolution, save folder, audio, etc.) |

Local recordings (`RecordingStore`) are **not** wiped — they remain on disk for the device.

### Sign-out consistency
Both **Log Out** and **Delete Account** call `SubscriptionManager.logOut()` + Supabase `signOut()`. Delete runs RPC first (requires active JWT), then RC logOut, then signOut for session manager cleanup.

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: profile name editing and delete account flow
```

---

## Blueprint Day 38 — PostHog analytics + Sentry (2026-05-30)

### Completed
- **SPM:** Added `https://github.com/PostHog/posthog-ios` product `PostHog` to FrameFlow target
- **`AnalyticsService.swift`** — static PostHog wrapper; `configure` / `identify` / `reset`; seven launch-checklist events (snake_case); no-op when API key empty
- **`FrameFlowApp.init()`** — Sentry `SentrySDK.start` when `Config.sentryDSN` non-empty (`tracesSampleRate = 0.2`); `AnalyticsService.configure(postHogAPIKey:)`
- **Event wiring:**
  - `sign_up` → `SignUpViewModel` on successful sign-in session
  - `recording_started` → `RecordingViewModel.runRecordingFlow` after capture starts
  - `recording_completed` → `RecordingViewModel.stopAndStage`
  - `export_completed` → `ExportViewModel.export` after persist
  - `upgrade_clicked` → Dashboard Upgrade, `ProUpgradeSheet`, Expiry banner Renew
  - `purchase_completed` → `SubscriptionViewModel.purchase`
  - `feature_blocked` → `ProGate.perform`, `WindowPickerViewModel` (4 windows), `LayoutPickerViewModel` (9:16)
- **User identity:** `AnalyticsService.identify` on bootstrap session restore + `markAuthenticated`; `reset` on logout/delete via `clearAuthenticatedSession`

### Empty-key behavior
- Empty `sentryDSN` → Sentry not started
- Empty `postHogAPIKey` → `isConfigured` false; all track/identify/reset methods return immediately

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: PostHog analytics and Sentry error tracking
```

---

## Blueprint Day 39 — Password reset deep link fix (2026-05-30)

### Problem
- Supabase reset email sent but link had no app redirect (`redirectTo` missing)
- `ResetPasswordView` was a placeholder; no URL scheme or `onOpenURL` handler

### Completed
- **`Info.plist`** — URL scheme `com.simranjit.frameflow` (merged with generated Info.plist)
- **`AuthConstants`** — `redirectURL` = `com.simranjit.frameflow://auth/callback`
- **`AuthService`** — `resetPasswordForEmail` with `redirectTo`; `session(from:)` for recovery link; `updatePassword(_:)` via `auth.update(user:)`
- **`ResetPasswordView` + `ResetPasswordViewModel`** — new/confirm password, 8+ chars + match validation, sign out after success
- **`FrameFlowApp.onOpenURL`** — queue URL, parse recovery session, navigate to reset password
- **`AppState`** — `isPasswordRecoveryFlow`, `pendingAuthCallbackURL`, `pendingLoginMessage`; bootstrap skips auto-login during recovery
- **`AuthContainerView`** — routes `.resetPassword` on auth stack
- **`LoginView`** — shows success banner after password reset

### Supabase Dashboard (manual)
Auth → URL Configuration → **Redirect URLs** — add:
```
com.simranjit.frameflow://auth/callback
```

### Flow
1. Forgot Password → email with deep link
2. User clicks link → FrameFlow opens → `session(from: url)` establishes recovery session
3. Set New Password → `updatePassword` → sign out → Login with success message
4. Log in with new password

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: password reset deep link and ResetPasswordView
```

---

## Blueprint Day 40 — PiP camera crash fix (2026-05-30)

### Problem (P0)
- Layout Picker → enable PiP camera crashed with:
  `stopRunning may not be called between calls to beginConfiguration and commitConfiguration`
- `CameraCapture.start()` called sync `stop()` then immediately `beginConfiguration()` while `stop()` had async-dispatched `stopRunning()` on `outputQueue` → race

### Root cause
Session lifecycle mutations were split across MainActor and `outputQueue`. `stop()` did not wait for `stopRunning()` to finish before `start()` reconfigured the session.

### Completed
- **`CameraCapture.swift`** — dedicated serial `sessionQueue` for all session mutations:
  - `beginConfiguration` / `commitConfiguration`
  - `addInput` / `removeInput` / `addOutput` / `removeOutput`
  - `startRunning` / `stopRunning`
  - `setSampleBufferDelegate` (sample delivery still on `outputQueue`)
- **`stop()` → async** — fully tears down on `sessionQueue` before returning (continuation bridge from `@MainActor`)
- **`start()`** — awaits serialized stop via `enqueueSessionOperation` before configure; rapid toggles cannot overlap
- **`LayoutPickerViewModel`** — `await cameraCapture.stop()` in `stopLivePreview` / `startCameraPreviewIfNeeded`; removed duplicate sync stop from `setCameraEnabled`
- **`RecordingSessionCoordinator`** — `await cameraCapture.stop()` on record stop, toggle-off, and disabled-camera path

### Manual verification
1. Pro user → Layout Picker → enable camera → preview shows
2. Toggle camera on/off repeatedly → no crash
3. Navigate away (onDisappear) → no crash
4. Start Recording with PiP enabled → no crash

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: serialize AVCaptureSession lifecycle to prevent PiP crash
```

---

## Blueprint Day 40 — Mic A/V sync fix (2026-06-01)

### Problem (P1)
- Mic-only exports: audio/video out of sync (audio sounded fast or video looked slow)
- Mic noise/clipping on some recordings
- Root cause: `retimedAudioSampleBuffer` **discarded capture timestamps** and packed audio contiguously via `nextAudioTimelinePTS`; silent drops when `!audioInput.isReadyForMoreMediaData` while video PTS advanced on host clock → timeline drift
- Secondary: mic tap dispatched `Task { @MainActor }` for append, competing with 30 Hz composite tick

### Timeline strategy (Option A)
- **Single shared host-clock anchor** (`recordingStartHostTime`) for video and mic audio
- **Audio PTS** = `presentationTimeForCaptureHostTime(AVAudioTime.hostTime)` minus `totalPausedDuration` (same pause math as video)
- **Dedicated `writerQueue`** serializes `appendFrame` + `appendAudioSampleBuffer` (callable from mic tap thread)
- **Pending audio queue** (max 256) drained when writer ready; no silent discard without accounting
- Removed `nextAudioFrame` counter and contiguous packing

### Noise reduction (minimal)
- Mic gain clamped to 0…1 in `AudioCaptureService`
- Soft clip samples to ±1.0 after gain in `makeSampleBuffer`

### DEBUG logging
- First 20 appends log video/audio PTS, wall elapsed, frame count, pending queue depth
- End-of-recording summary: queued count + not-ready stall count

### Files changed
- `RecordingEngine.swift` — writerQueue, host-time audio PTS, pending queue, pause on writer queue
- `AudioCaptureService.swift` — pass `AVAudioTime` host time; append on mixQueue (no MainActor hop); updated callback signature
- `RecordingSessionCoordinator.swift` — pass `captureHostTime` to engine

### Manual verification
1. Settings → Mic only → record 30–60s with speech + clap/visual cue
2. Export → QuickTime → lip sync / clap within ~100ms; video duration ≈ audio duration
3. PiP enabled during record (CameraCapture regression)
4. Pro: system-only path uses host time at ingest

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: align microphone audio timestamps with video host clock
```

---

## Blueprint Day 40 — A/V sync regression fix (2026-06-01)

### Problem
- After host-time audio PTS fix: first ~3s in sync, then audio led video on 15s PiP recordings
- Heavier composite load (PiP) correlated with drift

### Root cause confirmed
**`AVAudioTime.hostTime` uses `mach_absolute_time` units, not nanoseconds.**

Before (wrong):
```swift
CMTime(value: CMTimeValue(audioTime.hostTime), timescale: 1_000_000_000)
```

After (correct — same domain as `CMClockGetHostTimeClock()`):
```swift
CMClockMakeHostTimeFromSystemUnits(audioTime.hostTime)
```

Treating mach ticks as nanoseconds made audio PTS advance at a different rate than video wall clock → cumulative drift (audio ahead after ~3s).

### Additional hardening
- **`recordingStartHostTime`** set at `engine.start()` (not first video frame) — shared anchor for both tracks; audio still gated until first video append
- **DEBUG sync telemetry** every 1s: videoPTS, audioPTS, Δ ms, pendingAudio, videoSkips
- **Stop summary**: videoSkips, audioNotReady, maxPendingAudio, final Δ ms
- Video skip count when `!videoInput.isReadyForMoreMediaData` (PiP back-pressure visibility)

### Files changed
- `AudioCaptureService.swift` — `AudioMixerEngine.hostTime(from:)` uses `CMClockMakeHostTimeFromSystemUnits`
- `RecordingEngine.swift` — anchor at start, periodic DEBUG logs, video skip metrics

### Manual verification
1. Mic only, 30s clap → sync ±100ms end-to-end; DEBUG Δ stays near 0
2. Mic + PiP, 15–30s clap → sync ±100ms (previously failed)
3. QuickTime: audio duration ≈ video duration

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: correct AVAudio host time conversion for stable A/V sync
```

---

## Blueprint Day 40 — Sample-accurate timeline + mic dropout fix (2026-06-01)

### Evidence (19s Mic + PiP)
- Only 174 audio buffers (~80% missing vs expected ~880 at 1024/48kHz)
- `HALC_ProxyIOContext: skipping cycle due to overload`
- videoSkips=0 but videoPTS wall-clock ran ahead of sparse audio capture

### Root causes
1. **Host-time audio PTS** with HAL dropouts → audio timestamps spanned wall clock but sample content did not
2. **Wall-clock video PTS** at 30 Hz while composite under PiP load couldn't keep pace with real time perception
3. **Double composite render** in `tick()` (CIImage + full CGImage pass)
4. **Small tap buffer (1024)** + `.userInitiated` mixQueue under CPU pressure

### Fixes
**A. Mic capture reliability**
- Tap `bufferSize` 1024 → **4096**
- `mixQueue` QoS → **`.userInteractive`**
- Thread-safe `isCaptureActive` for tap path (not MainActor `isRunning`)
- **`AudioCaptureDiagnostics`** — tap/append/convertFail counts + 1 Hz logs

**B. Video timeline**
- **Frame-index PTS**: `CMTime(value: frameIndex, timescale: 24)` — only advances on successful append
- Recording composite **24 fps** (was 30 Hz)
- **Single composite pass** — `renderCompositeCIImage` + `createCGImage(from:)` (no duplicate render)

**C. Audio timeline**
- **Sample-count packing** — each buffer PTS += `frameLength/48000` from anchor at first video frame
- Removed host-time mapping for mic writer PTS (HAL gaps no longer stretch timeline)

**D. Pause/resume**
- Frame index and sample PTS freeze naturally (`isPaused` skips appends); removed host-clock pause offset (not needed for index timelines)

### DEBUG telemetry
Every 1s: `frameIndex`, videoPTS, audioPTS, Δ, pendingAudio, videoSkips, micTaps, micAppends  
Stop: frames, micTaps, micAppends, maxPendingAudio, final Δ

### Expected after fix
- 19s @ 4096 → ~220+ tap buffers; micTaps ≈ duration × 48000/4096
- Δ within ±50ms for full Mic+PiP clip when taps keep up
- video duration ≈ frameIndex/24; audio duration ≈ sum(buffer durations)

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: sample-accurate A/V timeline and reduce mic dropouts during recording
```

---

## Blueprint Day 40 — Audio-master video gate (2026-06-01)

### Evidence (15s Mic+PiP, post sample-count fix)
- `frameIndex=370` → videoPTS=15.375s but audio only 13.397s (158 taps × 4096/48000)
- Δ grew from -24ms → -1978ms; video timer ran at 24fps while HAL dropped ~86% of mic taps
- `videoSkips=0` — problem was timeline divergence, not writer queue

### Approach A: Audio-master video gate
- Video appends **only when audio sample timeline advanced** since last video frame
- `videoPTS = frameIndex / 24` capped at `audioEndPTS + 50ms`
- Skip video append (do **not** increment `frameIndex`) when gate fails
- Audio starts timeline on first buffer; video waits for `audioEndPTS > 0`
- Drain audio **before** video each tick

### Mic / performance
- `AudioCaptureDiagnostics.resetForRecording()` at recording start (coordinator)
- Stop summary skipped when `taps=0` (layout picker teardown)
- Preview CGImage refresh every 6 ticks (~4 Hz) during recording

### Expected stop summary after fix
- `lastVideoPTS ≈ lastAudioPTS` (within 100ms)
- `frames ≈ audioDuration × 24`
- `videoAudioGateSkips` > 0 under PiP load (video timer throttled to audio)
- Δ stable ±50ms entire clip

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: lock video timeline to audio sample progress during recording
```

---

## Blueprint Day 40 — Audio-master PTS + frame duplication (2026-06-01)

### Regression (skip-gate)
- ~3s Mic+PiP: `frames=33` `lastVideoPTS=1.333s` `lastAudioPTS=2.901s` Δ=+1568ms
- `videoAudioGateSkips=44` — skipping appends compressed motion → fast playback; preview laggy

### Fix: audio-end PTS (always append)
- **Removed** skip-gate that withheld video appends when audio hadn't advanced
- Every tick (~24 Hz): drain audio → **always append** video when writer ready (after first audio)
- `videoPTS = audioEndPTS`; when audio flat, duplicate with `lastVideoPTS + 1/24` (monotonic)
- Cap `videoPTS ≤ audioEnd + 50ms`; `duplicateFrameCount` in DEBUG stop summary
- `frameIndex` counts appends only (diagnostics)

### Preview decoupling
- Writer tick: composite → `appendFrame` only (no CGImage)
- Separate **10 Hz** preview timer reuses cached `lastCompositeCIImage`

### Expected after fix
- `lastVideoPTS ≈ lastAudioPTS` (±100ms); Δ stable ±50ms
- `frames ≈ lastVideoPTS × 24`; normal QuickTime speed; clap sync start+end
- `duplicateFrames > 0` under HAL load; no `videoAudioGateSkips`

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: use audio-end video PTS with frame duplication for A/V sync
```

---

## Window picker UI — Loom-style cards (2026-06-01)

### Problem
- Tiny 20×20 icon badge; black Desktop/Wallpaper thumbnails dominated grid
- 3 flexible columns stretched cards; only window title shown (no app name)

### Changes
- **`WindowPickerCard`** — header (48px icon + app name), 16:10 preview, footer (window title)
- Blank/black thumbnails → gradient + centered icon + "Preview unavailable" (`ImageDisplayHelpers.isLikelyBlankThumbnail`)
- Adaptive grid `220–280px`; subtitle under title
- **`WindowCaptureService`** — exclude bare `Desktop` (nil bundle), `Wallpaper-*`; `excludingDesktopWindows(true)`

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: redesign window picker with prominent app icons and Loom-style cards
```

---

## Security-scoped file access for exported recordings (2026-06-02)

### Problem
- Exported MP4s live in user save folder (Desktop, etc.) via bookmark
- `RecordingDetailViewModel.playInSystemPlayer()` called `NSWorkspace.open` without scoped access → sandbox denial
- Same for thumbnails, Finder reveal, rename, delete, AVPlayer in Export/Caption editors

### Fix
- **`SecurityScopedFileAccess`** — shared bookmark resolve + `withAccess(to:)` / `withSaveFolderAccess`
- App-container staging paths skip bookmark; external paths use save-folder bookmark
- Wrapped all external file ops in Recording Detail, Export, Caption view models
- Refactored `ExportService`; removed duplicate bookmark helpers from `RecordingSessionCoordinator`

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: security-scoped access for recording playback and file operations
```

---

## Recording Detail preview layout (2026-06-02)

### Problem
- 9:16 recordings rendered giant portrait preview (unbounded `scaledToFill` + hardcoded 16:9)
- User scrolled to reach Name, Details, Actions

### Fix
- `RecordingMetadata.previewAspectRatio` — 9:16 vs 16:9 from `format`
- Capped preview: `aspectRatio` + `maxWidth: 480` + `maxHeight: 300` on container
- Wide layout (≥700px): two-column HStack; narrow: stacked VStack with capped thumbnail
- `ExportView` VideoPlayer uses same format-aware aspect ratio

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: cap recording detail preview size and use format-aware aspect ratio
```

---

## Dashboard recording card thumbnails (2026-06-02)

### Problem
- `RecordingListItemView` showed static SF Symbol placeholder — never loaded frames from `filePath`

### Fix
- **`RecordingThumbnailService`** — shared AVAssetImageGenerator + `SecurityScopedFileAccess`, path-keyed cache
- **`RecordingListItemView`** — async `.task(id: filePath)` load, format-aware aspect, `maxHeight: 140`
- **`RecordingDetailViewModel`** — delegates to service (640×360 detail size)
- **`DashboardView.deleteRecording`** — deletes files via `RecordingFileCleanup` + scoped access; clears cache

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: load video thumbnails on dashboard recording cards
```

---

## Layout Picker PiP preview bounds (2026-06-02)

### Problem
- `PiPOverlayView` used full panel `GeometryReader` while composite preview was smaller/centered
- Facecam rendered outside preview canvas, overlapping left settings panel

### Fix
- **`PreviewCanvasFitting`** — shared fitted canvas size helper
- **`LayoutLivePreviewStack`** — single clipped ZStack for composite + PiP at same canvas size
- **`PiPOverlayView`** — fixed frame to parent geometry (no expand-to-panel)
- Re-clamp PiP on format/layout/preset change via logical canvas size

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: constrain PiP overlay to layout picker preview canvas bounds
```

---

## PiP canvas clamp + WYSIWYG live preview (2026-06-02)

### Problem
- Stale normalized PiP position from pre-fix panel geometry → facecam top-left bleed
- `CompositeEngine` did not clamp/crop PiP to canvas → same overflow in exports
- Layout picker preview used SwiftUI PiP overlay only; recording used composite engine (not WYSIWYG)

### Fix
- **`PiPLayoutMath`** — single pip rect/center/clamp for SwiftUI + CoreImage coordinate spaces
- **`CompositeEngine`** — clamp pip rect + crop composite to canvas
- **`CompositePreviewCoordinator`** — bakes camera via same composite path as recording
- **`PiPOverlayView`** — offset layout (no `.position` bleed); `interactionOnly` mode for drag handles
- **`PiPController.normalizePositionForCanvas`** on layout picker + recording start

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: clamp PiP to canvas bounds and bake camera into live composite preview
```

---

## PiP interaction chrome alignment (2026-06-02)

### Problem
- Baked facecam inside canvas but blue drag/resize chrome detached (Face-Top → chrome bottom-right)
- CI bottom-left compositing vs SwiftUI top-left overlay coords

### Fix
- `CompositePreviewNSView.isFlipped = true` for AppKit preview paths
- `LayoutLivePreviewStack` uses SwiftUI `Image` (top-left coords match overlay)
- `PiPOverlayView` — single framed interaction group; resize handle inside pip bounds
- `PiPLayoutMath` coordinate comments + DEBUG rect logging

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: align PiP interaction chrome with baked preview using shared coordinates
```

---

## Layout preview PiP regression fix (2026-06-02)

### Problem
- `scaleEffect(y:-1)` on baked composite flipped image only — chrome stayed put, face upside down
- Bottom-Right preset showed face top-left, chrome bottom-left

### Fix
- Revert layout preview to **windows-only composite** + **SwiftUI PiP overlay** (camera + chrome one view)
- Remove composite `scaleEffect`; remove `pipStateProvider` bake wiring
- `orientedCameraFrame` in `CompositeEngine` + camera-only `scaleEffect(y:-1)` in `PiPOverlayView`
- Removed noisy `[PiPOverlay]` debug logging

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: restore SwiftUI PiP overlay for layout preview and correct camera orientation
```

---

## Webcam orientation — single normalize at capture (2026-06-02)

### Problem
- Face upside down in layout preview + recording
- Duplicate flips: `PiPOverlayView.scaleEffect(y:-1)` + `CompositeEngine.orientedCameraFrame`

### Fix
- **`CameraFrameOrientation.normalize`** at capture in `CameraCapture` (`flipVertical = false`)
- Removed overlay `scaleEffect` and engine `orientedCameraFrame`
- One toggle (`flipVertical`) if still wrong after testing

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
fix: correct webcam orientation with single normalize at capture
```

---

## Single cursor + free-form window layout (2026-06-02)

### Part A — Single cursor
- `WindowStreamManager`: `showsCursor = false` on per-window SCK streams
- **`CursorCompositor`**: maps `NSEvent` mouse position → active window placement → draws `NSCursor.arrow` once in composite
- Wired into `CompositeEngine`, `CompositePreviewCoordinator`, `RecordingSessionCoordinator`
- Layout preview starts `CursorTracker` + `ActiveWindowMonitor`

### Part B — Free-float windows
- **`WindowPlacement`** model + **`WindowPlacementMath`** + **`WindowPlacementController`**
- **`LayoutPreset.freeForm`** (“Free”) + 5th layout card
- **`WindowPlacementsOverlayView`**: drag/resize chrome per window (like PiP)
- `CompositeEngine` uses custom placements when `freeForm`; persisted via `AppState.windowPlacements`
- Recording reads placements from `AppState` on start

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: free-form window layout and single-cursor composite rendering
```

---

## Blueprint Day 40.2 — Editor 2.0 Enhanced Single-Clip (2026-06-09)

### Implemented
- **Editor shell:** `EditorShellLayout` — left project bin, center preview, right inspector (Edit | Captions | Export), bottom tracks
- **Project bin:** `EditorProjectBinView` — main recording + Import image (PNG/JPG) / audio (MP3/WAV/AAC); session-scoped assets
- **Timeline tools:** `EditorTracksView` — Split at playhead, Delete selection, Undo cuts; multi-cut via `removedRanges[]`; split markers
- **Multi-cut model:** `EditTimelineModel.removedRanges` — cumulative kept ranges; `CaptionTimelineMapper` unchanged (uses kept ranges)
- **Image overlay:** `EditorImageOverlay` + preview + Edit tab opacity/position; burned via `EditorCompositionBuilder` at export
- **Imported audio:** `EditorImportedAudio` — volume + export-timeline start offset; mixed in `ExportService` via second audio track
- **Export:** `EditorProjectModel` passed through `ExportOptions`; duration mismatch guard on stitch; Phase D export fix retained
- **Shortcuts:** Space play/pause, S split at playhead

### Files (new)
- `EditorProjectModel.swift`, `EditorCompositionBuilder.swift`
- `EditorShellLayout.swift`, `EditorProjectBinView.swift`, `EditorTracksView.swift`, `EditorImageOverlayPreview.swift`

### Files (updated)
- `EditTimelineModel.swift`, `EditorViewModel.swift`, `EditorView.swift`, `EditorTimelineView.swift`
- `ExportService.swift`, `ExportViewModel.swift`, `CaptionTimelineMapper.swift`, `CaptionEditorViewModel.swift`

### Unchanged
- Recording engine, layout picker, PiP, composite, Dashboard, standalone `ExportView` re-export

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: Editor 2.0 shell with multi-cut, image overlay, and imported audio (Day 40.2)
```

---

## Blueprint Day 40.3 — Editor polish: caption export Y + draggable overlay/audio (2026-06-09)

### Symptom
Pro user selects **Bottom** caption position → preview correct → exported MP4 shows caption at **top**. Drag placement on preview did not reliably match burn-in.

### Root cause
`CaptionStyleConfig.captionOriginY` used **non-flipped** Core Animation math (bottom = low Y) while `CaptionRenderer.burnInCaptions` sets `parentLayer.isGeometryFlipped = true` (top-left origin, Y down). Top/Bottom were inverted; custom vertical offset sign was also wrong (+offset added Y instead of subtracting).

### Fix
- **`CaptionStyleConfig.captionOriginY`:** rewritten for flipped CALayer space — top = margin, bottom = renderHeight − margin − boxHeight; offset subtracts (+ moves up)
- **`CaptionPreviewView`:** caption drag hit-testing only when `isCaptionPlacementEditable` (Captions tab)
- **`EditorImageOverlayPreview`:** drag on preview (Edit tab), dashed chrome, normalized position callbacks
- **`EditorTracksView`:** draggable imported-audio clip on audio lane → `updateImportedAudioStart`
- **`EditorView`:** wired overlay/audio drag; hints for caption vs image drag

### Export style path
`EditorViewModel.saveCaptionsBeforeExport()` saves in-memory `selectedStyle` to sidecar before export (unchanged; sufficient after Y fix).

### Build
- `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **BUILD SUCCEEDED**

### Suggested commit
```
fix: align caption export placement with preview; draggable overlay and audio (Day 40.3)
```

---

## Blueprint Day 41 — Editor 3.0 contextual flow (2026-06-09)

### Problem
Editor 2.0 Filmora-style 4-panel IA fought the job (record → trim → captions → export): permanent project bin for 1 image + 1 audio, Export tab vs toolbar split, hidden Captions for Free, split import/controls, silent Dashboard re-export of full clip.

### Implemented
- **`EditorShellLayout`:** 2-column preview | inspector + full-width tracks (bin column removed)
- **`EditorSelection` + `EditorInspectorPanel`:** selection-driven controls (timeline, image, audio, captions, segment)
- **`EditorExportSheet`:** single export surface — summary, resolution, caption/SRT toggles, progress, Export button
- **`EditorViewModel.exportSummary`:** “What’s included” lines before export
- **Captions mode:** always in inspector bar; Free → Pro gate (Apple-style locked state)
- **Caption drag:** Pro + segments visible + not editing image (any inspector mode)
- **`EditorTracksView`:** Import menu; overlay/audio lane tap → select; “Clear all cuts”; per-cut remove via inspector
- **`EditTimelineModel.removeRemovedRange(at:)`**
- **`RecordingDetailView`:** “Re-export original…” + confirmation (honest full-clip path)

### Deferred
- Persist `EditorProjectModel` to disk for Dashboard re-edit
- Full undo/redo stack
- Timeline zoom

### Build
- `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **BUILD SUCCEEDED**

### Suggested commit
```
refactor: Editor contextual flow with export sheet and re-export trust fixes (Day 41)
```

---

## Blueprint Day 41.5 — Timeline clip timing for image + audio (2026-06-09)

### Problem
Image overlay and imported audio used full-trim/full-file timing: import wiped to trim span, preview always visible, export used infinite CALayer duration and full audio file.

### Implemented
- **`EditorTimelineClipView`:** reusable clip block — drag body, trim in/out handles
- **`EditorImageOverlay`:** `contains(playhead:)`, `clampedInterval`, default 5s at playhead on import (source timeline)
- **`EditorImportedAudio`:** `timelineEndSeconds`, `playDuration`, default 10s clip on export timeline
- **`EditorViewModel`:** `updateImageStart/End/ClipMove`, `updateAudioStart/End/ClipMove`; `clampImageOverlayToTrim` replaces `syncImageOverlayTimes`
- **Preview:** image hidden outside source interval
- **`EditorCompositionBuilder`:** image layers per kept-range export interval (Option B); audio insert uses clip duration clamped to composition
- **Export summary:** `Image: file · 0:05–0:12`, `Audio: file · 0:08–0:35`

### Build
- `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **BUILD SUCCEEDED**

### Suggested commit
```
feat: timeline clip timing for image overlay and imported audio
```

---

## Blueprint Day 41.5 — Timeline lane alignment fix (2026-06-09)

### Symptom
Preview showed image at playhead 2.0s (range 1.6–3.1s) but red playhead appeared left of IMG clip — timeline lied while preview was correct.

### Root cause
Main track used full panel width for playhead x; overlay/audio lanes used 52pt label + narrower track (`HStack spacing: 8` added extra gap). Different formulas → misaligned pixels at same timestamp.

### Fix
- **`EditorTimelineLayout`:** shared `laneLabelWidth`, row heights, `trackContentWidth`
- **`TimelineGeometry`:** shared `xPosition` / `timeAt` / `absoluteX`
- **`EditorTracksView`:** single `GeometryReader`; all lanes use `HStack(spacing: 0)` + fixed `trackWidth`
- **Unified playhead** in `ZStack` at `laneLabelWidth + xPosition(sourceTime)`
- Secondary blue playhead on audio row when export-mapped time differs (trim/cuts)
- **`EditorTimelineView` / `EditorTimelineClipView`:** accept explicit `trackWidth`; main track hides per-row playhead

### Build
- `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **BUILD SUCCEEDED**

### Suggested commit
```
fix: align overlay/audio timeline clips with main playhead column
```

---

## Blueprint Day 40.1 Phase D — Middle-chunk delete (2026-06-02)

### Context
- Phase B in/out trim only keeps one contiguous range (drop start and/or end)
- User request: **remove a chunk from the middle** (e.g. delete 20s–40s, keep 0–20s + 40–60s) while **captions still match** the stitched video

### Decision
- Add as **Day 40.1 Phase D** (not post-MVP) on branch `editor`
- Middle delete alone breaks caption timing unless segments are remapped — Phase D includes a shared **`CaptionTimelineMapper`** (or extend `TrimHelpers`) used by preview, `CaptionRenderer`, and SRT export

### Remap rules (source → export timeline)
- Drop segments fully inside removed range
- Clip segments overlapping cut boundaries
- Shift segments after cut by `−(cutEnd − cutStart)` (cumulative for multiple cuts in v2)
- Preview scrubber uses export timeline (head → tail jump over deleted section)

### Planned deliverables
| Area | Work |
|------|------|
| Model | `EditTimelineModel` — trim in/out + `RemovedRange`(s) → export duration + kept ranges |
| Mapper | `CaptionTimelineMapper` — segment filter/clip/shift; source ↔ export time |
| UI | `EditorTimelineView` — select region + delete; dim removed zone; export duration readout |
| Export | `ExportService` — multi `insertTimeRange` stitch; remapped segments for burn-in/SRT |
| Tier | Free + Pro (Edit tab); Pro captions/SRT use remapped times |

### Out of scope
- Ripple edit, multi-clip library, re-transcribe after cut
- Dashboard `ExportView` re-export (still full source clip)

### Acceptance (when implemented)
- Delete one middle chunk → exported duration correct; audio/video continuous at stitch point
- Pro: burned captions and optional SRT aligned to export timeline
- Works combined with Phase B in/out trim

### Suggested commit (when implemented)
```
feat: editor middle-chunk delete with caption remap (Day 40.1 Phase D)
```

---

## Blueprint Day 40.1 Phase C — Caption polish (2026-06-02)

### Implemented
- **Draggable caption placement (Pro, Captions tab):** vertical drag on preview with dashed affordance; `customVerticalOffsetNormalized` (−0.3…+0.3) on `CaptionStyleConfig`; persisted in sidecar; shared math in preview + `CaptionRenderer` burn-in; Top/Middle/Bottom picker resets offset
- **Editable segment times (Pro):** start/end fields on `CaptionSegmentRow`; validated in `CaptionEditorViewModel.updateSegmentTimes`; sorted by start time; flows through sidecar + trim export
- **Optional SRT (Pro, Export tab):** `alsoSaveSRT` toggle; writes `.srt` next to exported MP4 with trim-relative timecodes when trim active

### Files
- `CaptionStyleConfig.swift`, `CaptionSegment.swift` (sidecar fields)
- `CaptionPreviewView.swift`, `CaptionSegmentRow.swift`
- `CaptionEngine.swift`, `CaptionRenderer.swift`, `ExportService.swift`
- `CaptionEditorViewModel.swift`, `EditorViewModel.swift`, `ExportViewModel.swift`, `EditorView.swift`

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: editor caption placement and SRT export (Day 40.1 Phase C)
```

---

## Blueprint Day 40.1 Phase D — Middle-chunk delete + caption remap (2026-06-02)

### Implemented
- **`EditTimelineModel`:** trim window (Phase B) + optional single `RemovedRange`; computes `keptSourceRanges` and `exportDurationSeconds`; invalidates cut when trim handles move; min 0.5s removed span and min 0.5s head/tail within trim
- **`CaptionTimelineMapper`:** source ↔ export time mapping; `segmentsForExportTimeline` (SRT + preview overlay); `segmentsForSourceBurnIn` (absolute clipped times on full source before stitch); `snapToKeptSourceTime` for scrub/seek
- **`EditorTimelineView`:** orange selection handles (distinct from trim); hatched red removed zone; export duration readout when middle delete active
- **`EditorView` Edit tab:** Select region / Delete selection / Undo delete; export length readout
- **`EditorViewModel`:** owns `editTimeline`; selection + delete APIs; passes `editTimeline` + `exportDurationOverride` to export; SRT via export-timeline segments
- **`CaptionEditorViewModel`:** export-aware playback — skips removed zone, jumps between kept ranges, pauses at export end; caption overlay uses export-timeline lookup when edits applied
- **`ExportService`:** `ExportOptions.editTimeline`; burn-in on full source with clipped absolute segments; `writeEncodedExport` stitches multiple `insertTimeRange` calls for video + audio
- **`ExportViewModel`:** `editTimeline` + `exportDurationOverride`; standalone Dashboard re-export unchanged (`editTimeline = nil` → full clip)
- **Sidecar:** source segment times unchanged; remapping only at preview/export

### Export pipeline (trim + middle delete)
1. Load captions → `segmentsForSourceBurnIn` (absolute times on source file, clipped to kept ranges)
2. `burnInCaptions` on **full** source (gaps = no captions in removed zone)
3. `writeEncodedExport` loops kept ranges into composition at t=0, t+range1.duration, …
4. SRT: `segmentsForExportTimeline` (export-relative, t=0 at export start)

### Build
- `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **BUILD SUCCEEDED**

### Suggested commit
```
feat: editor middle-chunk delete with caption remap (Day 40.1 Phase D)
```

---

## Blueprint Day 40.1 Phase D — Export stitch bugfix (2026-06-02)

### Symptom
Middle delete UI worked (red dashed zone, timeline readout e.g. "Export: 32.2s (removed 3.7s)") but toolbar Export produced a **full uncut** MP4. Export tab rounded export/source to the same whole second (0:32 vs 0:32).

### Root cause
`EditTimelineModel.keptSourceRanges` and `exportDurationSeconds` were **`private(set)` cached fields** populated by `recompute()`. When the struct was copied into async `ExportOptions` / `ExportService`, the encode path could receive **stale or empty kept ranges**, causing `writeEncodedExport` to fall back to `[KeptSourceRange(start: 0, end: fullDuration)]` — a single full-source range with no stitch.

### Fix
- **`EditTimelineModel`:** `keptSourceRanges` + `exportDurationSeconds` are now **computed** from trim + `removedRange`; added `preparedForExport()`, `requiresStitchExport`
- **`EditorViewModel.exportRecording`:** always passes `editTimeline.preparedForExport()`; DEBUG log of kept ranges
- **`ExportService.writeEncodedExport`:** calls `preparedForExport()` at encode start; uses `requiresStitchExport`; **post-export duration check** throws if output differs from expected by >1s
- **`ExportViewModel`:** passes prepared timeline in `ExportOptions`; metadata duration from override/timeline
- **UI:** `formatExportDurationDisplay` shows fractional seconds when export is within 10s of source; Export tab shows **Removed:** span

### Build
- `xcodebuild -scheme FrameFlow -destination 'platform=macOS' build` — **BUILD SUCCEEDED**

### Suggested commit
```
fix: apply middle-delete stitch on export (Day 40.1 Phase D)
```

---

## Blueprint Day 40.1 Phase B — Editor trim timeline (2026-06-02)

### Implemented
- **`EditorTimelineView`** — in/out draggable handles (0.5s min span), playhead, duration readout, tap-to-seek
- **`EditorViewModel`** — trim state, `playbackRange` sync to caption player, trim passed to export
- **`TrimHelpers`** — segment clip/shift for export; shared timeline time formatting
- **`CaptionEditorViewModel.playbackRange`** — preview play/seek constrained to trim; auto-pause at out point
- **`ExportOptions` + `ExportService`** — `CMTimeRange` trim on video + audio during encode; caption burn-in uses segments clipped to trim (absolute times on full source, then trim in encode)
- **`ExportViewModel`** — optional trim fields (Editor only); standalone Export leaves nil

### Export path (documented)
1. Load captions → clip to `[trimStart, trimEnd]` with absolute times
2. `burnInCaptions` on **full** source with clipped segments
3. `writeEncodedExport` inserts `CMTimeRange(trimStart, trimEnd−trimStart)` for video + audio

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: post-record editor trim timeline (Day 40.1 Phase B)
```

---

## Blueprint Day 40.1 Phase A — Post-Record Editor (2026-06-02)

### Implemented
- **`AppRoute.editor`** — unified post-record screen; `.captionEditor` route redirects to `EditorView`
- **`EditorView` + `EditorViewModel`** — 55/45 split: shared `CaptionPreviewView` + inspector tabs
  - **Edit:** preview, play/pause, scrub; "Trim coming soon" placeholder (Phase B)
  - **Captions (Pro):** style cards, segment list, position picker, inline transcription progress; no export controls
  - **Export:** resolution picker, captions toggle, watermark notice, progress — settings only; toolbar **Export** is primary action
- **`RecordingView`:** Stop → `.editor` for all users; Pro starts `CaptionGenerationState` before navigate
- **`ExportView`:** unchanged for Dashboard / RecordingDetail re-export
- **`CaptionEditorView`:** legacy file retained; post-record path removed
- **`HelpView`:** FAQ updated for Post-Record Editor flow

### Files
- `EditorView.swift`, `EditorViewModel.swift`
- `Models.swift`, `RouteDetailView.swift`, `RecordingView.swift`
- `CaptionEditorViewModel.swift` (`loadPreview`), `HelpView.swift`
- `Docs/CURRENT_STATUS.md`, `Docs/DEV_LOG.md`

### Build
- `xcodebuild` macOS — **BUILD SUCCEEDED**

### Suggested commit
```
feat: unified post-record editor (Day 40.1 Phase A)
```

---

## Blueprint Day 40.1 — Post-Record Editor (planning, 2026-06-02)

### Context
- During **Day 40** recording-flow testing, separate **Caption Editor** and **Export** screens felt fragmented
- Caption Editor duplicated export (burn-in/SRT) while toolbar "Export Video" skipped saving edits
- User request: one **basic editor** after Stop — trim, captions (Pro), placement, export sizes in one place

### Decision (documented in Master Blueprint)
- **Stop → Editor → Dashboard** for all new recordings
- **Free:** Edit tab + Export tab (720p, watermark); no Captions tab
- **Pro:** + Captions tab (generate, style, position, segment text); export 1080p/4K; optional SRT on Export tab
- **Dashboard re-export:** keep standalone `ExportView`

### Phases
| Phase | Deliverable |
|-------|-------------|
| A | `EditorView` shell, three tabs, wire Stop → `.editor`, remove in-editor export |
| B | Timeline trim in/out |
| C | Draggable caption box, editable segment times, optional SRT |
| D | Middle-chunk delete + caption time remapping for preview/export/SRT |

### Files to create/modify (implementation — not started)
- `EditorView.swift`, `EditorViewModel.swift`
- `AppRoute.editor`, `RouteDetailView`, `RecordingView` navigation
- Refactor panels from `CaptionEditorView` + `ExportView`
- Blueprint + status docs updated

### Next
- Complete Day 40 checklist
- Implement Day 40.1 Phase A on `feature/uiFix`

### Suggested commit (docs only)
```
docs: add Blueprint Day 40.1 post-record editor flow
```

---

## Razor cut — iMovie Blade (timeline interaction)

### Completed
- Replaced scissors → range-select → popover with **razor mode** toggle (filled yellow icon when active)
- Click video lane in razor mode → instant `splitPoints` add at source time (snapped via `CaptionTimelineMapper`)
- Segment-based clip rendering with yellow borders + per-split trim handles; drag shared boundary moves split (no gap until `removedRanges`)
- Keyboard: **⌘B** blade at playhead; **S** toggles razor mode; **Escape** exits razor mode
- Removed playhead drag range-selection overlay + action popover
- Toolbar trash + `deleteSelection()` unchanged (secondary delete workflow)

### Files
- `EditTimelineModel.swift` — `VideoClipSegment`, `moveSplitPoint`, `videoClipSegments()`
- `EditorViewModel.swift` — `razorModeActive`, `splitAtPoint`, `moveSplitPoint`
- `EditorTimelineView.swift` — segment clips, razor tap, split handle drag
- `EditorTracksView.swift` — razor toolbar, hover line, Escape
- `EditorView.swift` — keyboard wiring

### Notes
- `splitPoints` remain visual markers; export gaps still driven by `removedRanges[]`
- Build verified: **BUILD SUCCEEDED**

### Suggested commit
```
feat: iMovie-style razor cut with segment clips and movable split boundaries
```

---

## Segment trim + ripple gap close

### Completed
- Extended `VideoClipSegment` with `effectiveStart/End`, `hasGapBefore/After`
- Segment mutations: `trimSegmentIn/Out`, `extendSegmentIn/Out`, `rippleCloseGap`
- Relaxed `pruneInvalidRemovedRanges` for segment-level gaps between splits
- Bilateral yellow handles per segment in `EditorTimelineView`; drag routes to trim/extend/ripple/moveSplit
- ViewModel: `trimVideoSegmentOut/In`, `extendVideoSegmentOut/In`, `rippleCloseVideoGap`, `moveVideoSplitBoundary`
- 6 unit tests in `FrameFlowTests` — all passing

### Suggested commit
```
feat: iMovie segment trim with export-aware gaps and ripple gap close
```

---

## Filmstrip timeline UI

### Completed
- `ThumbnailStripGenerator` actor — async AVAssetImageGenerator strip with cache (reuses SecurityScopedFileAccess pattern from dashboard thumbnails)
- `EditorFilmstripClipView` — tiled thumbnails, 2pt yellow border, loading placeholder, pill label when width > 80pt
- `EditorWaveformBar` — seeded procedural amplitude bars (14pt)
- Video lane 72pt (54pt filmstrip + 14pt waveform); `EditorFilmstripTrimHandle` 12pt with 3 grip lines
- `EditorTimelinePlayheadMarker` — white 1.5pt line + 12×10 downward triangle
- Removed left label column; full-width tracks; timeline bg `rgb(0.12)`; alternating lane rows

### Suggested commit
```
feat: iMovie filmstrip timeline with thumbnails, waveform, and chunky trim handles
```

---

## Filmora-style timeline toolbar + lane controls + preview transport

### Completed
- **Two-row toolbar** in `EditorTracksView`: undo/redo, delete, razor (yellow when active), stub edit tools; magnetic snap + auto-ripple toggles; zoom slider (0.5–4×) with +/- buttons
- **TimelineRulerView** — zoom-aware tick marks + HH:MM:SS labels above lanes
- **LaneControlBar** — 80pt left column per lane: name, lock, mute, eye; lock disables drag/trim; mute silences audio preview track; hide grays clip content
- **FilmoraPlayheadView** — red vertical line + draggable round handle for seek
- **AudioWaveformGenerator** + **AudioWaveformView** — real AVAssetReader amplitude data, cyan Canvas bars on audio lane
- **PreviewTransportBar** in `CaptionPreviewView` — timecode, quality picker, red scrubber, transport buttons; wired to `jumpToStart`, `togglePlayback`, `stopPreview`, in/out trim, snapshot to Downloads
- **EditorViewModel** — `timelineZoom`, lane state, `deleteSelectedClip()`, undo/redo, stub toasts, `snapshotCurrentFrame()`

### Files (new)
- `AudioWaveformGenerator.swift`, `AudioWaveformView.swift`, `FilmoraPlayheadView.swift`, `TimelineRulerView.swift`, `LaneControlBar.swift`, `PreviewTransportBar.swift`

### Stubs (intentional)
- Magnetic snap / auto-ripple behavior; detach audio, text, crop, color, stabilise; slow motion, fullscreen, layout toggle; undo/redo toast when NSUndoManager unavailable

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
feat: Filmora-style timeline toolbar, lane controls, playhead, and preview transport
```

---

## Editor MVP trim-down (blueprint Screen 11)

### Decision (updated)
- **Cut workflow: razor only** — scissors toggle + click lane → `splitAtPoint` / `splitPoints[]`. **Removed** select-region + Delete middle-cut UX. Razor splits are visual markers; export shortens via global trim only (not splits alone).

### Completed
- **EditorTracksView** — scissors toggle (yellow when active), Clear splits, timecode; one video lane + 24px ruler
- **EditorTimelineView** — per-segment bodies after razor; global in/out handles; movable split boundaries; razor tap + crosshair; white playhead; lane scrub
- **EditorView** — simplified preview (play + scrub only); source-time playhead; removed razor/overlay/audio wiring
- **EditorInspectorPanel** — Edit tab: trim + razor hints only (no Select region, no removed-sections list)
- **CaptionPreviewView** — minimal transport (play/pause + slider + times); removed stub transport buttons
- **EditorViewModel** — removed NLE surface state (razor, zoom, lane lock, stub tools)
- **ExportService** — stitch via `keptSourceRanges` (middle-delete truth)

### Retained (unchanged)
- `EditorShellLayout` 58/42 + tracks below
- Toolbar Discard / title / Export + `EditorExportSheet`
- Captions tab (Pro) + Whisper flow
- `CaptionTimelineMapper`, export stitch algorithm

### Suggested commit
```
refactor: MVP editor — single video lane, razor-only cuts, remove range delete and NLE chrome
```

---

## Editor simplified — preview, captions, info, export only

### Decision
- Post-record **Screen 11** is a single view: no bottom timeline, no trim handles, no razor/scissors, no import lanes. Export always uses the **full captured recording** (`editorProject` / `editTimeline` nil on export).

### Completed
- **EditorShellLayout** — preview + sidebar only (dropped `tracks` panel; 58/42 split)
- **EditorView** — toolbar Discard | title | Export Video; `CaptionPreviewView` + Space play/pause; removed timeline key handlers (↑↓, ⌘B, S, Esc)
- **EditorInspectorPanel** — one scrollable sidebar: Video info → Captions → Export hint; removed Edit | Captions segmented toggle and timeline/import/overlay sections
- **EditorClipInfoSection** — duration, resolution, format, file size, audio mode, layout (no trim/export-duration/split stats)
- **EditorViewModel** — `exportRecording` passes nil `editorProject` / `editTimeline` / `exportDurationOverride`; caption preview uses full source; removed `razorModeActive` and `tracksPanelHeight` from UI path
- **EditorTracksView** — excluded from Xcode target (`membershipExceptions`); timeline components left on disk unlinked

### Retained
- Stop → Editor navigation; `CaptionGenerationState.begin` / Generate / Retry; `EditorExportSheet` + `ExportViewModel` + `ExportService`; Pro gates; Discard → staging cleanup; `SecurityScopedFileAccess`

### Deferred (post-MVP)
- Timeline lane, razor, trim, middle-delete, overlay/audio import, filmstrip, Dashboard re-edit from library

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
feat: simplify editor to preview, captions, info, and export only
```

### Docs
- **FrameFlow_Master_Blueprint.md** — Day 40.1 rewritten: phases A–D = Flow, Simple layout, Captions, Export; trim/cut/timeline moved to post-MVP; Screen 11 + Day 41 checklist updated
- **CURRENT_STATUS.md** — aligned with simplified Day 40.1 scope
- **FrameFlow_Master_Blueprint.md** — **Day 45.1 UI Enhancement** added after Day 45 (professional redesign pass before Phase 17 distribution)
- **FrameFlow_Master_Blueprint.md** — **Day 41.2** = platform preview guides (Shorts/TikTok/Reels) on Layout Picker only; Day 40.2 retired; removed incorrect “layout improvement” 41.2 scope

---

## Day 41.2 — Platform preview guides (Layout Picker)

### Scope
- **Layout Picker only** — mock Shorts / TikTok / Reels UI on 9:16 live composite preview before recording
- **Preview decoration only** — not in `CompositeEngine`, `RecordingEngine`, export, Editor, or Recording Detail

### Completed
- **`PlatformPreviewOverlay`** — `.none`, `.youtubeShorts`, `.tiktok`, `.instagramReels`
- **`PlatformSafeZoneOverlayView`** — SF Symbols + placeholder text; semi-transparent panels; scales with canvas; `.allowsHitTesting(false)`
- **`LayoutPickerViewModel`** — `platformPreviewOverlay` (session-only); resets to `.none` when leaving 9:16
- **`LayoutPickerView`** — segmented picker + “Guide only — not included in your video”; 16:9 shows disabled hint
- **`LayoutLivePreviewStack`** / **`LayoutPreviewCanvas`** — overlay drawn above composite + PiP in preview ZStack

### Preserved
- Live preview start/stop; Pro gate on 9:16; layout presets; PiP drag/resize; window placement; recording output unchanged

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
feat: platform preview guides for Shorts, TikTok, and Reels on layout picker (Day 41.2)
```

---

## Day 41.2a — YouTube Shorts preview guide (iPhone reference)

### Scope
- **YouTube Shorts only** on Layout Picker 9:16 live preview — TikTok/Reels deferred to 41.2b
- Mock iPhone YouTube Shorts chrome: bottom nav, bottom-left metadata, right action column
- Preview decoration only — not in `CompositeEngine`, recording, or export

### Completed
- **`PlatformPreviewOverlay`** — `.none`, `.youtubeShorts` only
- **`YouTubeShortsGuideOverlayView`** — bottom nav (Home / Shorts / Create / Subscriptions / Library); progress bar; song pill; description; channel + Subscribe; “Use this sound”; right column (like/dislike/comments/share/remix + music thumbnail)
- **`PlatformSafeZoneOverlayView`** — routes to `YouTubeShortsGuideOverlayView`
- **`LayoutPickerView`** — segmented **None | YouTube Shorts** + guide caption when 9:16

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
feat: YouTube Shorts preview guide overlay on layout picker (Day 41.2a)
```

---

## Day 41.2a polish — iPhone 11 sizing calibration

### Problem
Initial overlay used `width / 720` scaling and heuristic padding (`navBar + 14% height` for right column), making icons ~40% too small and pushing the action column too high vs real iPhone 11 Shorts.

### Fix
- **`YouTubeShortsLayoutMetrics`** — iPhone 11 reference (414×896 pt); `ptWidth` / `ptHeight` map to any 9:16 canvas
- **`YouTubeShortsGuideOverlayView`** — anchored layout: nav ~6.3% height, 2pt progress bar, left stack at 62pt from bottom, right column at 68pt from bottom, ~26pt action icons
- Previews at **720×1280** (recording canvas) and **414×896** (iPhone 11)

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
fix: calibrate YouTube Shorts guide overlay to iPhone 11 proportions
```

---

## Day 41.2b — Instagram Reels preview guide (iPhone 11)

### Scope
- Instagram Reels mock chrome on Layout Picker 9:16 live preview — TikTok still deferred
- iPhone 11 proportions via `InstagramReelsLayoutMetrics` (414×896 pt)
- Preview decoration only — not in recording or export

### Completed
- **`PlatformPreviewOverlay.instagramReels`** — picker label **Reels** (segmented: None | YouTube Shorts | Reels)
- **`InstagramReelsLayoutMetrics`** — nav, action column, profile/caption offsets
- **`InstagramReelsGuideOverlayView`** — bottom nav (Home / Reels / Create / Search / Profile); right column (heart, comment, share, remix counts, ellipsis, audio thumb); bottom-left profile ring + username + verified + Follow + caption
- **`PlatformSafeZoneOverlayView`** — routes to Reels overlay

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
feat: Instagram Reels preview guide overlay on layout picker (Day 41.2b)
```

---

## Day 41.2b — TikTok preview guide (iPhone 11)

### Scope
- TikTok For You mock chrome on Layout Picker 9:16 live preview — completes Day 41.2b
- iPhone 11 proportions via `TikTokLayoutMetrics` (414×896 pt)
- Preview decoration only — not in recording or export

### Completed
- **`PlatformPreviewOverlay.tiktok`** — menu picker: None | YouTube Shorts | Reels | TikTok
- **`TikTokLayoutMetrics`** — top tabs, action column, feedback pills, nav offsets
- **`TikTokGuideOverlayView`** — top tabs (Explore / Following / For You) + search; right column (profile + badge, like, comment, bookmark, share, music disc); bottom-left username + caption; feedback pills; bottom nav with TikTok-style create button
- **`LayoutPickerView`** — platform picker switched to `.menu` (4 options)
- **`PlatformSafeZoneOverlayView`** — routes to TikTok overlay

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
feat: TikTok preview guide overlay on layout picker (Day 41.2b)
```

---

## Editor platform preview guides (9:16 post-record)

### Scope
- Reuse Layout Picker platform mock UI on **EditorView** video preview for vertical recordings only
- Shift caption preview into platform safe zones via `PlatformCaptionPreviewInsets` — preview only, export unchanged

### Completed
- **`EditorViewModel.platformPreviewOverlay`** — session state; reset on 16:9 load
- **`EditorInspectorPanel`** — Platform preview menu (9:16 only)
- **`EditorView`** — `PlatformSafeZoneOverlayView` via `CaptionPreviewView.previewOverlay`
- **`PlatformCaptionPreviewInsets`** — per-platform edge insets for caption overlay
- **`CaptionPreviewView` / `CaptionOverlayView`** — `platformPreviewOverlay` + `additionalPreviewInsets`

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
feat: platform preview guides on post-record editor for 9:16 videos
```

---

## Caption preview WYSIWYG fix (Editor + platform guides)

### Problem
- Platform guide active → captions shifted in preview via asymmetric insets but export used full-frame `captionOriginY` → burn-in appeared lower than preview
- Asymmetric leading/trailing insets broke horizontal centering when a platform preset was selected

### Fix
- Removed `PlatformCaptionPreviewInsets` from caption layout (platform chrome stays decorative only)
- Added **`CaptionLayoutMath`** — shared box height + frame math for preview and `CaptionRenderer`
- Refactored **`CaptionOverlayView`** to position via `captionFrame` (88% width centered, 8% margin via `captionOriginY`)
- Preview fonts scale with `containerHeight / 1080` like export
- Updated Editor hint: caption placement matches export

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
fix: align editor caption preview with export burn-in positioning
```

---

## Caption generation speed + progress fix

### Problem
- Post-record caption generation felt slow/stuck on "Transcribing…"
- `CaptionEngine.generateCaptions` always burned captions into MP4 after Whisper — redundant for Editor (SwiftUI overlay + export-time burn-in)
- Whisper progress could regress to 25% via `transcriptionStateCallback`, making the bar look frozen
- Cancelled generation tasks could leave `isTranscribing` stuck true

### Fix
- **`CaptionEngine.generateCaptions`** — `burnIn: Bool = false`; Editor path skips burn-in (sidecar + SRT only)
- **`CaptionGenerationState`** — run token guards; throttled monotonic progress; clears state on cancellation; runs Whisper off MainActor; elapsed seconds in status after 3s
- **`TranscriptionService`** — monotonic progress; explicit `openai_whisper-base.en` model; background `prepareModelInBackground()` on app launch / Layout Picker for Pro; model-state progress labels
- **`EditorViewModel` / `CaptionEditorViewModel`** — defer `AVPlayer` load while transcription runs to reduce CPU contention
- **`EditorView`** — hide 9:16 platform guide overlay during transcription

### Build
- **BUILD SUCCEEDED** (macOS 14+)

### Suggested commit
```
fix: speed up editor caption generation and fix stuck transcribing progress
```
