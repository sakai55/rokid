---
name: "rokid-agent-sop"
description: "Produce one Rokid AIUI Agent end-to-end for the sakai55/rokid repo: design within official capability limits, develop, static-check, pack (.aix), preview screenshots, README with review-submission section, and GitHub sync (main dir + aix/ package + screenshots + agent-<slug> branch). Use for every new agent in the 50-agent production line."
---

# Rokid Agent Production SOP

One agent = one life problem, glasses-directionality first. Walk all 9 steps; an agent is not done until step 8 is registered.

## Capability red lines (official-source verified, 2026-10-24)

Full dossier: `~/memory/rokid-glasses-capabilities.md` in Muse's memory (repo summary in root README). Never design beyond these:

- **No eye tracking.** "Gaze" = camera field centre + head orientation (`AbsoluteOrientationSensor`), head-steady confirm via `onOrientationStabilityChange`, nod confirm via `onHeadGesture('nod')`.
- **No OCR API.** Reading text = camera photo + LLM image input. Photo modes via `ImageCapture.takePhoto`: `telephoto` (distant small text, 2016×1512), `wide` (barcode/large field, 2016×2688), `default` (3024×4032). Barcodes: native `BarcodeDetector`.
- **Microphone modes** only via the AIUI microphone API: `wearer` (default) / `far-field` / `near-field` / `omnidirectional`, plus `system-audio`. The wx recorder cannot select a mode.
- **Permissions**: exactly `GEOLOCATION`, `CAMERA`, `RECORD_AUDIO` — no others exist; ASR has no separate permission.
- **Display**: monochrome green, design to the 480×352 runtime canvas.
- **LLM**: host-managed `LanguageModel` streaming only; tool calls arrive as `toolcall` events and are not auto-executed. **TTS**: 11 fixed voices; the `lang` attribute does not take effect.
- **Network**: HTTPS only, domains must be on the filed allowlist; no LAN direct connections. Network may be proxied via the phone app over Bluetooth.

- **Gestures first, minimal buttons (GO, 2026-10-24)**: the temple touchpad is the primary controller — tap = confirm (`Enter`), double-tap = back (`Backspace`), swipe = scroll/switch (`ArrowUp/Down`), head-steady + nod = gaze confirm; single-finger long-press wakes the assistant, two-finger long-press fires the AI Shortcut Command (a fixed text, ≤500 chars, delivered to a chosen agent — a hardware entry that bypasses ASR entirely). Full verified gesture table: capability dossier §3.2.1. Design pages so the main flow runs on gestures alone; keep on-screen buttons to the minimum and state the agent's gesture mapping in its README. (A fleet-wide UI unification for "too many same-style buttons" is deliberately deferred by GO until all 120 agents are done — do not start it early.)

If a feature cannot be wired to a real API, label it honestly in UI + README as sample/placeholder with the pending link named (see gaze-translate). Never fake a capability.

- **Current phase = MVP (GO, 2026-10-24)**: ship functionally correct agents; do not polish UI or invent interaction refinements now. The interaction model and UI unification get designed only after GO's real-device testing of the MVP fleet, because testing is what defines how interaction should work.

## Steps

1. **Design** — one life problem; name the directionality core (GAZE / HEAD / MIC4 / GEO-H / SCAN) and the exact APIs used. Check the red lines first.
2. **Develop** — in `<slug>/` (app.json + AGENTS.md + app.js + pages/*.ink). Project root must carry `.aixignore` excluding `.agents/`, `.aix/`, `artifacts/`, `*.aix`, `skills-lock.json`, `node_modules/`.
3. **Static check** — JSON parse of app.json, JS syntax parse, no legacy/invented APIs, permissions match features actually used.
4. **Pack** — `aix pack . -o <slug>.aix`; record the size. A pack that suddenly balloons means `.aixignore` is broken.
5. **Preview** — screenshots of ALL pages via the local preview pipeline (skill `rokid-preview-screenshots`); save to repo-root `screenshots/<slug>/`.
6. **README** — The README's very top (immediately after the H1 title) MUST carry the Studio import block, copy-ready: a line 「**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：」 followed by a fenced code block containing only `https://github.com/sakai55/rokid/tree/agent-<slug>` (GO, 2026-10-24). The branch copy of the README keeps the same top block. The README must also contain: features, directionality usage, permissions, pack/preview commands, device-test info table (Studio name / Version / Category / Intent / Agent ID / status — backfilled after Studio import), a 「预览截图」 section embedding `../screenshots/<slug>/*.png`, and the segmented 「提审资料 (Review Submission)」: Feature Description (≤500 chars), Opening Message (≤500, Markdown), Preview Media (3–5 files, ≥1 image + ≥1 video; video backfilled at device stage), Change Log split into Features added / Improvements / Fixes per Build.
7. **GitHub sync** — via terminal `git`/`gh` (logged in as sakai55; GitHub ops are pre-approved): push `<slug>/` to main, `aix/<slug>.aix` in the repo, screenshots to `screenshots/<slug>/`, and mirror the same file set to branch `agent-<slug>` **at branch root** (branch root = project root; keep it clean — no subdirectory copies, no stray .aix).
8. **Register** — mark the agent ✅ in the 50-agent PLAN progress table with AIX size, screenshot count, branch name. The root README agent list is auto-appended by the `rokid-agent-list-sync` cron — do not edit it by hand.
9. **Device test & submission (GO-triggered only)** — GO imports in Global Studio via `tree/agent-<slug>`, Device Debug → Package and Save, Hi Rokid updates the glasses resource package, voice-opens the agent. Only when GO says 「真机测试完成了」 may Muse submit for review in Studio, pasting the README's 提审资料 verbatim, then backfill the device-test table.
