# Chunk Rec Studio — Design Contract

## Design contract

- `pages/index` — probe page and hub: `MediaRecorder.isTypeSupported` for `video/mp4`, `video/webm;codecs=vp8,opus`, `audio/ogg;codecs=opus`, `audio/wav`; `getUserMedia({video:true,audio:true})` then track `getSettings()` readback and `getSupportedConstraints()` field list; supported video formats are cyclable from the first menu row (Enter) and persist to wx storage `av03_pick`.
- `pages/record` — durations 30/60/120 s by tap plus a voice-set duration via `SpeechRecognition` number parsing (re-say to correct); `MediaRecorder.start(1000)` chunking with `ondataavailable` chunk/byte counters, `pause()`/`resume()`, a per-second tick that speaks elapsed seconds and MB/min every 10 s, and automatic stop at the target; result persists to `av03_last`.
- `pages/settle` — chunk count, total bytes, duration, MB/min and a time-cap estimate whose basis is stated on the page (measured MB/min × an assumed 8 GB free space, an assumption, not a measurement); Enter or nod appends to `av03_sessions`.
- `pages/history` — reads `av03_sessions`, latest 8 plus grand totals, speak selected, clear.

## Technical honesty

- Playback is an explicit placeholder: the record page states "录后回放待真机验证（placeholder）" and the agent never claims it can play a recording back.
- Unsupported mime types are listed as unsupported; with no supported video format the record page falls back to the host default and reports failures verbatim.
- The storage-time cap is an estimate on a stated assumption, never presented as measured free space.

## Permissions

- `CAMERA` — video track for recording and probe readback. `RECORD_AUDIO` — audio track and voice-set duration input.

## Validation

- Static check pending batch acceptance.
