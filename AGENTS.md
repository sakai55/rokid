# Memory Seq （方向记忆） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA12, closing Group B
(head-as-controller): a direction-memory game. Extreme
simplicity: 3 states only (ready / playing / done), one page,
one main button.

Distinct from GA05/GA10: those follow cues in real time (GA05 voice
cues for clock positions, GA10 a visual dot). This game requires
REMEMBERING a sequence after it is announced, with NO cue on
screen during recall — the screen shows only "听" / "做", the
step within the round, and rounds won x/3, never a direction.
If a direction appeared on screen during announce or recall,
it would not be a memory game at all.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
step. The sequence is NEVER performed as a continuous sweep or
circle: every step is separated by a return to center, and the
recall phase replays the sequence step by step with returns,
exactly like the announcement phase. Never fast jerking. Slow,
small range, stop at mild stretch, never pain. For UP
specifically: only to a mild stretch, NEVER hyperextend, NEVER
throw the head back — this is said in the voice guidance, not
just on screen. Stop at once on pain / dizziness / numbness /
nausea. Sit or stand steady first. One round set is 3 rounds,
short. This is entertainment / daily activity, NOT medical
diagnosis, treatment or a rehab prescription; people with
cervical disease, vertigo, post-op or head/neck injury history
should ask a doctor first. The short version is on the in-game
ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 3 rounds. Per round: ANNOUNCE phase — TTS
  speaks the directions one by one, 1 second apart, screen
  shows only "听" + round number (never the directions);
  then RECALL phase — TTS says "请按顺序做出来", the player
  performs each step (turn to the direction, hold ~0.8 s,
  return to center) in order. A correct step advances (voice
  "对"); a wrong direction past threshold ends the round as
  failed at once (voice "错了，这轮没过", no retry within the
  round); after a failed round, the player returns to center
  and the next round is announced. A round completed in full
  order = won (+1 round). Done shows rounds won x/3 and
  "再来一局" (tap restarts, recalibrates, same sequences).
- **Fixed sequences (NOT random, so preview and device
  behaviour are reproducible), documented here and in the
  code (`ROUNDS`):**
  - Round 1: left, up, right (3 steps)
  - Round 2: down, left, down (3 steps — the repeat is
    allowed because each step is separated by a return)
  - Round 3: right, down, left, up (4 steps)
- **No per-step timeout beyond a stall re-prompt.** If the
  player stalls 8 seconds on a recall step, TTS re-prompts
  the phase ("轮到你了，按顺序做") once, then keeps waiting
  — never auto-fails on stall alone. The same once-per-step
  8 s re-prompt applies to calibration steps and to return
  steps ("回正到中间"), which likewise never auto-advance.
- **Advancing a step speaks NOTHING about the next direction.**
  Speaking the next direction after a correct step would give
  the memory away; the player learns the next step only from
  the step counter ("第 k 步 / n 步") on screen.
- **Return-to-center gates every next step and every next
  round.** After a correct step's hold, the player MUST return
  to center (<10 deg on BOTH axes) before the next step's
  recall starts; after a failed round, the next round is
  announced ONLY after the return actually happens. The final
  step's return is the round's completion: a won round goes
  straight to the next round's announce, and a failed last
  round ends the set at once (no return is needed to end).
- **Calibration is two prompts, inside the playing state (GA05's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请低一下头" as its first
  instruction, then "回正到中间", then "请向左转一下", then
  "回正到中间", then round 1's announce. Nothing counts
  before BOTH calibrations complete; restarting (tap on done)
  re-runs both.
- **Voice is primary.** Every phase is announced, every
  outcome is spoken (correct / wrong-direction / round won /
  round failed / final score). The screen mirrors only the
  phase, step and rounds won — never a direction. TTS uses
  the fixed host voice; the utterance `lang` is never set
  (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the current phase ("听" /
  "做"), the step within the round, rounds won x/3, and one
  short hint — plus the fleet-standard title, sensor line,
  main button and footer.

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
  - announce spacing: 1 s between spoken directions
  - recall stall re-prompt: 8 s, once per step, never auto-fail
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
    counts before both calibrations complete, the first
    announced direction is left (round 1 step 1) and the
    second is up, so a backwards calibration feels wrong at
    once, and any restart re-runs both prompts. The device
    checklist must confirm: (1) both calibration prompts
    appear and complete on a real look-down and a real left
    turn, (2) a real look-down then counts as down, not up,
    and a real look-up counts as up, not down, (3) a real left
    turn then counts as left, not right, and a real right turn
    counts as right, not left, (4) during announce the screen
    shows only "听" + round number and no direction, (5) a
    wrong direction in recall fails the round at once with
    "错了，这轮没过" and no retry, (6) after a failed round
    the next round is announced only after a real return to
    center, (7) an 8 s stall on a recall step re-prompts once
    and never auto-fails, (8) returning to center between
    steps is required — the next step never starts before the
    return, (9) round 2's repeated down is playable because
    each step is separated by a return.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, one tap per announce word, one tap per whole recall
  step as correct, return collapsed) so the playing and done
  states can be previewed. On a real device with a sensor there
  is no DEMO path at all, and the done screen says 「演示赢了
  x / 3」 only when demo steps were used.
- **Zero persistence by construction:** no storage calls anywhere;
  rounds won, step, center and learned signs live in page memory
  and die with the page.
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
- Logic harness (37 checks, all passing): down/left sign learning,
  calibration returns, announce words in order then recall, three
  correct round-1 steps winning the round, round-2 wrong direction
  failing the round at once with the fail voice, return gating the
  next round, round-3 full completion ending the set at 2/3 won,
  8 s stall re-prompting once without failing, early release
  returning to wait with no count.
- Preview screenshots in `screenshots/memory-seq/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
