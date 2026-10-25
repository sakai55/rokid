# Chin Tuck （收下巴） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA06: a chin-tuck hold exercise,
voice guided, closing Group A (neck exercises). Extreme
simplicity: 3 states only (ready / playing / done), one page, one
main button.

Distinct from GA01 `nod-count` and GA04 `stretch-hold`: those games
count FULL head motions (a nod, an up/down stretch at ~27 deg).
This game counts a SMALL motion only — the chin gliding straight
back — and its whole design is the tuck-vs-nod distinction: a
full nod is not a bigger tuck, it is the wrong motion, and it
counts nothing.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** Only segmented motion:
center -> one direction -> hold -> return to center -> next.
Never continuous circling, never sweep from one extreme to
another, never fast jerking. Slow, small range, stop at mild
stretch, never pain. **For chin-tuck specifically: a SMALL
horizontal glide only — the chin slides straight back, like
making a slight double chin; the head does NOT tilt down and
does NOT nod.** The voice guidance says this distinction
explicitly: 「不是低头，是下巴水平往后收」. Stop at once on
pain / dizziness / numbness / nausea. Sit or stand steady first.
One round is 60-180 s. This is entertainment / daily activity,
NOT medical diagnosis, treatment or a rehab prescription; people
with cervical disease, vertigo, post-op or head/neck injury
history should ask a doctor first. The short version is on the
in-game ready screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 8 chin-tuck holds: tuck -> hold 5 s ->
  relax/return to center, repeat. START calibrates the center
  (head straight at START), then ONE calibration prompt asks the
  player to look down once; whichever pitch sign the head
  actually moves is learned as DOWN, and the tuck uses that same
  pitch direction at SMALL amplitude (see "Thresholds" below).
  Each rep: glide into the small tuck band, hold the full 5 s
  (spoken countdown 5-4-3-2-1), return to center = 1 rep, spoken
  by TTS ("下巴轻轻往后收，像点头的一半还不到，稳住，5、4、3、
  2、1，放松").
- **A rep counts only as small tuck -> full 5 s hold ->
  return-to-center.** Releasing early counts nothing ("没稳住，
  重新来"). A move without a return never counts.
- **A full nod counts nothing, ever.** Pitch beyond the tuck
  band's upper bound (20 deg) is "too far": in `wait` it shows
  「幅度小一点，这是收下巴不是低头」 and counts nothing; pushed
  into mid-hold, it voids the hold ("幅度小一点，这是收下巴
  不是低头，慢慢回正重新来") with no count. There is no head-
  gesture handler at all: `onHeadGesture` is documented only for
  `'nod'`, and a nod must never count as a tuck, so no nod event
  can ever complete a rep.
- **Wrong direction is corrected, not counted.** An up-tilt past
  the tuck magnitude shows 「仰头了？请收下巴，不是仰头」 and
  counts nothing.
- **Stall = one re-prompt, never an auto-count.** If calibration
  or a rep stays unfinished longer than 8 s, TTS re-prompts
  exactly once per step; the count never moves on its own.
- **Voice is primary.** Every step is spoken, the hold countdown
  is spoken digit by digit, every rep is counted aloud,
  completion is spoken. The screen mirrors the same lines plus
  the countdown number. TTS uses the fixed host voice; the
  utterance `lang` is never set (documented: it does not take
  effect).
- **Gestures:** single tap = Enter = start / re-speak instruction
  / play again; double-tap = host back, never intercepted; no
  swipe handling, no other buttons. There is deliberately no
  head-gesture handler (see above).
- **Calibration is one prompt, inside the playing state.** It is
  not a fourth page state and not a menu: the playing screen
  simply shows "请低一下头" as its first instruction, then
  "回正到中间", then the first rep. Restarting (tap on done)
  re-runs calibration.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; head direction comes only from `AbsoluteOrientationSensor`.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  No tuck / glide / nod gesture events are claimed or used. The
  tuck is detected from the sensor quaternion, never from a
  gesture event — and no nod handler exists, so a nod event
  cannot count even by accident.
- **Thresholds (encoded and documented here):**
  - calibration look-down: ~25-30 deg pitch — coded as 27 deg
    (the GA01/GA04 exercise range; calibration is a real look-down,
    not a tuck)
  - tuck reached: ~12-15 deg pitch-down-equivalent — coded as
    14 deg. SMALLER than the 25-30 deg exercise range because a
    tuck is a small motion: the band must sit well below a full
    nod, or every nod would count as a tuck.
  - too far (full nod): >= 20 deg — counts nothing, with the
    "幅度小一点" correction. The 14-20 deg band is deliberately
    narrow: below it is "not yet tucked", above it is "a nod,
    not a tuck".
  - return-to-center: <8 deg pitch (tighter than GA01/GA04's 10
    deg, because the whole motion is smaller — a 10 deg return
    band would nearly overlap the 14 deg tuck band)
  - hold: full 5 s (5000 ms), spoken countdown 5-4-3-2-1; the hold
    accumulates only while steady where the host reports
    stability events via `onOrientationStabilityChange`; if the
    host never reports them, elapsed time alone gates the hold
    (documented fallback, not a fake stable)
  - early-release cut: dropping below 11 deg (tuck minus 3 deg)
    before the full hold voids the rep
  - rep-stall re-prompt: 8 s, once per step
- **Pitch formula (same as GA01/GA04, fleet-consistent):**
  `pitch = asin(2*(w*x - y*z))`, clamped, from the sensor
  quaternion, in degrees. Only the RELATIVE pitch vs the
  calibrated center is used, so the host's absolute zero never
  matters. Return is judged on pitch only: a chin tuck is a
  pitch-axis motion, and yaw is not gated (a sideways turn
  during a hold does not break it — documented, not hidden).
- **Pitch sign — learned, not assumed (device verification item).**
  The one-prompt calibration records the sign the head actually
  moves when asked to look down as DOWN; the tuck uses that same
  sign at small amplitude. Residual caveat: calibration trusts
  the player to follow that one prompt; looking up instead of
  down would learn the sign backwards (a backwards calibration
  makes real tucks read as up-tilts and count nothing — it fails
  safe as "no count + wrong-direction hint", never as a wrong
  count). The device checklist must confirm: (1) the calibration
  prompt appears and completes on a real look-down, (2) a small
  real tuck then enters the tuck band and counts after a 5 s hold
  + return, (3) a real FULL nod is rejected with the "幅度小一点"
  hint and counts nothing, both while waiting and mid-hold,
  (4) releasing before 5 s counts nothing, (5) no return = no
  count.
- **The tuck-detection proxy, stated honestly (device verification
  item).** A chin tuck is mostly a horizontal TRANSLATION, which
  an orientation sensor barely sees; there is no translation
  sensor API on this platform. This game therefore detects the
  tuck as a SMALL pitch motion in the learned down direction,
  and the voice cue deliberately describes it as "像点头的一半
  还不到" — the player glides the chin back with only the
  smallest nod-like component. The device test must confirm a
  natural tuck lands in the 14-20 deg band. If real tucks
  systematically under-register (pure glides reading near 0 deg),
  the fix is to adjust the THRESHOLD (lower the band), not to
  pretend the motion is something it is not — and if no small
  pitch band separates tucks from noise at all, that result must
  be reported honestly rather than shipped as a working tuck
  detector.
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
  'nod', which must never count here); permissions match the
  features actually used (empty, matching zero permission-gated
  features).
- Preview screenshots in `screenshots/chin-tuck/` (ready /
  playing / done), generated with the local Ink runtime pipeline and
  read back to confirm each shows its own state.
