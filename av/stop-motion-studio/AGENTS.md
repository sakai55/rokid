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

## Permissions

- `CAMERA` — grabFrame viewfinder, onion skin and frame capture.
- `RECORD_AUDIO` — the 「退出」 exit-word listening while shooting (the
  only ASR in this agent); TTS itself needs no permission.

## Validation

- Static check pending batch acceptance.
