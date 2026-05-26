# Changelog

All notable changes to FrameFlow are documented in this file.

## [Unreleased]

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
