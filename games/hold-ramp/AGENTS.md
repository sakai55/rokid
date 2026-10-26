# Hold Ramp （渐进保持） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA25, Wave 2, Group E
(precision control): a progressive hold ladder. Extreme
simplicity: 3 states only (ready / playing / done), one page,
one main button.

Distinct from GA04 (stretch-hold): GA04 holds a FIXED 5 s,
alternating up and down, 3 times each. Here the hold DURATION
itself climbs a ladder (2/3/4/5/6 s) and only the DOWN direction
is used — the skill is sustaining a hold longer and longer,
not switching directions. Also distinct from GA03 (ear-tilt):
that holds a side tilt for a fixed 5 s; this holds a down pitch
for a climbing duration. Also distinct from GA21/GA24: those
judge angles on the way out or on the way back; this judges
how LONG a hold is sustained.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> down -> hold -> return to center -> next level. The
game NEVER asks for a sweep, a circle, or an up-down swing:
one down hold per level, returned from, and only then is the
next level announced. Slow, small range, down only to a light
stretch, never forced, never fast jerking. Stop at once on pain
/ dizziness / numbness / nausea. Sit or stand steady first.
One round set is 5 levels, short. This is entertainment /
daily activity, NOT medical diagnosis, treatment or a rehab
prescription; people with cervical disease, vertigo, post-op or
head/neck injury history should ask a doctor first. The short
version is on the in-game ready screen; the full text is here
and in the README.

## Design contract

- **One mechanic.** 5 levels, ladder 2/3/4/5/6 seconds, one at
  a time. Per level: TTS calls the level ("第 2 级，低头保持
  3 秒") and the screen shows the same call (arrow + seconds).
  Holding the down zone (>=20 deg toward down) for the full
  level duration = level passed (+1, voice "爬上去了").
  Leaving the down zone before the hold completes resets the
  hold to zero and counts nothing; the level clock keeps
  running, so a stalled level still ends as a fail.
- **Fixed ladder (NOT random):** 2, 3, 4, 5, 6 seconds.
  Documented here and in the code (`LEVELS`).
- **Level clock:** level duration + 8 s of slack for
  re-settling; clock running out = level failed (voice
  "没爬上去").
- **Return-to-center gates every next level.** After every
  level (pass or fail) the player MUST return to center
  (<10 deg on BOTH axes, pitch and yaw) before the next level
  is announced. If not returned within 4 seconds, TTS prompts
  "请回正" and the grace timer resets — the grace counts
  nothing and the next level is NEVER announced until the
  return actually happens (GA10/GA13's stricter rule, NOT
  GA09's advance-anyway grace). The final level ends the game
  at once.
- **Calibration is one prompt, inside the playing state (GA04's
  pattern).** START calibrates the center (head straight at
  START), then the playing screen shows "请低一下头" as its
  first instruction, then "回正到中间", then level 1. Nothing
  counts before calibration completes; restarting (tap on
  done) re-runs it.
- **Voice is primary.** Every level call, every outcome, and
  completion are spoken. The screen mirrors the same lines.
  TTS uses the fixed host voice; the utterance `lang` is never
  set (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and a nod is a quick dip, not a
  sustained down hold.
- **Playing screen shows at most:** the level call (arrow +
  seconds), levels passed x/5, and one short hint.

## Technical honesty

- **No eye tracking.** Head direction comes only from
  `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Angles come from the sensor quaternion, never from a
  gesture event.
- **Thresholds (encoded and documented here):**
  - down zone: >=20 deg toward down
  - hold: the full level duration (2/3/4/5/6 s) inside the
    zone; the hold accumulates only while steady where the
    host reports stability events via
    `onOrientationStabilityChange`; if the host never reports
    them, elapsed time alone gates the hold (documented
    fallback, not a fake stable)
  - level clock: level duration + 8 s slack, no pass = fail
  - return gate: <10 deg on BOTH axes (pitch and yaw)
  - return grace: 4 s, then TTS "请回正" and the timer resets
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent):**
  - pitch = asin(2*(w*x - y*z)), clamped (GA01/GA04's formula)
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
    (GA02's formula) — read ONLY for the return gate
  - Only the RELATIVE pitch/yaw vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Down sign — learned, not assumed (device verification
  item).** The one calibration prompt records the pitch sign
  the head actually moves when asked to dip down as DOWN
  (GA04's pattern). Residual caveat: calibration trusts the
  player to follow that one prompt; dipping up instead would
  learn the sign backwards. Fail-safes: nothing counts before
  calibration completes, and any restart re-runs the prompt.
  The device checklist must confirm a real dip counts as down.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole level as a pass, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示爬上 x / 5」 only when demo
  levels were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, level, center and learned sign live in page memory
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
  documents only 'nod', which is not a sustained hold);
  permissions match the features actually used (empty, matching
  zero permission-gated features); CSS uses the green scale
  only (no `#ffffff`, no white rgba).
- Logic harness (30 checks, all passing), driving the real
  `.ink` state machine with synthetic sensor readings and a
  mocked clock: down-sign learning from a negative-raw-pitch
  host, calibration return, level 1 (2 s) pass with a return
  gate, hold reset on leaving the zone before the full
  duration, 20 deg zone edge inclusive and 19 deg not
  accumulating, level timeout (duration + 8 s) = fail,
  return grace holding the next level past 4 s with a spoken
  "请回正", level 2 requiring the full 3 s (not 2 s), full
  5-level ladder run ending 5/5 with restart re-running
  calibration.
- Preview screenshots in `screenshots/hold-ramp/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
