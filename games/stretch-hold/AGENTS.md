# Stretch Hold （仰低拉伸） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series G04: a slow up/down stretch-hold
exercise, voice guided. Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

Distinct from G01 `nod-count`: G01 counts QUICK nods (down ~0.8 s
hold). This game HOLDS: every rep requires moving past threshold,
holding the full 5 s (spoken countdown 5-4-3-2-1), AND returning to
center.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next
direction. Never continuous circling, never sweep from one extreme
to another, never fast jerking. Slow, small range, stop at mild
stretch, never pain. **For UP specifically: only to a mild stretch,
NEVER force the head far back, NEVER hyperextend, NEVER throw the
head back** — this is said in the voice guidance, not just on
screen. Down is likewise only to a mild stretch (never press the
chin to the chest). Stop at once on pain / dizziness / numbness /
nausea. Sit or stand steady first. One round is 60-180 s. This is
entertainment / daily activity, NOT medical diagnosis, treatment or
a rehab prescription; people with cervical disease, vertigo,
post-op or head/neck injury history should ask a doctor first. The
short version is on the in-game ready screen; the full text is here
and in the README.

## Design contract

- **One mechanic.** 6 slow alternating up/down holds: up -> hold
  5 s -> return -> down -> hold 5 s -> return, 3 up + 3 down.
  START calibrates the center (head straight at START), then ONE
  calibration prompt asks the player to look down once; whichever
  pitch sign the head actually moves is learned as DOWN, and UP is
  the opposite pitch sign (see "Pitch sign" below). Each rep: move
  past threshold, hold the full 5 s (spoken countdown 5-4-3-2-1),
  return to center = 1 rep, spoken by TTS ("慢慢仰头，到轻微拉伸就
  停，稳住，5、4、3、2、1，回正").
- **A rep counts only as direction -> full 5 s hold -> return-to-center.**
  Releasing early counts nothing ("没稳住，重新来"). A move without
  a return never counts, and the next direction is only accepted
  after the return: moving straight from one extreme to the other
  counts nothing and is told "请先回正，不要直接扫到另一边".
  Moving the wrong way while waiting counts nothing and is told
  "反了？请仰头/低头，不是另一边".
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
  shows "请低一下头" as its first instruction, then "回正到中间",
  then the first rep. Restarting (tap on done) re-runs calibration.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **Head-gesture API is officially documented ONLY for `'nod'`.**
  No shake / turn / tilt / look-up / look-down gesture events are
  claimed or used. Up/down detection comes from the sensor
  quaternion, never from a gesture event.
- **Thresholds (encoded and documented here):**
  - direction reached: ~25-30 deg pitch — coded as 27 deg
  - return-to-center: <10 deg
  - hold: full 5 s (5000 ms), spoken countdown 5-4-3-2-1; the hold
    accumulates only while steady where the host reports stability
    events via `onOrientationStabilityChange`; if the host never
    reports them, elapsed time alone gates the hold (documented
    fallback, not a fake stable)
  - rep-stall re-prompt: 8 s, once per step
- **Pitch formula (same as G01 nod-count, fleet-consistent):**
  `pitch = asin(2*(w*x - y*z))`, clamped, from the sensor
  quaternion, in degrees. Only the RELATIVE pitch vs the calibrated
  center is used, so the host's absolute zero never matters.
- **Pitch sign — learned, not assumed (device verification item).**
  The one-prompt calibration records the sign the head actually
  moves when asked to look down as DOWN; UP is the opposite sign,
  so a host pitch-sign inversion cannot silently swap up/down
  counts. Residual caveat: calibration trusts the player to follow
  that one prompt; looking up instead of down would learn the signs
  backwards (if the down sign is learned backwards, up/down swap).
  Fail-safe: nothing counts before calibration completes, the first
  rep is up again (so a backwards calibration feels wrong at once),
  and any restart re-runs calibration. The device checklist must
  confirm: (1) the calibration prompt appears and completes on a
  real look-down, (2) a real look-down then counts as down, not
  up, and (3) a real look-up then counts as up, not down.
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
- Preview screenshots in `screenshots/stretch-hold/` (ready /
  playing / done), generated with the local Ink runtime pipeline and
  read back to confirm each shows its own state.
