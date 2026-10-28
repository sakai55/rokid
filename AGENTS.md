# AV Sync Check — Agent Notes

AV09, boundary B9 (audio and video sampled together).

## Design contract

- Dual-track gate (index): one `getUserMedia({video:true, audio:true})` stream, device enumeration, supported constraints, and per-track `getSettings()` read-back; live RMS and grabFrame liveness indicators; stopping stops tracks and clears the timer.
- Sync events (sync): the page opens its own stream, samples about every 100ms into a 30-sample ring buffer (time / brightness / RMS), and times three user-marked claps against the audio peak and the brightness-step peak.
- Judge (judge): fixed thresholds displayed on screen — fps estimate, max frame gap, RMS mean, |delta median| — each pass/fail plus an overall verdict, filed to `av09_reports`.
- History (history): persistent report list with read-back and clear.

## Technical honesty

- Delta is a JS-clock estimate from one sampling buffer, never hardware sync; the sampling interval bounds its precision and the UI says so.
- Streams are never shared across pages; each page opens and closes its own, and the judge consumes only the sync page's stream data (handed over via the temp key `av09_tmp`).
- Frame rate is derived from the median frame gap; RMS is a relative level, not a sound-pressure reading. Missing peaks are recorded as "no peak detected", never interpolated.
- TTS never sets utterance `lang`.

## Permissions

`CAMERA` (video track and grabFrame brightness) and `RECORD_AUDIO` (audio track analysis), exactly as declared in app.json.

## Validation

- Static: JSON parse of app.json/package.json; `node --check` on every extracted setup script; green-only palette scan.
- Device stage (pending): confirm grabFrame brightness sampling cadence, Analyser RMS behaviour, and delta repeatability for real claps.
