---
name: playwright-mcp-chrome-missing
description: Playwright MCP fails with "Chromium distribution 'chrome' is not found"; workaround is driving the bundled chromium via node with an explicit executablePath
metadata:
  type: reference
---

# Playwright MCP is broken on this host (chrome channel not installed)

Every `mcp__playwright__*` call fails at `initializeServer` with:

```
Chromium distribution 'chrome' is not found at /opt/google/chrome/chrome
Run "npx playwright install chrome"
```

Cause: `.mcp.json` runs `@playwright/mcp` with `--config=playwright-mcp.config.json`, which sets
`ignoreHTTPSErrors` and a storageState but no `browser.channel`/`executablePath`. The MCP defaults
to the **chrome** channel; only Playwright's own chromium builds are on disk
(`~/.cache/ms-playwright/chromium-1234`). No `/usr/bin/chrome*`, no snap, no flatpak.

## Working workaround (no host changes, no MCP restart)

Drive chromium from a node script using the playwright package vendored with the MCP:

```js
const { chromium } = require('/home/basraven/.npm-global/lib/node_modules/@playwright/mcp/node_modules/playwright');
const browser = await chromium.launch({
  executablePath: '/home/basraven/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome',
  args: ['--no-sandbox', '--disable-dev-shm-usage']
});
const ctx = await browser.newContext({ ignoreHTTPSErrors: true }); // needed for self-signed .bas certs
```

Gotchas:
- The vendored playwright is `1.63.0-alpha` and wants browser build **1237**; on-disk builds are 1228/1234. Plain `chromium.launch()` fails — `executablePath` must be set explicitly.
- The browser lives at `.../chromium-1234/chrome-linux64/chrome` (note `-linux64`, not `-linux`).
- Capture console via `page.on('console')` + `page.on('pageerror')`; capture 404/asset failures via `page.on('response', r => r.status() >= 400)`.

Permanent fix (needs the MCP server restarted to take effect): add `"channel": "chromium"` to
`browser` in `playwright-mcp.config.json`, or install chrome for the `chrome` channel.

Related: [[seerr-v3-login]]
