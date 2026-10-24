# Traffic Light （红绿灯） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series G19, Group D (fun finale):
a traffic-light game. Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

Distinct from G07: G07 is pure stillness (one 10-second hold,
no turning at all). This game ALTERNATES motion and stillness
on command — green rounds turn, red rounds freeze — so the
skill is obeying the light, not just holding still. Distinct
from G13: G13 always names a direction to find; here red rounds
name NO direction and forbid ALL movement. Distinct from G09:
G09 dodges by turning away from obstacles; here the light
itself is the only instruction.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only slow, segmented
motion: green rounds turn to ONE cued direction and return to
center before the next round; red rounds do not move at all.
Never a sweep, never fast jerking, never a rapid
green-red-green flinch. Slow, small range, stop at mild
stretch, never pain. **For UP specifically: only to a mild
stretch, NEVER force the head far back, NEVER hyperextend,
NEVER throw the head back** — this is said in the voice
guidance, not just on screen. Stop at once on pain / dizziness
/ numbness / nausea. Sit or stand steady first. One game is 10
rounds, short. This is entertainment / daily activity, NOT
medical diagnosis, treatment or a rehab prescription; people
with cervical disease, vertigo, post-op or head/neck injury
history should ask a doctor first. The short version is on the
in-game ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 10 rounds, one at a time, fixed light
  sequence (NOT random, so preview and device behaviour are
  reproducible): green-left, red, green-up, red, green-right,
  green-down, red, green-left, red, green-up (6 green, 4 red).
  Documented here and in the code (`SEQ`). Rounds are
  separated by a return to center, so no circling arises from
  the sequence regardless of its order.
- **GREEN round.** TTS "绿灯，向左转" (or the cued direction;
  up rounds add "只到轻微拉伸，不要用力往后仰"). Reaching the
  cued direction past ~27 deg within 4 seconds = pass (+1,
  voice "通过"). Not reaching within 4 s = fail (voice
  "没赶上"). Turning the WRONG way does NOT fail a green round
  at once — it simply does not count as reaching, and the
  4-second clock still ends the round as a fail. This is a
  deliberate documented choice: the spec's fail condition is
  the clock, not the wrong turn.
- **RED round.** TTS "红灯，别动". Surviving 3 seconds with
  total angular change under 5 deg from the round-start
  reference (G07's quaternion-angle metric) = pass (+1, voice
  "稳住了"). Moving to 5 deg or beyond at ANY point during the
  3 s = fail at once (voice "动了"). Unlike G07 there is NO
  0.3 s grace on red, because freezing instantly is the whole
  point of red. Stability events are a supporting signal only:
  where the host reports instability, accumulation pauses but
  never resets; a 5-deg move fails even while unstable. If the
  host never reports stability events, elapsed time inside the
  still band alone gates the pass (documented fallback).
- **Return-to-center gates every next round.** After every
  round except the last (green OR red — see deviation note
  below), the player MUST return to center (<10 deg on BOTH
  axes) before the next round is announced. If not returned
  within 4 seconds, TTS prompts "请回正" and the grace timer
  resets — the grace counts nothing and the next round is
  NEVER announced until the return actually happens. This is
  G10/G13's stricter rule, deliberately NOT G09's
  advance-anyway grace. The final round ends the game at once:
  there is no next round for a return to gate.
- **Calibration is two prompts, inside the playing state (G05's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请低一下头" as its first
  instruction, then "回正到中间", then "请向左转一下", then
  "回正到中间", then round 1. Nothing counts before BOTH
  calibrations complete; restarting (tap on done) re-runs both.
- **Voice is primary.** Every light is announced, every
  outcome is spoken, completion is spoken. The screen mirrors
  the same lines. TTS uses the fixed host voice; the utterance
  `lang` is never set (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the light (filled circle +
  绿灯 on green rounds, hollow circle + 红灯 on red rounds —
  see display note), the cued direction on green rounds only,
  the round line ("通过 x / 10"), and one short hint.
- **DISPLAY NOTE (monochrome green).** The glasses display is
  monochrome green, so the light is NOT distinguished by
  color: green = filled circle ● + the word 绿灯, red = hollow
  circle ○ + the word 红灯. The words carry the meaning; the
  circles are decoration. This is stated in the code comment,
  here, and in the README.

## Deviation from the brief (deliberate, disclosed)

The brief said "no return gate is needed after red rounds"
because red rounds end at center. That holds only for PASSED
red rounds. A FAILED red round ends the moment the head moved
≥5 deg — the head is NOT at center. Announcing the next round
while the head is still turned would break the segmented-motion
rule, so the implementation applies the return gate uniformly
after every round except the last. For a passed red the gate is
satisfied instantly on the next tick (the head never left
center), so the observable behaviour for passed reds is
identical to "no gate"; the only difference is that failed
reds are walked back to center first. This is safer and keeps
one rule instead of two.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Directions and stillness come from the sensor quaternion,
  never from a gesture event.
- **Thresholds (encoded and documented here):**
  - direction reached: ~25-30 deg (pitch for up/down, yaw for
    left/right) — coded as 27 deg
  - green clock: 4 s, no reach = fail
  - red stillness: total angular change < 5 deg from the
    round-start reference quaternion (G07's metric:
    `2*acos(|dot(q, qRef)|)` in degrees); ≥ 5 deg at any point
    = fail at once, no grace
  - red survival: 3 s accumulated inside the still band
    (stability-paused where the host reports instability)
  - return-to-center: <10 deg on BOTH axes (pitch and yaw)
  - return grace: 4 s, then TTS "请回正" and the timer resets;
    the next round is never announced until the return happens
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent, G05's):**
  - pitch = asin(2*(w*x - y*z)), clamped
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
  - Only the RELATIVE pitch/yaw vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Sign learning — two axes, both learned, neither assumed
  (device verification items).**
  - DOWN: the first calibration prompt records the sign the
    head actually moves when asked to look down as DOWN; UP is
    the opposite pitch sign (G01/G04 pattern).
  - LEFT: the second calibration prompt records the sign the
    head actually moves when asked to turn left as LEFT; RIGHT
    is the opposite yaw sign (G02 pattern).
  - Residual caveats: calibration trusts the player to follow
    each prompt; looking up instead of down would learn the
    pitch signs backwards, and turning right instead of left
    would learn the yaw signs backwards. Fail-safes: nothing
    counts before both calibrations complete, and any restart
    re-runs both prompts. The device checklist must confirm:
    (1) both calibration prompts appear and complete on a real
    look-down and a real left turn, (2) a real look-down then
    counts as down, not up, and a real look-up counts as up,
    not down, (3) a real left turn then counts as left, not
    right, and a real right turn counts as right, not left,
    (4) green rounds pass only on reaching the cued direction
    within 4 s and fail on the clock, (5) red rounds pass only
    on 3 s of true stillness and fail the instant the head
    moves ≥5 deg, (6) returning to center between rounds is
    required — the next round never appears before the return,
    and a 4-second non-return produces a spoken "请回正" with
    no advance, including after a failed red.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole round as a pass, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示通过 x / 10」 only when demo
  rounds were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, round, center and learned signs live in page memory
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
- Logic harness (33 checks, all passing): constants read from
  the real .ink file; fixed light sequence (6 green, 4 red, no
  two reds adjacent); green reach at 27 deg / not at 26 deg for
  all four directions; wrong way on green does not pass; green
  4 s clock; red stillness via the quaternion-angle metric
  (4 deg inside, 6 deg fails at once, 5 deg boundary within
  float epsilon); red 30 ticks pass / 29 ticks not; return gate
  requires both axes < 10 deg; full-game 10/10 and mixed 8/10
  simulations with 9 return gates.
- Preview screenshots in `screenshots/traffic-light/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
