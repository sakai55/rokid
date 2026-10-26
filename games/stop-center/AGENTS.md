# Stop Center （回正定点） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA24, Wave 2, Group E
(precision control): a return-to-center stopping game.
Extreme simplicity: 3 states only (ready / playing / done),
one page, one main button.

Distinct from GA21 (angle-match) and GA13 (find-target):
GA21 judges landing IN a called angle band on the way OUT;
GA13 judges only REACHING a direction at ~27 deg. Here the
outbound turn is just the setup — the scored skill is the
RETURN: stopping dead inside a narrow center band (±5 deg)
instead of swinging through it to the other side. First-wave
games treated return only as a gate between trials; here
return IS the game. Also distinct from GA10 (follow-dot):
the target is not a called direction to reach, it is the
center itself, reached from alternating sides.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> return -> stop -> next trial. The
call NEVER asks for a sweep or a circle: one side per trial,
turned to, returned from, stopped in, and only then is the
next call announced. Never sweep from one extreme to another,
never fast jerking. Slow, small range, stop at mild stretch,
never pain. Stop at once on pain / dizziness / numbness /
nausea. Sit or stand steady first. One round set is 8 trials,
short. This is entertainment / daily activity, NOT medical
diagnosis, treatment or a rehab prescription; people with
cervical disease, vertigo, post-op or head/neck injury history
should ask a doctor first. The short version is on the in-game
ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 8 trials, alternating sides left/right.
  Per trial: TTS calls one side ("向左转") and the screen
  shows the same call (arrow + side). Turning >=20 deg toward
  that side speaks "回正，停住" once; returning so yaw is
  within ±5 deg (and pitch <10 deg) and holding steady ~0.8 s
  = hit (+1, voice "停住了"). Overshooting past 5 deg to the
  uncalled side during the stop phase = miss at once (voice
  "过冲了"). 14 s without finishing = miss (voice "没停住").
- **Fixed trial list (NOT random):** left, right, left, right,
  left, right, left, right. Documented here and in the code
  (`TRIALS`). Every trial is separated by a stop at center, so
  no circling arises.
- **After a hit the next call follows at once** — the player
  is already inside ±5 deg, so there is nothing to gate on.
  After a miss (overshoot or timeout) the player MUST return
  to center (<10 deg on BOTH axes, pitch and yaw) before the
  next call: if not returned within 4 seconds, TTS prompts
  "请回正" and the grace timer resets — the grace counts
  nothing and the next call is NEVER announced until the
  return actually happens (GA10/GA13's stricter rule, NOT
  GA09's advance-anyway grace). The final trial ends the game
  at once.
- **Calibration is one prompt, inside the playing state (GA02's
  pattern).** START calibrates the center (head straight at
  START), then the playing screen shows "请向左转一下" as its
  first instruction, then "回正到中间", then trial 1. Nothing
  counts before calibration completes; restarting (tap on
  done) re-runs it.
- **Voice is primary.** Every call, the "回正，停住" cue,
  every outcome, and completion are spoken. The screen mirrors
  the same lines. TTS uses the fixed host voice; the utterance
  `lang` is never set (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the call (arrow + side)
  or the stop cue, stops x/8, and one short hint.

## Technical honesty

- **No eye tracking.** Head direction comes only from
  `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Angles come from the sensor quaternion, never from a
  gesture event.
- **Thresholds (encoded and documented here):**
  - outbound reach: >=20 deg toward the called side
  - stop band: yaw within ±5 deg, pitch <10 deg
  - hold: ~0.8 s (800 ms) inside the stop band; the hold
    accumulates only while steady where the host reports
    stability events via `onOrientationStabilityChange`; if
    the host never reports them, elapsed time alone gates the
    hold (documented fallback, not a fake stable)
  - overshoot: past 5 deg to the uncalled side during the stop
    phase = miss at once
  - trial clock: 14 s, no finish = miss
  - return gate (after a miss): <10 deg on BOTH axes
  - return grace: 4 s, then TTS "请回正" and the timer resets
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent):**
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
    (GA02's formula)
  - pitch = asin(2*(w*x - y*z)), clamped (GA01/GA04's formula)
    — read ONLY for the center gates
  - Only the RELATIVE pitch/yaw vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Yaw sign — learned, not assumed (device verification
  item).** The one calibration prompt records the sign the
  head actually moves when asked to turn left as LEFT; RIGHT is
  the opposite yaw sign (GA02's pattern). Residual caveat:
  calibration trusts the player to follow that one prompt;
  turning right instead of left would learn the signs
  backwards. Fail-safes: nothing counts before calibration
  completes, the first trial is left again, so a backwards
  calibration feels wrong at once, and any restart re-runs the
  prompt. The device checklist must confirm: (1) the
  calibration prompt appears and completes on a real left
  turn, (2) a real left turn then counts as left, not right.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole trial as a hit, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示停住 x / 8」 only when demo
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
- Logic harness (19 checks, all passing), driving the real
  `.ink` state machine with synthetic sensor readings and a
  mocked clock: left-sign learning from a negative-raw-yaw
  host, calibration return, outbound reach entering the stop
  phase, 8 ticks (0.8 s) in the stop band = hit with the next
  trial at once, overshoot past 5 deg = instant miss with a
  return gate, 5 deg stop-band edge inclusive and 6 deg not
  accumulating, 14 s timeout = miss, return grace holding the
  next call past 4 s with a spoken "请回正", hold reset on
  leaving the band before 8 ticks, full 8-trial run ending 8/8
  with restart re-running calibration.
- Preview screenshots in `screenshots/stop-center/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
