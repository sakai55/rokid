# Level Keep （端水平） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA14, Group C
(observation/control): a level-hold game. Extreme simplicity:
3 states only (ready / playing / done), one page, one main
button.

Distinct from GA07 and from photo-level:
- GA07 steady-hold counts the ABSENCE of motion in ANY direction
  (total angular change from the settle reference, <5 deg).
  This game counts ROLL ONLY: pitch/yaw drift alone does NOT
  break level. The player can look slightly up/down or turn
  slightly and still be level, as long as the head is not
  tilted sideways. Level is shown as a visual ball on a track
  (centered = level, offset left/right with roll) — GA07 has no
  ball, because GA07 has no axis to display.
- photo-level levels a CAMERA photo. This game levels the HEAD
  (roll from the orientation sensor), with no camera at all.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** This game involves NO
turning at all: the whole game is holding the head level.
Never fast jerking. Sit or stand steady first, feet steady,
no walking while playing. Stop at once on pain / dizziness /
numbness / nausea. One round is a single 10-second level hold,
replayable. This is entertainment / daily activity, NOT medical
diagnosis, treatment or a rehab prescription; people with
cervical disease, vertigo, post-op or head/neck injury history
should ask a doctor first. The short version is on the in-game
ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** Tap start -> 1-second settle ("摆好，端平，
  开始") capturing the level reference -> hold the head level
  for 10 continuous seconds = win. The playing screen shows at
  most a level ball/track (ball centered = level, ball offset
  left/right with roll), seconds held x/10, and one short hint
  ("端平，别歪"). TTS guides: start cue, the settle cue, the
  hold-start cue ("开始，端平，别歪"), tilt warnings
  ("往左歪了" / "往右歪了", once per excursion — see the
  direction-naming convention below), the reset cue
  ("歪了，从头来"), the rest cue after 5 resets
  ("休息一下再来"), and the success announcement
  ("端平 10 秒，好平").
- **A win counts only as 10 continuous seconds in band.**
  Any roll beyond ±8 deg sustained longer than 0.3 s resets
  the timer to 0 immediately and the attempt restarts
  automatically (1-second settle, level reference re-captured,
  no tap needed for the restart).
- **Fairness grace: tilts under ~0.3 s do NOT reset.** A
  deviation beyond the band lasting under 300 ms (a tremor /
  blink-scale wobble) freezes accumulation but does not clear
  it; if the head returns inside the band within 300 ms, the
  hold resumes from the same value. Only a tilt sustained for
  300 ms or more resets (see "Thresholds").
- **Reset cap: 5 resets in one round -> rest.** On the 5th reset
  the game does NOT restart again: TTS says "休息一下再来" and
  the game returns to ready, whose hint then reads "休息一下再
  来 · 单击重新开始". A fresh start resets the reset count.
- **Tap abandons (real device).** Tap during playing abandons
  the round to ready ("停了"). In the sensor-SKIP demo the tap
  is instead the labeled demo stepper (see below) — the demo
  needs taps to advance, so it cannot also abandon.
- **Voice is primary.** Every step is spoken; the screen mirrors
  the same lines plus the ball, the roll band note and the
  seconds-held number. TTS uses the fixed host voice; the
  utterance `lang` is never set (documented: it does not take
  effect).
- **Gestures:** single tap = Enter = start / abandon / play
  again; double-tap = host back, never intercepted; no swipe
  handling, no other buttons. There is deliberately no
  head-gesture handler at all (see below).

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  This game uses NO gesture events at all — no nod handler, no
  other gesture claimed. Level comes from the sensor
  quaternion alone.
- **Roll metric (exact, as implemented):** roll from the sensor
  quaternion, `roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))`,
  in degrees (the GA03 ear-tilt formula). The level reference
  is the roll captured at the end of the settle, and the
  judged value is the RELATIVE roll: the wrapped difference
  of the current roll and the reference roll, in [-180, 180].
  Only the RELATIVE roll vs the captured reference is used, so
  the host's absolute zero never matters. Pitch and yaw are
  never computed and never judged — a pitch/yaw drift alone
  cannot break level, by construction.
- **Roll direction naming — display convention, NOT a verified
  host sign.** Relative roll > 0 is displayed and spoken as a
  RIGHT tilt ("往右歪了", ball to the right) and relative
  roll < 0 as a LEFT tilt ("往左歪了", ball to the left).
  This naming is a convention to verify on device, not a
  claimed gesture or a verified host sign: the device
  checklist must confirm a real right tilt shows
  "往右歪了" (and a real left tilt shows "往左歪了"); if the
  host roll axis is inverted, the naming must be swapped.
  The band, grace and win logic are unaffected by naming,
  since they judge |relative roll| only.
- **Thresholds (encoded and documented here):**
  - settle: 1000 ms; the level reference roll is captured at
    the end of the settle (if no reading has arrived yet, the
    settle waits in 200 ms steps rather than capturing null)
  - level band: |relative roll| <= 8 deg (tighter than a
    direction threshold, because level is a fine control task)
  - ball scale: 1 track cell per ~2 deg of relative roll,
    clamped to the track ends (band edge ±8 deg = ±4 cells
    from center)
  - grace: tilt beyond 8 deg for < 300 ms does NOT reset
    (accumulation frozen, not cleared); >= 300 ms sustained
    resets the timer to 0 and auto-restarts the attempt
  - win: 10000 ms accumulated while inside the band
  - reset cap: 5 resets in one round -> rest + back to ready
  - tick: 100 ms; hold accumulates 100 ms per tick while inside
    the band
- **Stability event — supporting signal only, never the sole
  signal.** Where the host reports `onOrientationStabilityChange`,
  an unstable report PAUSES accumulation but never resets it and
  never passes a hold on its own; a stable report is not
  required for a win. If the host never reports stability
  events, elapsed time inside the band alone gates the hold
  (documented fallback, not a fake stable).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo stepper (settle, then +1 s per
  tap, ball centered throughout) so the playing and done states
  can be previewed. On a real device with a sensor there is no
  DEMO path at all, and the done screen says 「演示端平 10 秒」
  only when demo seconds were used.
- **Zero persistence by construction:** no storage calls anywhere;
  held time, level reference roll, reset count and grace state
  live in page memory and die with the page.
- **No camera, no mic/ASR, no network, no LLM.** Nothing to SKIP.
  In particular this game uses no camera, unlike photo-level.

## Permissions

None — `permissions` is an empty array. Sensor and TTS are not
among the only three permissions (`GEOLOCATION`, `CAMERA`,
`RECORD_AUDIO`), and the code uses neither of those three features,
so nothing is declared. Verified by a successful empty-permissions
pack (see README).

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; no head-gesture handler at all (the API documents
  only 'nod', which this game never uses); permissions match the
  features actually used (empty, matching zero permission-gated
  features).
- Logic harness (17 checks, all passing): roll formula values,
  relative-roll wrap at ±180 deg, yaw-only and pitch-only
  rotations giving roll 0 (so pitch/yaw drift cannot break
  level), 100 level ticks = win, a 200 ms tilt excursion not
  resetting, a 400 ms tilt resetting once then winning, band
  boundary at 8 deg, 5 resets -> rest, ball centering /
  ±4 cells at the band edge / clamping at the track ends.
- Preview screenshots in `screenshots/level-keep/` (ready /
  playing / done), generated with the local Ink runtime pipeline and
  read back to confirm each shows its own state.
