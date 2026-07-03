# Drazlo

**Drazlo** is a native macOS screen recorder built for creators — multi-window capture, picture-in-picture camera, on-device captions, and export for YouTube, TikTok, and Shorts.

- **Download:** [drazlo.vercel.app/download](https://drazlo.vercel.app/download)
- **Website:** [drazlo.vercel.app](https://drazlo.vercel.app)
- **Privacy:** [drazlo.vercel.app/privacy/](https://drazlo.vercel.app/privacy/)
- **Terms:** [drazlo.vercel.app/terms/](https://drazlo.vercel.app/terms/)

## Requirements

- **macOS 14.0 (Sonoma)** or later
- **Apple Silicon** recommended for on-device captions and 4K export
- Signed & notarized DMG distributed via [GitHub Releases](https://github.com/JeeT001/FrameFlow/releases)

## Plans

- **Free** — up to 2 windows, 720p, microphone audio
- **Drazlo Pro** — 4 windows, PiP, captions, 9:16 vertical, system audio, 1080p/4K, no watermark (subscription)

## Build from source

1. Clone the repo and open `FrameFlow/FrameFlow.xcodeproj` in Xcode
2. Copy the config template:
   ```bash
   cp FrameFlow/FrameFlow/App/Utils/Config.example.swift \
      FrameFlow/FrameFlow/App/Utils/Config.swift
   ```
3. Add your local API keys in `Config.swift` (Supabase, RevenueCat, etc.)
4. Select the **Drazlo** scheme and build (⌘B)

### Do not commit

- `FrameFlow/FrameFlow/App/Utils/Config.swift` — local secrets (gitignored)
- `Scripts/notary.env` — Apple notarization credentials (gitignored)
- `Scripts/sparkle.env` — Sparkle EdDSA private key path (gitignored)

Use `Config.example.swift` and `Scripts/*.example` as templates only.

## Maintainers

- Release signing & notarization: [`Docs/RELEASE_SIGNING.md`](Docs/RELEASE_SIGNING.md)
- Ongoing updates & appcast: [`Docs/RELEASING_UPDATES.md`](Docs/RELEASING_UPDATES.md)
- Marketing site: [`website/README.md`](website/README.md)

## Tech stack

SwiftUI · ScreenCaptureKit · AVFoundation · WhisperKit · Supabase · RevenueCat · Sparkle 2

## License

MIT — see [LICENSE](LICENSE). Copyright © 2026 Simranjit Babbar.
