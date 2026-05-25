# FrameFlow Dev Log

Canonical path: `Docs/DEV_LOG.md` (referenced by Cursor rules and `CURSOR_START_HERE.md`).

---

## Day 1 — Project Foundation

### Completed
- Created Xcode macOS SwiftUI project
- Set deployment target to macOS 14.0
- Created app folders/groups (`App/`, `Views/`, `Views/Screens/`)
- Created Cursor docs structure
- Built `NavigationSplitView` shell (sidebar: **Home, Settings, Account** — blueprint Option B)
- Set window minimum size to 900×600 and default size to 1100×700

### Decisions
- Use SwiftUI
- Use MVVM architecture
- Use `@Observable` for `AppRouter` (macOS 14+)
- Use direct DMG distribution before Mac App Store
- Keep project documentation updated daily
- **Navigation: Option B** — follow blueprint sidebar/routes, not simplified Home/Record/Projects

### Next (Day 2)
- Add SPM dependencies (Supabase, RevenueCat, WhisperKit, Sparkle, Sentry)
- Add `Config.swift` and `.gitignore` for secrets

---

## Day 2 — Navigation & Placeholders

### Completed
- Added `AppRoute` enum (18 routes aligned with blueprint screens)
- Added `AppRouter` with sidebar selection and `navigate(to:)`
- Wired sidebar sections to routes (Home → Dashboard, Settings → Settings, Account → Profile)
- Created 18 placeholder screen views with planned UI as disabled controls
- Added toolbar route picker for end-to-end navigation testing during placeholder phase

### Files
- `App/Models.swift` — `SidebarSection`, `AppRoute`
- `App/ViewModels.swift` — `AppRouter`
- `App/Components.swift` — `ScreenPlaceholder`
- `Views/MainAppView.swift`, `Views/RouteDetailView.swift`, `Views/Screens/PlaceholderScreens.swift`

### Next (Day 3+)
- Supabase `AuthService` and auth flow screens
- Replace placeholders with real Dashboard and recording flow UI
- Screen recording entitlements and permission guides

---

## Day 2 (docs) — Cursor & documentation setup (Part 1)

### Completed
- Populated `.cursor/rules/frameflow_rules.mdc` (`alwaysApply: true`)
- Populated `Docs/CURRENT_STATUS.md` with phase, Option B, and next tasks
- Populated `Docs/CURSOR_START_HERE.md` with read order and scope boundaries
- Canonical dev log at `Docs/DEV_LOG.md` (aligned with Cursor rules; replaces informal `Dev_Log.md` naming)

### Decisions
- **Option B confirmed:** blueprint navigation (Home / Settings / Account + `AppRoute`)
- Target code layout: `App/Views`, `App/ViewModels`, etc. (migration deferred to Part 2 — Swift)

### Next
- **Part 2:** Reorganize Swift files under `App/` without changing behavior
- **Day 2 (blueprint):** SPM packages + `Config.swift` + `.gitignore`

### Suggested commit
```
chore: add Cursor rules and align project documentation (Option B)
```
