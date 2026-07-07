# Drazlo website

Static marketing site + legal pages + Sparkle appcast. Deployed on **Vercel** at [drazlo.vercel.app](https://drazlo.vercel.app).

Release DMGs are hosted on the **public** [GitHub Releases](https://github.com/JeeT001/FrameFlow/releases) page — no GitHub login required to download.

## Structure

| Path | Purpose |
|------|---------|
| `/` | Launch homepage — download, features, layouts, trim editor, pricing |
| `/download` | Redirect → latest GitHub Release DMG |
| `/downloads/Drazlo-x.y.z.dmg` | Redirect → matching GitHub Release asset |
| `/appcast.xml` | Sparkle auto-update feed (copy of `Resources/Release/appcast.xml`) |
| `/release-notes/1.0.x/` | Release notes for Sparkle `releaseNotesLink` |
| `/privacy/`, `/terms/` | Legal pages |

## Local preview

```bash
cd website
python3 -m http.server 8080
# Open http://localhost:8080
```

Note: `/download` redirect only works on Vercel; locally use the GitHub Releases URL directly.

## Deploy to Vercel

1. Connect repo (root directory = `website/`) to Vercel
2. Production URL: **https://drazlo.vercel.app** (optional custom domain: `drazlo.app`)
3. Push `website/` changes to `main` → **Deploy Website** GitHub Action runs automatically

After each app release:

1. Sign DMG → update `website/appcast.xml` + `Resources/Release/appcast.xml`
2. Update `vercel.json` `/download` redirect to latest version
3. Add `website/release-notes/<version>/index.html` if needed
4. Push to `main`

Homepage sections (anchors): `#features`, `#layouts`, `#editor`, `#layout-examples`, `#how`, `#usecases`, `#pricing`. Layout mockups share `.mockup-canvas` + `.win-tile` compositor styling.

## Latest download (v1.0.13)

- **Homepage CTA:** https://drazlo.vercel.app/download
- **Direct GitHub asset:** https://github.com/JeeT001/FrameFlow/releases/download/v1.0.13/Drazlo-1.0.13.dmg
- **Appcast:** https://drazlo.vercel.app/appcast.xml

## Do not commit

API keys, notary credentials, or Sparkle private keys.
