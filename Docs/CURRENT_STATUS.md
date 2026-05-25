# FrameFlow — Current Status

**Last updated:** 2026-05-25  
**Version:** v0.1.0

## Current Phase

**Phase 3 — Authentication** (blueprint-aligned, Option B)

## Currently Working On

- Ready for **Blueprint Day 6** — Login, Sign Up, and Forgot Password UI wired to `AuthService`

## Completed

- Xcode macOS SwiftUI project (macOS 14.0+ target on app)
- Git repository and Cursor docs/rules
- MVVM folder layout under `FrameFlow/FrameFlow/App/`
- `NavigationSplitView` shell: sidebar **Home, Settings, Account** (Option B)
- `AppRouter` + `AppRoute` (18 blueprint placeholder screens)
- **Blueprint Day 2:** SPM dependencies + `Config.swift` / `Config.example.swift` + `.gitignore`
- **Blueprint Day 5:** `SupabaseClientProvider` + `AuthService` (service layer only; no auth UI yet)
- Blueprint Days 3–4 (navigation shell + placeholders) — complete

## Next Task

1. **Blueprint Day 6** — Build Login, Sign Up, Forgot Password views + ViewModels calling `AuthService`
2. **Blueprint Day 7** — Session persistence + `AppState` auth guard (after Day 6)

## Important Decisions

| Topic | Decision |
|-------|----------|
| Platform | Native macOS, SwiftUI |
| Architecture | MVVM; `@Observable` for routers/state |
| Navigation | **Option B** — blueprint sidebar + `AppRoute` (unchanged until Day 7) |
| Auth | `AuthService` + `SupabaseClientProvider`; credentials from gitignored `Config.swift` |
| Secrets | `Config.example.swift` committed; `Config.swift` gitignored at repo root |
| Git | **Single repo** at project root (`/Users/simranjit/Desktop/FrameFlow`); no nested submodule |
| Capture / captions | ScreenCaptureKit / WhisperKit — later phases only |

## Code Layout

```
FrameFlow/FrameFlow/
├── FrameFlowApp.swift
├── Assets.xcassets/
└── App/
    ├── Views/          (+ Screens/)
    ├── ViewModels/
    ├── Models/
    ├── Components/
    ├── Services/       SupabaseClient.swift, AuthService.swift
    ├── Utils/          Config.swift (gitignored), Config.example.swift
    └── Resources/
```

## Reference Docs

- [Master Blueprint](FrameFlow_Master_Blueprint.md)
- [Dev Log](DEV_LOG.md)
- [Cursor Start Here](CURSOR_START_HERE.md)
