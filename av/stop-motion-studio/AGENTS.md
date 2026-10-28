# Stop Motion Studio — Design Contract

v1 is a VERIFICATION build (GO 2026-10-28, scope tightened twice): only the
core chain 拍一帧 → 合成播放 (shoot frames → composite playback) is built and
verified. Everything deeper is deferred until the core chain passes on a real
device — see the README 后续 section; none of it is in the code.

## Design contract

- Shared session state lives in the project module `store.js` (frames,
  per-frame sizes, shooting seconds, stop reason, target, measured fps).
  Frames exist ONLY in that in-memory store: closing the agent drops them.
  The only persisted data anywhere is work metadata in `av11_works` and the
  settings in `av11_cfg`.
- `pages/index` — beginner settings: only two word choices plus how to shoot.
  Speed words 慢速 5 fps / 中速 8 fps / 快速 12 fps; length words 短 5 s /
  中 10 s / 长 15 s (nominal finished seconds). Target frames are COMPUTED,
  never set directly: `min(fps × nominal seconds, 120)`, and the page shows
  one big human line （中速 · 长 — 拍 120 张，成片约 15 秒） plus, in auto mode,
  the estimated shooting time (target × 2 s) — and when that exceeds the
  3-minute safety cap, the truncated frame estimate (~90) with the same
  stop-reason wording the shoot page uses. Shoot mode: manual (default) or
  auto at a FIXED 2 s per frame; there are no numeric fps/frames/duration/
  interval selectors. Work name by voice (`SpeechRecognition`; final
  transcript sets the name, 「开始」 goes straight to shoot, re-speaking
  corrects). Config persisted to `av11_cfg`.
- `pages/shoot` — `getUserMedia({video:true})` → `ImageCapture.grabFrame()`
  preview loop (~350 ms) on the page canvas (`wx.createCanvasContext`);
  onion skin = previous captured frame's ImageBitmap redrawn with
  `globalAlpha` 0.45 over the live frame. Capture: `grabFrame()` → canvas
  scaled to 480×352 → JPEG (`convertToBlob` q0.6; fallback `createImageBlob`
  unscaled when no canvas jpeg output exists) → data URL + byte size into
  the in-memory store. TTS speaks the count every frame, progress every 10.
  Auto mode captures every 2 s. Shooting stops by itself at the target frame
  count （停因 拍够了） or at 180 s of actual shooting （停因 满 3 分钟了）; manual
  finish is 停因 手动结束. The stop reason is spoken on stop and recorded.
  On finish the page writes the `av11_works` metadata entry (name / fps /
  frames / target / stop reason / shooting seconds / average KB / total KB /
  finished seconds / measured fps = null until the play page fills it).
  `onHide`/`onUnload` stop timers and tracks; returning via navigateBack
  restarts the camera and treats a finished sequence as a retake
  continuation. Nod captures one frame.
- `pages/play` — the composite: frames decoded (data URL → `atob` → `Blob` →
  `createImageBitmap`) and drawn to the page canvas on a `1000/fps`
  interval. The verification panel shows, side by side: set fps vs MEASURED
  fps (computed from actual draw timestamps), frames shot / target, average
  KB per frame, total KB, actual shooting seconds, stop reason, estimated
  finished seconds. Measured fps is written back into the `av11_works`
  entry. Pause/resume, replay, loop toggle, delete-last-frame, back to
  shoot for a retake (clears the stop reason so the shoot page continues
  the same sequence). Nod toggles play/pause.

## Technical honesty

- In-glasses playback is called 合成播放 (composite playback), never
  「生成视频」: this runtime has no documented still-frame video encoder
  (no canvas.captureStream / WebCodecs in the official API reference), and
  v1 does not probe or promise export — that is deferred work.
- 「最长 3 分钟」 is a shooting-time SAFETY cap (180 s), not a finished-film
  length and not a setting. Finished length is frames ÷ fps.
- Frames are never written to storage. If the shared in-memory store does
  not survive page navigation on some host, the play page will honestly
  show 0 frames — that is itself one of the things the verification build
  exists to catch.
- Hosts without camera / ImageCapture / canvas state the gap instead of
  fabricating frames.

## Permissions

- `CAMERA` — grabFrame viewfinder, onion skin and frame capture.
- `RECORD_AUDIO` — voice naming on the settings page (the only ASR in v1);
  TTS itself needs no permission.

## Validation

- Static check pending batch acceptance.
