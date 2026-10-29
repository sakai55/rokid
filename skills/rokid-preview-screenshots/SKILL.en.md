---
name: "rokid-preview-screenshots"
description: "Render AIUI agent preview screenshots locally (480x352 canvas) from `aix preview --html-out` output using a self-contained Ink runtime and headless Chrome, instead of the unreachable hosted preview. Use whenever an agent needs preview images of all its pages."
---

# AIUI Preview Screenshots (local pipeline)

[中文](SKILL.md) | English | [日本語](SKILL.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

Why this exists: `aix preview` starts a local server, but the `preview.html` it generates loads the Ink runtime from a CDN this environment cannot reliably reach, and the remote browser cannot open loopback URLs. This pipeline renders everything locally. The working tools live in `~/workspace/preview-tools/` (on the maintainer's machine).

## Steps

1. Export the preview HTML from the agent dir:
   ```bash
   ~/tools/bin/aix preview . --html-out artifacts/preview.html
   ```
2. Make a render copy whose importmap points at a **local** Ink runtime instead of the CDN:
   ```bash
   npm i @yodaos-pkg/ink@<version matching the preview>   # self-contained, relative imports + WASM
   sed 's#https://ga.jspm.io/[^"]*#/ink/index.js#' preview.html > www/preview.html
   ```
   The Ink version must match the runtime the preview was generated with (check the generated HTML / `.aix/agent-id` context); a mismatched runtime can silently render a blank canvas.
3. Serve `www/` with the correct WASM MIME type:
   ```bash
   node server.js   # ~/workspace/preview-tools/server.js, port 8902, application/wasm
   ```
4. Screenshot with puppeteer (`~/workspace/preview-tools/shot.js`): the glasses canvas frame is exactly **480×352** — crop to the frame, not to the browser window. For multi-state pages, drive the UI first (e.g. click RUN ALL at its canvas coordinates, ~(88,103) on the benchmark page) and capture each state as its own PNG.
5. Save the finals as `preview-<slug>-<page-or-state>.png` into the repo at `screenshots/<slug>/` and embed them in the agent README's 「预览截图」 (Preview Screenshots) section.

## Gotchas

- The remote/hosted browser route (upload preview.html to a viewer site) fails on file-grant size checks whenever the HTML is regenerated — stick with this local route.
- A timed interaction state may revert before you capture it (e.g. a greeting that flips back after ~1s): read the saved PNG back and confirm it actually shows the intended state; if two saved states come out byte-identical, say so — don't fake the second state.
- Hardware-dependent items (camera/mic/sensors) FAIL or SKIP in the web runtime by design. That is expected in preview screenshots; real behavior is verified on device.
