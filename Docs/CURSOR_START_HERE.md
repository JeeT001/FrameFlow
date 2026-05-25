# Cursor Start Here — FrameFlow

Read these **before coding**, in order:

1. [CURRENT_STATUS.md](CURRENT_STATUS.md) — phase, tasks, decisions  
2. [FrameFlow_Master_Blueprint.md](FrameFlow_Master_Blueprint.md) — product spec and build plan  
3. [DEV_LOG.md](DEV_LOG.md) — daily progress log  
4. [.cursor/rules/frameflow_rules.mdc](../.cursor/rules/frameflow_rules.mdc) — enforced project rules  

## Navigation choice

**Option B (blueprint)** — use the master blueprint, not the simplified sidebar.

- Sidebar: **Home**, **Settings**, **Account**
- Home → Dashboard; Account → Profile
- Other screens via `AppRoute` / `AppRouter` (see blueprint Section 5 and Phase 2)

Do **not** switch to Home / Record / Projects / Settings unless the blueprint is updated.

## Current focus

**Phase 1 — App foundation**

- SwiftUI macOS app with `NavigationSplitView`
- Sidebar + route-driven detail content
- Clean placeholder screens (MVVM-ready)
- Minimum window size **900×600**

## Out of scope (until later phases)

- ScreenCaptureKit / recording engine
- Live capture, export pipeline, WhisperKit integration
- Supabase auth implementation (Phase 3 in blueprint)

## After you change code

1. Explain changes step by step  
2. Suggest a Git commit message  
3. Update `CURRENT_STATUS.md` and `DEV_LOG.md` when progress is significant  

## Suggested commit prefix

- `feat:` — new user-facing behavior  
- `chore:` — docs, rules, tooling  
- `refactor:` — structure only (e.g. move files under `App/`)  
