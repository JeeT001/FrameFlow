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
- Minimal first-run `OnboardingView`
- `AuthService.restoreSession()` for bootstrap
- `PermissionManager` and `DeviceCapabilityManager`
- Settings permissions UI (Day 8 testing section)
- `FrameFlow.entitlements` with sandbox, network client, camera, and mic
- `RecordingMetadata` model and local `RecordingStore` (Application Support `recordings.json`)
- `DashboardView` with recording grid, empty state, and New Recording navigation
- `RecordingListItemView` for dashboard recording cards
- `AppState.SubscriptionStatus` scaffold and `isPro` for upgrade/banner UI (no RevenueCat yet)

### Changed
- Moved `Services`, `Resources`, and `Utils` stubs into dedicated subfolders under `App/`
- Excluded `Config.example.swift` from compile when local `Config.swift` is present
- Replaced auth screen placeholders with functional Supabase-backed forms
- `FrameFlowApp` launches `RootView` instead of always showing `MainAppView`
