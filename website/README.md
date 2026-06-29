# Drazlo website (`drazlo.app`)

Static marketing site + legal pages + Sparkle appcast. Deployed via **Vercel** (or any static host).

## Structure

| Path | Purpose |
|------|---------|
| `/` | Launch homepage — download, features, pricing |
| `/download` | Redirect → latest GitHub Release DMG |
| `/downloads/Drazlo-x.y.z.dmg` | Redirect → matching GitHub Release asset |
| `/appcast.xml` | Sparkle auto-update feed (copy of `Resources/Release/appcast.xml`) |
| `/release-notes/1.0.6/` | Release notes for Sparkle `releaseNotesLink` |
| `/privacy/`, `/terms/` | Legal pages |

## Local preview

```bash
cd website
python3 -m http.server 8080
# Open http://localhost:8080
```

Note: `/download` redirect only works on Vercel; locally use the GitHub Releases URL directly.

## Deploy to Vercel

1. Connect repo (or `website/` folder) to Vercel
2. Set production domain: **drazlo.app**
3. Deploy from `main` when `website/` changes

After each release:

1. Update `vercel.json` `/download` redirect to latest version (or use `/downloads/Drazlo-<version>.dmg`)
2. Copy `Resources/Release/appcast.xml` → `website/appcast.xml`
3. Add `website/release-notes/<version>/index.html` if needed
4. Redeploy

## Latest download (v1.0.7)

- **Homepage CTA:** https://drazlo.app/download
- **Direct GitHub asset:** https://github.com/JeeT001/FrameFlow/releases/download/v1.0.7/Drazlo-1.0.7.dmg
- **Appcast:** https://drazlo.app/appcast.xml

**Sparkle requires `drazlo.app` DNS + Vercel deploy.** See `Docs/SPARKLE_FEED_FIX.md` if Check for Updates fails.

## Do not commit

API keys, notary credentials, or Sparkle private keys.
