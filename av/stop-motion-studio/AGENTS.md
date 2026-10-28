# Stop Motion Studio — Design Contract

v1.1 is a MINIMAL verification build (GO 2026-10-28 22:15): operations were
cut to exactly two — nod to start, say 「退出」 to finish and composite. Only
the core chain 逐帧拍 → 合成播放 is built; everything deeper stays deferred
until the core chain passes on a real device (README 后续 section).

v1.1.1 is the DIAGNOSTIC hardening of that build (GO real-device report
2026-10-28 23:12: nod fired, start TTS played, zero frames captured). The
fault domain is the capture chain after `_begin`, including the shape where
an encode promise never settles (hang): `_busy` stayed true forever, every
later tick was skipped, no error, frames stuck at 0. v1.1.1 exists to make
that class of failure impossible to hide and possible to route around.

## Design contract

- Shared session state lives in the project module `store.js` (frames,
  per-frame sizes, frame mode, first encode error, start channel, shooting
  seconds, stop reason, target, measured fps). Frames exist ONLY in that
  in-memory store: closing the agent drops them. The only persisted data
  anywhere is work metadata in `av11_works` (which now also carries `mode`,
  `encodeError` and `startVia` — the diagnostics a real-device run must
  bring back). There are NO settings and no `av11_cfg` (deleted with the
  settings page in v1.1; zero references).
- Fixed constants (shoot page, not settings): playback FPS 12, target
  120 frames (= 12 × 10 s of film), capture interval 1000 ms, shooting
  safety cap 180 s, encode timeout 600 ms, busy watchdog 2500 ms. The
  shoot page carries one small line stating them: 「12 帧/秒 · 满 120 张
  约 10 秒 · 点头或单击开始 · 说退出合成」.
- `pages/shoot` (ENTRY page) — opens straight into `getUserMedia({video:true})`
  → `ImageCapture.grabFrame()` preview (~350 ms, WAITING state only) on the
  page canvas (`wx.createCanvasContext`); onion skin = previous captured
  frame's ImageBitmap redrawn with `globalAlpha` 0.45 over the live frame
  (none before the first frame).
- **Start is dual-channel (diagnostic, v1.1.1)**: `onHeadGesture('nod')`
  starts the take, and so does a temple single-tap (`Enter` key). Which
  channel fired is recorded (`store.startVia`) and written into the work
  metadata. Reading the result: tap starts but nod does not = gesture
  channel problem; either starts but frames stay 0 = frame-chain problem.
  Starting also STOPS the preview timer — preview and capture never both
  call grabFrame; while shooting, the view is maintained by drawing each
  captured frame (plus onion) as it lands.
- **Graded capture (v1.1.1)** — `_capture` per frame: `grabFrame()` →
  draw live+onion → encode path first while mode is undecided/url:
  canvas scaled to 480×352 → JPEG (`convertToBlob` q0.6; fallback
  `createImageBlob`; `toDataURL` inside the canvas branch) → FileReader
  data URL + real byte size, stored as `{kind:'url', url}`. The WHOLE
  encode call races a **600 ms timeout** (`_raceTimeout` around
  `_encodeFrame`): a rejection OR a timeout records the first error
  verbatim into `store.encodeError`, latches `store.mode='memory'` for
  the rest of the take, announces 「编码不可用，已切内存帧模式」 on a big
  line + TTS, drops the effective target to **40 frames**, and saves THAT
  frame bitmap-direct: canvas `getImageData` pixels as `{kind:'px', img}`
  (typeof-checked), or the `ImageBitmap` itself as `{kind:'bmp', bmp}`
  (never closed while stored). In memory mode `_capture` never touches
  an encoding API again. Byte sizes for bitmap frames are ESTIMATES
  (w×h×4) and are labelled as such on the play page.
- **Busy watchdog (v1.1.1)**: the 500 ms elapsed timer checks the capture
  busy flag; a frame in flight longer than 2500 ms is force-released and
  counted as one failure, so no hung link can block the take forever.
- **Failure visibility (v1.1.1)**: a failed frame increments a visible
  「失败 N 次 · 最近：<error, 40 chars>」 line next to the counter; the
  first failure speaks 「拍帧失败」 once. If the take is 5 s in with 0
  frames, the hint line shows a specific diagnosis distinguishing
  「编码超时/失败已切内存帧」 / 「grabFrame 失败：<原文>」 /
  「编码失败：<原文>」 / camera-not-ready / watchdog-reset.
- Big readout: frames shot / effective target and estimated film seconds
  (frames ÷ 12). While shooting, a nod does NOTHING (speech moves the
  head; never let it alter the take). While shooting, `SpeechRecognition`
  (continuous, interimResults) listens for 「退出」 in any result (final
  or interim): a hit finishes the take. ASR start failure or error shows
  「语音退出不可用，请用双击结束」 and double-tap (Backspace) takes the
  same finish path — fallback only, not a third regular operation. Four
  finish conditions, all recorded as the stop reason: voice / target
  (120 frames, or 40 in memory mode) / time (180 s) / back (double-tap).
  TTS speaks at: start （开始拍摄，说退出结束合成）, halfway （已拍一半）,
  the finish line carrying the stop reason — plus, new in v1.1.1, the
  one-time mode-switch notice and the one-time first-failure notice.
  On finish: stop ASR, timers and tracks, write the `av11_works` metadata
  entry (fps / frames / target / mode / encodeError / startVia / stop
  reason / shooting seconds / average KB / total KB / film seconds /
  measured fps = null until play fills it), then navigate to the play
  page. `onHide`/`onUnload` stop everything; entering the page always
  starts a fresh sequence (resetSession).
- `pages/play` — entering starts looped composite playback at 12 fps
  immediately, drawing each frame by kind: `url` → data URL decoded via
  `atob` → `Blob` → `createImageBitmap`; `px` → `putImageData` onto an
  offscreen 480×352 canvas, then `drawImage` (Canvas is a documented
  drawImage source) scaled to the stage; `bmp` → `drawImage` directly.
  Replay from frame 0 is dual-channel too: nod or single-tap (`Enter`);
  there are no menus or switches. The verification panel shows: set fps
  (12) vs MEASURED fps (actual draw timestamps), frames shot / effective
  target, actual film seconds (frames ÷ 12), average KB per frame, total
  KB (both labelled 估算 in memory mode), actual shooting seconds, stop
  reason, frame mode (dataURL / 内存帧） and the first encode error.
  Measured fps is written back into the `av11_works` entry on hide/unload.

## Technical honesty

- In-glasses playback is called 合成播放 (composite playback), never
  「生成视频」: this runtime has no documented still-frame video encoder
  (no canvas.captureStream / WebCodecs in the official API reference), and
  this build does not probe or promise export — that is deferred work.
- 「最长 3 分钟」 is a shooting-time SAFETY cap (180 s), not a finished-film
  length and not a setting. Finished length is frames ÷ 12 fps.
- Frames are never written to storage. If the shared in-memory store does
  not survive page navigation on some host, the play page will honestly
  show 0 frames — one of the things this verification build exists to catch.
- Hosts without camera / ImageCapture / canvas / ASR state the gap instead
  of fabricating frames or pretending the voice exit works. A host whose
  JPEG encoder rejects or hangs is no longer a dead end: the take routes
  into bitmap mode and says so, big, on screen and in the metadata.

## v1.1.2 addendum (device-proven root cause + fleet error codes)

- The Ink runtime has NO FileReader (device-proven 2026-10-28, v1.1.0
  died every frame at Blob→dataURL). FileReader must never appear in
  this project again — Blob→dataURL goes through `blob.arrayBuffer()`
  + chunked `btoa` only, still inside the 600 ms timeout breaker.
- Every failure point maps to a fleet error code, defined ONCE in
  `err.js`. Display/TTS/`lastError` use the code as-is. Canonical
  table: repo-root `ERROR-CODES.md`; the project `ERROR-CODES.md`
  is an AV11 excerpt. Same-code repeats only bump a ×N counter; the
  latest code + raw text lands in `av11_works` metadata as
  `lastError`.
- Fast fail: 10 consecutive frame failures stop the take on the shoot
  page (E2010 shown, TTS speaks just the code) — never grind to the
  180 s cap again. A take ending with 0 frames shows E4001 and stays
  on the shoot page; it never navigates to an empty play page.

## v1.1.3 addendum (error-code form finalised: bare codes only)

- GO's final ruling (2026-10-28 23:37, fleet table v1.4.0): the ONLY
  error-code form is the bare code `E####` — the numeric segment is
  unique fleet-wide, so no prefix is carried in code definitions,
  display, TTS or `lastError`. `err.js` defines the 34 codes as bare
  literals (the prefix-concatenation layer is deleted) and self-checks
  the bare shape at load. v1.1.3 changes nothing else: capture chain,
  breakers, fallbacks and behaviour are byte-identical to v1.1.2 apart
  from the code strings.

## v1.2.0 addendum (diagnostic log return pilot)

- A log client exists: `logq.js` at the project root. It queues runtime
  events in `localStorage` under `av11_logq` (cap 100, oldest dropped)
  and POSTs batches (≤50 events, grouped by the session that recorded
  them) to the front door's /log endpoint with the `x-channel-key`
  header, using `fetch` (documented in the web API reference — the same
  form the fleet's channel client uses). Config (endpoint + key) lives
  ONLY at the top of logq.js; the repo stores the placeholder
  `PASTE_CHANNEL_KEY_HERE`, and while the key is the placeholder the
  client is a complete no-op (no sends, no storage touched) — that is
  also the review build's off state.
- Flush points are exactly three: take finish (shoot page `_finish` /
  `_autoStop`), play-page entry (`onLoad`), and next launch (app.js
  `onLaunch` → `initLog`, which drains the previous run's leftover
  queue under its own session before opening the new session and
  logging `start`).
- Event set: start (raw = version), begin (raw = start channel
  nod/tap), frame0, mode (raw = dataURL | frame, at latch time), a
  mirror of EVERY `_recordErr` call (step 'fail', same code, same raw
  text), finish (raw = stop reason + frame count), play (raw = first
  measured fps). Failure points therefore reach the stream through the
  `_recordErr` funnel automatically — that funnel was already the only
  legal way to surface a failure (error-code protocol), and it stays
  so.
- The client must never throw or block: all exports are try/catch
  wrapped, sends are fire-and-forget, failed sends keep the queue for
  the next flush point. Privacy: no photo data, no recognised speech
  text; raw is truncated to 200 chars and a raw starting with 'data:'
  is dropped outright.
- Persisted data in this agent is now `av11_works` metadata plus this
  diagnostic queue (`av11_logq`); frames still live only in the
  in-memory store.

## Permissions

- `CAMERA` — grabFrame viewfinder, onion skin and frame capture.
- `RECORD_AUDIO` — the 「退出」 exit-word listening while shooting (the
  only ASR in this agent); TTS itself needs no permission.

## Validation

- Static check pending batch acceptance.
