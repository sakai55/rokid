# Motion Frame Watch — Design Contract

## Design contract

- `pages/index` — hub menu: threshold row (2% / 5% / 10%, Arrow keys select the row, Enter cycles), baseline calibration, watch and log entries. Calibration: `getUserMedia` → `ImageCapture.grabFrame()` → document canvas downsample to 64×48 → `getImageData` luminance array persisted to wx storage `av02_baseline` together with the threshold.
- `pages/watch` — `setInterval` ~1200 ms sampling with the same grabFrame pipeline; per-pixel luminance difference (>24 counts as changed); live difference %, sample count and measured interval (Date.now delta) are shown. Foreground only: `onHide`/`onUnload` clear the interval and stop tracks. Over threshold: stop, persist `av02_alert`, navigate to proof.
- `pages/proof` — `takePhoto({mode:'default'})` proof photo held in memory only (byte size shown, never persisted); `LanguageModel` multi-modal prompt returns one change sentence (unavailable is labelled, never invented); spoken alert on entry; Enter or nod writes `{time, diff, desc}` to `av02_log` and navigates to log.
- `pages/log` — reads `av02_log`, latest 8 plus count/max settlement, speak selected, clear.

## Technical honesty

- No published grabFrame frame-rate cap exists; the page reports only the locally measured interval and says so.
- No background watching: leaving the watch page stops sampling, and the UI states this.
- The proof photo is never written to storage; only time, difference % and the text description are logged.
- All camera/LLM calls are guarded; a host without them states the gap instead of fabricating a baseline or a difference.

## Permissions

- `CAMERA` — baseline frame, watch sampling, proof photo. No audio permission: this agent has no ASR input by design.

## Validation

- Static check pending batch acceptance.
