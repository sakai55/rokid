# Memory Six （六向记忆） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA26, Wave 2, Group F
(memory / rhythm advanced): a six-direction memory game.
Extreme simplicity: 3 states only (ready / playing / done),
one page, one main button.

Distinct from GA12 (memory-seq): GA12 only used FOUR
directions (left / right / up / down) with 3–4 step sequences.
Here the element set grows to SIX by adding left tilt and
right tilt (side bends), and rounds grow 3 → 4 → 5 steps — the
memory load is genuinely larger, and the replay must tell a
tilt apart from a turn, because a step is judged on its own
axis only. Also distinct from GA22 (tilt-match): that judges
tilt ANGLE precision against small targets; here tilt is one
element of a remembered sequence, judged only by direction.
Also distinct from GA33 (path-follow, planned): that shows the
path on screen and drills execution; here the sequence is
voice-only and must be remembered.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> return to center -> next step. The
announce NEVER asks for a sweep or a circle: one step at a time,
each returned from before the next step is attempted. Never
fast jerking. Slow, small range, stop at mild stretch, never
pain. Stop at once on pain / dizziness / numbness / nausea.
Sit or stand steady first. One round set is 3 rounds, short.
This is entertainment / daily activity, NOT medical diagnosis,
treatment or a rehab prescription; people with cervical disease,
vertigo, post-op or head/neck injury history should ask a doctor
first. The short version is on the in-game ready screen; the
full text is here and in the README.

## Design contract

- **One mechanic.** 3 rounds, sequences over 6 directions.
  Fixed sequences (NOT random): round 1 (3 steps) left, up,
  right tilt; round 2 (4 steps) down, left tilt, right, up;
  round 3 (5 steps) right tilt, left, down, left tilt, right.
  Documented here and in the code (`ROUNDS`).
- **Announce is voice-only (GA12's pattern).** The round is
  spoken one item per 1.2 s; the screen shows only "听…" and
  the round number — NO direction is shown on screen during
  the announce, so the player must actually remember. Then the
  screen shows only the step number ("第 2 个"), never the
  direction name.
- **Replay, step by step.** Each step: reach the called
  direction's threshold (turns / up / down >=25 deg, tilts
  >=15 deg) — voice "对" — then return to center (<10 deg on
  ALL THREE axes, pitch / yaw / roll) before the next step.
  If not returned within 4 seconds, TTS prompts "请回正" and
  the grace timer resets — the next step is NEVER attempted
  until the return actually happens. A round's final step
  returns to a round gate: after every round (pass or fail)
  the player must return to center before the next round is
  announced, same grace rule.
- **Fail rules.** Reaching a DIFFERENT direction's threshold
  first = round failed at once (voice "顺序错了"). 10 s
  without the right step = round failed. Score = rounds
  reproduced correctly, x/3; a failed round does not end the
  game — the next round still runs.
- **Calibration is three prompts, inside the playing state.**
  START calibrates the center (head straight at START), then
  three prompts in order, each followed by a return to center:
  "请向左转一下" learns LEFT, "请低一下头" learns DOWN,
  "请向左贴一下耳" learns LEFT TILT; RIGHT / UP / RIGHT TILT
  are the opposite signs. Nothing counts before calibration
  completes; restarting (tap on done) re-runs all three.
- **Voice is primary.** Every announce item, every outcome,
  and completion are spoken. The screen mirrors counts only.
  TTS uses the fixed host voice; the utterance `lang` is never
  set (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the phase (calibration /
  listening / step number / return), rounds passed x/3, and
  one short hint. Never a direction name during announce or
  replay.

## Technical honesty

- **No eye tracking.** Head direction comes only from
  `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Angles come from the sensor quaternion, never from a
  gesture event.
- **Thresholds (encoded and documented here):**
  - turns / up / down reach: >=25 deg toward the direction
  - tilt reach: >=15 deg toward the tilt side
  - return gates (step and round): <10 deg on ALL THREE axes
    (pitch, yaw, roll)
  - step clock: 10 s, no right step = round failed
  - announce pacing: one item per 1.2 s
  - return grace: 4 s, then TTS "请回正" and the timer resets
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent):**
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
    (GA02's formula)
  - pitch = asin(2*(w*x - y*z)), clamped (GA01/GA04's formula)
  - roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)), in degrees
    (side bend; a tilt is judged on roll alone, so a turn
    cannot be mistaken for a tilt and vice versa)
  - Only the RELATIVE pitch/yaw/roll vs the calibrated center
    are used, so the host's absolute zero never matters.
- **Three signs — learned, not assumed (device verification
  items).** The three calibration prompts record the signs the
  head actually moves for left, down, and left tilt. Residual
  caveat: calibration trusts the player to follow each prompt;
  doing a prompt backwards would learn that sign backwards.
  Fail-safes: nothing counts before calibration completes, and
  any restart re-runs all three prompts. The device checklist
  must confirm: (1) each prompt appears and completes on the
  real movement, (2) a real left turn / dip / left tilt then
  counts as that direction, not its opposite, (3) a right turn
  during a right-tilt step does not count (tilt/turn
  separation).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, announce skipped, then one tap per whole step as
  correct, returns collapsed) so the playing and done states
  can be previewed. On a real device with a sensor there is no
  DEMO path at all, and the done screen says 「演示记住 x / 3」
  only when demo steps were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, round, step, center and learned signs live in page
  memory and die with the page.
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
- Logic harness (92 checks, all passing), driving the real
  `.ink` state machine with synthetic sensor readings and a
  mocked clock: three-sign learning from a negative-sign host
  for yaw / pitch / roll, calibration returns between prompts,
  announce advancing to replay, round 1 full pass (left, up,
  right tilt) with a round return gate, wrong step failing the
  round at once, a right turn during a right-tilt step failing
  the round (tilt/turn separation), step timeout (10 s) failing
  the round, step return gate holding the next step past the
  4 s grace with a spoken "请回正", full 3-round run ending
  3/3 with restart re-running calibration, tilt threshold edge
  (15 deg reached, 14 deg not).
- Preview screenshots in `screenshots/memory-six/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
