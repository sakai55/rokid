# Steady Hold （稳头挑战） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA07: opening Group B
(head-as-controller). Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

Distinct from Group A (GA01–GA06): those games count head MOTIONS
(nods, turns, tilts, tucks). This game counts the ABSENCE of
motion — the whole game is staying still, and it involves NO
turning at all. That is itself the safety point: there is no
direction to overshoot, no extreme to sweep to, and no circle to
turn.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** This game involves NO
turning at all: the whole game is staying still. Never fast
jerking. Sit or stand steady first, feet steady, no walking
while playing. Stop at once on pain / dizziness / numbness /
nausea. One round is short: a single 10-second hold, replayable.
This is entertainment / daily activity, NOT medical diagnosis,
treatment or a rehab prescription; people with cervical disease,
vertigo, post-op or head/neck injury history should ask a doctor
first. The short version is on the in-game ready screen; the full
text is here and in the README.

## Design contract

- **One mechanic.** Tap start -> 1-second settle ("摆好，开始稳
  住") -> hold the head still for 10 continuous seconds = win.
  The playing screen shows at most a big progress (seconds held
  x/10) and one short hint ("别动，稳住"). TTS guides: start
  cue, the settle cue, the hold-start cue ("开始，稳住，别动"),
  the reset cue ("动了，从头来"), the rest cue after 5 resets
  ("休息一下再来"), and the success announcement ("稳满 10 秒，
  好稳").
- **A win counts only as 10 continuous seconds under threshold.**
  Any sustained movement beyond threshold resets the timer to 0
  immediately and the attempt restarts automatically (1-second
  settle, center re-captured, no tap needed for the restart).
- **Fairness grace: wobbles under ~0.3 s do NOT reset.** A
  deviation beyond threshold lasting under 300 ms (a
  tremor / blink-scale wobble) freezes accumulation but does not
  clear it; if the head returns inside threshold within 300 ms,
  the hold resumes from the same value. Only movement sustained
  for 300 ms or more resets (see "Thresholds").
- **Reset cap: 5 resets in one round -> rest.** On the 5th reset
  the game does NOT restart again: TTS says "休息一下再来" and
  the game returns to ready, whose hint then reads "休息一下再
  来 · 单击重新开始". A fresh start resets the reset count.
- **Tap abandons (real device).** Tap during playing abandons
  the round to ready ("停了"). In the sensor-SKIP demo the tap
  is instead the labeled demo stepper (see below) — the demo
  needs taps to advance, so it cannot also abandon.
- **Voice is primary.** Every step is spoken; the screen mirrors
  the same lines plus the seconds-held number. TTS uses the
  fixed host voice; the utterance `lang` is never set
  (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / abandon / play
  again; double-tap = host back, never intercepted; no swipe
  handling, no other buttons. There is deliberately no
  head-gesture handler at all (see below).

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  This game uses NO gesture events at all — no nod handler, no
  other gesture claimed. Stillness comes from the sensor
  quaternion alone.
- **Deviation metric (exact, as implemented):** total angular
  change from the orientation captured at the end of the settle,
  computed from quaternions: `angle = 2*acos(|dot(q, qCenter)|)`,
  in degrees. One number combining pitch + yaw + roll, so a
  drift in ANY direction breaks stillness — there is no axis to
  hide a movement in. Only the RELATIVE angle vs the captured
  center is used, so the host's absolute zero never matters.
- **Thresholds (encoded and documented here):**
  - settle: 1000 ms; the center quaternion is captured at the
    end of the settle (if no reading has arrived yet, the settle
    waits in 200 ms steps rather than capturing null)
  - still threshold: total angular deviation < 5 deg
  - grace: deviation beyond 5 deg for < 300 ms does NOT reset
    (accumulation frozen, not cleared); >= 300 ms sustained
    resets the timer to 0 and auto-restarts the attempt
  - win: 10000 ms accumulated while inside threshold
  - reset cap: 5 resets in one round -> rest + back to ready
  - tick: 100 ms; hold accumulates 100 ms per tick while inside
    threshold
- **Stability event — supporting signal only, never the sole
  signal.** Where the host reports `onOrientationStabilityChange`,
  an unstable report PAUSES accumulation but never resets it and
  never passes a hold on its own; a stable report is not
  required for a win. If the host never reports stability
  events, elapsed time inside threshold alone gates the hold
  (documented fallback, not a fake stable).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo stepper (settle, then +1 s per
  tap) so the playing and done states can be previewed. On a
  real device with a sensor there is no DEMO path at all, and the
  done screen says 「演示稳满 10 秒」 only when demo seconds were
  used.
- **Zero persistence by construction:** no storage calls anywhere;
  held time, center quaternion, reset count and grace state live
  in page memory and die with the page.
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
  invented APIs; no head-gesture handler at all (the API documents
  only 'nod', which this game never uses); permissions match the
  features actually used (empty, matching zero permission-gated
  features).
- Preview screenshots in `screenshots/steady-hold/` (ready /
  playing / done), generated with the local Ink runtime pipeline and
  read back to confirm each shows its own state.
