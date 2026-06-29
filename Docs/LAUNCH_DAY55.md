# Day 55 — Launch Preparation (Drazlo)

**Phase 19 — Final Preparation**  
**Positioning:** *Record your Mac. Post everywhere. Skip the editing.*

---

## Launch checklist

### Website & distribution

- [x] Marketing homepage at `website/index.html` (hero, features, Free vs Pro, download CTA)
- [x] `/download` redirect → latest notarized DMG (v1.0.6 via GitHub Releases)
- [x] Release notes page: `/release-notes/1.0.6/`
- [x] Privacy + Terms pages preserved; back links point to homepage
- [x] `website/README.md` — deploy instructions
- [ ] **Manual:** Deploy `website/` to Vercel → **drazlo.app**
- [ ] **Manual:** Verify live homepage + download + appcast after DNS deploy

### Sparkle auto-update

- [x] EdDSA key pair generated (`generate_keys` → macOS Keychain)
- [x] `SUPublicEDKey` set in `Info.plist` (requires **new app build** for installed users to trust updates)
- [x] `Resources/Release/appcast.xml` — v1.0.6, signed enclosure
- [x] `website/appcast.xml` — copy for static host
- [ ] **Manual:** Publish `appcast.xml` at https://drazlo.app/appcast.xml
- [ ] **Manual:** Test **Settings → About → Check for Updates** on Mac with older build (< 1.0.6)

**Sparkle public key (Info.plist):** `+tejosiUt6pIGS7MO+meT7mrd04Lg/8UouJpl7xkf9A=`  
**Private key:** macOS Keychain (from `generate_keys`) — not in git

### DMG (latest release)

- [x] **v1.0.6** published — notarized, no background arrow
- [x] GitHub Release: https://github.com/JeeT001/FrameFlow/releases/tag/v1.0.6
- [x] Local verify: `spctl`, `stapler validate` pass

```bash
gh release download v1.0.6 --repo JeeT001/FrameFlow --pattern 'Drazlo-*.dmg' --dir build
spctl -a -vv -t open --context context:primary-signature build/Drazlo-1.0.6.dmg
xcrun stapler validate build/Drazlo-1.0.6.dmg
```

### Day 54 billing gate (launch blocker if incomplete)

- [ ] RevenueCat **Production** mode (not Sandbox)
- [ ] Stripe **Live** connected to RevenueCat
- [ ] Webhook registered: `https://rdqohexzpxrkggcagrmq.supabase.co/functions/v1/revenuecat-webhook`
- [ ] Supabase secrets: `REVENUECAT_WEBHOOK_SECRET`, `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Test purchase → Pro unlock in app (~30s)
- [ ] GitHub secret `REVENUECAT_API_KEY` set for CI

**Status:** Day 54 **not fully verified** — soft launch OK for download; **paid Pro checkout** may be blocked until secrets + Production mode are confirmed.

### Marketing (user publishes — drafts below)

- [ ] YouTube demo video (60–90s)
- [ ] Product Hunt launch
- [ ] Launch email to early interest list
- [ ] Social posts (Twitter/X, Reddit)

---

## Live URLs (after Vercel deploy)

| Resource | URL |
|----------|-----|
| Homepage | https://drazlo.app |
| Download | https://drazlo.app/download |
| Appcast | https://drazlo.app/appcast.xml |
| Release notes | https://drazlo.app/release-notes/1.0.6/ |
| Privacy | https://drazlo.app/privacy/ |
| Terms | https://drazlo.app/terms/ |
| GitHub DMG | https://github.com/JeeT001/FrameFlow/releases/download/v1.0.6/Drazlo-1.0.6.dmg |

---

## Demo video script (60–90s)

**Hook (0–5s):** “You record on Mac. You post on TikTok. Drazlo connects both.”

**Problem (5–15s):** Quick montage — OBS overload, separate caption tool, export confusion.

**Record (15–35s):**
1. Open Drazlo → pick 2 windows
2. Choose 9:16 layout + PiP camera
3. Hit Record → demo a short workflow

**Edit & export (35–55s):**
1. Stop → trim in editor
2. Generate captions (Pro badge if needed)
3. Export 1080p MP4

**CTA (55–90s):** “Download free at drazlo.app. Pro unlocks captions, 4K, and no watermark.”

**Shot list:** Screen capture only; no face cam required. Use light theme for clarity.

---

## Product Hunt draft

**Name:** Drazlo  
**Tagline:** Record your Mac. Post everywhere.  
**Description:**

Drazlo is a native macOS screen recorder built for creators who ship to YouTube, TikTok, and Shorts — without opening five different apps.

Pick multiple windows, add a draggable PiP camera, capture system audio, burn in auto captions (Pro), and export in the right aspect ratio. Free tier includes 720p recording; Pro adds 1080p/4K, vertical layouts, captions, and watermark-free exports.

Made on Apple Silicon with ScreenCaptureKit and WhisperKit — your recordings stay on your Mac until you export.

**First comment (maker):** Thanks for checking out Drazlo! I built this because tutorial creators deserve a Mac-native recorder that goes straight to social formats. Happy to answer questions about captions, multi-window capture, or the roadmap.

**Gallery captions:** (1) Multi-window picker (2) 9:16 layout + PiP (3) Caption editor (4) Export sheet

---

## Launch email template

**Subject:** Drazlo is live — record your Mac, post everywhere

**Body:**

Hi,

Drazlo is now available for macOS — a native screen recorder for creators.

**Download:** https://drazlo.app/download

**What you get:**
- Multi-window screen recording with layout presets
- PiP camera and system audio (Pro)
- Auto captions and export for vertical video (Pro)
- Free tier to try before you upgrade

macOS 14+ required. Install by dragging Drazlo to Applications.

Questions? Reply to this email or write kiwibooking.nz@gmail.com.

— Simranjit

---

## Social drafts

### Twitter/X thread

1. Drazlo is live on macOS — record multiple windows, add PiP, export for TikTok/YouTube. Download: drazlo.app
2. Built for creators who hate juggling OBS + caption tools + export presets. One app, native Mac.
3. Free: 720p, 2 windows. Pro: 4K, captions, 9:16, no watermark. Try it and tell me what you record first.

### r/macapps

**Title:** [Release] Drazlo — native macOS screen recorder with multi-window capture, PiP, and captions

**Body:** I built Drazlo for tutorial/creator workflows on Mac. Multi-window picker, layout presets, optional WhisperKit captions, export to common formats. Free tier + Pro subscription. Not on the App Store — notarized DMG from drazlo.app. Feedback welcome!

### r/contentcreation / r/indiehackers

Focus on workflow: record → caption → export for Shorts/Reels without a separate editor. Link drazlo.app, mention indie solo dev, ask for creator use cases.

---

## Press kit (one paragraph)

**Drazlo** is a native macOS screen recording app for content creators. It combines multi-window capture, draggable picture-in-picture camera, on-device auto captions, and social-ready export formats in a single SwiftUI app. Drazlo is distributed as a notarized DMG with Sparkle auto-updates; a free tier covers basic recording, with **Drazlo Pro** unlocking HD export, vertical layouts, system audio, captions, and watermark-free output. Download at **https://drazlo.app**.

**Bullets:**
- Multi-window screen recording with layout presets
- PiP camera + system/mic audio (Pro)
- On-device captions with multiple styles (Pro)
- Export for YouTube, TikTok, and Shorts aspect ratios

---

## Next release workflow (after Day 55)

1. Bump version in Xcode + CHANGELOG
2. Tag `v*` → CI builds notarized DMG
3. `./Scripts/sign_sparkle_update.sh build/Drazlo-<version>.dmg`
4. Update `Resources/Release/appcast.xml` + `website/appcast.xml`
5. Update `website/vercel.json` `/download` redirect
6. Add release notes page; redeploy website

---

## Suggested commits (Day 55)

```
feat(website): launch homepage with download, features, and pricing
chore: publish Sparkle appcast for v1.0.6 and set SUPublicEDKey
docs: add Day 55 launch checklist and marketing drafts
```

**Note:** `SUPublicEDKey` change requires a **future app release tag** (v1.0.7+) for the key to ship inside the binary. Until then, Sparkle update checks from existing 1.0.6 builds may fail signature validation against the new key pair.
