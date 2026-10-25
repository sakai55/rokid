# Nod Count （点头操） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA01: a slow nod-count exercise, voice
guided. Extreme simplicity: 3 states only (ready / playing / done),
one page, one main button.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
direction. Never continuous circling, never sweep from one extreme
to another, never fast jerking. Slow, small range, stop at mild
stretch, never pain. Stop at once on pain / dizziness / numbness /
nausea. Sit or stand steady first. One round is 60-180 s. This is
entertainment / daily activity, NOT medical diagnosis, treatment or
a rehab prescription; people with cervical disease, vertigo, post-op
or head/neck injury history should ask a doctor first. The short
version is on the in-game ready screen; the full text is here and
in the README.

## Design contract

- **One mechanic.** 10 slow nods. START calibrates the center (head
  straight at START). Each rep: pitch down past threshold, hold
  ~0.8 s, return to center = 1 rep, spoken by TTS. 10 reps = done
  state with score 10/10 and 「再来一局」 (tap restarts and
  recalibrates the center).
- **A rep counts only as down -> hold -> return-to-center.** A down
  motion that backs off before the hold is aborted with no count. A
  `onHeadGesture('nod')` event on its own never counts and never
  double-counts: it only completes a rep the sensor already saw go
  down, once the head is back inside the center band; in `wait` it
  is ignored.
- **Stall = one re-prompt, never an auto-count.** If a rep stays in
  `down` or `held` longer than 8 s without returning, TTS says
  「慢慢回正到中间」 exactly once per rep; the count never moves
  on its own.
- **Voice is primary.** Every step is spoken (「低头，停，回正」),
  every rep is counted aloud, completion is spoken. The screen
  mirrors the same lines. TTS uses the fixed host voice; the
  utterance `lang` is never set (documented: it does not take
  effect).
- **Gestures:** single tap = Enter = start / re-speak instruction /
  play again; nod = the game action itself; double-tap = host back,
  never intercepted; no swipe handling, no other buttons.
- **Wrong direction is corrected, not counted.** An up-tilt past
  the down threshold magnitude shows 「抬头了？请低头，不是抬头」
  and counts nothing.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  No shake / turn / tilt gesture events are claimed or used.
  Left/right/up/down/tilt detection comes from the sensor
  quaternion, never from a gesture event.
- **Thresholds (encoded and documented here):**
  - direction reached: ~25-30 deg pitch down — coded as 27 deg
  - return-to-center: <10 deg
  - hold-steady: ~0.8 s (800 ms), gated on
    `onOrientationStabilityChange` stable where the host reports
    stability events; if the host never reports them, elapsed time
    alone gates the hold (documented fallback, not a fake stable)
  - rep-stall re-prompt: 8 s, once per rep
- **Pitch formula** (fleet-consistent with the glasses-benchmark
  guided-interaction test): `pitch = asin(2*(w*x - y*z))` from the
  sensor quaternion, clamped to [-1, 1]. Only the RELATIVE pitch
  vs the calibrated center is used, so the host's absolute zero
  never matters.
- **DOWN-SIGN ASSUMPTION — device verification item.** Head-down is
  taken as negative relative pitch. If the first device test shows
  the sign inverted, flip the comparison in `_tick` (the game
  already refuses to count an up-tilt, so an inversion fails safe
  as "no count + wrong-direction hint", never as a wrong count).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled 「演示点头一次」 stepper so the playing
  and done states can be previewed. On a real device with a sensor
  there is no DEMO path at all, and the done screen says
  「演示完成」 only when demo reps were used.
- **Zero persistence by construction:** no storage calls anywhere;
  count and calibration live in page memory and die with the page.
- **No camera, no mic/ASR, no network, no LLM.** Nothing to SKIP.

## Permissions

None — `permissions` is an empty array. Sensor and TTS are not
among the only three permissions (`GEOLOCATION`, `CAMERA`,
`RECORD_AUDIO`), and the code uses neither of those three features,
so nothing is declared. Verified by a successful empty-permissions
pack (see README).

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used
  (empty, matching zero permission-gated features).
- Preview screenshots in `screenshots/nod-count/` (ready / playing /
  done), generated with the local Ink runtime pipeline and read back
  to confirm each shows its own state.
