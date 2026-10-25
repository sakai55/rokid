# Ear Tilt （贴耳操） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA03: a slow side-tilt hold exercise,
voice guided. Extreme simplicity: 3 states only (ready / playing /
done), one page, one main button.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
direction. Never continuous circling, never sweep from one extreme
to another, never fast jerking. Slow, small range, stop at mild
stretch, never pain. The ear goes toward the shoulder; NEVER lift
the shoulder up to meet the ear — the shoulder stays down (this is
said in the voice guidance, not just on screen). Stop at once on
pain / dizziness / numbness / nausea. Sit or stand steady first.
One round is 60-180 s. This is entertainment / daily activity, NOT
medical diagnosis, treatment or a rehab prescription; people with
cervical disease, vertigo, post-op or head/neck injury history
should ask a doctor first. The short version is on the in-game
ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 6 slow alternating side tilts: left -> hold
  5 s -> return -> right -> hold 5 s -> return, 3 left + 3 right.
  START calibrates the center (head straight at START), then ONE
  calibration prompt asks the player to tilt left once; whichever
  roll sign the head actually moves is learned as LEFT (see
  "Roll sign" below). Each rep: tilt past threshold, hold the full
  5 s (spoken countdown 5-4-3-2-1), return to center = 1 rep,
  spoken by TTS ("向左贴，肩膀别抬，稳住，5、4、3、2、1，回正").
- **A rep counts only as tilt -> full 5 s hold -> return-to-center.**
  Releasing early counts nothing ("没贴够，重新贴"). A tilt without
  a return never counts, and the next direction is only accepted
  after the return: tilting straight from one extreme to the other
  counts nothing and is told "请先回正，不要直接扫到另一边".
  Tilting the wrong way while waiting counts nothing and is told
  "反了？请向左/右贴，不是另一边".
- **Stall = one re-prompt, never an auto-count.** If calibration or
  a rep stays unfinished longer than 8 s, TTS re-prompts exactly
  once per step; the count never moves on its own.
- **Voice is primary.** Every step is spoken, the hold countdown is
  spoken digit by digit, every rep is counted aloud, completion is
  spoken. The screen mirrors the same lines plus the countdown
  number. TTS uses the fixed host voice; the utterance `lang` is
  never set (documented: it does not take effect).
- **Gestures:** single tap = Enter = start / re-speak instruction /
  play again; double-tap = host back, never intercepted; no swipe
  handling, no other buttons. There is deliberately no head-gesture
  handler: the gesture API is documented only for 'nod', and nod is
  not this game's action.
- **Calibration is one prompt, inside the playing state.** It is not
  a fourth page state and not a menu: the playing screen simply
  shows "请向左贴一下" as its first instruction, then "回正到中间",
  then the first rep. Restarting (tap on done) re-runs calibration.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No shake / turn / tilt gesture events are claimed or used.
  Left/right tilt detection comes from the sensor quaternion, never
  from a gesture event.
- **Thresholds (encoded and documented here):**
  - tilt reached: ~25-30 deg roll — coded as 27 deg
  - return-to-center: <10 deg
  - hold: full 5 s (5000 ms), spoken countdown 5-4-3-2-1; the hold
    accumulates only while steady where the host reports stability
    events via `onOrientationStabilityChange`; if the host never
    reports them, elapsed time alone gates the hold (documented
    fallback, not a fake stable)
  - rep-stall re-prompt: 8 s, once per step
- **Roll formula:** `roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))`
  from the sensor quaternion, in degrees. Only the RELATIVE roll vs
  the calibrated center is used, so the host's absolute zero never
  matters.
- **Roll sign — learned, not assumed (device verification item).**
  The one-prompt calibration records the sign the head actually
  moves when asked to tilt left, so a host roll-sign inversion
  cannot silently swap left/right counts. Residual caveat:
  calibration trusts the player to follow that one prompt; tilting
  right instead of left would learn the signs backwards. Fail-safe:
  nothing counts before calibration completes, the first rep is left
  again (so a backwards calibration feels wrong at once), and any
  restart re-runs calibration. The device checklist must confirm:
  (1) the calibration prompt appears and completes on a real left
  tilt, (2) a real left tilt then counts as left, not right, and
  (3) a real left tilt's roll sign matches the learned sign (if the
  device's roll axis differs, the calibration still absorbs it —
  what must be checked is that left counts as left, not the raw sign).
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo stepper (calibration steps, then
  one tap per whole rep) so the playing and done states can be
  previewed. On a real device with a sensor there is no DEMO path
  at all, and the done screen says 「演示完成」 only when demo reps
  were used.
- **Zero persistence by construction:** no storage calls anywhere;
  count, center and learned sign live in page memory and die with
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
- Preview screenshots in `screenshots/ear-tilt/` (ready / playing /
  done), generated with the local Ink runtime pipeline and read back
  to confirm each shows its own state.
