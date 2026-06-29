# Deploy Drazlo website (Sparkle appcast + download page)

**Root cause of Sparkle “retrieving update information”:** `https://drazlo.app/appcast.xml` is not reachable. As of diagnosis, `drazlo.app` returns **NXDOMAIN** (domain not registered or no DNS). v1.0.7’s `SUFeedURL` is hardcoded to that URL.

---

## Fix checklist (required for v1.0.7 Sparkle)

### 1. Register the domain

`drazlo.app` must exist in DNS. Register at any `.app` registrar (Google Domains, Namecheap, Cloudflare, etc.).

Verify:

```bash
dig +short drazlo.app
# Must return A or CNAME records — not empty
```

### 2. Create Vercel project (website root)

1. Go to [vercel.com](https://vercel.com) → **Add New Project**
2. Import **JeeT001/FrameFlow** (or deploy only `website/`)
3. **Root Directory:** `website` ← critical
4. Framework: **Other** (static)
5. Deploy

### 3. Attach custom domain

1. Vercel project → **Settings → Domains** → add `drazlo.app` and `www.drazlo.app`
2. At your registrar, set DNS per Vercel instructions:
   - **A** `76.76.21.21`, or
   - **CNAME** `cname.vercel-dns.com`
3. Wait for SSL (usually minutes)

### 4. Verify appcast (before testing Sparkle)

```bash
curl -sI https://drazlo.app/appcast.xml
curl -s https://drazlo.app/appcast.xml | grep sparkle:version
```

Expected:

- HTTP **200**
- Body contains `<sparkle:version>7</sparkle:version>`
- `Content-Type` includes `xml`

### 5. Test in app

On Mac with **v1.0.7** installed:

**Settings → About → Check for Updates** → should say **“You’re up to date”**.

---

## Optional: GitHub Actions auto-deploy

Workflow: `.github/workflows/deploy-website.yml`

Add GitHub secrets (from Vercel → Project → Settings):

| Secret | Where to find |
|--------|----------------|
| `VERCEL_TOKEN` | Vercel → Account → Tokens |
| `VERCEL_ORG_ID` | Vercel project `.vercel/project.json` or API |
| `VERCEL_PROJECT_ID` | Same |

Pushes to `main` that touch `website/**` will redeploy.

---

## Manual deploy (CLI)

```bash
npm i -g vercel
cd website
vercel --prod
# Link project once; set domain in Vercel dashboard
```

---

## Why GitHub raw URL does not work

Repo is **private** — `raw.githubusercontent.com/.../appcast.xml` returns 404. Sparkle needs a **public HTTPS** feed.

---

## Interim workaround (requires v1.0.8)

If domain registration is delayed, ship **v1.0.8** with:

```xml
<key>SUFeedURL</key>
<string>https://YOUR-PROJECT.vercel.app/appcast.xml</string>
```

Deploy `website/` to Vercel first, use the free `*.vercel.app` URL, then migrate to `drazlo.app` later (another release or keep vercel URL).

**v1.0.7 cannot change feed URL without reinstalling a newer build.**

---

## Files served

| URL | File |
|-----|------|
| `/appcast.xml` | `website/appcast.xml` |
| `/` | `website/index.html` |
| `/download` | Redirect → GitHub Release DMG |
| `/release-notes/1.0.7/` | `website/release-notes/1.0.7/index.html` |

Keep `website/appcast.xml` in sync with `Resources/Release/appcast.xml` after each release.
