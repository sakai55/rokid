# Hotword Forge — Agent Notes

AV05 (audio/video boundary series). One scene: before a hands-busy warehouse stocktake, the wearer forges recognition hotwords and segmentation settings against the real host capabilities, tests them live, and settles per-word hit counts.

## Design contract

- Capability gate first (index): `SpeechRecognitionSession.getCapabilities()` is read back field by field; any unsupported item disables its forge control on the spot, and a missing API blocks the forge entirely.
- Forge (forge): 12 warehouse words, multi-select hotwords with fixed boost +5 shown; VAD silence steps only inside the host `vadSilenceDuration` range; segmentation only among host-listed modes; a 4-line stocktaking dialogue is stored for `updateContext` injection on the test page.
- Test (test): mime is the intersection of host `audioFormats` and `MediaRecorder.isTypeSupported`; `MediaRecorder.start(250)` chunks are written through a serial Promise chain into `session.audio.getWriter()`; interim results render live, finals accumulate and are counted per hotword.
- Settle (settle): last-test hits, weak words (0 hits), config recap, and a cross-session cumulative board persisted in wx storage `av05_hits` (merged only on explicit settle, never double-counted).
- Page-to-page handoff uses wx storage temp keys `av05_caps_tmp` / `av05_cfg_tmp` / `av05_last_tmp`; these are handoff only, not persistence claims.

## Technical honesty

- Every hardware/API call is guarded (`typeof` + try/catch). On a host without the session API (including Web preview) pages still render and state the gap plainly; no fake capabilities, hits, or transcripts are ever shown.
- Caps fields the host omits are shown as "host did not provide" and the matching control is closed, not defaulted silently.
- TTS goes through `speechSynthesis.speak(..., 'immediate')`; the utterance `lang` attribute is never set (documented as not taking effect).

## Permissions

`RECORD_AUDIO` only: the test page records the wearer's own voice for the recognition session. No camera, no location.

## Validation

Static check pending batch acceptance: JSON parse of app.json/package.json, `node --check` on every extracted `<script setup>`, green-only palette scan, and API-wiring grep (getCapabilities / updateContext / getWriter / start(250)) to be run by the batch acceptance pass.
