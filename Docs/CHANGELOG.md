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

### Changed
- Moved `Services`, `Resources`, and `Utils` stubs into dedicated subfolders under `App/`
- Excluded `Config.example.swift` from compile when local `Config.swift` is present
