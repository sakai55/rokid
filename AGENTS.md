# Find Target （找方向） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA13, opening Group C
(observation/control: head-steady = confirm): a find-the-
direction game. Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

Distinct from GA05/GA10/GA12: GA05 follows clock-position cues in
sequence, GA10 follows a VISUAL dot, GA12 replays a sequence from
memory. This game is a SINGLE voice cue per trial, confirmed by
head-steady: the cue names ONE direction, the player finds it,
holds steady, returns — nothing to follow, nothing to remember.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
trial. The cue NEVER asks for a sweep or a circle: one direction
per trial, found, returned from, and only then is the next cue
announced. Never sweep from one extreme to another, never fast
jerking. Slow, small range, stop at mild stretch, never pain.
For UP specifically: only to a mild stretch, NEVER hyperextend,
NEVER throw the head back — this is said in the voice guidance,
not just on screen. Stop at once on pain / dizziness / numbness
/ nausea. Sit or stand steady first. One round set is 8 trials,
short. This is entertainment / daily activity, NOT medical
diagnosis, treatment or a rehab prescription; people with
cervical disease, vertigo, post-op or head/neck injury history
should ask a doctor first. The short version is on the in-game
ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 8 trials, one at a time. Per trial: TTS cues
  one direction ("请看向左") and the screen shows the same
  direction arrow (← / ↓ / → / ↑) plus the word. Turning to
  the direction and holding ~0.8 s = found (+1, voice
  "找到了"). Turning to a WRONG direction past threshold =
  miss for that trial at once (voice "不是这个方向").
  No correct direction within 4 seconds = miss (voice
  "没找到"). A find that backs off before the hold is aborted
  with no count; the 4-second trial clock keeps running, so a
  stalled trial still ends as a miss.
- **Fixed cue sequence (NOT random, so preview and device
  behaviour are reproducible):** left, down, right, up, right,
  left, up, down (trials 1–8). Documented here and in the code
  (`SEQ`). It contains NO clockwise run of adjacent steps —
  no up->right->down, right->down->left, down->left->up or
  left->up->right triple — and every trial is separated by a
  return to center, so no circling arises in either direction.
- **Return-to-center gates every next cue.** After every trial
  (found or miss) the player MUST return to center (<10 deg on
  BOTH axes) before the next cue is announced. If not returned
  within 4 seconds, TTS prompts "请回正" and the grace timer
  resets — the grace counts nothing and the next cue is NEVER
  announced until the return actually happens. This is GA10's
  stricter rule, deliberately NOT GA09's advance-anyway grace:
  the return rule is what keeps this game segmented, not a
  sweep. The final trial ends the game at once: there is no
  next trial for a return to gate.
- **Calibration is two prompts, inside the playing state (GA05's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请低一下头" as its first
  instruction, then "回正到中间", then "请向左转一下", then
  "回正到中间", then trial 1. Nothing counts before BOTH
  calibrations complete; restarting (tap on done) re-runs both.
- **Voice is primary.** Every trial is announced, every outcome
  is spoken (found / wrong-direction / timeout miss),
  completion is spoken. The screen mirrors the same lines. TTS
  uses the fixed host voice; the utterance `lang` is never set
  (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the cued direction (big
  arrow + word), trials found x/8, and one short hint.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Directions come from the sensor quaternion, never from a
  gesture event.
- **Thresholds (encoded and documented here):**
  - direction reached: ~25-30 deg (pitch for up/down, yaw for
    left/right) — coded as 27 deg
  - return-to-center: <10 deg on BOTH axes (pitch and yaw), so
    a return counts only when the head is genuinely straight
    again
  - hold: ~0.8 s (800 ms); the hold accumulates only while
    steady where the host reports stability events via
    `onOrientationStabilityChange`; if the host never reports
    them, elapsed time alone gates the hold (documented
    fallback, not a fake stable)
  - trial clock: 4 s, no correct direction = miss
  - return grace: 4 s, then TTS "请回正" and the timer resets;
    the next cue is never announced until the return happens
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent, GA05's):**
  - pitch = asin(2*(w*x - y*z)), clamped
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
  - Only the RELATIVE pitch/yaw vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Sign learning — two axes, both learned, neither assumed
  (device verification items).**
  - DOWN: the first calibration prompt records the sign the
    head actually moves when asked to look down as DOWN; UP is
    the opposite pitch sign (GA01/GA04 pattern).
  - LEFT: the second calibration prompt records the sign the
    head actually moves when asked to turn left as LEFT; RIGHT
    is the opposite yaw sign (GA02 pattern).
  - Residual caveats: calibration trusts the player to follow
    each prompt; looking up instead of down would learn the
    pitch signs backwards, and turning right instead of left
    would learn the yaw signs backwards. Fail-safes: nothing
    counts before both calibrations complete, the first cue is
    left and the second is down, so a backwards calibration
    feels wrong at once, and any restart re-runs both prompts.
    The device checklist must confirm: (1) both calibration
    prompts appear and complete on a real look-down and a real
    left turn, (2) a real look-down then counts as down, not
    up, and a real look-up counts as up, not down, (3) a real
    left turn then counts as left, not right, and a real right
    turn counts as right, not left, (4) returning to center
    between trials is required — the next cue never appears
    before the return, and a 4-second non-return produces a
    spoken "请回正" with no advance.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole trial as a find, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示找到 x / 8」 only when demo
  trials were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, trial, center and learned signs live in page memory
  and die with the page.
- **No camera, no mic/ASR, no network, no LLM.** Nothing to SKIP.

## Permissions

None — `permissions` is an empty array. Sensor and TTS are not
among the only three permissions (`GEOLOCATION`, `CAMERA`,
`RECORD_AUDIO`), and the code uses neither of those three
features, so nothing is declared. Verified by a successful
empty-permissions pack (see README).

## Validation

- Static check: app.json parses; `<script setup>` and app.js
  pass `node --check`; no `Page(`/`App(`/`Widget(` legacy
  usage; no invented APIs; no head-gesture handler (the API
  documents only 'nod', which is not this game's action);
  permissions match the features actually used (empty, matching
  zero permission-gated features).
- Logic harness (36 checks, all passing): down/left sign
  learning, calibration returns, trial cues in fixed order,
  0.8 s hold finding a trial, early release returning to wait
  with no count, wrong direction failing the trial at once,
  4 s timeout missing the trial, return grace re-prompting
  "请回正" with no advance until a real return, full 8-trial
  run ending at 6/8 with 2 misses, restart re-running both
  calibrations, inverted-sign host still counting left as left.
- Preview screenshots in `screenshots/find-target/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
