# Guess Direction （猜方向） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA18, opening Group D
(fun finale): a guess-the-direction game. Extreme simplicity:
3 states only (ready / playing / done), one page, one main
button.

Distinct from GA13: GA13 NAMES the direction ("请看向左") and
the screen shows the same arrow. This game names NOTHING and
shows NOTHING about the secret: the only feedback is distance
("还远 / 近了 / 很近了 / 到了附近，停稳"), so the player must
search. Distinct from GA05: GA05 follows clock-position cues in
sequence; here the sequence is secret, and distance — not a
cue — is the guide. Distinct from GA12: GA12 replays a sequence
from memory; here there is nothing to remember, only a hidden
direction to hunt by distance.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only slow, segmented
searching: move slowly toward the hidden direction, stop,
return to center between rounds — never a sweep, never a
circle, never fast jerking. Slow, small range, stop at mild
stretch, never pain. **For UP specifically: only to a mild
stretch, NEVER force the head far back, NEVER hyperextend,
NEVER throw the head back** — this is said in the voice
guidance, not just on screen. Stop at once on pain / dizziness
/ numbness / nausea. Sit or stand steady first. One game is 5
rounds, short. This is entertainment / daily activity, NOT
medical diagnosis, treatment or a rehab prescription; people
with cervical disease, vertigo, post-op or head/neck injury
history should ask a doctor first. The short version is on the
in-game ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 5 rounds, one at a time. Per round: TTS
  says only "第 x 轮，猜猜看是哪个方向" — the secret is never
  named or shown until the round ends. The player slowly moves
  the head; TTS reports distance bands only (see below). Head
  within ≤12 deg of the secret AND held steady ~0.8 s = found
  (+1, voice reveals the secret: "猜对了，是向左"). No find
  within 20 seconds = miss (voice reveals the secret: "时间到，
  是向左"). A hold that backs off before 0.8 s counts nothing
  and the hold restarts from zero if the player comes back.
- **Fixed secret sequence (NOT random, so preview and device
  behaviour are reproducible):** left, down, right, up, right
  (rounds 1–5). Documented here and in the code (`SEQ`). The
  game screen NEVER shows it, and voice never names it before
  the round ends. Rounds are separated by a return to center,
  so no circling arises from the sequence regardless of its
  order.
- **Distance bands (documented exactly, encoded in code):**
  distance = sqrt(dYaw^2 + dPitch^2) in degrees, where the
  secret direction is 27 deg along its own axis and 0 on the
  other axis, measured in down-positive / left-positive space
  vs the calibrated center. ≤12 deg = "到了附近，停稳" (also
  shown on screen); ≤25 deg = "很近了"; ≤45 deg = "近了";
  >45 deg = "还远". At center the head is 27 deg from any
  secret, so the opening band of every round is "近了" — never
  "还远" at start, and never "到了附近" without moving. A new
  hint is spoken ONLY when the band changes; the same hint is
  never repeated.
- **Return-to-center gates every next round.** After every
  round (found or miss) the player MUST return to center (<10
  deg on BOTH axes) before the next round is announced. If not
  returned within 4 seconds, TTS prompts "请回正" and the grace
  timer resets — the grace counts nothing and the next round is
  NEVER announced until the return actually happens. This is
  GA10/GA13's stricter rule, deliberately NOT GA09's
  advance-anyway grace: the return rule is what keeps this game
  segmented, not a sweep. The final round ends the game at
  once: there is no next round for a return to gate.
- **Calibration is two prompts, inside the playing state (GA05's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请低一下头" as its first
  instruction, then "回正到中间", then "请向左转一下", then
  "回正到中间", then round 1. Nothing counts before BOTH
  calibrations complete; restarting (tap on done) re-runs both.
- **Voice is primary.** Every round is announced, every band
  change is spoken, every outcome is spoken with the secret
  revealed, completion is spoken. The screen mirrors the same
  lines — but never the secret. TTS uses the fixed host voice;
  the utterance `lang` is never set (documented: it does not
  take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the current distance hint
  word (no arrow, no secret — the arrow slot shows "?"), the
  round line ("第 x / 5 轮 · 猜对 y / 5"), and one short hint
  ("慢慢找，停稳").

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Directions come from the sensor quaternion, never from a
  gesture event.
- **Thresholds (encoded and documented here):**
  - secret direction: 27 deg along its axis (25–30 deg band)
  - distance bands: ≤12 / ≤25 / ≤45 deg (near / very near /
    close; above = far)
  - hold: ~0.8 s (800 ms); the hold accumulates only while
    steady where the host reports stability events via
    `onOrientationStabilityChange`; if the host never reports
    them, elapsed time alone gates the hold (documented
    fallback, not a fake stable); leaving the near band
    resets the hold to zero
  - round clock: 20 s, no find = miss (even mid-hold)
  - return grace: 4 s, then TTS "请回正" and the timer resets;
    the next round is never announced until the return happens
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent, GA05's):**
  - pitch = asin(2*(w*x - y*z)), clamped
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
  - down-positive pitch and left-positive yaw are used after
    sign learning; distance = sqrt(dYaw^2 + dPitch^2)
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
    counts before both calibrations complete, and any restart
    re-runs both prompts. The device checklist must confirm:
    (1) both calibration prompts appear and complete on a real
    look-down and a real left turn, (2) a real look-down then
    counts as down, not up, and a real look-up counts as up,
    not down, (3) a real left turn then counts as left, not
    right, and a real right turn counts as right, not left,
    (4) the secret is never shown or named before a round ends,
    (5) bands change only on movement and are spoken only on
    band change, (6) returning to center between rounds is
    required — the next round never appears before the return,
    and a 4-second non-return produces a spoken "请回正" with
    no advance.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole round as a find, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示猜对 x / 5」 only when demo
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
- Logic harness (34 checks, all passing): constants read from
  the real .ink file; fixed secret sequence; center distance 27
  deg = 'close' for every secret; exact-secret distance 0 =
  'near'; band boundaries 12 / 25 / 45 deg; opposite side 54 deg
  = 'far'; wrong-axis move 38.2 deg = 'close', not 'near'; hold
  reached at 8 ticks of 100 ms, not at 7; hold reset on leaving
  the near band; return gate requires both axes <10 deg;
  band-change-only speech; secret revealed only at round end.
- Preview screenshots in `screenshots/guess-direction/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
