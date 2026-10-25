# Follow Dot （追光点） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series G10, Group B (head-as-controller):
a follow-the-dot game. Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

Distinct from G05: G05 follows VOICE cues for clock positions;
this game follows a VISUAL dot — the dot's position on screen is
the cue, and the voice only names it ("光点在左").

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one position -> hold -> return to center -> next dot.
The dot NEVER moves continuously and NEVER traces a circle: it
jumps discretely between 4 positions, disappears on a hit, and
the next dot only appears after the player returns to center.
Never sweep from one extreme to another, never fast jerking.
Slow, small range, stop at mild stretch, never pain. For UP
specifically: only to a mild stretch, NEVER hyperextend, NEVER
throw the head back — this is said in the voice guidance, not
just on screen. Stop at once on pain / dizziness / numbness /
nausea. Sit or stand steady first. One round is 10 dots, short.
This is entertainment / daily activity, NOT medical diagnosis,
treatment or a rehab prescription; people with cervical disease,
vertigo, post-op or head/neck injury history should ask a doctor
first. The short version is on the in-game ready screen; the full
text is here and in the README.

## Design contract

- **One mechanic.** 10 dots, one at a time. A dot appears at one
  of 4 positions (up / down / left / right of center), shown as a
  large dot in a 3-row position grid (top / left-center-right /
  bottom) plus a big "光点在左" line, and announced by voice.
  Turning to the dot and holding ~0.8 s = hit (+1, voice
  "跟到了", dot disappears). Turning to a WRONG position past
  threshold = miss at once for that dot (voice "不是这个方向",
  dot disappears, no hold-or-undo). No correct position within
  4 seconds = miss (voice "没跟到", dot disappears). A hit that
  backs off before the hold is aborted with no count; the
  4-second dot clock keeps running, so a stalled dot still ends
  as a miss.
- **Fixed dot sequence (NOT random, so preview and device
  behaviour are reproducible):** left, up, left, down, right, up,
  down, right, left, up (positions for dots 1–10). Documented
  here and in the code (`SEQ`). It contains NO clockwise
  adjacent step at all — no up->right, right->down, down->left
  or left->up step — so no clockwise run can arise. NOTE: the
  task brief's example sequence (left, up, right, down, left,
  down, right, up, down, left) itself contains clockwise triples
  (up->right->down, right->down->left), so it was NOT used
  verbatim; the sequence above honours the brief's own
  "avoiding any clockwise run" rule instead.
- **Return-to-center gates every next dot.** After every dot
  (hit or miss) the player MUST return to center (<10 deg on
  BOTH axes) before the next dot appears. If not returned within
  4 seconds, TTS prompts "请回正" and the grace timer resets —
  the grace counts nothing and the next dot is NEVER announced
  until the return actually happens. This differs from G09's
  advance-anyway grace, deliberately: the return rule is what
  keeps this game segmented, not a sweep. The final dot ends the
  game at once: there is no next dot for a return to gate.
- **Calibration is two prompts, inside the playing state (G05's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请低一下头" as its first
  instruction, then "回正到中间", then "请向左转一下", then
  "回正到中间", then dot 1. Nothing counts before BOTH
  calibrations complete; restarting (tap on done) re-runs both.
- **Voice is primary.** Every dot is announced, every outcome
  is spoken (hit / wrong-direction / timeout miss), completion
  is spoken. The screen mirrors the same lines. TTS uses the
  fixed host voice; the utterance `lang` is never set
  (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the dot (large, in one of
  4 positions), the score (hits x/10), and one short hint.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used. Dot
  positions come from the sensor quaternion, never from a
  gesture event.
- **Thresholds (encoded and documented here):**
  - position reached: ~25-30 deg (pitch for up/down, yaw for
    left/right) — coded as 27 deg
  - return-to-center: <10 deg on BOTH axes (pitch and yaw), so
    a return counts only when the head is genuinely straight
    again
  - hold: ~0.8 s (800 ms); the hold accumulates only while
    steady where the host reports stability events via
    `onOrientationStabilityChange`; if the host never reports
    them, elapsed time alone gates the hold (documented
    fallback, not a fake stable)
  - dot clock: 4 s, no correct position = miss
  - return grace: 4 s, then TTS "请回正" and the timer resets;
    the next dot is never announced until the return happens
  - calibration stall re-prompt: 8 s, once per calibration step
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
    counts before both calibrations complete, the first dot is
    left and the second is up, so a backwards calibration feels
    wrong at once, and any restart re-runs both prompts. The
    device checklist must confirm: (1) both calibration prompts
    appear and complete on a real look-down and a real left
    turn, (2) a real look-down then counts as down, not up, and
    a real look-up counts as up, not down, (3) a real left turn
    then counts as left, not right, and a real right turn
    counts as right, not left, (4) returning to center between
    dots is required — the next dot never appears before the
    return, and a 4-second non-return produces a spoken
    "请回正" with no advance.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole dot as a hit, return collapsed)
  so the playing and done states can be previewed. On a real
  device with a sensor there is no DEMO path at all, and the
  done screen says 「演示跟到 x / 10」 only when demo dots were
  used.
- **Zero persistence by construction:** no storage calls
  anywhere; score, dot, center and learned signs live in page
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
  zero permission-gated features).
- Preview screenshots in `screenshots/follow-dot/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
