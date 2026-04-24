# Pulse — Legal & Support Site

Static site served at https://brunocerberus.github.io/Pulse/ via GitHub Pages. Referenced from the app's [LegalURLs.swift](../Pulse/Configs/LegalURLs.swift) and required by App Store Review Guideline 3.1.2 (functional Privacy Policy and Terms links on every subscription surface).

## Pages

| File | URL |
|---|---|
| `index.html` | `/Pulse/` |
| `privacy-policy.html` | `/Pulse/privacy-policy.html` |
| `terms-of-service.html` | `/Pulse/terms-of-service.html` |
| `support.html` | `/Pulse/support.html` |

## One-time enablement

After this lands on `master`, enable Pages:

```bash
gh api -X POST repos/BrunoCerberus/Pulse/pages \
  -f 'source[branch]=master' \
  -f 'source[path]=/docs'
```

Or via the GitHub UI: **Settings → Pages → Source: Deploy from a branch → `master` / `/docs` → Save**. First deployment takes ~1 minute. Verify with `curl -I https://brunocerberus.github.io/Pulse/privacy-policy.html` (expect `HTTP/2 200`).

## Editing

Content is plain HTML with a shared `style.css`. Dark mode is handled by `prefers-color-scheme`. Bump the `Last updated` line at the top of each legal page when making material changes and re-announce in-app.

## Jurisdiction

Section 13 of `terms-of-service.html` ("Governing Law") is intentionally generic. Replace with a specific jurisdiction if you incorporate or if required by local law.
