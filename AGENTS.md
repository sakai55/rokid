# Pace Turn （匀速转头） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA23, Wave 2, Group E
(precision control): a paced-turn game. Extreme simplicity:
3 states only (ready / playing / done), one page, one main button.

Distinct from GA15 (slow-scan): GA15 is ONE continuous
left-to-right pass with an 8 s minimum — only a lower bound, and
no return between sides. This game is SINGLE turns from center,
each with a 3–5 s pace WINDOW: too fast fails AND too slow
fails, and every turn starts from and returns to center.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> return to center -> next turn. The
call NEVER asks for a sweep or a circle: one side per turn,
turned to, returned from, and only then is the next call
announced. Never sweep from one extreme to another, never fast
jerking. This game is about turning SLOWLY and EVENLY: a fast
turn is a failed turn by design, speed is never rewarded. Slow,
small range, stop at mild stretch, never pain. Stop at once on
pain / dizziness / numbness / nausea. Sit or stand steady
first. One round set is 6 turns, short. This is entertainment /
daily activity, NOT medical diagnosis, treatment or a rehab
prescription; people with cervical disease, vertigo, post-op or
head/neck injury history should ask a doctor first. The short
version is on the in-game ready screen; the full text is here
and in the README.

## Design contract

- **One mechanic.** 6 turns, one at a time. Per turn: TTS calls
  one side ("向左，匀速转") and the screen shows the same call
  (arrow + side). The player turns from center to that side's
  edge (27 deg). The turn counts (+1, voice "节奏正好") ONLY if
  it is completed inside the pace window defined below.
- **Timing definition (exact).** The pace clock starts the
  moment the relative yaw leaves the center zone — |yaw| past
  10 deg TOWARD the called side — and stops when the yaw reaches
  the side threshold, 27 deg toward the called side.
  - ON PACE: elapsed between 3.0 s and 5.0 s inclusive -> counts.
  - TOO FAST: reaching 27 deg in < 3.0 s -> fail ("太快了").
  - TOO SLOW: the clock passing 5.0 s before reaching 27 deg ->
    fail at once ("太慢了"), the turn is over. The deadline is
    checked before the reach on any tick past 5.0 s, so a head
    that only crosses 27 deg after 5.0 s is too slow, never on
    pace. (A reach at exactly 5.0 s is inside the window.)
  - WRONG SIDE: yaw past 15 deg to the opposite side -> fail at
    once ("方向反了"), checked before the turn starts and while
    it runs.
  - ABORT: returning inside the center zone (<10 deg) before
    reaching 27 deg, after the clock started -> fail
    ("没转到底").
  - A flick straight past the edge in one tick is judged with
    ~0 elapsed = too fast: the turning checks run in the same
    tick the clock starts.
- **Fixed side list (NOT random, so preview and device
  behaviour are reproducible):** left, right, left, right,
  left, right. Documented here and in the code (`SIDES`). Every
  turn is separated by a return to center, so no circling
  arises.
- **Idle re-prompt.** If a called turn has not started (head
  still in the center zone) after 8 s, TTS re-prompts the call
  exactly once; nothing is ever auto-counted.
- **No mid-turn cue.** TTS stays minimal by design: the only
  spoken lines are the call, the result, the return prompt and
  the calibration prompts. There is deliberately no "keep
  going" encouragement mid-turn.
- **Return-to-center gates every next call.** After every turn
  (counted or failed) the player MUST return to center (<10 deg
  on BOTH axes, pitch and yaw) before the next call is
  announced. If not returned within 4 seconds, TTS prompts
  "请回正" and the grace timer resets — the grace counts
  nothing and the next call is NEVER announced until the return
  actually happens. This is GA10/GA13's stricter rule,
  deliberately NOT GA09's advance-anyway grace: the return rule
  is what keeps this game segmented, not a sweep. The final
  turn ends the game at once: there is no next turn for a
  return to gate.
- **Calibration is one prompt, inside the playing state
  (GA02's pattern).** It is not a fourth page state and not a
  menu: START calibrates the center (head straight at START),
  then the playing screen shows "请向左转一下" as its first
  instruction, then "回正到中间", then turn 1. Nothing counts
  before calibration completes; restarting (tap on done)
  re-runs it.
- **Voice is primary.** Every turn is announced, every outcome
  is spoken (on-pace / too fast / too slow / wrong side /
  aborted), completion is spoken via the result line of the
  final turn. The screen mirrors the same lines. TTS uses the
  fixed host voice; the utterance `lang` is never set
  (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the current side call
  (arrow + side), the on-pace count x/6, and one short hint.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No look / turn / tilt gesture events are claimed or used.
  Angles come from the sensor quaternion, never from a gesture
  event.
- **Thresholds (encoded and documented here):**
  - side edge (turn complete): 27 deg toward the called side
  - center zone: |yaw| <= 10 deg; the pace clock starts past
    10 deg toward the called side
  - pace window: 3.0–5.0 s inclusive (PACE_MIN_MS 3000,
    PACE_MAX_MS 5000); the too-slow deadline is checked before
    the reach on any tick with elapsed > 5000 ms
  - wrong side: past 15 deg to the opposite side = fail at once
  - abort: back inside 10 deg before reaching 27 deg, after the
    clock started = fail
  - return-to-center: <10 deg on BOTH axes (pitch and yaw)
  - return grace: 4 s, then TTS "请回正" and the timer resets;
    the next call is never announced until the return happens
  - idle / calibration stall re-prompt: 8 s, once per step
  - tick: 100 ms, so judged elapsed times are quantised to
    100 ms steps (a true 2.95 s turn reads as 2.9 or 3.0 s —
    device-stage tolerance note, not a hidden fudge)
- **Formulas (fleet-consistent):**
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
    (GA02's formula) — turns are judged on yaw alone, because
    every called target is a left/right turn
  - pitch = asin(2*(w*x - y*z)), clamped (GA01/GA04's formula) —
    read ONLY for the return-to-center gate (both axes <10 deg)
  - Only the RELATIVE pitch/yaw vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Yaw sign — learned, not assumed (device verification
  item).** The one calibration prompt records the sign the head
  actually moves when asked to turn left as LEFT; RIGHT is the
  opposite yaw sign (GA02's pattern). Residual caveat:
  calibration trusts the player to follow that one prompt;
  turning right instead of left would learn the signs backwards.
  Fail-safes: nothing counts before calibration completes, the
  first turn is left again, so a backwards calibration feels
  wrong at once, and any restart re-runs the prompt. The device
  checklist must confirm: (1) the calibration prompt appears
  and completes on a real left turn, (2) a real left turn then
  counts as left, not right (the left-sign check).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole turn as an on-pace turn, return
  collapsed) so the playing and done states can be previewed.
  On a real device with a sensor there is no DEMO path at all,
  and the done screen says 「演示匀速 x / 6」 only when demo
  turns were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, turn, center and learned sign live in page memory
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
- Logic harness (see README 验证情况 for the count), driving
  the real `.ink` state machine with synthetic sensor readings
  and a controllable clock: left-sign learning from a
  negative-raw-yaw host, calibration return, fixed side order,
  on-pace at 4.0 s counting, window edges (3.0 s counts, 2.9 s
  too fast, 5.0 s counts, past 5.0 s too slow even when the edge
  is crossed late), too-slow failing at once before the edge,
  wrong side failing before and during a turn, abort on backing
  into the center zone, one-tick flick judged too fast, return
  gate holding the next call past the 4 s grace with a spoken
  "请回正", idle re-prompt counting nothing, full 6-turn run
  ending with only on-pace turns scored, restart re-running
  calibration.
- Preview screenshots in `screenshots/pace-turn/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
