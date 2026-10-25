# Slow Scan （慢速扫描） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series G15, Group C
(observation/control): a single slow left-to-right head scan.
Extreme simplicity: 3 states only (ready / playing / done),
one page, one main button.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** This game is ONE slow
pass from left to right, never a circle, never a sweep back and
forth, never fast jerking. The whole point is slowness: a fast
pass does not count. Slow, small range, stop at mild stretch,
never pain. Stop at once on pain / dizziness / numbness /
nausea. Sit or stand steady first. One game is a single slow
pass, replayable, short. This is entertainment / daily
activity, NOT medical diagnosis, treatment or a rehab
prescription; people with cervical disease, vertigo, post-op
or head/neck injury history should ask a doctor first. The
short version is on the in-game ready screen; the full text is
here and in the README.

## Design contract

- **One mechanic.** One slow pass, left limit to right limit.
  Flow: (1) calibration (left prompt, as below); (2) START
  POSITION: the player turns to the LEFT limit (yaw past ~27°
  to the left) and holds briefly — voice "先转到最左，停一下";
  (3) SCAN: the player turns slowly and continuously from the
  left limit to the right limit (yaw past ~27° to the right).
- **Completion rule (exact).** The scan counts ONLY if BOTH
  hold: (a) at least 8 seconds from LEAVING the left limit to
  reaching the right limit, AND (b) the player passes through
  center (yaw within ±10°) on the way. The scan clock starts
  when the head leaves the left limit (drops below 22° with
  hysteresis after the hold), NOT at the hold itself — the
  hold is not scan time. A pass that never registers center
  (a jump/teleport in sensor terms) restarts the scan phase.
  Reaching the right limit in under 8 seconds = too fast,
  voice "太快了，回到最左，重新慢扫", and the scan restarts
  (not counted). Reversing direction mid-scan — returning to
  the left limit (past 27° left again) after the scan has
  started — restarts the scan phase with voice "回到最左，
  重新慢扫". A restart returns to the left-limit step only;
  calibration is NOT re-run.
- **Speed warning (documented choice).** While scanning, if
  the instantaneous yaw speed exceeds ~45°/s, TTS warns ONCE
  per scan attempt ("慢一点"). A single fast moment does NOT
  fail the scan — the 8-second rule is the fail condition.
  Rationale: a momentary wobble should not punish an
  otherwise slow pass; the warning is coaching, the clock is
  the judge.
- **No circling past the end.** Reaching the right limit ends
  the scan at once (voice "到了，停"), and any further turning
  after completion is ignored — the tick machine runs only
  while the phase is playing. The player must NOT continue
  past the right limit into a circle.
- **Playing screen shows at most:** a scan progress bar (left
  to right, 20 cells, center = half), one short hint ("慢，
  再慢一点" while scanning), and the current phase (big line)
  plus the elapsed scan seconds. TTS guides: start, the
  left-limit cue, the scan cue, slow-down warnings, and
  completion with total seconds.
- **Calibration is one prompt, inside the playing state (G02's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请向左转一下" as its first
  instruction; whichever yaw sign the head actually moves is
  learned as LEFT, then "回正到中间", then the left-limit
  step. Restarting (tap on done) re-runs calibration.
- **Voice is primary.** Every step is spoken, completion is
  spoken with the total seconds. The screen mirrors the same
  lines plus the bar. TTS uses the fixed host voice; the
  utterance `lang` is never set (documented: it does not take
  effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No shake / turn / tilt gesture events are claimed or used.
  Left/right detection comes from the sensor quaternion, never
  from a gesture event.
- **Thresholds (encoded and documented here):**
  - left/right limit: ~25-30 deg yaw — coded as 27 deg
  - return-to-center / center-pass band: <10 deg
  - hold briefly at the left limit: ~0.8 s (800 ms); backing
    off below 22 deg before the hold aborts the hold, no scan
    starts
  - scan departure: below 22 deg (27 - 5 hysteresis) after
    the hold; this moment starts the 8-second clock
  - minimum scan time: 8000 ms, judged as >= 8000 ms
  - center-pass: |left-yaw| < 10 deg at any tick during the scan
  - reversal: left-yaw >= 27 deg again during the scan
  - speed warning: instantaneous yaw speed > 45 deg/s,
    warned once per scan attempt, never a fail
  - calibration stall re-prompt: 8 s, once per calibration step
- **Yaw formula:** `yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))`
  from the sensor quaternion, in degrees. Only the RELATIVE yaw vs
  the calibrated center is used, so the host's absolute zero never
  matters.
- **Yaw sign — learned, not assumed (device verification item).**
  The one-prompt calibration records the sign the head actually
  moves when asked to turn left, so a host yaw-sign inversion cannot
  silently swap left/right — unlike G01's documented
  down-sign assumption, which G15 does not need. Residual caveat:
  calibration trusts the player to follow that one prompt; turning
  right instead of left would learn the signs backwards. Fail-safe:
  nothing counts before calibration completes, and any restart
  re-runs calibration. The device checklist must confirm:
  (1) the calibration prompt appears and completes on a real left
  turn, (2) a real left turn then counts as left, not right,
  (3) a deliberately fast pass (under 8 s) is rejected and
  restarts, and (4) a deliberately slow pass (over 8 s through
  center) completes and reports its seconds.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo stepper (calibration steps, then
  to the left limit, then one tap per third of the scan, completing
  at a labeled fixed 9.6 s) so the playing and done states can be
  previewed. On a real device with a sensor there is no DEMO path
  at all, and the done screen says 「演示慢扫完成」 only when demo
  steps were used.
- **Zero persistence by construction:** no storage calls anywhere;
  center, learned sign, scan time and warning flag live in page
  memory and die with the page.
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
  invented APIs; no head-gesture handler (the API documents only
  'nod', which is not this game's action); permissions match the
  features actually used (empty, matching zero permission-gated
  features).
- Logic harness (20 checks, all passing): constants read from the
  real .ink file; slow 9 s / 12 s passes, exactly 8 s passes,
  7.9 s and 5 s too fast, teleport without center restarts,
  return to the left limit mid-scan restarts, a fast moment warns
  but a slow pass still passes, exactly 45 deg/s does not warn,
  incomplete scan is not a pass, progress-bar endpoints and
  clamping, 20-cell bar half-filled at center, hold abort below
  22 deg, left-sign learning, done ignores further turning, no
  gesture handler, no legacy usage.
- Preview screenshots in `screenshots/slow-scan/` (ready / playing /
  done), generated with the local Ink runtime pipeline and read back
  to confirm each shows its own state.
