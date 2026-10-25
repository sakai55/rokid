# Neck Clock （时钟点位） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA05: the flagship anti-circling
teaching game. Extreme simplicity: 3 states only (ready / playing /
done), one page, one main button.

Distinct from GA01–GA04: this game does not count reps in one axis.
It teaches the point-vs-circle distinction itself: every cue is ONE
clock position (12 = up, 6 = down, 3 = right, 9 = left), reached,
held ~0.8 s, and returned from — and only then is the next cue
announced. The sequence is fixed and deliberately NON-circular:
12, 9, 6, 3, 9, 12, 3, 6 — never a 12-3-6-9 clockwise run, and no
cue may be reached by sweeping from the previous one.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
direction. Never continuous circling, never sweep from one extreme
to another, never fast jerking. Slow, small range, stop at mild
stretch, never pain. **For UP (12 o'clock) specifically: only to a
mild stretch, NEVER force the head far back, NEVER hyperextend,
NEVER throw the head back** — this is said in the voice guidance,
not just on screen. Down is likewise only to a mild stretch (never
press the chin to the chest). Stop at once on pain / dizziness /
numbness / nausea. Sit or stand steady first. One round is 60-180 s.
This is entertainment / daily activity, NOT medical diagnosis,
treatment or a rehab prescription; people with cervical disease,
vertigo, post-op or head/neck injury history should ask a doctor
first. The short version is on the in-game ready screen; the full
text is here and in the README.

## The anti-circle teaching line

The opening voice line and the ready screen both say, verbatim:

「这是点位，不是转圈：每次只到一个点位，停住，回正，再报下一个」

The ready screen additionally prints the fixed sequence
(12、9、6、3、9、12、3、6) and states it does not run clockwise
around the dial. The done voice line closes the lesson: 「完成，
8 个点位都到过了，没有转圈。」

## Design contract

- **One mechanic.** 8 clock points in the fixed order above.
  START calibrates the center (head straight at START), then TWO
  calibration prompts inside the playing state (not extra states):
  (1) 「请低一下头」 learns DOWN; (2) 「请向左转一下」 learns
  LEFT. Each calibration step is followed by a return-to-center
  step, and the center is re-set on each return. Nothing counts
  before BOTH calibrations complete; restart re-runs both.
- **A point counts only as reach -> hold ~0.8 s -> return.**
  Releasing early counts nothing ("没稳住，重新来"). A move
  without a return never counts, and the next cue is only announced
  after the return: sweeping straight to the next position without
  returning counts nothing and is told "请先回正，不要直接转到
  下一个点". Moving to a wrong position while waiting counts
  nothing and is told "反了？请先回正，再到 X 点钟方向".
- **Stall = one re-prompt, never an auto-count.** If calibration
  or a cue stays unfinished longer than 8 s, TTS re-prompts exactly
  once per step; the count never moves on its own.
- **Voice is primary.** Every cue is announced ("下一个点位：
  9 点钟方向，左"), every reach is confirmed ("稳住"), every
  return is requested ("回正到中间"), completion is spoken. The
  screen mirrors the same lines: huge clock number + direction
  character (e.g. 「9 · 左」), count x/8, one short hint. TTS uses
  the fixed host voice; the utterance `lang` is never set
  (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak instruction /
  play again; double-tap = host back, never intercepted; no swipe
  handling, no other buttons. There is deliberately no head-gesture
  handler: the gesture API is documented only for 'nod', and nod is
  not this game's action.
- **Calibration is two prompts, inside the playing state.** It is
  not a fourth page state and not a menu: the playing screen simply
  shows "请低一下头" / "回正到中间" / "请向左转一下" / "回正到
  中间" as its first instructions, then the first cue (12).
  Restarting (tap on done) re-runs both calibrations.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No clock-position / turn / tilt / look-up / look-down gesture
  events are claimed or used. Clock positions come from the sensor
  quaternion, never from a gesture event.
- **Thresholds (encoded and documented here):**
  - direction reached: ~25-30 deg (pitch for 12/6, yaw for 3/9)
    — coded as 27 deg
  - return-to-center: <10 deg on BOTH axes (pitch and yaw), so a
    return counts only when the head is genuinely straight again
  - hold: ~0.8 s (800 ms); the hold accumulates only while steady
    where the host reports stability events via
    `onOrientationStabilityChange`; if the host never reports them,
    elapsed time alone gates the hold (documented fallback, not a
    fake stable)
  - cue-stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent):**
  - pitch = asin(2*(w*x - y*z)), clamped, as in GA01/GA04
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees,
    as in GA02
  - Only the RELATIVE pitch/yaw vs the calibrated center are used,
    so the host's absolute zero never matters.
- **Sign learning — two axes, both learned, neither assumed
  (device verification items).**
  - DOWN: the first calibration prompt records the sign the head
    actually moves when asked to look down as DOWN; UP is the
    opposite pitch sign (GA01/GA04 pattern).
  - LEFT: the second calibration prompt records the sign the head
    actually moves when asked to turn left as LEFT; RIGHT is the
    opposite yaw sign (GA02 pattern).
  - Residual caveats: calibration trusts the player to follow each
    prompt; looking up instead of down would learn the pitch signs
    backwards, and turning right instead of left would learn the
    yaw signs backwards. Fail-safes: nothing counts before both
    calibrations complete, the first cue is 12 (up) and the second
    is 9 (left), so a backwards calibration feels wrong at once,
    and any restart re-runs both prompts. The device checklist must
    confirm: (1) both calibration prompts appear and complete on a
    real look-down and a real left turn, (2) a real look-down then
    counts as 6, not 12, and a real look-up counts as 12, not 6,
    (3) a real left turn then counts as 9, not 3, and a real right
    turn counts as 3, not 9, (4) returning to center between cues is
    required — sweeping from one cue to the next counts nothing.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo stepper (calibration steps, then
  one tap per whole cue) so the playing and done states can be
  previewed. On a real device with a sensor there is no DEMO path
  at all, and the done screen says 「演示完成」 only when demo
  cues were used.
- **Zero persistence by construction:** no storage calls anywhere;
  count, center and learned signs live in page memory and die with
  the page.
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
- Preview screenshots in `screenshots/neck-clock/` (ready /
  playing / done), generated with the local Ink runtime pipeline and
  read back to confirm each shows its own state.
