# FRAMEFLOW — Complete macOS App Blueprint
### Professional Creator Recording Tool
**Version 3.0 (Final) | May 2026**

---

## ASSUMPTIONS

- App name placeholder: **FrameFlow** — replace with your final brand name throughout
- Minimum macOS: **14.0 Sonoma** (ScreenCaptureKit stability + system audio support)
- Distribution: **Signed + notarised DMG** via your website (not App Store for MVP)
- Apple Developer account already registered ($99 USD/year)
- Payments: **RevenueCat** + **Stripe** (no Apple IAP for MVP)
- Auth: **Email + password** via Supabase Auth (Apple Sign In post-MVP)
- Backend: **Supabase** (free tier covers MVP up to 50,000 users)
- Built entirely using **Cursor AI** with the prompts provided in Section 9
- You have basic or beginner Swift/SwiftUI knowledge
- The app records a virtual composited canvas of multiple windows — not a full-screen crop
- Captions use **WhisperKit** (on-device, no API cost, works offline)
- System audio uses **ScreenCaptureKit native audio** (no virtual driver required)

---

## TABLE OF CONTENTS

1.  Executive Summary
2.  Platform & Device Support
3.  App Overview
4.  Full Feature List
5.  Full Screen Breakdown (All 19 Screens)
6.  Complete App Flow
7.  Subscription & Payments
8.  Feature Implementation Details
9.  Recommended Tech Stack
10. Data Models
11. Development Roadmap (55-Day Plan)
12. Git Workflow
13. Testing Plan
14. DMG Distribution & CI/CD
15. MVP Launch Checklist
16. Future Improvements

---

## SECTION 1 — EXECUTIVE SUMMARY

### What the App Is

FrameFlow is a native macOS application that lets content creators select specific
open application windows on their Mac — such as VS Code, Chrome, Terminal, Figma,
or Zoom — and automatically records them composited into intelligent layouts. It
produces creator-ready videos for vertical platforms (TikTok, Instagram Reels,
YouTube Shorts) or widescreen formats, with auto-zoom on clicks, cursor highlights,
system audio, PiP camera overlay, and auto-generated captions — all without any
manual editing or post-processing.

### Who It Is For

- Tech content creators recording coding tutorials and dev walkthroughs
- Indie SaaS founders making product demo videos for marketing
- Educators creating software tutorial content and online courses
- YouTubers, TikTokers, and Reels creators who record screen-based content
- Anyone on a Mac who wastes hours cropping and editing recordings for social media

### The Problem It Solves

No existing Mac screen recorder lets you select multiple app windows, composite them
live into a smart layout, auto-focus on the active window, auto-zoom on clicks,
overlay your camera, generate captions, and export directly in 9:16 vertical format
— all in one step. Creators currently record in 16:9, manually crop, resize, add
captions, and spend hours per video in editors. FrameFlow eliminates all of that.

### Positioning Statement

"Record your Mac. Post everywhere. Skip the editing."

FrameFlow is the macOS screen recorder built for creators who post short-form and
long-form content. Not for enterprises. For the developer recording a product demo.
The educator making a Shorts tutorial. The SaaS founder showing their app to customers.

### MVP Goal

Ship a working macOS app within 55 development days that allows a user to:
- Select 2–4 open application windows as recording sources
- Preview a live composite layout in 9:16 or 16:9 before recording
- Record with mic + system audio, PiP camera, cursor highlights, and auto-zoom
- Auto-generate captions via WhisperKit after recording
- Export a creator-ready video with no editing required
- Manage their account and subscription within the app

---

## SECTION 2 — PLATFORM & DEVICE SUPPORT

### Recommended Minimum: macOS 14.0 Sonoma

macOS 14 gives you:
- Stable per-window ScreenCaptureKit streams (fixed major bugs from macOS 13)
- Native system audio capture via SCStreamConfiguration.capturesAudio
- Improved AVFoundation audio mixing
- Swift 5.9 features that Cursor generates best
- Better Metal GPU compositing performance

Set in Xcode: Deployment Target → macOS 14.0

### Supported MacBook Models

| Model | Chip | Supported | Performance |
|---|---|---|---|
| MacBook Air M1 (2020) | Apple M1 | YES — Primary target | Excellent |
| MacBook Pro 13" M1 (2020) | Apple M1 | YES | Excellent |
| MacBook Pro 14"/16" M1 Pro/Max (2021) | M1 Pro/Max | YES | Outstanding |
| MacBook Air M2 (2022) | Apple M2 | YES — Primary target | Excellent |
| MacBook Pro 13" M2 (2022) | Apple M2 | YES | Excellent |
| MacBook Pro 14"/16" M2 Pro/Max (2023) | M2 Pro/Max | YES | Outstanding |
| MacBook Air M3 (2024) | Apple M3 | YES | Excellent |
| MacBook Pro M3 Pro/Max (2023) | M3 Pro/Max | YES | Outstanding |
| MacBook Air M4 (2025) | Apple M4 | YES | Excellent |
| MacBook Pro M4 Pro/Max (2025) | M4 Pro/Max | YES | Best possible |
| Intel MacBook Pro 2019–2021 | Intel Core i5/i7/i9 | LIMITED | Warn user |
| Intel MacBook Pro 2018 or older | Intel | NO | Cannot run macOS 14 |

### Market Coverage Estimate

- Apple Silicon Macs: ~72% of all active Mac users (2026)
- macOS 14 or later: ~80% of all active Mac users
- Your actual target (creators): ~85%+ are on M1 or later

### Performance Expectations

| Device | 2-Window 1080p | 4-Window 4K | 4K Export (5 min) |
|---|---|---|---|
| M1 / M2 Air | Excellent | Good | ~3 minutes |
| M1 / M2 Pro/Max | Excellent | Excellent | ~1.5 minutes |
| M3 / M4 any | Excellent | Excellent | Under 1 minute |
| Intel (2019–2021) | Good | Acceptable | ~8–10 minutes |

### Intel Mac Handling

- Show a one-time banner: "FrameFlow is optimised for Apple Silicon. Performance may
  be slower on your Mac."
- Disable 4K export on Intel (show "Not available on Intel Mac" with lock icon)
- Limit auto-zoom frame rate to 30fps on Intel vs 60fps on Apple Silicon
- Cap multi-window compositing to 2 windows on Intel (suggest 1080p max)

Cursor Prompt:
"Create a DeviceCapabilityManager class in Swift that detects Apple Silicon vs Intel
using sysctlbyname('hw.optional.arm64'). Expose: isAppleSilicon (Bool),
supports4KExport (Bool, true on Apple Silicon only), maxWindowCount (Int, 4 on
Apple Silicon, 2 on Intel), compositeFrameRate (Int, 60 on Apple Silicon, 30 on Intel).
Use this throughout the app to conditionally enable or restrict features."

Git Commit: feat: device capability detection for Apple Silicon vs Intel

---

## SECTION 3 — APP OVERVIEW

| Field | Detail |
|---|---|
| App Name (placeholder) | FrameFlow |
| Target Platform | macOS 14.0 Ventura and later |
| App Type | Native macOS desktop application (SwiftUI) |
| Distribution | Signed + notarised DMG download from your website |
| Primary Language | Swift 5.9 / SwiftUI |
| Backend | Supabase (auth + PostgreSQL + Edge Functions) |
| Payments | RevenueCat + Stripe |
| Transcription | WhisperKit (on-device, no API cost) |
| Auto-Update | Sparkle 2 |

### Core Use Cases

1. User selects 2–4 open app windows from a visual picker with live thumbnails
2. Chooses a layout preset (Stacked, Side-by-Side, PiP, or more)
3. Chooses format: 9:16 vertical or 16:9 horizontal
4. Optionally adds camera overlay (draggable PiP bubble)
5. Sets audio mode: mic only, system only, or mic + system
6. Hits Record — the app composites windows live, auto-zooms on clicks, highlights
   cursor, auto-focuses active window, and captures everything in real time
7. Pauses/resumes as needed — paused time is not in the final video
8. Stops — navigates to the **Post-Record Editor** (unified edit + captions + export)
9. User trims (basic in/out), optionally generates/edits captions (Pro), picks export quality, and exports
10. Creator-ready MP4 saved to chosen folder

### What Is Included in MVP

- Window picker with live thumbnails (2 windows free, 4 windows Pro)
- Live composite preview canvas
- Vertical 9:16 and horizontal 16:9 recording modes
- Layout presets: Stacked, Side-by-Side, PiP variants
- Auto-focus: active window highlighted during recording
- Adjustable window zoom (1x–4x, keyboard shortcuts)
- Auto zoom on cursor clicks with ripple effects
- Cursor highlight overlay (colour, size, ripple customisable)
- Microphone audio recording
- System audio capture (ScreenCaptureKit native, no driver needed)
- Combined mic + system audio mode
- Picture-in-Picture camera overlay (draggable, resizable)
- Pause and resume recording (paused time excluded from video)
- Countdown timer before recording starts (3/5/10 seconds)
- Full keyboard shortcut suite for all recording controls
- **Post-Record Editor** (Day 40.1): single screen after Stop — preview, basic trim, export settings
- Auto-generated captions via WhisperKit (Pro, Captions tab in Editor)
- 5 caption style presets + draggable caption placement (Pro)
- Caption segment text editing (Pro)
- Export: MP4 H.264 from Editor Export tab; captions burned in and optional SRT (Pro)
- Free tier: 720p, watermark, 2 windows, 16:9 only, mic audio only
- Pro tier: 4K, no watermark, 4 windows, 9:16, system audio, PiP, captions
- User account (email + password)
- Subscription management via RevenueCat/Stripe
- Dark mode support (follows system appearance)
- Settings screen with all preferences

### What Is Excluded from MVP

- Mac App Store distribution (post-MVP)
- Apple Sign In (post-MVP)
- Cloud storage of recordings (post-MVP)
- Team/multi-seat accounts (post-MVP)
- Multi-clip timeline, split/delete, ripple edit (post-MVP; basic in/out trim is Day 40.1 Phase B)
- AI auto-zoom toward cursor independent of clicks (click-zoom is included)
- Recording scheduler (post-MVP)
- Custom background images behind windows (post-MVP)

---

## SECTION 4 — FULL FEATURE LIST

### Core MVP Features by Category

**Capture**

| Feature | Description | Tier |
|---|---|---|
| Window Picker | Visual grid of open app windows with live thumbnails | Free + Pro |
| Max 2 Windows | Free tier window limit | Free |
| Max 4 Windows | Pro tier window limit | Pro |
| Live Composite Preview | Real-time canvas preview before and during recording | Free + Pro |
| Vertical 9:16 Mode | Portrait format for TikTok, Reels, Shorts | Pro only |
| Horizontal 16:9 Mode | Standard landscape recording | Free + Pro |
| Stacked Layout | Windows arranged top and bottom | Free + Pro |
| Side-by-Side Layout | Windows arranged left and right | Free + Pro |
| PiP Layouts | Camera overlay on main windows | Pro only |

**Zoom & Focus**

| Feature | Description | Tier |
|---|---|---|
| Auto-Focus Mode | Active window gets highlighted border | Pro only |
| Adjustable Zoom (basic) | Zoom 1x–2x via slider | Free |
| Adjustable Zoom (full) | Zoom 1x–4x, keyboard shortcuts, cursor-anchored | Pro |
| Auto Zoom on Click | Smooth zoom toward cursor click position | Pro only |
| Cursor Highlight | Coloured circle following cursor | Free (white only) |
| Click Ripple Effect | Expanding ring on mouse click | Pro only |
| Custom Cursor Style | Colour, size, ripple speed options | Pro only |
| Smooth Focus Transitions | Animated pan when auto-focus switches windows | Pro only |

**Audio**

| Feature | Description | Tier |
|---|---|---|
| Microphone Recording | Capture mic audio alongside screen | Free + Pro |
| System Audio Capture | Capture internal audio via ScreenCaptureKit | Pro only |
| Combined Audio | Mic + system audio mixed together | Pro only |
| Mic Volume Control | Slider 0–100% | Free + Pro |
| System Audio Volume | Slider 0–100% | Pro only |

**Camera**

| Feature | Description | Tier |
|---|---|---|
| PiP Camera Overlay | Floating webcam on top of composite | Pro only |
| Draggable PiP | Drag camera bubble to any position | Pro only |
| Resizable PiP | Resize camera bubble by corner handle | Pro only |
| PiP Layout Presets | 6 presets (corners, split, face-top) | Pro only |
| Camera Shape | Rounded rectangle, circle, or square | Pro only |
| Mirror Camera | Horizontal flip toggle | Pro only |

**Recording Controls**

| Feature | Description | Tier |
|---|---|---|
| Start / Stop | Button and keyboard shortcut (Cmd+R) | Free + Pro |
| Pause / Resume | Button and keyboard shortcut (Cmd+P) | Free + Pro |
| Countdown Timer | 3/5/10 second countdown before record starts | Free + Pro |
| Recording HUD | Timer, status, zoom level, audio level | Free + Pro |
| Global Keyboard Shortcuts | Work even when app is not focused | Free + Pro |
| Auto-hide HUD | HUD hides after 3 seconds, reappears on mouse move | Free + Pro |

**Captions**

| Feature | Description | Tier |
|---|---|---|
| Auto Captions (WhisperKit) | On-device transcription, no API cost | Pro only |
| Caption Editor | Edit per-segment text and timestamps | Pro only |
| 5 Caption Style Presets | Classic, TikTok Bold, Highlighted Word, Minimal, Custom | Pro only |
| Burn Captions to Video | Captions rendered into exported MP4 pixels | Pro only |
| SRT File Export | Export .srt subtitle file alongside video | Pro only |

**Export**

| Feature | Description | Tier |
|---|---|---|
| 720p Export | Standard definition output | Free |
| 1080p Export | Full HD output | Pro only |
| 4K Export | Ultra HD output (Apple Silicon only) | Pro only |
| Watermark | FrameFlow branding on video | Free (removed on Pro) |
| MP4 H.264 | Export format | Free + Pro |
| Choose Save Folder | Export to any folder | Free + Pro |
| Recording History | Past recording metadata and quick access | Free (5) / Pro (unlimited) |

**Account & Settings**

| Feature | Description | Tier |
|---|---|---|
| Email + Password Auth | Sign up, login, reset password | Free + Pro |
| Profile Management | Edit name, view subscription status | Free + Pro |
| All Settings | Resolution, folder, mic, auto-focus defaults | Free + Pro |
| Dark Mode | Follows system appearance | Free + Pro |
| Auto-Update (Sparkle) | In-app update notifications | Free + Pro |

### Future Features (Post-MVP)

- Mac App Store distribution
- Apple Sign In
- Cloud recording storage (Supabase Storage or S3)
- AI auto-zoom toward cursor at all times (not just clicks)
- Custom background images or gradients behind windows
- Basic clip trimmer (cut start and end)
- Recording scheduler (start/stop at set time)
- Team accounts with shared recording library
- Keyboard shortcut display overlay (show pressed keys visually in video)
- Reaction-style split layout (full face left, full screen right)
- Affiliate referral programme
- AppSumo lifetime deal spike

---

## SECTION 5 — FULL SCREEN BREAKDOWN (All 19 Screens)

---

### Screen 1: Welcome / Onboarding

**Purpose:** Greet first-time users. Explain the app in 3 steps. Drive sign up.

**UI Elements:** App logo, 3-step TabView carousel (Pick Windows → Set Layout → Record & Export),
Sign Up button, Log In link

**User Actions:** Tap Sign Up → Sign Up. Tap Log In → Login.

**Data Needed:** None. Static content.

**Navigation From:** App launch (first time only — shown once via UserDefaults isFirstLaunch flag)

**Navigation To:** Sign Up screen, Login screen

---

### Screen 2: Sign Up

**Purpose:** Create a new FrameFlow account.

**UI Elements:** Full name field, Email field, Password field, Confirm password field,
Sign Up button, "Already have an account?" link, Privacy Policy link, Terms link

**User Actions:** Fill form → Sign Up → validation → account created → Dashboard

**Data Needed:** name, email, password. Supabase Auth creates user. Row inserted in users table.

**Error States:** Email already exists | Password under 8 chars | Passwords don't match | Network error

**Navigation From:** Welcome screen, Login screen

**Navigation To:** Dashboard (success), Login screen (link)

---

### Screen 3: Login

**Purpose:** Returning users sign in.

**UI Elements:** Email field, Password field, Log In button, Forgot Password link, Sign Up link

**User Actions:** Enter credentials → Log In → Dashboard

**Error States:** Invalid credentials | Account not found | Too many attempts (rate limited)

**Navigation From:** Welcome, Sign Up, any post-logout redirect

**Navigation To:** Dashboard, Forgot Password

---

### Screen 4: Forgot Password

**Purpose:** Send a password reset link to the user's email.

**UI Elements:** Email field, Send Reset Link button, Back to Login link

**User Actions:** Enter email → Send → success message shown → user clicks link in email

**Navigation From:** Login

**Navigation To:** Login (after sent), Reset Password (via email link)

---

### Screen 5: Reset Password

**Purpose:** Set a new password after clicking the email link.

**UI Elements:** New password field, Confirm password field, Set New Password button

**Navigation From:** Email reset link

**Navigation To:** Login screen

---

### Screen 6: Dashboard / Home

**Purpose:** Main hub. See recent recordings. Start a new recording.

**UI Elements:**
- Top bar: app logo, user avatar (initials), Upgrade button (free users)
- "New Recording" large CTA button (primary action)
- Recent Recordings list: thumbnail, name, date, duration, resolution badge
- Subscription expired banner (if applicable)
- Sidebar: Home, Settings, Account

**User Actions:** New Recording → Window Picker | Tap recording → Detail | Tap avatar → Profile

**Data Needed:** userId, recordings from local recordings.json, subscription status from RevenueCat

**Empty State:** Illustration + "No recordings yet. Hit New Recording to get started."

**Navigation From:** Login, Sign Up, any screen via sidebar

**Navigation To:** Window Picker, Recording Detail, Settings, Profile

---

### Screen 7: Window Picker

**Purpose:** Select which open app windows to include in the recording.

**UI Elements:**
- Grid of all open windows: live thumbnail, app icon, app name, selection checkbox
- Selected count badge (e.g. "2 of 4 selected")
- "Next: Choose Layout" button (enabled when 1+ selected)
- Upgrade prompt banner when free user tries selecting 3rd window
- Refresh button (re-fetches open windows)

**User Actions:** Click to select/deselect. Tap Next → Layout Picker.

**Data Needed:** Open windows from ScreenCaptureKit SCShareableContent API

**Error States:** No open windows found | Screen recording permission denied (shows guide sheet)

**Navigation From:** Dashboard

**Navigation To:** Layout Picker

---

### Screen 8: Layout Picker

**Purpose:** Choose format, layout, camera, and audio mode before recording.

**UI Elements:**
- Format toggle: 9:16 Vertical / 16:9 Horizontal (Pro gate on vertical)
- Layout preset cards with diagram icons:
  - Stacked (top/bottom)
  - Side-by-Side (left/right)
  - PiP Bottom-Right (Pro)
  - PiP Face-Top 9:16 (Pro)
  - PiP Face-Left (Pro)
- Live preview canvas showing selected windows in chosen layout
- Camera toggle: "Add Camera Overlay" (Pro) — opens camera source picker
- Audio mode row: tap to open Audio Mode Picker sheet
- Auto-Focus toggle
- Cursor Highlight toggle
- Countdown timer picker (Off / 3s / 5s / 10s)
- "Start Recording" button

**Data Needed:** Selected windows, subscription status, available cameras, audio devices

**Pro Gates:** Vertical mode | PiP layouts | Camera overlay | System audio

**Navigation From:** Window Picker

**Navigation To:** Countdown Overlay → Recording Screen

---

### Screen 9: Audio Mode Picker (Sheet)

**Purpose:** Choose how audio is captured before recording starts.

**UI Elements:**
- 4 selectable option cards with SF Symbol icons:
  - Microphone Only
  - System Audio Only
  - Microphone + System Audio (default)
  - No Audio
- Microphone volume slider (0–100%) — visible when mic selected
- System audio volume slider (0–100%) — visible when system selected (Pro)
- Live audio level bar: animated bars showing mic input level
- Microphone device picker (lists available input devices)
- Confirm button

**Data Needed:** Available audio input devices from AVFoundation, subscription status

**Pro Gates:** System audio options require Pro subscription

**Navigation From:** Layout Picker (tapping audio mode row)

**Navigation To:** Back to Layout Picker

---

### Screen 10: Recording Screen

**Purpose:** Active recording view with live composite and controls.

**UI Elements:**
- Live composite canvas (full window, all selected windows composited with chosen layout)
- Camera PiP overlay (draggable during recording setup, fixed during record)
- Auto-focus window highlight (glowing border on active window)
- Cursor highlight circle (follows cursor, ripple on click)
- Recording HUD (auto-hides after 3 seconds):
  - Left: REC/PAUSED dot + timer (MM:SS:ms)
  - Centre: zoom level indicator ("1.5x"), audio mode icon
  - Right: Pause/Resume button, Stop button, Quick Settings popover
- Countdown overlay (3-2-1 animated full screen before recording starts)

**User Actions:**
- Drag camera bubble to reposition PiP (before recording starts)
- Cmd+R: Stop recording
- Cmd+P: Pause / Resume
- Cmd+= / Cmd+-: Zoom in / out
- Cmd+0: Reset zoom
- Cmd+F: Toggle auto-focus
- Cmd+H: Toggle cursor highlight
- Cmd+K: Toggle camera overlay
- Tap Stop button → Export/Caption screen

**Data Needed:** Live SCStream frames, mic/system audio via AVAudioEngine, PiP camera frames

**Error States:**
- Source window closed mid-recording → grey placeholder, recording continues
- Camera disconnected → placeholder gradient, recording continues
- Mic permission denied → silent audio track, recording continues

**Navigation From:** Layout Picker (after countdown)

**Navigation To:** Post-Record Editor (all users)

---

### Screen 11: Post-Record Editor (Day 40.1)

**Purpose:** Unified post-recording workspace — preview, basic edits, captions (Pro), and export.
Replaces the separate Caption Editor → Export hop for new recordings.

**Layout:**
- **Top:** Discard (staging) | recording name | **Export** (primary action)
- **Center-left (~55%):** Video preview with play/scrub; caption overlay when Pro + captions enabled
- **Center-right (~45%):** Inspector with segmented tabs: **Edit** | **Captions*** | **Export**
  (*Captions tab hidden for Free — show Pro upgrade CTA instead)
- **Bottom:** Simple timeline strip with trim in/out handles (Phase B); duration readout

**Edit tab (Free + Pro):**
- Play / pause, scrubber
- Trim start/end (Phase B — `AVMutableComposition` or export-time range)
- Phase C+: draggable caption safe-area on preview (Pro)

**Captions tab (Pro only):**
- "Generate captions" button (WhisperKit; progress inline — no full-screen blocker)
- 5 style preset cards (reuse `CaptionStyleCard`)
- Position: Top / Middle / Bottom (+ drag on preview in Phase C)
- Scrollable segment list: edit text (times read-only v1; editable v2)
- Saves segments + style to sidecar via `CaptionEngine.saveCaptions` — **no burn-in here**

**Export tab (Free + Pro):**
- Duration + source file size labels
- Resolution: **720p only (Free)** | 720p / 1080p / 4K (Pro; 4K Apple Silicon only)
- Pro: toggle "Include captions in export"; optional "Also save SRT file"
- Free: watermark notice
- Export progress bar (delegates to `ExportService`)

**Toolbar actions:**
- **Discard** → delete staging, Dashboard
- **Export** → persist caption edits if any, run `ExportService`, success → Dashboard / Reveal in Finder

**User Actions:**
- Trim clip (Phase B)
- Generate / edit captions (Pro)
- Choose resolution and export
- Discard without saving

**Data Needed:** Staged recording (`pendingRecording`), caption sidecar, subscription status

**Navigation From:** Recording Screen (all users on Stop)

**Navigation To:** Dashboard (after export or discard)

**Implementation notes:**
- New route: `AppRoute.editor` (or repurpose `captionEditor` → `EditorView`)
- Reuse: `CaptionEditorViewModel` (captions), `ExportViewModel` / `ExportService` (export)
- Deprecate post-record navigation to standalone `ExportView`; keep `ExportView` for Dashboard re-export shortcut

---

### Screen 11 (legacy): Caption Editor — superseded by Editor Captions tab

> **Day 40.1:** `CaptionEditorView` logic moves into Editor **Captions** tab. Remove duplicate
> export format picker and in-editor burn-in export. Screen retained temporarily for migration.

---

### Screen 12: Export / Preview Screen — re-export path

**Purpose:** Quick re-export from Dashboard / Recording Detail (existing saved recordings).
For **new recordings**, export lives in Editor **Export** tab (Day 40.1).

**UI Elements:** (unchanged from Day 26)
- Video player, duration/file size, resolution picker, captions toggle (Pro), Export, Discard

**Navigation From:** Dashboard re-export, Recording Detail

**Navigation To:** Dashboard (after export or discard)

---

### Screen 13: Recording Detail

**Purpose:** View and manage a past recording from the Dashboard list.

**UI Elements:** Video thumbnail, file name (editable), date recorded, duration, file size,
resolution badge, Play button (opens in system player), Re-export button, Delete button

**User Actions:** Play | Rename | Re-export at different resolution | Delete

**Data Needed:** Local recording metadata from recordings.json

**Navigation From:** Dashboard (tap any recent recording)

**Navigation To:** Dashboard (back)

---

### Screen 14: Profile / Account

**Purpose:** Manage account details and subscription.

**UI Elements:**
- Avatar (initials circle)
- Display name (editable inline)
- Email (read-only)
- Subscription badge: Free / Pro + renewal date
- Plan details: price, next billing date
- Manage Subscription button (opens RevenueCat/Stripe portal)
- Change Password button (triggers email reset)
- Delete Account button (confirmation alert first)
- Log Out button

**User Actions:** Edit name → saved to Supabase | Manage Sub → portal | Log Out → Login

**Navigation From:** Dashboard avatar, Settings

**Navigation To:** Login (logout), Subscription Screen

---

### Screen 15: Settings

**Purpose:** Configure app preferences.

**UI Elements:**
- Default export resolution (720p / 1080p / 4K)
- Default save folder (NSOpenPanel browse button)
- Default audio mode picker
- Microphone device picker (from AVFoundation)
- Auto-focus default toggle
- Cursor highlight default toggle
- Auto zoom on click toggle
- Zoom hold duration picker (0.5s / 1.0s / 1.5s / 2.0s)
- Cursor highlight colour picker (White / Yellow / Red)
- Recording countdown default (Off / 3s / 5s / 10s)
- Caption style default picker
- Caption transcription engine picker (WhisperKit / OpenAI API)
- OpenAI API key field (if cloud selected)
- Recording complete notification toggle
- Screen recording permission status + Open System Settings button
- Camera permission status + Open System Settings button
- Dark mode override (System / Always Light / Always Dark)
- App version label
- Check for Updates button

**User Actions:** Every change saved to UserDefaults immediately

**Navigation From:** Dashboard sidebar, Profile

**Navigation To:** System Settings (permission buttons only)

---

### Screen 16: Subscription / Pricing

**Purpose:** Show Free vs Pro comparison and allow subscribing.

**UI Elements:**
- Free vs Pro feature comparison table
- Annual plan card: $9/mo billed $108/yr (7-day free trial)
- Monthly plan card: $19/mo (7-day free trial)
- Lifetime card: $79 one-time (launch period only — hidden after 60 days)
- "Start Free Trial" button (becomes "Upgrade" after trial)
- "Restore Purchase" link
- Close button

**User Actions:** Select plan → Payment flow | Restore → re-link existing subscription

**Navigation From:** Any Pro gate, Profile, Dashboard upgrade button

**Navigation To:** Payment/Checkout flow, Dashboard (success)

---

### Screen 17: Payment / Checkout

**Purpose:** Handle subscription payment.

**UI Elements:** RevenueCat/Stripe payment sheet (modal), order summary, card fields, Pay button

**Error States:** Card declined | Network error | 3D Secure challenge

**Navigation From:** Subscription screen

**Navigation To:** Dashboard (success) | Subscription screen (failure)

---

### Screen 18: Help / Support

**Purpose:** Basic support resources.

**UI Elements:**
- FAQ DisclosureGroup list (8–10 questions)
- Email Support button (pre-filled system mail composer)
- Privacy Policy link (opens in browser)
- Terms of Service link (opens in browser)
- App version

**Navigation From:** Settings, Profile

---

### Screen 19: Empty States & Error States

| State | Screen | Message + Action |
|---|---|---|
| No recordings | Dashboard | "No recordings yet. Hit New Recording to get started." + button |
| No open windows | Window Picker | "No open app windows found. Open an app first." + Refresh |
| Permission denied (screen) | Window Picker | "Screen recording permission required." + Open Settings |
| Permission denied (camera) | Layout Picker | "Camera permission required for PiP." + Open Settings |
| Network error | Login/Sign Up | "No internet connection. Please check and try again." |
| Payment failed | Checkout | "Payment could not be processed. Check your card details." |
| Subscription expired | Any Pro feature | "Your Pro plan has ended. Renew to restore access." + Renew |
| Window closed mid-recording | Recording | Grey panel with "Window closed" label |
| Camera disconnected | Recording | Blurred gradient in PiP with camera icon |
| Export failed | Export | "Export failed. Check available disk space." |
| Intel Mac + 4K | Export | "4K is not available on Intel Macs. Choose 1080p." |
| Caption generation failed | Caption Editor | "Captions could not be generated. You can skip or try again." |

---

## SECTION 6 — COMPLETE APP FLOW

### Flow 1: First-Time User (Free Tier)

1. App launches → Welcome / Onboarding screen (3-step carousel)
2. Tap Sign Up → fill form → account created
3. Email verification → user clicks link → Dashboard (empty state)
4. Tap New Recording → macOS prompts for screen recording permission
5. Grant permission → Window Picker screen
6. Select up to 2 windows → Layout Picker
7. Choose 16:9 (vertical is locked) → Audio Mode: Mic Only → Start Recording
8. 3-second countdown → recording starts
9. Record → Tap Stop → **Post-Record Editor** (Edit + Export tabs; no captions — free tier)
10. Export tab: 720p (watermarked) → saved to Desktop
11. Dashboard: recording appears in list

### Flow 2: Pro User (First Recording)

1. App launches → Dashboard
2. Tap New Recording → Window Picker → select up to 4 windows
3. Layout Picker → toggle 9:16 vertical → choose PiP Face-Top layout
4. Enable Camera Overlay (selects front camera)
5. Audio mode: Microphone + System Audio
6. Auto-Focus ON, Cursor Highlight ON, Auto Zoom on Click ON
7. Countdown 3s → Recording starts
8. Record — auto-zooms on clicks, highlights cursor, PiP camera visible
9. Cmd+P to pause → Cmd+P to resume → Cmd+R to stop
10. **Post-Record Editor:** Captions tab → WhisperKit generates captions → pick TikTok Bold style → Export tab → Export at 4K, no watermark → saved to ~/Movies/FrameFlow

### Flow 3: Free User Hitting a Pro Gate

1. Free user selects 9:16 vertical in Layout Picker
2. App shows upgrade sheet: "Vertical export is a Pro feature"
3. User taps Upgrade → Subscription/Pricing screen
4. Selects Annual plan → 7-day free trial → payment info entered
5. Trial activated → vertical mode unlocked
6. User continues recording in 9:16

### Flow 4: Subscription Expired

1. RevenueCat detects failed renewal → webhook fires → Supabase updated to "past_due"
2. On next app launch: banner shows "Your Pro plan has ended. Renew to restore access."
3. Pro features show lock icons
4. Existing recordings still accessible
5. 3-day grace period — if payment updated in Stripe portal, sub auto-resumes
6. After grace period: full downgrade to free tier

### Flow 5: Settings / Account Management

1. User opens Settings → changes default save folder, audio mode, caption style
2. All saved instantly to UserDefaults
3. User opens Profile → taps Manage Subscription → RevenueCat/Stripe portal in browser
4. User taps Change Password → email reset triggered
5. User taps Log Out → session cleared, RevenueCat logged out, back to Login

---

## SECTION 7 — SUBSCRIPTION & PAYMENTS

### Pricing Model

| Plan | Price | Billing | Trial |
|---|---|---|---|
| Free | $0 | Forever | No trial needed |
| Pro Annual | $9/mo | $108/year | 7-day free trial |
| Pro Monthly | $19/mo | Monthly | 7-day free trial |
| Lifetime (launch only) | $79 | One-time | None |

Remove lifetime offer after 60 days from launch. Switch everyone to subscription only.

### Free vs Pro Feature Comparison

| Feature | Free | Pro |
|---|---|---|
| Max source windows | 2 | 4 |
| Export resolution | 720p | 720p / 1080p / 4K |
| Watermark | Yes | No |
| Vertical 9:16 export | No | Yes |
| System audio capture | No | Yes |
| Combined audio | No | Yes |
| Auto-Focus | No | Yes |
| Adjustable zoom | 1x–2x | 1x–4x |
| Auto zoom on click | No | Yes |
| Cursor ripple effects | Basic | Full custom |
| PiP camera overlay | No | Yes |
| Auto captions (WhisperKit) | No | Yes |
| Caption style presets | No | All 5 |
| SRT file export | No | Yes |
| Recording history | Last 5 | Unlimited |
| Layout presets | Stacked, Side-by-Side | All presets incl. PiP |

### Payment Providers

| Provider | Role | Notes |
|---|---|---|
| RevenueCat | Subscription management SDK | Free up to $2,500 MRR. Handles trials, webhooks, analytics. |
| Stripe | Card payment processing | 2.9% + 30¢ per transaction. Connected via RevenueCat. |
| Apple IAP | Post-MVP (if App Store) | Required for Mac App Store. Apple takes 15–30%. |

### Subscription Status Checking

1. On app launch: Purchases.shared.getCustomerInfo() called
2. RevenueCat returns entitlement status
3. SubscriptionManager ObservableObject stores isPro (Bool)
4. All Pro-gated views check isPro before allowing access
5. RevenueCat webhook → Supabase Edge Function → subscriptions table updated
6. App re-fetches status on Profile/Subscription screen open

### Payment Failure Handling

- RevenueCat webhook fires with BILLING_ISSUE event
- Supabase subscription row updated to status: "past_due"
- App shows non-blocking banner on Dashboard
- Pro features locked after 3-day grace period
- User updates card in Stripe portal → subscription resumes automatically

---

## SECTION 8 — FEATURE IMPLEMENTATION DETAILS

This section provides the deep technical approach for each complex feature.

---

### 8A — Window Zoom (Adjustable + Auto on Click)

**Adjustable Zoom:**
- ZoomController stores zoomLevel (CGFloat 1.0–4.0) per window
- On zoom change: apply CIAffineTransform to each window's CIImage frame before compositing
- Transform: scale(zoomLevel) with translation to anchor at cursor position
- Animate between levels using CADisplayLink for frame-accurate interpolation
- Keyboard: Cmd+= adds 0.25x, Cmd+- subtracts 0.25x, Cmd+0 resets to 1.0x
- UI: horizontal slider in Layout Picker + zoom level label in Recording HUD

**Auto Zoom on Click:**
- NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) detects all clicks
- Convert global click position to position within that window's capture frame
- Trigger: animate zoom from current to (current + 0.75x extra) over 0.25s
- Hold at peak zoom for 1.0s (configurable: 0.5s/1.0s/1.5s/2.0s in Settings)
- Animate back over 0.35s using spring easing
- All zoom transforms applied to CIImage before AVAssetWriter — burned into video

**Cursor Highlight + Click Ripple:**
- Draw a filled circle (default 32pt, white, 60% opacity) following cursor position
- On click: animate an expanding ring (24pt → 96pt over 0.5s, fading to 0 opacity)
- Rendered as a CIImage overlay composited on top of all windows before encoding
- Burned into the final video — not just shown in preview

Files: ZoomController.swift, CursorTracker.swift, ClickEffectRenderer.swift

Cursor Prompt:
"Build a ZoomController class in Swift for a macOS screen recorder that:
1. Stores zoomLevel (CGFloat 1.0–4.0) and cursorPosition (CGPoint) as Published properties
2. Has zoomIn(), zoomOut(), resetZoom() methods changing level by 0.25
3. Uses CADisplayLink to animate zoom changes at 60fps with spring interpolation
4. Applies the zoom as a CIAffineTransform to a CIImage, anchored to cursorPosition
5. Also build a CursorTracker that uses NSEvent.addGlobalMonitorForEvents for .mouseMoved
   and .leftMouseDown. On move: updates cursorPosition. On click: triggers auto-zoom
   sequence (zoom up 0.75x over 0.25s, hold 1.0s, zoom back over 0.35s)
6. On click, also generates a ripple CIImage overlay: expanding ring from 24pt to 96pt
   over 0.5s, composited on top of the window frames before AVAssetWriter encoding"

Git Commit: feat: adjustable zoom and auto click zoom with ripple cursor effects

---

### 8B — System Audio Capture

**Approach:** ScreenCaptureKit native audio (macOS 14+). No virtual driver required.

**Implementation:**
- In SCStreamConfiguration for each SCStream: set capturesAudio = true,
  excludesCurrentProcessAudio = true, sampleRate = 48000, channelCount = 2
- Receive audio CMSampleBuffers in the same SCStreamOutput delegate alongside video
- Create an AVAudioEngine graph:
  - Node A: AVAudioInputNode (microphone)
  - Node B: AVAudioSourceNode receiving system audio buffers from SCStream
  - AVAudioMixerNode: combines both with configurable volume per source
  - Output: AVAssetWriterInput (audio track in the recorded video)
- AudioMode enum: micOnly / systemOnly / combined / none
- When mode is micOnly: only Node A active, Node B silent
- When mode is systemOnly: Node A muted, Node B active
- When mode is combined: both nodes active, mixed in AVAudioMixerNode

Files: AudioCaptureService.swift, AudioMixerEngine.swift

Cursor Prompt:
"Build an AudioCaptureService for a macOS screen recorder that captures and mixes audio.
It should: 1) Capture microphone audio using AVAudioEngine inputNode, 2) Receive system
audio CMSampleBuffers from ScreenCaptureKit SCStream (capturesAudio=true), 3) Convert
system audio CMSampleBuffers to AVAudioPCMBuffer, 4) Mix both using AVAudioMixerNode
with separate volume controls, 5) Support AudioMode enum: micOnly, systemOnly, combined,
none, 6) Output mixed audio to AVAssetWriterInput, 7) Expose audioLevel Published Float
(0.0–1.0) for the HUD level indicator. Include start() and stop() async methods."

Git Commit: feat: system audio capture with mic mixing via ScreenCaptureKit

---

### 8C — Picture-in-Picture Camera

**Implementation:**
- AVCaptureSession with AVCaptureDeviceInput from front camera
- AVCaptureVideoDataOutput provides frames as CMSampleBuffer
- Convert each frame to CIImage
- Apply PiPConfig: position (CGPoint 0–1), size (CGSize 0–1), shape (roundedRect/circle)
- Composite camera CIImage on top of window composite using CISourceOverCompositing
- PiPConfig stored as ObservableObject, updated when user drags/resizes the overlay
- Drag: SwiftUI DragGesture on the PiP overlay updates position in PiPConfig
- Resize: corner handle DragGesture updates size in PiPConfig
- Snap to corners when within 20pt of canvas edge

**PiP Layout Presets:**

| Preset | Description | Best Format |
|---|---|---|
| Bottom-Right | Camera 25% width, bottom-right | 16:9 and 9:16 |
| Bottom-Left | Camera 25% width, bottom-left | 16:9 and 9:16 |
| Top-Right | Camera 25% width, top-right | 16:9 |
| Face-Top (9:16) | Camera takes top 35%, screen bottom 65% | 9:16 only |
| Face-Left | Camera takes left 30%, screen right 70% | 16:9 |
| No Camera | PiP disabled | Any |

Files: CameraCapture.swift, PiPController.swift, PiPOverlayView.swift

Cursor Prompt:
"Build a CameraCapture class for a macOS screen recorder using AVCaptureSession.
It should: 1) Use AVCaptureDeviceInput for the front camera, 2) Output frames via
AVCaptureVideoDataOutput as CMSampleBuffers, 3) Convert each frame to CIImage,
4) Composite the camera CIImage on top of the window composite using CISourceOverCompositing
according to a PiPConfig struct (position: CGPoint 0–1, size: CGFloat 0–1,
shape: roundedRect or circle, borderColor: CIColor, borderWidth: CGFloat),
5) Support 6 preset configurations as static PiPConfig values.
Also build a PiPOverlayView in SwiftUI that shows a draggable resizable camera preview
in the Layout Picker with corner resize handles, snapping to canvas edges within 20pt."

Git Commit: feat: PiP camera overlay with drag, resize, and layout presets

---

### 8D — Pause / Resume Recording

**Implementation (timestamp offset approach):**
- AVFoundation's AVAssetWriter does not natively support pause
- When pauseRecording() called: set isPaused = true, record pauseStartTime = CMClockGetTime
- Continue receiving SCStream frames but do NOT append to AVAssetWriterInput while paused
- When resumeRecording() called: calculate pauseDuration = CMClockGetTime - pauseStartTime
- Add pauseDuration to a running totalPausedDuration offset
- For every subsequent CMSampleBuffer: subtract totalPausedDuration from presentation
  timestamp before appending to AVAssetWriterInput
- Result: final video has zero gap — paused period is simply not in the file

Files: RecordingEngine.swift (add pauseRecording(), resumeRecording(), isPaused, totalPausedDuration)

Cursor Prompt:
"Add pause and resume to a Swift AVAssetWriter-based screen recorder. When pauseRecording()
is called: set isPaused=true and store pauseStartTime using CMClockGetTime(CMClockGetHostTimeClock()).
Stop appending samples while paused. When resumeRecording() called: calculate
pauseDuration = CMClockGetTime - pauseStartTime, add to totalPausedDuration (CMTime).
For every CMSampleBuffer appended to AVAssetWriterInput: subtract totalPausedDuration
from the presentation timestamp using CMTimeSubtract before calling append().
Expose isPaused as Published Bool and formattedElapsedTime as Published String."

Git Commit: feat: pause and resume recording with timestamp offset compensation

---

### 8E — Auto Captions (WhisperKit)

**Implementation:**
- After recording stops, extract audio track from recording file using AVAssetReader
- Pass audio file to WhisperKit for transcription
- WhisperKit returns word-level timestamps as [WordTiming] array
- Convert to CaptionSegment array: { id, text, startTime, endTime }
- Display in Caption Editor screen for review and editing
- On export: use AVVideoComposition + AVMutableVideoCompositionInstruction to overlay
  caption text on each frame using CATextLayer positioned per style config
- CATextLayer font, size, position, background configured by CaptionStyleConfig

**Caption Styles:**

| Style | Appearance | Best For |
|---|---|---|
| Classic | White bold text, semi-transparent black bar bottom | YouTube tutorials |
| TikTok Bold | Large yellow/white words, one at a time, centre frame | TikTok, Reels |
| Highlighted Word | Full sentence shown, current word highlighted | Educational |
| Minimal | Small white text, bottom, no background | Professional demos |
| Custom | User picks font, size, colour, position, background | Any |

Files: CaptionEngine.swift, TranscriptionService.swift, CaptionStyleConfig.swift,
CaptionEditorView.swift, CaptionRenderer.swift

WhisperKit SPM: github.com/argmaxinc/WhisperKit

Cursor Prompt:
"Build a CaptionEngine for a macOS screen recorder using WhisperKit Swift package.
It should: 1) Accept a local audio file URL extracted from the MP4 using AVAssetReader,
2) Run WhisperKit transcription with word-level timestamps and return [CaptionSegment]
(id: UUID, text: String, startTime: Double, endTime: Double), 3) Build a CaptionRenderer
that takes [CaptionSegment] and CaptionStyleConfig and burns captions into the video
using AVMutableVideoComposition with CATextLayer — each segment renders as text on the
correct frames based on timestamps, 4) Support 3 built-in styles: Classic (white bold
text on black bar, bottom), TikTokBold (large centred word-by-word), Minimal (small
white text bottom no background), 5) Also write an SRT file from the segments array."

Git Commit: feat: WhisperKit captions with 5 style presets and video burn-in

---

### 8F — Recording HUD and Keyboard Shortcuts

**HUD Layout:**
- Left: coloured dot (red = recording, yellow = paused) + timer (MM:SS)
- Centre: zoom level ("1.5x") + audio mode icon (mic/speaker/both)
- Right: Pause/Resume button + Stop button + Quick Settings popover
- Auto-hides after 3 seconds of no mouse movement
- Always uses dark background (rgba 0,0,0,0.65) — readable on any content

**Global Keyboard Shortcuts:**

| Action | Shortcut |
|---|---|
| Start / Stop Recording | Cmd + R |
| Pause / Resume | Cmd + P |
| Zoom In | Cmd + = |
| Zoom Out | Cmd + - |
| Reset Zoom | Cmd + 0 |
| Toggle Auto-Focus | Cmd + F |
| Toggle Cursor Highlight | Cmd + H |
| Toggle Camera (PiP) | Cmd + K |
| Discard Recording | Cmd + Escape |
| Export | Cmd + E |

Cursor Prompt:
"Create a KeyboardShortcutManager class for a macOS SwiftUI app that registers global
keyboard shortcuts using NSEvent.addGlobalMonitorForEvents(matching: .keyDown). Register:
Cmd+R (toggle start/stop recording), Cmd+P (toggle pause/resume), Cmd+= (zoom in 0.25x),
Cmd+- (zoom out 0.25x), Cmd+0 (reset zoom), Cmd+F (toggle auto-focus), Cmd+H (toggle
cursor highlight), Cmd+K (toggle PiP camera). Each shortcut calls the appropriate method
on RecordingEngine, ZoomController, or CursorTracker. Add removeMonitor cleanup in deinit."

Git Commit: feat: global keyboard shortcuts for all recording controls

---

## SECTION 9 — RECOMMENDED TECH STACK

| Layer | Technology | Why |
|---|---|---|
| App Framework | SwiftUI | Native macOS, required for ScreenCaptureKit + AVFoundation access |
| Window Capture | ScreenCaptureKit | Official Apple API, hardware-accelerated, privacy-safe, per-window |
| Video Compositing | AVFoundation + CIImage/Metal | Frame-accurate compositing at 60fps |
| System Audio | ScreenCaptureKit (capturesAudio) | Native, no virtual driver, works on macOS 14+ |
| Audio Mixing | AVAudioEngine | Flexible multi-source audio graph, mix mic + system |
| Zoom + Effects | CIAffineTransform + CADisplayLink | Frame-accurate smooth zoom tied to recording rate |
| Camera (PiP) | AVCaptureSession | Standard macOS webcam capture |
| Captions | WhisperKit (SPM: argmaxinc/WhisperKit) | On-device, offline, no API cost, accurate |
| Subtitle Burn-in | AVMutableVideoComposition + CATextLayer | Frame-accurate caption rendering |
| Backend | Supabase | Auth + PostgreSQL + Edge Functions. Free tier generous for MVP |
| Database | Supabase PostgreSQL | Hosted, Row Level Security built in |
| Auth | Supabase Auth | Email/password, reset, session management |
| Subscriptions | RevenueCat (SPM: RevenueCat/purchases-ios) | Best macOS subscription management, free to $2,500 MRR |
| Payments | Stripe via RevenueCat | Card processing, no direct integration needed |
| Local Storage | UserDefaults | App settings and preferences |
| Recording Metadata | Local recordings.json | Index of all recordings with metadata, stored on disk |
| Colour System | Asset Catalog Color Sets | Automatic dark/light mode colour switching |
| Auto-Update | Sparkle 2 (SPM: sparkle-project/Sparkle) | Standard direct-distribution Mac update mechanism |
| CI/CD | GitHub Actions (macos-15 runner) | Automated build, sign, notarise, DMG, release |
| Analytics | PostHog | Feature usage tracking, free tier, privacy-respecting |
| Error Tracking | Sentry (SPM: getsentry/sentry-cocoa) | Crash reporting in production, free tier |
| Version Control | Git + GitHub (private repo) | Standard |
| Global Shortcuts | NSEvent.addGlobalMonitorForEvents | Works even when app is not focused |

---

## SECTION 10 — DATA MODELS

### User (Supabase Table)

| Field | Type | Description |
|---|---|---|
| id | UUID PK | Auto-generated by Supabase Auth |
| email | String | Unique. Set at sign up. |
| display_name | String? | Editable from Profile screen |
| created_at | Timestamp | Account creation date |
| updated_at | Timestamp | Last profile update |

### Subscription (Supabase Table)

| Field | Type | Description |
|---|---|---|
| id | UUID PK | Auto-generated |
| user_id | UUID FK → users.id | Owner |
| plan | String | 'free' / 'pro_monthly' / 'pro_annual' / 'lifetime' |
| status | String | 'active' / 'trialing' / 'past_due' / 'cancelled' / 'expired' |
| revenuecat_id | String? | RevenueCat customer ID |
| stripe_customer_id | String? | Stripe customer ID |
| current_period_end | Timestamp? | Next billing date |
| trial_end | Timestamp? | Trial expiry (null if not trialing) |
| created_at | Timestamp | When subscription was created |
| updated_at | Timestamp | Last update (set by webhook) |

### Recording (Local — recordings.json on disk)

| Field | Type | Description |
|---|---|---|
| id | UUID | Locally generated |
| name | String | User-editable (default: date-time stamp) |
| file_path | String | Absolute path to .mp4 file |
| duration_seconds | Int | Length in seconds |
| resolution | String | e.g. "1920x1080", "1080x1920" |
| format | String | "9:16" or "16:9" |
| layout | String | "stacked" / "side_by_side" / "pip_bottom_right" / etc. |
| window_count | Int | Number of source windows |
| has_captions | Bool | Whether captions were burned in |
| has_camera | Bool | Whether PiP camera was used |
| audio_mode | String | "mic" / "system" / "combined" / "none" |
| created_at | Date | Recording date/time |
| file_size_bytes | Int | Exported file size |

### CaptionSegment (In-memory + saved as .srt)

| Field | Type | Description |
|---|---|---|
| id | UUID | Auto-generated |
| recording_id | UUID | Links to the recording |
| text | String | Transcribed text (user-editable) |
| start_time | Double | Seconds from video start |
| end_time | Double | Seconds from video start |
| sequence | Int | Order in SRT file (1-indexed) |

### Settings (UserDefaults — local only)

| Key | Type | Default | Description |
|---|---|---|---|
| defaultResolution | String | "1080p" | Default export resolution |
| defaultSaveFolder | String | "~/Desktop" | Where recordings are saved |
| defaultAudioMode | String | "combined" | "mic" / "system" / "combined" / "none" |
| defaultMicDevice | String? | nil | System default mic |
| defaultMicVolume | Float | 1.0 | 0.0–1.0 |
| defaultSystemVolume | Float | 0.8 | 0.0–1.0 |
| autoFocusEnabled | Bool | true | Auto-focus on by default |
| cursorHighlightEnabled | Bool | true | Cursor highlight on by default |
| autoZoomOnClick | Bool | true | Auto zoom on click by default |
| zoomStrength | Float | 0.75 | Extra zoom amount on click |
| zoomHoldDuration | Double | 1.0 | Seconds to hold zoom |
| cursorHighlightColor | String | "white" | "white" / "yellow" / "red" |
| countdownDuration | Int | 3 | Seconds before recording starts |
| captionStyle | String | "classic" | Default caption style |
| notificationsEnabled | Bool | true | Export complete notification |
| isFirstLaunch | Bool | true | Show onboarding only once |

### AppState (In-Memory ObservableObject)

| Property | Type | Description |
|---|---|---|
| currentUser | User? | Logged-in user object |
| subscription | Subscription? | Current subscription record |
| isPro | Bool (computed) | True if subscription active/trialing and not free |
| isRecording | Bool | True while recording active |
| isPaused | Bool | True while recording paused |
| selectedWindows | [SCWindow] | Windows selected in picker |
| currentLayout | LayoutConfig | Active layout settings |
| pipConfig | PiPConfig | PiP position, size, shape |
| audioMode | AudioMode | Current audio mode selection |
| zoomLevel | CGFloat | Current zoom level |
| isAppleSilicon | Bool | From DeviceCapabilityManager |

---

## SECTION 11 — DEVELOPMENT ROADMAP (55-Day Plan)

> Each day assumes 3–5 hours of focused development.
> Use Cursor with the prompts provided. Commit to Git every day.

---

### PHASE 1: Project Setup (Days 1–2)

---

**DAY 1 — Xcode Project + GitHub**

Goal: Create the Xcode project, configure entitlements, set up GitHub.

Steps:
1. Xcode → New Project → macOS App → SwiftUI → Name: FrameFlow
2. Deployment Target: macOS 14.0
3. Add entitlements:
   - com.apple.security.screen-recording-capture
   - com.apple.security.device.camera
   - com.apple.security.device.audio-input
4. Create private GitHub repo, push first commit

Files: FrameFlow.xcodeproj, FrameFlow.entitlements, Info.plist, README.md, .gitignore

Cursor Prompt:
"Create a SwiftUI macOS app project structure called FrameFlow with a NavigationSplitView
layout — sidebar on the left (Home, Settings, Account) and main content on the right.
Include the @main App entry point. Set the window minimum size to 900x600."

Git Commit: feat: initialise FrameFlow SwiftUI macOS project

---

**DAY 2 — Folder Structure + All Dependencies**

Goal: Create project folders and add all Swift Package Manager dependencies.

Folders: Views/, Models/, ViewModels/, Services/, Utils/, Resources/

Add via File → Add Package Dependencies:
- github.com/supabase/supabase-swift (Supabase)
- github.com/RevenueCat/purchases-ios (RevenueCat)
- github.com/argmaxinc/WhisperKit (Captions)
- github.com/sparkle-project/Sparkle (Auto-update)
- github.com/getsentry/sentry-cocoa (Error tracking)

Also create: Config.swift (add to .gitignore IMMEDIATELY — contains all API keys)

Cursor Prompt:
"Create a Config.swift file in a SwiftUI macOS app that holds static constants:
supabaseURL, supabaseAnonKey, revenueCatAPIKey, sentryDSN, postHogAPIKey.
All values are empty strings as placeholders. Add a comment at the top: DO NOT COMMIT.
Create a .gitignore that includes Config.swift, .DS_Store, xcuserdata/, and build/."

Git Commit: chore: add folder structure, all SPM dependencies, and Config.swift

---

### PHASE 2: App Structure and Navigation (Days 3–4)

---

**DAY 3 — Navigation Shell and App Router**

Goal: Build the core navigation system the whole app will use.

Files: AppRouter.swift, MainAppView.swift, SidebarView.swift

Cursor Prompt:
"Build a SwiftUI macOS app navigation system with NavigationSplitView. The sidebar shows
items for Home, Settings, and Account with SF Symbol icons. AppRouter is an ObservableObject
with a currentRoute: AppRoute enum (cases: dashboard, windowPicker, layoutPicker,
audioMode, recording, editor, captionEditor, export, profile, settings, subscription, help,
onboarding, login, signUp). Note: `editor` added Day 40.1; `captionEditor` legacy until migration.
Inject AppRouter as @EnvironmentObject."

Git Commit: feat: navigation shell with sidebar and AppRouter

---

**DAY 4 — All Placeholder Screens**

Goal: Placeholder views for every screen so navigation can be tested end-to-end.

Files (create all): DashboardView, WindowPickerView, LayoutPickerView, AudioModePickerView,
RecordingView, CaptionEditorView, ExportView, ProfileView, SettingsView, SubscriptionView,
HelpView, OnboardingView, LoginView, SignUpView, ForgotPasswordView, ResetPasswordView,
RecordingDetailView, PaymentView — each showing just its name as a Text label.

Cursor Prompt:
"Create 18 placeholder SwiftUI views for a macOS screen recorder app. Each view shows
a Text with the screen name centred and a list of planned UI elements as disabled gray
buttons. Wire all of them into the AppRouter. Screen names: Dashboard, WindowPicker,
LayoutPicker, AudioModePicker, Recording, CaptionEditor, Export, Profile, Settings,
Subscription, Help, Onboarding, Login, SignUp, ForgotPassword, ResetPassword,
RecordingDetail, Payment."

Git Commit: feat: placeholder views for all 18 screens

---

### PHASE 3: Authentication (Days 5–7)

---

**DAY 5 — Supabase Setup + AuthService**

Goal: Create Supabase project, configure credentials, build AuthService.

Setup:
1. supabase.com → New Project (save URL and anon key to Config.swift)
2. Add project URL and anon key to Config.swift

Files: SupabaseClient.swift, AuthService.swift

Cursor Prompt:
"Create an AuthService class in Swift using the Supabase Swift SDK. Include async functions:
signUp(email: String, password: String, name: String) -> Result<User, Error>,
signIn(email: String, password: String) -> Result<User, Error>,
signOut() async throws,
resetPassword(email: String) async throws,
getCurrentSession() -> Session?.
Use a shared SupabaseClient singleton initialised with the URL and anon key from Config.swift."

Git Commit: feat: Supabase client and AuthService

---

**DAY 6 — Login, Sign Up, Forgot Password Views**

Goal: Build functional auth screens connected to AuthService.

Cursor Prompt:
"Build a SwiftUI macOS Login screen with email and password text fields, a Log In button
that calls AuthService.signIn(), a loading ProgressView while waiting, error Text below the
form, and a Forgot Password link. Use a LoginViewModel @StateObject. Also build a Sign Up
screen with name, email, password, and confirm password fields using a SignUpViewModel.
Both ViewModels validate inputs before calling AuthService and navigate on success via AppRouter."

Git Commit: feat: login and sign up screens with form validation

---

**DAY 7 — Session Persistence + AppState**

Goal: Keep users logged in between launches. Show onboarding once.

Files: AppState.swift, FrameFlowApp.swift

Cursor Prompt:
"Create an AppState ObservableObject in Swift that on init: 1) Checks UserDefaults
for isFirstLaunch — if true, route to onboarding; 2) Calls supabaseClient.auth.session
to check for existing session — if valid, set currentUser and route to dashboard;
if nil, route to login. Inject AppState as @EnvironmentObject from FrameFlowApp.
The root view switches between OnboardingView, LoginView, and MainAppView based on
AppState.authStatus enum (unauthenticated / authenticated / firstLaunch)."

Git Commit: feat: session persistence and auth guard via AppState

---

### PHASE 4: Permissions and Device Detection (Day 8)

---

**DAY 8 — Permission Manager + Device Capability**

Goal: Handle screen recording and camera permissions. Detect Apple Silicon vs Intel.

Files: PermissionManager.swift, DeviceCapabilityManager.swift

Cursor Prompt:
"Create a PermissionManager class in Swift with async functions:
checkScreenRecordingPermission() -> Bool using SCShareableContent,
requestCameraPermission() async -> Bool using AVCaptureDevice.requestAccess,
openSystemSettings() that opens Privacy & Security in System Settings using
NSWorkspace.shared.open with the correct URL scheme.
Also create DeviceCapabilityManager that detects Apple Silicon via sysctlbyname('hw.optional.arm64')
and exposes: isAppleSilicon, maxWindows (4/2), supports4K, compositeFrameRate (60/30)."

Git Commit: feat: permission manager and device capability detection

---

### PHASE 5: Core Screens (Days 9–11)

---

**DAY 9 — Dashboard**

Goal: Build the Dashboard with recordings list, empty state, and New Recording button.

Files: DashboardView.swift, RecordingStore.swift, RecordingListItemView.swift

Cursor Prompt:
"Build a SwiftUI macOS Dashboard. RecordingStore is an ObservableObject that reads a
local recordings.json file from the app's support directory and returns [RecordingMetadata].
DashboardView shows: a top bar with app name, user avatar (initials in a circle), and
an Upgrade button (hidden if Pro); a large New Recording button; a LazyVGrid of
RecordingListItemView cells (thumbnail placeholder, name, date, duration, resolution badge);
and an empty state when no recordings exist. Show a subscription expired banner at the top
when AppState.subscriptionStatus is past_due or expired."

Git Commit: feat: dashboard with recording list and empty state

---

**DAY 10 — Profile + Settings Screens**

Cursor Prompt:
"Build a SwiftUI macOS Profile screen with: a circular avatar showing user initials,
an editable display name TextField with a Save button that calls UserService.updateDisplayName(),
a read-only email label, a subscription badge (Free or Pro with renewal date),
a Manage Subscription button, a Change Password button (triggers AuthService.resetPassword),
and a Log Out button. Build a Settings screen using SwiftUI Form with all settings from
the SettingsStore (resolution, save folder via NSOpenPanel, audio mode, mic device from
AVFoundation, auto-focus toggle, cursor highlight toggle, auto zoom toggle, zoom hold duration,
cursor colour picker, countdown timer, caption style, notification toggle, permission status rows,
dark mode override picker, app version, check for updates button)."

Git Commit: feat: profile and settings screens fully wired

---

**DAY 11 — Onboarding, Help, Forgot Password**

Cursor Prompt:
"Build a SwiftUI macOS Onboarding screen using TabView with 3 pages. Each page has a
large SF Symbol icon, a bold title, a subtitle description, and page indicator dots.
Page 1: 'Pick Your Windows' — window grid icon. Page 2: 'Choose Your Layout' — layout
diagram icon. Page 3: 'Record and Export' — video camera icon. Last page shows Sign Up
and Log In buttons. Also build a Help screen with DisclosureGroup FAQ items (8 questions
about permissions, pricing, system audio, export formats, captions) and an Email Support
button using mailto:. Also build the Forgot Password screen."

Git Commit: feat: onboarding, help, and forgot password screens

---

### PHASE 6: Window Capture (Days 12–15)

---

**DAY 12 — Screen Permission Check + Window Enumeration**

Files: WindowCaptureService.swift

Cursor Prompt:
"Using ScreenCaptureKit on macOS 14, build a WindowCaptureService with:
1) checkPermission() that calls SCShareableContent.excludingDesktopWindows to check access,
2) fetchWindows() async -> [SCWindow] that returns all capturable windows filtered to:
on-screen only, has a title, not FrameFlow itself (exclude by bundleID),
3) For each SCWindow, fetch a thumbnail using SCScreenshotManager.captureImage with
SCContentFilter(desktopIndependentWindow:),
4) Return a [WindowItem] model: { scWindow, thumbnail: CGImage?, appIcon: NSImage?, appName }."

Git Commit: feat: window enumeration with ScreenCaptureKit

---

**DAY 13 — Window Picker View**

Cursor Prompt:
"Build a SwiftUI macOS Window Picker screen. Use a LazyVGrid with 3 columns. Each cell
shows: the window thumbnail as an Image, the app icon in a small badge, the window title
as a label below, and a checkmark overlay when selected. Tapping selects/deselects.
Free users can select max 2 — show an upgrade sheet when they try a 3rd.
Pro users can select max 4. Show a 'X selected' badge in the toolbar.
A Next button is enabled when 1+ windows selected. A Refresh button re-fetches windows.
If permission is denied, show a full-screen empty state with Open System Settings button."

Git Commit: feat: window picker UI with selection and free/pro limit

---

**DAY 14 — Layout Picker View**

Cursor Prompt:
"Build a SwiftUI macOS Layout Picker screen. Left panel: a Picker for 9:16/16:9 format
(vertical requires Pro), layout preset cards shown as simple SVG-style diagrams (Stacked,
Side-by-Side, PiP Bottom-Right, PiP Face-Top), camera toggle and camera source picker
(lists available cameras from AVCaptureDevice), an audio mode row that shows current mode
and opens AudioModePickerView as a sheet on tap, an Auto-Focus toggle, a Cursor Highlight
toggle, a Countdown picker. Right panel: a live preview canvas showing selected windows
in the chosen layout using placeholder rectangles (real streams added in Day 16).
Bottom: Start Recording button."

Git Commit: feat: layout picker with format, presets, camera, and audio controls

---

**DAY 15 — Audio Mode Picker View**

Cursor Prompt:
"Build a SwiftUI macOS Audio Mode Picker shown as a sheet from Layout Picker.
It shows 4 option cards with icons and descriptions: Microphone Only (mic SF Symbol),
System Audio Only (speaker SF Symbol), Microphone + System Audio (both icons), No Audio.
Each card has a selection ring when active. If System Audio or Combined is selected and
the user is free tier, show a Pro badge on that card and an upgrade prompt on tap.
Below the cards: a mic volume slider (0-100%) when mic is included, a system audio volume
slider (0-100%) when system audio is included, a live audio level visualiser (5 animated bars)
that responds to AVAudioEngine input level. A Confirm button closes the sheet."

Git Commit: feat: audio mode picker with volume controls and live level meter

---

### PHASE 7: Recording Engine (Days 16–23)

---

**DAY 16 — Live Composite Preview Canvas**

Files: WindowStreamManager.swift, CompositeEngine.swift, CompositePreviewView.swift

Cursor Prompt:
"Using ScreenCaptureKit SCStream, capture live frames from multiple SCWindow sources
simultaneously on macOS 14. For each window: create SCStream with SCContentFilter and
SCStreamConfiguration (resolution matching window size, 60fps on Apple Silicon, 30fps
on Intel). Implement SCStreamOutput to receive CMSampleBuffer video frames. Convert each
to CIImage. CompositeEngine composites all CIImages into a single canvas CIImage using the
chosen layout (stacked: top+bottom halves, sideBySide: left+right halves) with CISourceAtopCompositing.
Display result in SwiftUI using a NSViewRepresentable wrapping an NSView that shows the
composited CGImage via its CALayer contents."

Git Commit: feat: live composite preview canvas with multi-window SCStream

---

**DAY 17 — AVAssetWriter Recording Pipeline**

Files: RecordingEngine.swift

Cursor Prompt:
"Build a RecordingEngine class in Swift using AVAssetWriter to record composite frames to MP4.
It should: 1) Accept CVPixelBuffer frames from CompositeEngine at up to 60fps,
2) Write them to AVAssetWriterInput with H.264 codec and configurable resolution,
3) Simultaneously accept audio from AudioCaptureService and write to a second
AVAssetWriterInput, 4) Support start(outputURL: URL) and stop() async -> URL methods,
5) Track recording duration as a Published formatted string (MM:SS), 6) Handle the
outputURL as a temp file during recording, moved to final destination on stop,
7) Support Universal Binary: use VideoToolbox hardware encoding on Apple Silicon."

Git Commit: feat: AVAssetWriter recording pipeline with H.264 and audio

---

**DAY 18 — Audio Capture Service**

Files: AudioCaptureService.swift, AudioMixerEngine.swift

Use prompt from Section 8B above.

Git Commit: feat: system audio capture with mic mixing via ScreenCaptureKit

---

**DAY 19 — Zoom Controller + Cursor Tracker**

Files: ZoomController.swift, CursorTracker.swift, ClickEffectRenderer.swift

Use prompt from Section 8A above.

Git Commit: feat: zoom controller and auto click zoom with ripple cursor effects

---

**DAY 20 — Auto-Focus Mode**

Files: ActiveWindowMonitor.swift

Cursor Prompt:
"Create an ActiveWindowMonitor class in Swift that uses NSWorkspace.didActivateApplication-
Notification to detect the frontmost app. Compare its bundleIdentifier to the list of
selected SCWindows. When the active app matches a recording source, publish activeWindowID.
In CompositeEngine, when auto-focus is enabled: draw a 3pt blue CIImage border overlay
around the active window's panel in the composite before encoding. When auto-focus switches
windows: animate the border appearing on the new window over 0.4 seconds using linear
interpolation of the CIImage alpha."

Git Commit: feat: auto-focus mode with active window detection and animated highlight

---

**DAY 21 — PiP Camera Overlay**

Files: CameraCapture.swift, PiPController.swift, PiPOverlayView.swift

Use prompt from Section 8C above.

Git Commit: feat: PiP camera overlay with drag, resize, and layout presets

---

**DAY 22 — Pause / Resume Recording**

Modify: RecordingEngine.swift

Use prompt from Section 8D above.

Git Commit: feat: pause and resume with timestamp offset compensation

---

**DAY 23 — Recording Screen View + HUD**

Files: RecordingView.swift, RecordingHUDView.swift

Cursor Prompt:
"Build a SwiftUI macOS Recording screen. The main area shows the live CompositePreviewView
filling the window. The camera PiP overlay is shown as a draggable panel before recording starts,
then fixed in position during recording. RecordingHUDView is an overlay at the top:
dark semi-transparent pill shape. Left: coloured dot (red=recording, yellow=paused) + timer.
Centre: zoom level label + audio mode SF Symbol icon. Right: Pause/Resume button + Stop button.
The HUD auto-hides after 3 seconds using a Timer and opacity animation, reappears on mouseMoved.
A countdown overlay (3-2-1) animates full-screen using ScaleEffect before recording begins."

Git Commit: feat: recording screen with HUD, countdown, and PiP positioning

---

### PHASE 8: Captions and Export (Days 24–28)

---

**DAY 24 — WhisperKit Integration + Caption Engine**

Files: CaptionEngine.swift, TranscriptionService.swift

Use prompt from Section 8E above.

Git Commit: feat: WhisperKit captions with 5 style presets and video burn-in

---

**DAY 25 — Caption Editor Screen**

> **Superseded for navigation by Day 40.1** — caption UI moves into Editor **Captions** tab.
> Keep building blocks: `CaptionEditorView`, `CaptionPreviewView`, `CaptionEditorViewModel`.

Files: CaptionEditorView.swift, CaptionPreviewView.swift

Cursor Prompt:
"Build a SwiftUI macOS Caption Editor screen (shown after recording, Pro users only).
Layout: HStack with two panels. Left panel (40% width): VideoPlayer showing the recording
with a scrubber, and the current caption rendered as an overlay matching the selected style.
Right panel (60%): a VStack with: 1) A horizontal ScrollView of 5 caption style cards at top
(Classic, TikTok Bold, Highlighted Word, Minimal, Custom — each a small card with a style name,
tap to select with blue border), 2) A ScrollView of CaptionSegmentRow items (start time,
end time, editable text TextField), 3) At bottom: caption position Picker (Top/Middle/Bottom),
export format Picker (Burned In/SRT/Both), and Export Button. Also a 'Skip Captions' text button
in the toolbar."

Git Commit: feat: caption editor screen with live preview and segment editing

---

**DAY 26 — Export Screen + ExportService**

> **Post-record export UI moves to Editor Export tab (Day 40.1).** Keep `ExportView` for
> Dashboard / Recording Detail re-export.

Files: ExportView.swift, ExportService.swift

Cursor Prompt:
"Build a SwiftUI macOS Export screen. Show a VideoPlayer for the recording preview.
Below it: a resolution Picker (720p always available; 1080p and 4K locked with a lock icon
for free users; 4K also locked on Intel Macs with a different message). A 'Captions included'
badge if captions were added. An Export button that calls ExportService.export() and shows
a ProgressView with percentage. ExportService should: apply CaptionRenderer if captions exist,
encode at chosen resolution using AVAssetExportSession or AVAssetWriter, apply watermark for
free users (FrameFlow watermark text in bottom-left corner as a CATextLayer), save to the
user's chosen folder from SettingsStore, add a RecordingMetadata entry to recordings.json,
trigger a UNUserNotificationCenter notification on completion."

Git Commit: feat: export screen with resolution picker, watermark, and progress

---

**DAY 27 — Recording Detail Screen**

Files: RecordingDetailView.swift

Cursor Prompt:
"Build a SwiftUI macOS Recording Detail screen. Show: a large video thumbnail (tap to play
in system player using NSWorkspace.open), an editable file name TextField that renames the
actual file on disk when saved, metadata labels (date, duration, file size, resolution, format,
audio mode, has camera, has captions), a Re-export button (re-opens the Export screen with
this recording), and a Delete button (shows a confirmation alert, then deletes the file and
removes from recordings.json). Include a 'Reveal in Finder' button using NSWorkspace.selectFile."

Git Commit: feat: recording detail screen with rename, re-export, and delete

---

**DAY 28 — Watermark System**

Modify: ExportService.swift

Cursor Prompt:
"In the ExportService, add watermark compositing for free tier users. The watermark is a
text label 'Made with FrameFlow' in a small semi-transparent white font, positioned in the
bottom-left corner of the video canvas with 10pt padding. Render it using a CATextLayer
added to the AVMutableVideoComposition's animationTool. The watermark should be visible
in all exported formats (9:16 and 16:9). For Pro users, skip the watermark layer entirely."

Git Commit: feat: watermark compositing for free tier exports

---

### PHASE 9: Backend Integration (Days 29–31)

---

**DAY 29 — Supabase Database Tables + RLS**

Run this SQL in the Supabase dashboard SQL editor:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  plan TEXT NOT NULL DEFAULT 'free',
  status TEXT NOT NULL DEFAULT 'active',
  revenuecat_id TEXT,
  stripe_customer_id TEXT,
  current_period_end TIMESTAMPTZ,
  trial_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_select_own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "users_insert_own" ON users FOR INSERT WITH CHECK (auth.uid() = id);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subs_select_own" ON subscriptions FOR SELECT USING (auth.uid() = user_id);
```

Git Commit: chore: Supabase tables and RLS policies

---

**DAY 30 — UserService + Subscription Webhook**

Files: UserService.swift, supabase/functions/revenuecat-webhook/index.ts

Cursor Prompt (UserService):
"Create a UserService in Swift using Supabase Swift SDK with:
createUser(id: UUID, email: String, name: String) — inserts into users table,
fetchUser(userId: UUID) -> User? — fetches user record,
updateDisplayName(userId: UUID, name: String) — updates display_name.
Call createUser after successful sign up. Call fetchUser on app launch after session restore."

Cursor Prompt (Webhook):
"Write a Supabase Edge Function in TypeScript for a RevenueCat webhook endpoint.
Validate Authorization header against REVENUECAT_WEBHOOK_SECRET env var.
Handle events: INITIAL_PURCHASE (insert subscription row, status: active),
RENEWAL (update current_period_end, status: active), CANCELLATION (status: cancelled),
EXPIRATION (status: expired), BILLING_ISSUE (status: past_due).
Use Supabase service role client to write to the subscriptions table.
Return 200 on success, 401 on bad secret, 400 on unknown event."

Git Commit: feat: UserService and RevenueCat webhook edge function

---

**DAY 31 — RevenueCat SDK + SubscriptionManager**

Files: SubscriptionManager.swift

Cursor Prompt:
"Integrate RevenueCat Purchases SDK into a SwiftUI macOS app. In FrameFlowApp.swift,
configure Purchases.configure(withAPIKey: Config.revenueCatAPIKey). After user logs in,
call Purchases.shared.logIn(appUserID: user.id.uuidString).
Create SubscriptionManager ObservableObject with: isPro (Bool, true when 'pro' entitlement
is active), subscriptionStatus (String: active/trialing/past_due/cancelled/expired),
planName (String: Free/Pro Annual/Pro Monthly/Lifetime), renewalDate (Date?),
fetchStatus() async that calls Purchases.shared.customerInfo(), and showManageSubscriptions()
that calls Purchases.shared.showManageSubscriptions(). Inject as @EnvironmentObject."

Git Commit: feat: RevenueCat SDK and SubscriptionManager

---

### PHASE 10: Subscription Screens (Days 32–33)

---

**DAY 32 — Subscription Pricing Screen + Paywall Gates**

Files: SubscriptionView.swift, ProGateModifier.swift

Cursor Prompt (Subscription Screen):
"Build a SwiftUI macOS Subscription screen. Show a feature comparison table (rows for key
features, columns: Free, Pro with checkmarks and X marks). Show 3 plan cards: Annual ($9/mo,
billed $108/yr, 7-day trial), Monthly ($19/mo, 7-day trial), Lifetime ($79 one-time — visible
only when SettingsStore.showLifetimeDeal is true). Each card has a plan name, price, billing
description, and a 'Start Free Trial' button that calls Purchases.shared.purchase(package:).
Show ProgressView during purchase. On success call SubscriptionManager.fetchStatus() then
navigate to Dashboard. On error show an Alert with the error message."

Cursor Prompt (Pro Gate):
"Create a SwiftUI ViewModifier called requiresPro(feature: String) that checks
SubscriptionManager.isPro. If false, overlays a sheet showing the feature name, a brief
description of why it's Pro, and an 'Upgrade' button navigating to SubscriptionView.
Apply it to: vertical mode in LayoutPicker, 3rd/4th window in WindowPicker, system audio
in AudioModePicker, PiP in LayoutPicker, captions in CaptionEditorView, 1080p/4K in ExportView."

Git Commit: feat: subscription pricing screen and Pro gate modifier

**Note (Test Store → Stripe):** Day 32 purchase code stays as-is. During dev use RevenueCat **Test Store**. Before **Day 42** testing, connect **Stripe** (test mode) and **Web Billing** in the RevenueCat dashboard — no new Swift billing screens. Switch to **Production** RC + Stripe on **Day 54** before launch (see MVP Launch Checklist, Payments).

---

**DAY 33 — Expired Subscription Banner + Manage Subscription**

Cursor Prompt:
"Create an ExpiryBannerView in SwiftUI for the Dashboard that appears when
SubscriptionManager.subscriptionStatus is 'past_due' or 'expired'. The banner is a
HStack at the top of the Dashboard: an amber warning icon, text 'Your Pro plan has ended.
Renew to restore access.', and a Renew button that navigates to SubscriptionView.
The banner has an amber background and can be dismissed (adds dismissed state to UserDefaults,
re-shows on next launch if still expired). Also wire the Manage Subscription button in
ProfileView to call Purchases.shared.showManageSubscriptions()."

Git Commit: feat: expiry banner and manage subscription flow

---

### PHASE 11: Keyboard Shortcuts + Global Hotkeys (Day 34)

---

**DAY 34 — Keyboard Shortcut Manager**

Files: KeyboardShortcutManager.swift

Use prompt from Section 8F above.

Git Commit: feat: global keyboard shortcuts for all recording controls

---

### PHASE 12: Dark Mode (Day 35)

---

**DAY 35 — Dark Mode Colour System**

Goal: Define all app colours in Asset Catalog for automatic dark/light mode switching.

In Assets.xcassets, create Color Sets for each colour with Any and Dark appearance:

| Color Name | Light | Dark |
|---|---|---|
| appPrimary | #1A56DB | #4B8EF1 |
| appBackground | #FFFFFF | #1C1C1E |
| appSurface | #F3F4F6 | #2C2C2E |
| appBorder | #E5E7EB | #3A3A3C |
| appTextPrimary | #1F2A37 | #F2F2F7 |
| appTextSecondary | #4B5563 | #AEAEB2 |
| recRed | #DC2626 | #FF453A |
| proGold | #D97706 | #FFD60A |
| successGreen | #0E9F6E | #30D158 |
| pauseYellow | #F59E0B | #FFD60A |

Cursor Prompt:
"Create an AppColors.swift file in a SwiftUI macOS app with a Color extension defining
all app colours as static properties loaded from the Asset Catalog using Color('colorName').
Colors: appPrimary, appBackground, appSurface, appBorder, appTextPrimary, appTextSecondary,
recRed, proGold, successGreen, pauseYellow. Then search through all View files in the project
and replace any hardcoded Color(..) or hex Color values with the appropriate AppColors property.
Also add a colorScheme override option in SettingsStore (.system / .light / .dark) and apply
it with .preferredColorScheme() on the root view."

Git Commit: feat: semantic colour system with dark mode via Asset Catalog

---

### PHASE 13: Settings Wiring + Profile Polish (Days 36–37)

---

**DAY 36 — Settings Wired to App Behaviour**

Cursor Prompt:
"Create a SettingsStore ObservableObject that reads and writes all settings to UserDefaults
using @AppStorage for each property. Connect settings to app behaviour:
- defaultResolution → initial value in ExportView resolution picker
- defaultSaveFolder → used in ExportService output path
- defaultAudioMode → pre-selects mode in AudioModePickerView
- defaultMicDevice → set as AVAudioEngine input on launch
- autoFocusEnabled → default value of Auto-Focus toggle in LayoutPickerView
- cursorHighlightEnabled → default state in RecordingEngine
- autoZoomOnClick → enables/disables CursorTracker's click zoom
- zoomHoldDuration → passed to ZoomController
- countdownDuration → sets RecordingView countdown seconds
- notificationsEnabled → controls UNUserNotificationCenter on export complete"

Git Commit: feat: SettingsStore wired to all app behaviour

---

**DAY 37 — Profile Edit + Delete Account**

Cursor Prompt:
"Complete the Profile screen. Make display name editable: show a TextField that activates
on tap, reveals a Save button, calls UserService.updateDisplayName() on save, and shows
a brief success checkmark animation. Delete Account: shows a destructive Alert asking for
confirmation, then calls supabaseClient.auth.admin.deleteUser() using the user's ID,
clears AppState.currentUser, clears UserDefaults, calls Purchases.shared.logOut(), and
navigates to the Login screen. Add an App Icon and display name to the Profile screen header
that shows the app version."

Git Commit: feat: profile name editing and delete account flow

---

### PHASE 14: Analytics + Error Tracking (Day 38)

---

**DAY 38 — PostHog Analytics + Sentry**

Cursor Prompt:
"Integrate PostHog analytics and Sentry error tracking into a SwiftUI macOS app.
In FrameFlowApp.swift init: configure Sentry with SentrySDK.start using Config.sentryDSN
and set tracesSampleRate to 0.2. Also initialise PostHog with Config.postHogAPIKey.
Create an AnalyticsService with static methods for key events:
trackSignUp(method: String), trackRecordingStarted(windowCount: Int, format: String, layout: String),
trackRecordingCompleted(duration: Int, format: String),
trackExportCompleted(resolution: String, hasCaptions: Bool, hasCamera: Bool),
trackUpgradeClicked(source: String), trackPurchaseCompleted(plan: String),
trackFeatureBlocked(feature: String).
Call these methods from the relevant ViewModels."

Git Commit: feat: PostHog analytics and Sentry error tracking

---

### PHASE 15: Testing (Days 39–42)

---

**DAY 39 — Auth + Permission Flow Testing**

Test checklist:
- Sign up (success, duplicate email, weak password)
- Login (success, wrong password, rate limit)
- Forgot password email received and link works
- Session persists between app launches
- Screen recording permission denied → guide shown → settings opens
- Camera permission denied → guide shown → settings opens
- Intel Mac → 4K disabled, 2 window max, performance warning shown

---

**DAY 40 — Recording Flow Testing**

Test checklist:
- Window Picker: thumbnails load in under 3 seconds with 10+ apps open
- Free user: 3rd window blocked, vertical blocked, system audio blocked
- Layout Picker: live preview shows correct layout for each preset
- PiP: camera appears, drag to reposition, resize via corner handle
- Audio Mode: record mic only, system only, combined — verify in playback
- Countdown: all durations work
- Recording starts, zoom in/out via keyboard, reset zoom
- Auto-zoom on click: click in window during recording, verify zoom in video playback
- Auto-focus: switch between apps during recording, verify highlight switches
- Pause: paused duration not in final video
- Stop → **Post-Record Editor** (all users; Free: Edit + Export tabs only)

---

**DAY 40.1 — Post-Record Editor (unified Edit + Captions + Export)**

**Context:** Emerged from Day 40 recording-flow testing. Current flow splits Caption Editor and
Export into two screens with duplicate export paths. Target: one Editor after Stop.

**Goal:** Replace `Stop → Caption Editor (Pro) / Export (free)` with `Stop → Editor → Dashboard`.

**Phases:**

| Phase | Scope | Files (indicative) |
|-------|--------|-------------------|
| **A — Flow refactor** | New `EditorView` shell; Edit + Captions + Export tabs; Stop → Editor; remove in-editor burn-in/SRT export; save captions on Export | `EditorView.swift`, `EditorViewModel.swift`, `RecordingView.swift`, `RouteDetailView.swift`, `Models.swift` (`AppRoute.editor`), refactor `CaptionEditorView` / `ExportView` panels |
| **B — Basic trim** | Timeline strip; in/out trim handles; apply range in `ExportService` | `EditorTimelineView.swift`, `ExportService.swift` |
| **C — Polish** | Draggable caption region; editable segment times; optional SRT on Export tab | `CaptionPreviewView`, `CaptionSegmentRow`, `ExportViewModel` |

**Free tier:** Edit tab + Export tab (720p, watermark). No Captions tab (Pro CTA).

**Pro tier:** All three tabs; WhisperKit generate on demand; 1080p/4K; captions burn-in + optional SRT.

**Acceptance (Phase A):**
- Stop navigates to Editor for Free and Pro
- No export buttons inside Captions tab
- Toolbar Export saves caption sidecar then runs `ExportService`
- Free user never sees caption generation UI
- Dashboard re-export still uses standalone `ExportView`

**Cursor prompt (Phase A):**
"Build `EditorView` as the unified post-recording screen. Three inspector tabs: Edit (preview +
play), Captions (Pro only — reuse CaptionEditor panels without export), Export (reuse ExportView
resolution picker + watermark notice). Toolbar: Discard, Export. Wire `RecordingView` stop to
`.editor`. Remove duplicate export from `CaptionEditorView`. Keep `ExportView` for Dashboard
re-export only."

Git Commit: feat: unified post-record editor (Day 40.1 Phase A)

---

**DAY 41 — Captions + Export Testing**

Test checklist (updated for Day 40.1 Editor):
- Stop → Editor opens for Free and Pro (not separate Caption Editor / Export hop)
- Free: Edit + Export tabs only; 720p locked; watermark on export; no caption UI
- Pro: Captions tab → Generate captions → edit text, style, position
- Editor Export tab: resolution picker, include-captions toggle, export progress
- Toolbar Export persists caption sidecar before burn-in
- Dashboard / Recording Detail re-export still opens standalone Export screen
- WhisperKit transcription on a 2-minute English recording → accuracy acceptable
- All 5 caption styles preview correctly in Editor preview
- Burn captions → export → QuickTime → captions visible at correct times
- Optional SRT export from Editor Export tab (Pro)
- Export 720p (free, watermark), 1080p and 4K (Pro, no watermark)
- Apple Silicon: 4K export completes in under 3 min for 5-min recording
- Intel Mac: 4K disabled, 1080p export completes in reasonable time
- Phase B (when shipped): trim in/out reflected in exported duration

---

**DAY 42 — Subscription + Dark Mode + Edge Cases**

Test checklist:
- Purchase Annual plan (Stripe test card: 4242 4242 4242 4242)
- Payment failure (Stripe test card: 4000 0000 0000 9995)
- Simulate expiry via RevenueCat dashboard → expiry banner shown → Pro features locked
- Restore purchase after reinstall
- Dark mode: check all 18 screens in Dark and Light mode
- Auto mode (time-based): app responds to system switch
- Recording HUD readable in dark mode on light content and dark content
- Source window closes mid-recording: placeholder shown, recording continues
- Camera disconnects mid-recording: placeholder shown, recording continues
- Disk space full: export fails with friendly message

---

### PHASE 16: Bug Fixing (Days 43–45)

- Day 43: Fix critical bugs (crashes, broken core flows)
- Day 44: Fix secondary bugs (UI glitches, edge case errors)
- Day 45: Performance — run Instruments Time Profiler + Allocations during 4-window
  recording. CPU < 65% on M2 Air. Memory growth < 50MB over 10-minute recording.

---

### PHASE 17: Distribution + Auto-Update (Days 46–48)

---

**DAY 46 — Code Signing + Notarisation**

Steps:
1. In Xcode: Signing & Capabilities → Team → select your team → enable automatic signing
2. Set bundle ID: com.yourname.frameflow
3. Archive: Product → Archive
4. Organizer → Distribute App → Developer ID → upload for notarisation
5. Or use command line (faster):
   - Export signed app: xcodebuild archive + xcodebuild -exportArchive
   - Zip and notarise: xcrun notarytool submit FrameFlow.zip --apple-id "you@email.com"
     --team-id TEAMID --password APP_SPECIFIC_PASSWORD --wait
   - Staple: xcrun stapler staple FrameFlow.app

---

**DAY 47 — DMG Creation + Signing**

Steps:
1. brew install create-dmg
2. Create a 1600x800px DMG background PNG (light and dark versions)
3. Run create-dmg (see Section 14 for full command)
4. Sign the DMG: codesign --sign "Developer ID Application: ..." FrameFlow.dmg
5. Notarise the DMG: xcrun notarytool submit FrameFlow.dmg ...
6. Staple: xcrun stapler staple FrameFlow.dmg
7. Test on a clean Mac (not logged into developer account) — should install with zero warnings

Git Commit: chore: DMG creation and notarisation workflow documented

---

**DAY 48 — Sparkle Auto-Update**

Steps:
1. Add Sparkle 2 via SPM: github.com/sparkle-project/Sparkle
2. In Info.plist add: SUFeedURL → https://yourwebsite.com/appcast.xml
3. Generate Sparkle keys: ./generate_keys (from Sparkle Utilities folder)
4. Store private key securely (NOT in Git) — used to sign update packages
5. Create appcast.xml on your website listing current version with DMG URL + signature

Cursor Prompt:
"Integrate Sparkle 2 into a SwiftUI macOS app. In FrameFlowApp, create an
SPUStandardUpdaterController as a @StateObject. Add a 'Check for Updates' menu item
in the app's main menu that calls updaterController.updater.checkForUpdates(). Also add
a 'Check for Updates' button in SettingsView. Configure Sparkle to check automatically
once per week on app launch using the SUFeedURL from Info.plist."

Git Commit: feat: Sparkle 2 auto-update with weekly check and manual trigger

---

### PHASE 18: CI/CD Automation (Day 49)

---

**DAY 49 — GitHub Actions Release Pipeline**

Create .github/workflows/release.yml:

```yaml
name: Build, Sign, Notarise, and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Import Signing Certificate
        uses: apple-actions/import-codesign-certs@v3
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_P12_PASSWORD }}

      - name: Archive App
        run: |
          xcodebuild archive \
            -scheme FrameFlow \
            -configuration Release \
            -archivePath build/FrameFlow.xcarchive \
            CODE_SIGN_IDENTITY="Developer ID Application" \
            DEVELOPMENT_TEAM=${{ secrets.TEAM_ID }}

      - name: Export Signed App
        run: |
          xcodebuild -exportArchive \
            -archivePath build/FrameFlow.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist ExportOptions.plist

      - name: Notarise App
        run: |
          ditto -c -k --keepParent build/export/FrameFlow.app build/FrameFlow.zip
          xcrun notarytool submit build/FrameFlow.zip \
            --apple-id ${{ secrets.APPLE_ID }} \
            --team-id ${{ secrets.TEAM_ID }} \
            --password ${{ secrets.APPLE_APP_PASSWORD }} \
            --wait
          xcrun stapler staple build/export/FrameFlow.app

      - name: Build DMG
        run: |
          brew install create-dmg
          mkdir -p dist
          cp -r build/export/FrameFlow.app dist/
          create-dmg \
            --volname "FrameFlow" \
            --volicon "Resources/AppIcon.icns" \
            --background "Resources/dmg-background.png" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --icon "FrameFlow.app" 200 190 \
            --hide-extension "FrameFlow.app" \
            --app-drop-link 600 190 \
            "build/FrameFlow-${{ github.ref_name }}.dmg" \
            "dist/"

      - name: Notarise DMG
        run: |
          xcrun notarytool submit "build/FrameFlow-${{ github.ref_name }}.dmg" \
            --apple-id ${{ secrets.APPLE_ID }} \
            --team-id ${{ secrets.TEAM_ID }} \
            --password ${{ secrets.APPLE_APP_PASSWORD }} \
            --wait
          xcrun stapler staple "build/FrameFlow-${{ github.ref_name }}.dmg"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: build/FrameFlow-*.dmg
          generate_release_notes: true
```

GitHub Secrets to add:
- CERTIFICATES_P12 — Developer ID cert exported as base64
- CERTIFICATES_P12_PASSWORD — cert export password
- APPLE_ID — your Apple ID email
- TEAM_ID — Apple Developer Team ID (10-char string)
- APPLE_APP_PASSWORD — app-specific password from appleid.apple.com

ExportOptions.plist (create in project root):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
```

Result: Push tag v1.0.0 → GitHub builds, signs, notarises, creates DMG, attaches to release.
You download the DMG and upload to your website. Total automated time: ~10 minutes.

Git Commit: chore: GitHub Actions CI/CD release pipeline

---

### PHASE 19: Final Preparation (Days 50–55)

---

**DAY 50 — App Icon + Metadata**

- App icon: create a 1024x1024px icon in Figma or Canva. Use a clean, bold design.
  Suggestion: film frame icon in blue with a play/record symbol. Export to all required sizes.
- Add all icon sizes to Assets.xcassets AppIcon
- Set CFBundleShortVersionString: 1.0.0, CFBundleVersion: 1
- Set NSHumanReadableCopyright in Info.plist
- Test icon appears correctly in Dock, Finder, and Launchpad

---

**DAY 51 — Privacy Policy + Terms**

Create on your website (use Termly.io or similar to generate):
- Privacy Policy: describe data collected (email, subscription status via Stripe/RevenueCat),
  mention Supabase as data processor, ScreenCaptureKit only captures when user explicitly starts,
  no recordings uploaded to any server
- Terms of Service: subscription terms, cancellation policy, refund policy (none — 7-day trial)
- Link both in: Help screen, Sign Up screen footer

---

**DAY 52 — Feedback Collection Setup**

- Create a Typeform or Google Form: overall rating (1-5), what do you use it for, what
  would you improve, would you recommend it (NPS score)
- After user's 3rd export: show a non-intrusive banner at bottom of Dashboard:
  "Enjoying FrameFlow? Share your feedback →" with a link that opens the form in browser
- Set to show once per week max using UserDefaults with a date check

---

**DAY 53 — Final Smoke Test**

Complete user flow on a fresh Mac account (not developer machine):
1. Download DMG from GitHub release → double-click → drag to Applications
2. Launch → no security warnings appear
3. Sign up → email verified → Dashboard shown
4. Grant screen recording permission → Grant camera permission
5. New Recording → select 2 windows → choose 9:16 layout → PiP camera on → Combined audio
6. Countdown → Record for 60 seconds
7. Pause → Resume → Stop
8. **Post-Record Editor** → Captions tab: generate captions → TikTok Bold → Export tab → Export
9. Open exported file in QuickTime → captions visible, audio correct, PiP visible
10. Dashboard → recording in list
11. Go to Profile → check subscription shows Free
12. Open Subscription → purchase Annual (test card) → Pro features unlock
13. New Recording → 4 windows → 4K export → verify no watermark

---

**DAY 54 — Deploy Supabase to Production**

- Deploy Edge Function: supabase functions deploy revenuecat-webhook
- Add REVENUECAT_WEBHOOK_SECRET to Supabase Edge Function secrets
- In RevenueCat dashboard: add webhook URL pointing to your Supabase Edge Function
- Switch RevenueCat from Sandbox to Production mode
- Verify webhook fires correctly by doing a test purchase with RevenueCat sandbox

---

**DAY 55 — Launch Preparation**

- Upload signed DMG to your website download page
- Update appcast.xml with v1.0.0 release info (for Sparkle auto-update)
- Create a short demo video of FrameFlow in action for your YouTube channel
- Set up a Product Hunt page (schedule for launch day)
- Send a launch email to any early interest list
- Post on Twitter/X, relevant subreddits (r/macapps, r/contentcreation, r/indiehackers)

---

## SECTION 12 — GIT WORKFLOW

### Branching Strategy

| Branch | Purpose | Rules |
|---|---|---|
| main | Production code only | Never commit directly. Merge from release/* only. |
| develop | Main working branch | Commit daily. All features merge here. |
| feature/[name] | New features | Branch from develop. Example: feature/pip-camera |
| fix/[name] | Bug fixes | Branch from develop. Example: fix/caption-timing |
| release/v[x.y.z] | Release prep | Branch from develop when ready to ship. |

### Commit Style (Conventional Commits)

| Prefix | Use For | Example |
|---|---|---|
| feat: | New feature | feat: add PiP camera overlay with drag and resize |
| fix: | Bug fix | fix: recording timer resets incorrectly after pause |
| chore: | Config, deps, tooling | chore: add WhisperKit SPM dependency |
| refactor: | Code restructure (no behaviour change) | refactor: extract CompositeEngine from RecordingView |
| test: | Test additions | test: add unit tests for CaptionSegment SRT generation |
| docs: | Documentation | docs: update README with system audio requirements |
| style: | Formatting only | style: fix spacing inconsistencies in SettingsView |

### Commit Frequency

- Minimum: once per day, end of each session
- Ideal: after each complete, working unit (a view, a service, a bug fix)
- Never commit broken code to develop — stash it instead:
  git stash save "wip: whisperkit integration"

### Rolling Back Safely

Undo last commit (keep your changes):
  git reset --soft HEAD~1

Discard last commit completely:
  git reset --hard HEAD~1

Revert a specific commit without rewriting history:
  git revert [commit-hash]

Always run git log --oneline before rolling back.

---

## SECTION 13 — TESTING PLAN

### Auth Flow Tests

| Test | Steps | Expected |
|---|---|---|
| Sign up success | Valid name, email, password | Account created, Dashboard shown |
| Sign up duplicate email | Use existing email | Error: "Account already exists" |
| Sign up weak password | Under 8 characters | Error: "Password must be 8+ characters" |
| Login success | Valid credentials | Dashboard shown, session persisted |
| Login wrong password | Wrong password | Error: "Invalid email or password" |
| Login rate limit | 10 failed attempts | Error: "Too many attempts. Try later." |
| Forgot password | Enter email, tap send | Email received, reset link works |
| Session persists | Login, quit, reopen | Still logged in, Dashboard shown |
| Logout | Tap Log Out | Login screen shown, session cleared |

### Recording Flow Tests

| Test | Expected |
|---|---|
| Window Picker loads with 10+ apps open | Thumbnails within 3 seconds |
| Free user selects 3rd window | Upgrade sheet shown |
| Free user selects 9:16 vertical | Upgrade sheet shown |
| Free user enables system audio | Upgrade sheet shown |
| Free user enables PiP camera | Upgrade sheet shown |
| Layout Picker live preview | Shows correct layout for each preset |
| PiP: drag camera bubble | Position updates in live preview |
| PiP: resize camera bubble | Size updates, stays within canvas |
| Countdown: 3s/5s/10s | Correct countdown shown before recording |
| Auto-zoom on click | Click during recording, zoom visible in exported video |
| Auto-focus | Switch app during recording, highlight switches in video |
| Pause: paused time excluded | Pause 30s, verify final video is 30s shorter |
| Source window closes mid-recording | Grey placeholder, no crash |
| Stop → Post-Record Editor | Editor shown after recording (Free: Edit+Export; Pro: +Captions) |
| Editor → Export → Dashboard | Final MP4 saved; recording appears on Dashboard |

### Caption Tests

| Test | Expected |
|---|---|
| WhisperKit transcription (2-min English) | >90% accuracy on clear speech |
| Edit caption segment text | Change reflects in preview immediately |
| Classic style | White text, black bar, bottom position |
| TikTok Bold style | Large centred word-by-word animation |
| Caption position: Top/Middle/Bottom | Correct vertical position in video |
| Burn captions | Open exported MP4, captions visible at correct times |
| SRT export | Open SRT file, format correct, timecodes accurate |

### Subscription Tests

| Test | Expected |
|---|---|
| Annual purchase (card: 4242 4242 4242 4242) | Pro activated, features unlocked |
| Payment failure (card: 4000 0000 0000 9995) | Error alert, no Pro activated |
| 7-day trial: subscribe, check status | Trial active, full Pro features |
| Simulate expiry via RevenueCat dashboard | Expiry banner shown, Pro locked |
| Restore purchase | Subscription re-linked, Pro restored |
| Manage subscription | Stripe portal opens in browser |

### Dark Mode Tests

Check every screen in: Light mode / Dark mode / Auto (system)
- All text readable and sufficient contrast
- Buttons and interactive elements visible
- Recording HUD readable on both light and dark content behind it
- Subscription pricing screen professional-looking in both modes
- DMG background: appropriate for dark Finder window

### Performance Tests

| Test | Target |
|---|---|
| App launch to recording-ready | Under 3 seconds |
| Window Picker thumbnails (15 apps) | Under 3 seconds |
| CPU during 2-window 1080p recording (M2 Air) | Under 60% |
| Memory during 10-minute recording | Growth under 50MB |
| 4K export of 5-minute recording (M2) | Under 2 minutes |
| WhisperKit transcription of 5-minute audio (M2) | Under 45 seconds |

### Error Handling Tests

- Disconnect internet during login → friendly error, no crash
- Export with disk nearly full → friendly disk space error, no crash
- Open app with screen recording permission revoked → permission guide shown
- Open app with camera permission revoked → PiP disabled, permission guide on tap
- Recording mic permission denied → video records, audio silent, no crash

---

## SECTION 14 — DMG DISTRIBUTION & CI/CD

### What You Need

- Apple Developer account (already registered)
- Developer ID Application certificate (create in Xcode → Settings → Accounts → Manage Certificates)
- Developer ID Installer certificate (same place, for DMG signing)
- App-specific password: appleid.apple.com → Sign-In and Security → App-Specific Passwords

### Manual Distribution Workflow

1. Archive in Xcode (Product → Archive)
2. Organizer → Distribute App → Developer ID → Notarise automatically → Export
3. Staple: xcrun stapler staple FrameFlow.app
4. Create DMG with create-dmg (see command below)
5. Sign DMG: codesign --sign "Developer ID Application: ..." FrameFlow.dmg
6. Notarise DMG: xcrun notarytool submit FrameFlow.dmg --apple-id ... --wait
7. Staple DMG: xcrun stapler staple FrameFlow.dmg
8. Upload to your website download page
9. Test on a clean Mac — zero security warnings

### create-dmg Command

```bash
create-dmg \
  --volname "FrameFlow" \
  --volicon "Resources/AppIcon.icns" \
  --background "Resources/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "FrameFlow.app" 200 190 \
  --hide-extension "FrameFlow.app" \
  --app-drop-link 600 190 \
  "FrameFlow-1.0.0.dmg" \
  "dist/"
```

### Automated via GitHub Actions

See Day 49 above for the full release.yml file.
Push any tag starting with v to trigger the full pipeline:
  git tag v1.0.0
  git push origin v1.0.0

GitHub builds, signs, notarises, packages DMG, attaches to GitHub Release automatically.
Pull the DMG from the GitHub Release and upload to your website.

### Sparkle Appcast (appcast.xml)

Host this file at: https://yourwebsite.com/appcast.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>FrameFlow</title>
    <item>
      <title>FrameFlow 1.0.0</title>
      <pubDate>Mon, 01 Jun 2026 00:00:00 +0000</pubDate>
      <sparkle:version>1.0.0</sparkle:version>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="https://yourwebsite.com/downloads/FrameFlow-1.0.0.dmg"
        sparkle:version="1.0.0"
        type="application/octet-stream"
        sparkle:edSignature="YOUR_SIGNATURE_FROM_SIGN_UPDATE_TOOL"
        length="FILESIZE_IN_BYTES" />
      <sparkle:releaseNotesLink>https://yourwebsite.com/release-notes/1.0.0</sparkle:releaseNotesLink>
    </item>
  </channel>
</rss>
```

---

## SECTION 15 — MVP LAUNCH CHECKLIST

### App Functionality
- [ ] Complete flow works: sign up → window pick → layout → record → export
- [ ] Free tier limits enforced: 2 windows, 720p, watermark, 16:9, mic only, no PiP
- [ ] Pro features all working: 4 windows, 4K, 9:16, system audio, PiP, captions
- [ ] Pause/resume: paused time not in final video
- [ ] Auto-zoom on click: zoom visible in exported video, not just preview
- [ ] PiP camera: drag, resize, all 6 presets working
- [ ] Captions: WhisperKit transcribes, editor shows, burn-in works, SRT exports
- [ ] All error states shown gracefully (no raw crash messages)
- [ ] Intel Mac: 4K disabled, 2 window max, performance warning shown
- [ ] Dark mode: all screens correct in Light, Dark, and Auto

### Auth & Accounts
- [ ] Sign up, login, logout all working
- [ ] Forgot password email delivered and link works
- [ ] Session persists between app launches
- [ ] Profile name edit saves correctly to Supabase
- [ ] Delete account removes data and returns to Login

### Payments
- [ ] RevenueCat in Production mode (not Sandbox)
- [ ] Stripe connected to RevenueCat in Production
- [ ] Webhook Edge Function deployed to Supabase production
- [ ] Annual and Monthly plans purchasable
- [ ] 7-day trial activates on first purchase
- [ ] Lifetime plan visible (if launch period, hide after 60 days)
- [ ] Subscription status syncs within 30 seconds of purchase
- [ ] Expiry and cancellation handled, banner shown

### Security
- [ ] Config.swift in .gitignore — not in GitHub
- [ ] Supabase service role key only in Edge Functions (not in Swift app)
- [ ] RevenueCat and Stripe keys not in version control
- [ ] Supabase RLS policies tested — users cannot read other users' data
- [ ] RevenueCat webhook secret validated in Edge Function

### Distribution
- [ ] App signed with Developer ID Application certificate
- [ ] App notarised — xcrun notarytool submit completes successfully
- [ ] Notarisation stapled to app
- [ ] DMG signed and notarised
- [ ] Install test on clean Mac: zero security warnings, opens normally
- [ ] Download link working from your website

### Legal & Privacy
- [ ] Privacy Policy published on website
- [ ] Terms of Service published on website
- [ ] Both linked in Help screen and Sign Up screen
- [ ] Screen recording and camera permission descriptions in Info.plist are honest

### Analytics & Error Tracking
- [ ] Sentry initialised with production DSN
- [ ] PostHog tracking: sign_up, recording_started, recording_completed, export_completed,
      upgrade_clicked, purchase_completed, feature_blocked

### Feedback
- [ ] Support email address set up and linked in Help screen
- [ ] Feedback prompt shown after 3rd export (once per week max)
- [ ] Typeform or Google Form set up and linked

---

## SECTION 16 — FUTURE IMPROVEMENTS

### Design & Polish (v1.1 — First Priority)

- Professional app icon by a designer (Fiverr or 99designs, $50–$200)
- Onboarding with actual illustrations or Lottie animations (use LottieFiles)
- Smooth animated screen transitions (NavigationTransition API)
- Custom recording-complete sound effect
- Animated onboarding for new features (coach marks)
- App welcome video on website showing the full workflow in 60 seconds

### Advanced Recording Features (v1.2)

- Full AI auto-zoom: zoom toward cursor at all times, not just on click
- More layout presets: Full-focus (one window large, others as small sidebar panels), 2x2 Grid
- Custom background: solid colour, gradient, or uploaded image behind composited windows
- Keyboard shortcut display overlay: show key presses as a visual label in the recording
- Screen annotation tools: draw arrows, circles, highlight regions during recording
- Clip trimmer: basic start/end trim before export (no timeline editor needed)

### Audio & Captions Improvements (v1.3)

- Noise reduction filter for mic audio using Accelerate framework
- Per-language caption model selection (Spanish, French, Hindi, Japanese)
- Caption translation: transcribe in one language, display in another (via OpenAI API)
- Caption animation: word-by-word with timing refined to individual phonemes
- Multi-speaker detection: label different speakers in captions

### Infrastructure & Distribution (v2.0)

- Mac App Store distribution (switch payments to Apple IAP, Apple takes 15–30%)
- Apple Sign In (required for App Store)
- Cloud recording storage: upload recordings to Supabase Storage with CDN
- Team accounts: 3-seat plan for small teams, shared recording library
- Usage dashboard: total recording time, most used layout, top features per user

### Monetisation Expansion

- AppSumo lifetime deal at launch for spike of early adopters ($49–79 one-time)
- Affiliate programme: creators earn 20% recurring for referrals (via Rewardful or Partnerstack)
- Education discount: 50% off for verified students (via SheerID)
- Annual business plan: $25/mo, 3 seats, shared folder

---

## QUICK REFERENCE — KEYBOARD SHORTCUTS

| Action | Shortcut |
|---|---|
| Start / Stop Recording | Cmd + R |
| Pause / Resume | Cmd + P |
| Zoom In | Cmd + = |
| Zoom Out | Cmd + - |
| Reset Zoom | Cmd + 0 |
| Toggle Auto-Focus | Cmd + F |
| Toggle Cursor Highlight | Cmd + H |
| Toggle Camera (PiP) | Cmd + K |
| Discard Recording | Cmd + Escape |
| Export | Cmd + E |

---

## QUICK REFERENCE — TECH STACK SUMMARY

| What | Technology |
|---|---|
| App | SwiftUI (macOS 14+) |
| Window Capture | ScreenCaptureKit |
| Video Compositing | AVFoundation + CIImage + Metal |
| System Audio | ScreenCaptureKit capturesAudio |
| Audio Mixing | AVAudioEngine |
| Camera PiP | AVCaptureSession |
| Zoom & Effects | CIAffineTransform + CADisplayLink |
| Captions | WhisperKit (on-device, free) |
| Subtitle Burn-in | AVMutableVideoComposition + CATextLayer |
| Backend | Supabase |
| Auth | Supabase Auth |
| Subscriptions | RevenueCat + Stripe |
| Dark Mode | Asset Catalog Color Sets |
| Auto-Update | Sparkle 2 |
| CI/CD | GitHub Actions |
| Analytics | PostHog |
| Error Tracking | Sentry |
| Global Shortcuts | NSEvent.addGlobalMonitorForEvents |

---

*End of FrameFlow Complete Blueprint — Version 3.0*
*This is your single source of truth. Update it as the app evolves.*
*Total development time: 55 days at 3–5 hours per day.*
