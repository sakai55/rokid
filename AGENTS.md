# Tilt Match （贴耳对角度） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA22, Wave 2, Group E (precision
control): a tilt angle-matching game. Extreme simplicity: 3 states
only (ready / playing / done), one page, one main button.

This game is the ROLL-axis counterpart of GA21 (angle-match):
GA21 judged angle precision on the YAW axis (turn left/right into
a called band); this game judges the same precision on the ROLL
axis (ear-to-shoulder tilt into a called band).

Distinct from GA03 (ear-tilt): GA03 tilted to the comfortable
limit and held a full 5 s — a stretch exercise. This game matches
SMALL called target angles (12 or 20 deg, +/-5 deg) and holds
only ~0.8 s — precision, not stretch. Overshooting a 12 deg
target out to 20+ deg is NOT a hit; the player must settle back
into the band, and leaving the band resets the hold.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
trial. The call NEVER asks for a sweep or a circle: one side and
one small angle per trial, matched, returned from, and only then
is the next call announced. Never sweep from one extreme to
another, never fast jerking. Ear tilts are gentle: the ear goes
toward the shoulder, NEVER force it, and NEVER lift the shoulder
up to meet the ear — the shoulder stays down, and "肩膀别抬" is
said in the voice guidance (every trial call, the calibration
prompt, the ready screen), not just written here. Slow, small
range, stop at mild stretch, never pain. Stop at once on pain /
dizziness / numbness / nausea. Sit or stand steady first. One
round set is 6 trials, short. This is entertainment / daily
activity, NOT medical diagnosis, treatment or a rehab
prescription; people with cervical disease, vertigo, post-op or
head/neck injury history should ask a doctor first. The short
version is on the in-game ready screen; the full text is here
and in the README.

## Design contract

- **One mechanic.** 6 trials, one at a time. Per trial: TTS calls
  one side and one small angle ("向左贴，12 度，肩膀别抬") and
  the screen shows the same call (arrow + side + degrees).
  Tilting so the relative roll enters the target band (target
  +/-5 deg) speaks "停，稳住" once; holding steady ~0.8 s inside
  the band = hit (+1, voice "对上了"). Leaving the band before
  the hold completes — leaning back OR overshooting — resets
  the hold to zero and counts nothing; the 10-second trial clock
  keeps running, so a stalled trial still ends as a miss.
- **Fixed trial list (NOT random, so preview and device
  behaviour are reproducible):** (left, 12°), (right, 20°),
  (left, 20°), (right, 12°), (left, 12°), (right, 20°) — 3 per
  side. Documented here and in the code (`TRIALS`). Every trial
  is separated by a return to center, so no circling arises.
- **Miss rules.** Tilting to the WRONG side past 15 deg = miss
  for that trial at once (voice "没对上"). No hit within
  10 seconds = miss (voice "没对上"), including a hold that is
  still incomplete when the clock runs out.
- **Return-to-center gates every next call.** After every trial
  (hit or miss) the player MUST return to center (roll, pitch
  AND yaw all <10 deg vs the calibrated center) before the next
  call is announced. If not returned within 4 seconds, TTS
  prompts "请回正" and the grace timer resets — the grace counts
  nothing and the next call is NEVER announced until the return
  actually happens. This is GA10/GA13's stricter rule,
  deliberately NOT GA09's advance-anyway grace: the return rule
  is what keeps this game segmented, not a sweep. The final
  trial ends the game at once: there is no next trial for a
  return to gate.
- **Calibration is one prompt, inside the playing state (GA03's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then the
  playing screen shows "请向左贴一下" as its first instruction,
  then "回正到中间", then trial 1. Nothing counts before
  calibration completes; restarting (tap on done) re-runs it.
- **Voice is primary.** Every trial is announced (with
  "肩膀别抬"), band entry is spoken ("停，稳住"), every outcome
  is spoken (hit / miss), completion is spoken. The screen
  mirrors the same lines. TTS uses the fixed host voice; the
  utterance `lang` is never set (documented: it does not take
  effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the target call (arrow +
  side + degrees), hits x/6, and one short hint.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Angles come from the sensor quaternion, never from a gesture
  event.
- **Thresholds (encoded and documented here):**
  - target band: called angle +/-5 deg (12 deg targets judge
    7-17 deg, 20 deg targets judge 15-25 deg)
  - hold: ~0.8 s (800 ms) inside the band; the hold accumulates
    only while steady where the host reports stability events
    via `onOrientationStabilityChange`; if the host never
    reports them, elapsed time alone gates the hold (documented
    fallback, not a fake stable)
  - wrong side: past 15 deg toward the uncalled side = miss at
    once
  - calibration trigger: a 15 deg tilt in either direction
    during the calibration prompt; the direction actually moved
    is learned as LEFT (see roll sign below)
  - trial clock: 10 s, no hit = miss
  - return-to-center: roll, pitch AND yaw all <10 deg vs the
    calibrated center (roll is the judged axis; pitch and yaw
    must also be back, so a leftover turn or nod cannot fake a
    return — the same both-axes return discipline as GA21,
    extended to all three axes because tilting also moves the
    fleet pitch reading)
  - return grace: 4 s, then TTS "请回正" and the timer resets;
    the next call is never announced until the return happens
  - calibration stall re-prompt: 8 s, once per step
- **Formulas (fleet-consistent):**
  - roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)), in degrees
    (GA03's formula) — trials are judged on roll alone, because
    every called target is a left/right ear tilt
  - pitch = asin(2*(w*x - y*z)), clamped (GA01/GA04's formula)
    and yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)) (GA02's
    formula) — read ONLY for the return-to-center gate
  - Only the RELATIVE roll/pitch/yaw vs the calibrated center
    are used, so the host's absolute zero never matters.
- **Roll sign — learned, not assumed (device verification
  item).** The one calibration prompt records the sign the head
  actually moves when asked to tilt left as LEFT; RIGHT is the
  opposite roll sign (GA03's pattern). Residual caveat:
  calibration trusts the player to follow that one prompt;
  tilting right instead of left would learn the signs backwards.
  Fail-safes: nothing counts before calibration completes, the
  first trial is left again, so a backwards calibration feels
  wrong at once, and any restart re-runs the prompt. The device
  checklist must confirm: (1) the calibration prompt appears and
  completes on a real left tilt, (2) a real left tilt then
  counts as left, not right (the left-tilt sign check).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole trial as a hit, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示对上 x / 6」 only when demo
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
- Logic harness (45 checks, all passing), driving the real
  `.ink` state machine with synthetic quaternion readings and a
  controllable clock: fixed trial list and constants read from
  the source; left-sign learning from both a negative-raw-roll
  host and a positive-raw-roll host; calibration return; trial
  calls in fixed order with the "肩膀别抬" line; band edges
  inclusive at 7 and 17 deg for a 12 deg target and exclusive
  outside (6.9 deg not in band, 26 deg overshoot not in band for
  a 20 deg target); band entry speaking "停，稳住" once; leaving
  the band early resetting the hold with no count; 8 ticks
  (0.8 s) in band = hit but 7 ticks not; return gate holding the
  next call past the 4 s grace with a spoken "请回正", a yaw
  offset keeping the gate closed, and a real return releasing
  the next call; wrong side past 15 deg = instant miss while
  14 deg does not miss (the exact-15 boundary asserted on the
  `_wrongSide` predicate itself, because a quaternion feed of
  exactly -15 deg computes to -14.999999999999998); 10 s timeout
  = miss; full 6-trial run ending 4/6 with the final trial
  ending the game at once; calibration stall re-prompting once
  with no auto-count; restart re-running calibration with the
  score reset.
- Preview screenshots in `screenshots/tilt-match/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
