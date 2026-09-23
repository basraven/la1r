---
name: seerr-v3-login
description: seerr/jellyseerr (basflix.bas) v3 login page structure, expected console noise, and how to test the login error path without credentials
metadata:
  type: reference
---

# seerr v3 login page (basflix.bas / jellyseerr.bas)

Upgraded 2026-09-23 from 2.7.3 to 3.4.1 (full frontend rewrite; rebranded "seerr"). Namespace `torrent`,
ingress `jellyseerr-https`. Both hostnames serve the same pod.

## What the unauthenticated login page contains
- Wordmark/logo: **seerr** (not "Jellyseerr") — but `<title>` is still `Sign In - Jellyseerr` and the
  media-server button is labelled `Jellyseerr`. `applicationTitle` is persisted from the old install.
- Card heading: `Login with Jellyfin` (localLogin, authenticates against the Jellyfin server).
- Inputs: `#username` (type=text, placeholder "Username") and `#password` (type=password + eye toggle).
  **Not** an email field — v3 local login uses the Jellyfin username.
- Buttons: `Sign In` (submit), `Quick Connect` (Jellyfin quick-connect), and `Jellyseerr` (mediaServerLogin).
- Link: `Forgot Password?` → `https://jellyfin.bas/web/index.html#!/forgotpassword.html`.
- Random TMDB backdrop pulled from `image.tmdb.org` (external egress dependency for the visual).

## Expected console output when logged out — NOT bugs
- `GET /api/v1/auth/me` → **401** (fires twice; logged as `Failed to load resource: the server responded with a status of 401`).
- Chrome verbose `[DOM] Input elements should have autocomplete attributes` on the login inputs (a11y nit, upstream).
- No uncaught `pageerror`, no asset 404s as of 3.4.1.

## Login error path (testable with a throwaway username, no real creds)
- POST goes to `/api/v1/auth/jellyfin` → `401 {"message":"INVALID_CREDENTIALS"}`.
- UI shows a **transient toast**: `The username or password is incorrect.` It is gone well before a 6s
  screenshot, so a text-poll at +6s will wrongly conclude "no feedback". Detect it by installing a
  `MutationObserver` on `document.body` before clicking submit, not by sampling `body.innerText`.
- The page never blanks or crashes on bad creds — form stays mounted with values retained.

Related: [[playwright-mcp-chrome-missing]]
