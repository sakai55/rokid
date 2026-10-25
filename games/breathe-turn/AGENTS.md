# Breathe Turn （呼吸转头） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA17, closing Group C
(observation/control): a voice-paced breathing game — inhale
turn, exhale return. Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only slow, segmented
motion: one side turn per breath, always returning to center on
the exhale before the next breath — never a circle, never a fast
swing side to side, never holding a turned position across
multiple breaths. Slow, small range, stop at mild stretch, never
pain. Stop at once on pain / dizziness / numbness / nausea or
breathlessness. Sit or stand steady first; do not hold the
breath, do not force deep breathing — breathe normally and
comfortably, the voice only paces the rhythm, it does not
prescribe a medical breathing technique. One game is 8 breath
cycles, short. This is entertainment / daily activity, NOT
medical diagnosis, treatment, rehab or breathing therapy;
people with cervical disease, vertigo, post-op, head/neck
injury, or respiratory/cardiac conditions should ask a doctor
first. The short version is on the in-game ready screen; the
full text is here and in the README.

## Design contract

- **One mechanic.** 8 breath cycles, fixed alternating side
  sequence L,R,L,R,L,R,L,R (never two same-side turns in a row
  without a return, so no circling). Each cycle is 4 s inhale +
  4 s exhale, with a 1 s pause between cycles.
- **Inhale:** voice "吸气，慢慢向左转" (or right). Reaching the
  cued side (past ~27° yaw) at any point during the 4 s inhale
  counts as the turn achieved. No hold is required during the
  inhale — the hold is the return.
- **Exhale:** voice "呼气，慢慢回正". Returning to center
  (<10° on BOTH yaw and pitch) at any point during the 4 s
  exhale counts as the return achieved.
- **A cycle counts (+1) only if BOTH the turn and the return
  were achieved in their phases.** Otherwise it is a miss:
  voice "这一轮没跟上，没关系，下一轮" — encouraging, not
  punishing. After 8 cycles the done screen shows completed
  x/8 and "再来一局" (tap restarts, recalibrates).
- **CENTER-PASS RULE for a new turn (documented, implemented).**
  If the player is still turned when a new inhale starts (the
  previous return was missed), the new turn does NOT count
  until the head first passes through center (|yaw| < 10°).
  A still-turned head is never silently counted as a new turn.
  The missed return already failed the previous cycle; the
  center-pass requirement is the guard for the next one.
- **Calibration is one prompt, inside the playing state (GA02's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请向左转一下" as its first
  instruction, then "回正到中间", then cycle 1. Nothing counts
  before calibration completes; restarting (tap on done)
  re-runs calibration.
- **Voice is primary.** Every phase is announced, every cycle's
  result is spoken, completion is spoken with the completed
  count. The screen mirrors the same lines. TTS uses the fixed
  host voice; the utterance `lang` is never set (documented:
  it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the current phase (吸气/
  呼气) with the cued side arrow, cycle count x/8, and one
  short hint ("跟着呼吸，慢慢转").

## Technical honesty

- **NO BREATH SENSOR — breathing is NEVER measured.** Rokid
  glasses have no breath sensor. This game is VOICE-PACED:
  TTS announces "吸气" and "呼气" on a fixed 4 s + 4 s rhythm
  and the sensor checks only the HEAD movement in each phase.
  The ready screen says this plainly ("眼镜测不到呼吸，语音
  只定节奏"), and so do this file and the README. Any claim
  that the glasses detect breath would be false.
- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No shake / turn / tilt gesture events are claimed or used.
  Left/right detection comes from the sensor quaternion, never
  from a gesture event.
- **Thresholds (encoded and documented here):**
  - cued side reached: ~25-30 deg yaw — coded as 27 deg
  - return-to-center: <10 deg on BOTH yaw and pitch
  - inhale phase: 4000 ms; exhale phase: 4000 ms
  - pause between cycles: 1000 ms
  - cycles per game: 8, fixed alternating sequence
    L,R,L,R,L,R,L,R
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent, GA02/GA15's, plus pitch):**
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
  - pitch = asin(2*(w*x - y*z)), clamped, in degrees
  - Only the RELATIVE yaw/pitch vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Yaw sign — learned, not assumed (device verification item).**
  The one-prompt calibration records the sign the head actually
  moves when asked to turn left, so a host yaw-sign inversion
  cannot silently swap left/right counts. Residual caveat:
  calibration trusts the player to follow that one prompt;
  turning right instead of left would learn the signs backwards.
  Fail-safe: nothing counts before calibration completes, the
  first cycle is left again (so a backwards calibration feels
  wrong at once), and any restart re-runs calibration. The
  device checklist must confirm: (1) the calibration prompt
  appears and completes on a real left turn, (2) a real left
  turn then counts as left, not right, (3) a breath-paced
  cycle with a real turn + real return counts, (4) a cycle
  with a turn but no return does NOT count, (5) the 4 s + 4 s
  pacing feels comfortable on device (not rushed, not dragging).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per phase — inhale turn, exhale return —
  per cycle, 8 demo cycles) so the playing and done states can
  be previewed. On a real device with a sensor there is no DEMO
  path at all, and the done screen says 「演示完成」 only when
  demo cycles were used.
- **Zero persistence by construction:** no storage calls anywhere;
  center, learned sign, cycle and completed counts live in page
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
- Logic harness (see README for the check count): constants
  read from the real .ink file; cycle counting, phase timing,
  alternating sequence, center-pass rule, both-axes return,
  demo stepping, and done-ignores-turning.
- Preview screenshots in `screenshots/breathe-turn/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
