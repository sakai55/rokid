# Stop Motion Studio — Design Contract

v1.1 is a MINIMAL verification build (GO 2026-10-28 22:15): operations were
cut to exactly two — nod to start, say 「退出」 to finish and composite. Only
the core chain 逐帧拍 → 合成播放 is built; everything deeper stays deferred
until the core chain passes on a real device (README 后续 section).

## Design contract

- Shared session state lives in the project module `store.js` (frames,
  per-frame sizes, shooting seconds, stop reason, target, measured fps).
  Frames exist ONLY in that in-memory store: closing the agent drops them.
  The only persisted data anywhere is work metadata in `av11_works`.
  There are NO settings and no `av11_cfg` (deleted with the settings page
  in v1.1; zero references).
- Fixed constants (shoot page, not settings): playback FPS 12, target
  120 frames (= 12 × 10 s of film), capture interval 1000 ms, shooting
  safety cap 180 s. The shoot page carries one small line stating them:
  「12 帧/秒 · 满 120 张约 10 秒 · 点头开始 · 说退出合成」.
- `pages/shoot` (ENTRY page) — opens straight into `getUserMedia({video:true})`
  → `ImageCapture.grabFrame()` preview (~350 ms) on the page canvas
  (`wx.createCanvasContext`); onion skin = previous captured frame's
  ImageBitmap redrawn with `globalAlpha` 0.45 over the live frame (none
  before the first frame). Waiting state: `onHeadGesture('nod')` starts
  auto-capture — every 1000 ms `grabFrame()` → canvas scaled to 480×352 →
  JPEG (`convertToBlob` q0.6; fallback `createImageBlob`) → data URL + byte
  size into the in-memory store. Big readout: frames shot / 120 and
  estimated film seconds (frames ÷ 12). While shooting, a nod does NOTHING
  (speech moves the head; never let it alter the take). While shooting,
  `SpeechRecognition` (continuous, interimResults) listens for 「退出」 in
  any result (final or interim): a hit finishes the take. ASR start failure
  or error shows 「语音退出不可用，请用双击结束」 and double-tap
  (Backspace) takes the same finish path — fallback only, not a third
  regular operation. Four finish conditions, all recorded as the stop
  reason: voice / target (120 frames) / time (180 s) / back (double-tap).
  TTS speaks at exactly three moments: start （开始拍摄，说退出结束合成）,
  60 frames （已拍一半）, and the finish line carrying the stop reason.
  On finish: stop ASR, timers and tracks, write the `av11_works` metadata
  entry (fps / frames / target / stop reason / shooting seconds / average
  KB / total KB / film seconds / measured fps = null until play fills it),
  then navigate to the play page. `onHide`/`onUnload` stop everything;
  entering the page always starts a fresh sequence (resetSession).
- `pages/play` — entering starts looped composite playback at 12 fps
  immediately: frames decoded (data URL → `atob` → `Blob` →
  `createImageBitmap`) and drawn on a `1000/12` interval, wrapping at the
  end. `onHeadGesture('nod')` restarts from frame 0 — the only operation
  on this page; there are no menus, keys or switches. The verification
  panel shows: set fps (12) vs MEASURED fps (actual draw timestamps),
  frames shot / 120, actual film seconds (frames ÷ 12), average KB per
  frame, total KB, actual shooting seconds, stop reason. Measured fps is
  written back into the `av11_works` entry on hide/unload.

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
  of fabricating frames or pretending the voice exit works.

## Permissions

- `CAMERA` — grabFrame viewfinder, onion skin and frame capture.
- `RECORD_AUDIO` — the 「退出」 exit-word listening while shooting (the
  only ASR in v1.1); TTS itself needs no permission.

## Validation

- Static check pending batch acceptance.
