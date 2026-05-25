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
