# Turn Dodge （左右闪避） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA09, Group B (head-as-controller):
a left/right dodge game. Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
round. Never continuous circling, never sweep from one extreme
to the other, never fast jerking — dodges are calm turns, not
flinches. Slow, small range, stop at mild stretch, never pain.
Stop at once on pain / dizziness / numbness / nausea. Sit or
stand steady first. One round is 10 dodges, short. This is
entertainment / daily activity, NOT medical diagnosis, treatment
or a rehab prescription; people with cervical disease, vertigo,
post-op or head/neck injury history should ask a doctor first.
The short version is on the in-game ready screen; the full text
is here and in the README.

## Design contract

- **One mechanic.** 10 rounds, one obstacle at a time. The
  obstacle side is announced by voice and shown on screen.
  Obstacle on the LEFT means turn RIGHT (away from it),
  obstacle on the RIGHT means turn LEFT. Reaching the opposite
  direction past threshold and holding ~0.8 s = dodge (+1,
  voice "躲开了"). Turning TOWARD the obstacle past threshold =
  hit (0, voice "被撞到了"). No turn within 4 seconds = miss
  (0, voice "没躲开").
- **Fixed obstacle sequence (NOT random, so preview and device
  behaviour are reproducible):** L, R, R, L, R, L, L, R, L, R
  (obstacle side per round 1–10). Documented here and in the
  code (`SEQ`); the dodge direction each round is always the
  opposite of the obstacle side.
- **Return-to-center gates every next round.** After each
  non-final round the player MUST return to center before the
  next round is announced: the next round starts only after
  return <10 deg, or after a 4-second return grace, at which
  point the next round is announced anyway with a spoken
  "请回正" reminder. The grace never counts anything — it only
  stops the game waiting forever. The final round ends the
  game at once: there is no next round for a return to gate.
- **A dodge that backs off before the hold is aborted with no
  count.** The 4-second round clock keeps running, so a stalled
  dodge still ends as a miss. A hit is immediate the moment the
  head passes threshold toward the obstacle — there is no
  hold-or-undo for a wrong turn.
- **Calibration is one prompt, inside the playing state (GA02's
  pattern).** It is not a fourth page state and not a menu:
  START calibrates the center (head straight at START), then
  the playing screen shows "请向左转一下" as its first
  instruction; whichever yaw sign the head actually moves is
  learned as LEFT, then "回正到中间", then round 1. Restarting
  (tap on done) re-runs calibration.
- **Voice is primary.** Every round is announced, every outcome
  is spoken (dodge / hit / miss), completion is spoken. The
  screen mirrors the same lines. TTS uses the fixed host voice;
  the utterance `lang` is never set (documented: it does not
  take effect).
- **Gestures:** single tap = Enter = start / re-speak
  instruction / play again; double-tap = host back, never
  intercepted; no swipe handling, no other buttons. There is
  deliberately no head-gesture handler: the gesture API is
  documented only for 'nod', and nod is not this game's action.
- **Playing screen shows at most:** the obstacle side + dodge
  arrow (big line = obstacle side, hint = dodge direction with
  arrow), the score (dodges x/10), and one short hint.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No shake / turn / tilt gesture events are claimed or used.
  Left/right detection comes from the sensor quaternion, never
  from a gesture event.
- **Thresholds (encoded and documented here):**
  - dodge direction reached: ~25-30 deg yaw — coded as 27 deg
  - return-to-center: <10 deg
  - hold-steady: ~0.8 s (800 ms), gated on
    `onOrientationStabilityChange` stable where the host reports
    stability events; if the host never reports them, elapsed time
    alone gates the hold (documented fallback, not a fake stable)
  - round clock: 4 s, no turn = miss
  - return grace: 4 s, then next round announced anyway with a
    spoken "请回正" reminder
  - calibration stall re-prompt: 8 s, once per calibration step
- **Yaw formula:** `yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))`
  from the sensor quaternion, in degrees. Only the RELATIVE yaw vs
  the calibrated center is used, so the host's absolute zero never
  matters.
- **Yaw sign — learned, not assumed (device verification item).**
  The one-prompt calibration records the sign the head actually
  moves when asked to turn left, so a host yaw-sign inversion cannot
  silently swap left/right dodges — unlike GA01's documented
  down-sign assumption, which GA09 does not need. Residual caveat:
  calibration trusts the player to follow that one prompt; turning
  right instead of left would learn the signs backwards. Fail-safe:
  nothing counts before calibration completes, and any restart
  re-runs calibration. The device checklist must confirm:
  (1) the calibration prompt appears and completes on a real left
  turn, (2) a real dodge away from a left obstacle (turn right)
  counts as a dodge, not a hit, and a real turn toward the
  obstacle counts as a hit, not a dodge.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo stepper (calibration steps, then
  one tap per whole round as a dodge) so the playing and done states
  can be previewed. On a real device with a sensor there is no DEMO
  path at all, and the done screen says 「演示躲开 x / 10」 only when
  demo rounds were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, round, center and learned sign live in page memory and die
  with the page.
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
- Preview screenshots in `screenshots/turn-dodge/` (ready / playing /
  done), generated with the local Ink runtime pipeline and read back
  to confirm each shows its own state.
