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
