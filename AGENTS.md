# Daily Routine （每日一套） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA20, Group D (fun finale) and the
SERIES FINALE (20/20): a guided daily routine stringing the
A-group moves together. Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

Distinct from every other game in the series: GA01–GA06 each teach
ONE move; this finale strings all five A-group moves together in
one routine, with a per-segment skip rule so the routine always
finishes. It is not a harder version of any single game — its
holds are deliberately SHORTER (3 s, not 5 s) than GA03/GA04/GA06,
because a routine that demanded five 5-second holds plus nods
and turns would run long and tire the neck.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold/return -> center -> next move.
Never continuous circling, never a sweep from one extreme to
another, never fast jerking. Slow, small range, stop at mild
stretch, never pain. **For UP specifically: only to a mild
stretch, NEVER hyperextend, NEVER throw the head back** — this
is said in the voice guidance, not just on screen. Stop at once
on pain / dizziness / numbness / nausea. Sit or stand steady
first. The whole routine takes about 2 minutes (honest estimate
from the segment timings: roughly 90–120 seconds of moves plus
returns and calibration — not a promised exact duration). This
is entertainment / daily activity, NOT medical diagnosis,
treatment or a rehab prescription; people with cervical disease,
vertigo, post-op or head/neck injury history should ask a doctor
first. The short version is on the in-game ready screen; the
full text is here and in the README.

## Design contract

- **One mechanic.** Follow the guided routine to the end. 5
  segments in FIXED order (NOT random, so preview and device
  behaviour are reproducible), documented here and in the code
  (`SEG_NAMES`, `SEG_REPS`, `TURN_SEQ`, `EAR_SEQ`,
  `STRETCH_SEQ`):
  1. 点头 3 次 — gentle nods, GA01 pattern: down past ~27 deg,
     hold ~0.8 s, return <10 deg. Nod event primary + pitch
     fallback (see below).
  2. 转头左右各 2 次 — alternating left, right, left, right,
     GA02 pattern: past ~27 deg, hold ~0.8 s, return <10 deg.
  3. 贴耳左右各 1 次 — ear-to-shoulder hold 3 s each side,
     GA03 pattern BUT 3 s, not GA03's 5 s (deliberate routine
     shortening). Voice: 「肩膀别抬」.
  4. 仰低拉伸各 1 次 — up hold 3 s, then down hold 3 s, GA04
     pattern BUT 3 s, not GA04's 5 s (deliberate routine
     shortening). Up only to a mild stretch.
  5. 收下巴 2 次 — chin tucks, GA06 pattern BUT 3 s, not GA06's
     5 s (deliberate routine shortening): small pitch in the
     14–20 deg band, hold 3 s, return <8 deg pitch. Pitch
     >= 20 deg is a full nod, NOT a tuck, and counts nothing
     (voice correction 「幅度小一点，这是收下巴不是低头」).
- **A rep counts only as target -> full hold -> return.** A
  move that backs off before the hold is aborted with no count.
  A move without a return never counts.
- **Segment timeout: 30 s per segment.** If a segment is not
  completed within 30 s, voice says 「这一节先跳过」 and the
  routine moves to the next segment. A skipped segment is
  counted as skipped, NOT as failed and NOT as completed; the
  routine always finishes. The done screen reports completed
  segments x/5; skipped segments are simply the remainder.
- **Return-to-center gates every next segment.** After every
  segment except the last, the player MUST return to center
  (<10 deg on BOTH axes; after the tuck segment the pitch
  return is already <8 deg, the gate still checks both axes)
  before the next segment is announced. If not returned within
  4 seconds, TTS prompts 「请回正」 and the grace timer resets
  — the grace counts nothing and the next segment is NEVER
  announced until the return actually happens. This is
  GA10/GA13's stricter rule, deliberately NOT GA09's
  advance-anyway grace. The final segment ends the routine at
  once: there is no next segment for a return to gate.
- **Calibration is three prompts, inside the playing state.**
  It is not a fourth page state and not a menu: START
  calibrates the center (head straight at START), then the
  playing screen shows 「请低一下头」 as its first
  instruction, then 「回正到中间」, then 「请向左转一下」,
  then 「回正到中间」, then 「请向左贴一下」, then
  「回正到中间」, then segment 1. Nothing counts before ALL
  THREE calibrations complete; restarting (tap on done)
  re-runs all three.
- **Voice is primary.** Every segment is announced, every rep
  is counted, every hold is counted down in the hint, segment
  completion and skipping are spoken. The screen mirrors the
  same lines. TTS uses the fixed host voice; the utterance
  `lang` is never set (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; nod = the segment-1 action itself;
  double-tap = host back, never intercepted; no swipe handling,
  no other buttons.
- **Playing screen shows at most:** the current segment name,
  segment progress x/5, the current move count or hold seconds,
  and one short hint.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  No shake / turn / tilt gesture events are claimed or used.
  The nod event is used ONLY in segment 1, and it NEVER counts
  on its own: it only completes a nod rep the sensor already
  saw go down, once the head is back inside the center band
  (GA01's pattern); in `segWait` it moves a head already down
  past 15 deg into the hold, so a gentle nod the pitch
  fallback would miss still counts when the sensor confirms
  the head is down. All other moves come from the sensor
  quaternion, never from a gesture event.
- **Thresholds (encoded and documented here):**
  - direction reached: ~25-30 deg — coded as 27 deg
  - nod / turn hold: ~0.8 s (800 ms)
  - ear / stretch / tuck hold: 3 s (3000 ms, routine variant)
  - tuck band: 14–20 deg pitch; >= 20 deg = full nod, voided
    with correction; early-release cut below 11 deg voids
  - tuck return: pitch < 8 deg (GA06, tighter than 10 deg)
  - other returns: <10 deg on BOTH axes (pitch and yaw)
  - segment timeout: 30 s, then skip (never fail)
  - return grace: 4 s, then TTS 「请回正」 and the timer resets;
    the next segment is never announced until the return happens
  - calibration stall re-prompt: 8 s, once per step
  - holds accumulate only while steady where the host reports
    stability events via `onOrientationStabilityChange`; if the
    host never reports them, elapsed time alone gates the hold
    (documented fallback, not a fake stable)
- **Formulas (fleet-consistent):**
  - pitch = asin(2*(w*x - y*z)), clamped
  - yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z)), in degrees
  - roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y)), in degrees
  - Only the RELATIVE values vs the calibrated center are
    used, so the host's absolute zero never matters.
- **Sign learning — three axes, all learned, none assumed
  (device verification items).**
  - DOWN: the first calibration prompt records the sign the
    head actually moves when asked to look down as DOWN; UP is
    the opposite pitch sign (GA01/GA04 pattern).
  - LEFT: the second calibration prompt records the sign the
    head actually moves when asked to turn left as LEFT; RIGHT
    is the opposite yaw sign (GA02 pattern).
  - LEFT ROLL: the third calibration prompt records the sign
    the head actually moves when asked to tilt left as LEFT;
    right roll is the opposite roll sign (GA03 pattern).
  - Residual caveats: calibration trusts the player to follow
    each prompt; doing the opposite motion would learn that
    axis backwards. Fail-safes: nothing counts before all three
    calibrations complete, and any restart re-runs all three.
    The device checklist must confirm: (1) all three prompts
    appear and complete on real motions, (2) a real look-down
    then counts as down, not up, and a real look-up as up,
    (3) a real left turn then counts as left, not right,
    (4) a real left tilt then counts as left roll, not right,
    (5) a real full nod in the tuck segment is rejected with
    the 「幅度小一点」 hint and counts nothing, (6) a segment
    left unfinished for 30 s is skipped with 「这一节先跳过」
    and the routine continues, (7) the next segment never
    appears before the return, with a 4-second non-return
    producing a spoken 「请回正」.
- **The tuck-detection proxy, stated honestly (device
  verification item, GA06's flag carried over).** A chin tuck is
  mostly a horizontal TRANSLATION, which an orientation sensor
  barely sees; there is no translation sensor API on this
  platform. This routine therefore detects the tuck as a SMALL
  pitch motion in the learned down direction, and the voice cue
  deliberately describes it as 「像点头的一半还不到」 — the
  player glides the chin back with only the smallest nod-like
  component. The device test must confirm a natural tuck lands
  in the 14–20 deg band. If real tucks systematically
  under-register (pure glides reading near 0 deg), the fix is
  to adjust the THRESHOLD (lower the band), not to pretend the
  motion is something it is not — and if no small pitch band
  separates tucks from noise at all, that result must be
  reported honestly rather than shipped as a working tuck
  detector.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen
  says 「传感器：SKIP（网页预览无方向传感器，演示模式）」, and
  the main button becomes a labeled demo stepper (calibration
  steps, then one tap per whole segment) so the playing and
  done states can be previewed. On a real device with a sensor
  there is no DEMO path at all, and the done screen says
  「演示完成」 only when demo segments were used.
- **Zero persistence by construction:** no storage calls anywhere;
  count, center and learned signs live in page memory and die
  with the page.
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
  usage; no invented APIs; the only head-gesture handler is
  `onHeadGesture` for `'nod'` in segment 1 only; permissions
  match the features actually used (empty, matching zero
  permission-gated features).
- Logic harness (77 checks, all passing, driving the real
  `.ink` code with synthetic sensor readings): constants read
  from the real file (27/10 deg, 0.8 s / 3 s holds, 14–20 deg
  tuck band, 8 deg tuck return, 30 s segment timeout, 4 s
  return grace, segment reps 3/4/2/2/2, fixed sequences);
  three-prompt calibration; full 5-segment run to 5/5;
  wrong-way turn ignored; return gate blocks while turned;
  ear early-release aborts with no count; tuck overshoot
  >= 20 deg voids the hold with no count; tuck return < 8 deg
  completes the routine; 30 s timeout skips (not completes)
  a segment and the routine continues; nod-event path
  (down-past-15 into hold, return completion).
- Preview screenshots in `screenshots/daily-routine/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
