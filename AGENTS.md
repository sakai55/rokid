# Angle Match （对角度） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA21, opening Wave 2, Group E
(precision control): an angle-matching game. Extreme simplicity:
3 states only (ready / playing / done), one page, one main button.

Distinct from GA13 (find-target): GA13 only judged REACHING a
direction at ~27 deg — any turn past the threshold counted. This
game judges ANGLE PRECISION against called targets: the turn must
LAND in the called band (15 or 30 deg, +/-5 deg) and hold there.
Overshooting a 15 deg target out to 30 deg is NOT a hit; the
player must settle back into the band, and leaving the band
resets the hold.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
trial. The call NEVER asks for a sweep or a circle: one side and
one angle per trial, matched, returned from, and only then is
the next call announced. Never sweep from one extreme to
another, never fast jerking. Slow, small range, stop at mild
stretch, never pain. Stop at once on pain / dizziness /
numbness / nausea. Sit or stand steady first. One round set is
8 trials, short. This is entertainment / daily activity, NOT
medical diagnosis, treatment or a rehab prescription; people
with cervical disease, vertigo, post-op or head/neck injury
history should ask a doctor first. The short version is on the
in-game ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 8 trials, one at a time. Per trial: TTS calls
  one side and one angle ("向左，15 度") and the screen shows the
  same call (arrow + side + degrees). Turning so the relative
  yaw enters the target band (target +/-5 deg) speaks "停，稳住"
  once; holding steady ~0.8 s inside the band = hit (+1, voice
  "对上了"). Leaving the band before the hold completes —
  backing off OR overshooting — resets the hold to zero and
  counts nothing; the 10-second trial clock keeps running, so a
  stalled trial still ends as a miss.
- **Fixed trial list (NOT random, so preview and device
  behaviour are reproducible):** (left, 15°), (right, 30°),
  (right, 15°), (left, 30°), (left, 15°), (right, 15°),
  (left, 30°), (right, 30°). Documented here and in the code
  (`TRIALS`). Every trial is separated by a return to center, so
  no circling arises.
- **Miss rules.** Turning to the WRONG side past 27 deg = miss
  for that trial at once (voice "没对上"). No hit within
  10 seconds = miss (voice "没对上"), including a hold that is
  still incomplete when the clock runs out.
- **Return-to-center gates every next call.** After every trial
  (hit or miss) the player MUST return to center (<10 deg on
  BOTH axes, pitch and yaw) before the next call is announced.
  If not returned within 4 seconds, TTS prompts "请回正" and the
  grace timer resets — the grace counts nothing and the next
  call is NEVER announced until the return actually happens.
  This is GA10/GA13's stricter rule, deliberately NOT GA09's
  advance-anyway grace: the return rule is what keeps this game
  segmented, not a sweep. The final trial ends the game at
  once: there is no next trial for a return to gate.
- **Calibration is one prompt, inside the playing state (GA02's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then the
  playing screen shows "请向左转一下" as its first instruction,
  then "回正到中间", then trial 1. Nothing counts before
  calibration completes; restarting (tap on done) re-runs it.
- **Voice is primary.** Every trial is announced, band entry is
  spoken ("停，稳住"), every outcome is spoken (hit / miss),
  completion is spoken. The screen mirrors the same lines. TTS
  uses the fixed host voice; the utterance `lang` is never set
  (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the target call (arrow +
  side + degrees), hits x/8, and one short hint.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Angles come from the sensor quaternion, never from a gesture
  event.
- **Thresholds (encoded and documented here):**
  - target band: called angle +/-5 deg (15 deg targets judge
    10-20 deg, 30 deg targets judge 25-35 deg)
  - hold: ~0.8 s (800 ms) inside the band; the hold accumulates
    only while steady where the host reports stability events
    via `onOrientationStabilityChange`; if the host never
    reports them, elapsed time alone gates the hold (documented
    fallback, not a fake stable)
  - wrong side: past 27 deg toward the uncalled side = miss at
    once
  - trial clock: 10 s, no hit = miss
  - return-to-center: <10 deg on BOTH axes (pitch and yaw)
  - return grace: 4 s, then TTS "请回正" and the timer resets;
    the next call is never announced until the return happens
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent):**
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
    (GA02's formula) — trials are judged on yaw alone, because
    every called target is a left/right angle
  - pitch = asin(2*(w*x - y*z)), clamped (GA01/GA04's formula) —
    read ONLY for the return-to-center gate (both axes <10 deg)
  - Only the RELATIVE pitch/yaw vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Yaw sign — learned, not assumed (device verification
  item).** The one calibration prompt records the sign the head
  actually moves when asked to turn left as LEFT; RIGHT is the
  opposite yaw sign (GA02's pattern). Residual caveat:
  calibration trusts the player to follow that one prompt;
  turning right instead of left would learn the signs backwards.
  Fail-safes: nothing counts before calibration completes, the
  first trial is left again, so a backwards calibration feels
  wrong at once, and any restart re-runs the prompt. The device
  checklist must confirm: (1) the calibration prompt appears
  and completes on a real left turn, (2) a real left turn then
  counts as left, not right (the left-sign check).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole trial as a hit, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示对上 x / 8」 only when demo
  trials were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, trial, center and learned sign live in page memory
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
  zero permission-gated features); CSS uses the green scale
  only (no `#ffffff`, no white rgba).
- Logic harness (33 checks, all passing), driving the real
  `.ink` state machine with synthetic sensor readings and a
  controllable clock: left-sign learning from a negative-raw-yaw
  host, calibration return, trial calls in fixed order, band
  edges inclusive at target +/-5 deg and exclusive outside,
  band entry speaking "停，稳住", early band exit (overshoot)
  resetting the hold with no count, 8 ticks (0.8 s) in band =
  hit but 7 ticks not, return gate holding the next call past
  the 4 s grace with a spoken "请回正", pitch-out-of-band
  keeping the gate closed, wrong side past 27 deg = instant
  miss, 10 s timeout = miss, full 8-trial run ending 6/8 with
  the final trial ending the game at once, restart re-running
  calibration with the score reset.
- Preview screenshots in `screenshots/angle-match/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
