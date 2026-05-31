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

### Not in scope
- Day 33 expiry banner dismiss polish
- Stripe / web billing (production DMG distribution — future)
- Mac App Store Connect IAP

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
