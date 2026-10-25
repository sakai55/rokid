# Rhythm Nod （节奏点头） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA11: a rhythm-nod game, Group B
(head-as-controller). Extreme simplicity: 3 states only (ready /
playing / done), one page, one main button.

Distinct from GA08 (nod-catch): GA08 times one nod against a
falling ball; this game times a nod against a repeating beat.
The head is a rhythm controller, and the only head action is one
small gentle nod per beat, at a slow fixed tempo.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** This game uses only
small gentle nods: no circling, no sweeping, no fast jerking.
Nods stay small and unhurried even on the beat: the beat is
slow (1 second apart) precisely so nobody has to jerk. Slow,
small range, stop at mild stretch, never pain. Stop at once on
pain / dizziness / numbness / nausea. Sit or stand steady
first. One round is 16 beats, short. This is entertainment /
daily activity, NOT medical diagnosis, treatment or a rehab
prescription; people with cervical disease, vertigo, post-op or
head/neck injury history should ask a doctor first. The short
version is on the in-game ready screen; the full text is here
and in the README.

## Design contract

- **One mechanic.** Count-in first: 4 slow preparatory beats,
  one per second, announced by voice ("准备，1、2、3、4"); no
  nod is counted during count-in, so the player learns the
  tempo before any beat counts. Then 16 scored beats, one
  every 1000 ms, fixed tempo (no acceleration). Hit window:
  ±300 ms around each beat instant. A nod inside the window =
  hit (+1, voice "对"); a nod before the window of a still-
  pending beat = early miss (voice "早了", that beat is spent);
  a nod after the window but before the next beat's window
  opens (beat instant + 700 ms) = late miss (voice "晚了",
  that beat is spent); no nod by the next window opening =
  miss (voice "漏了"). Between beats the screen shows the
  beat indicator pulsing at beat instants. Done shows hits
  x/16 and "再来一局" (tap restarts, count-in again).
- **One nod per beat, no second chance, no double-count.** A
  beat is verdict-ed at most once: `_onNod()` acts only while
  the beats phase is running AND the current beat is still
  pending (`_beatSpent` false); after a hit, early miss or
  late miss, further nod signals are ignored until the next
  beat's window opens (the beat advances at beat instant +
  700 ms). A nod during count-in, during the lead, or after a
  verdict is ignored and can never leak into the next beat.
  The last beat finishes the round at once on its verdict; a
  pending last beat with no nod finishes at beat + 700 ms
  with a "漏了" verdict.
- **Early, honestly bounded.** Because a spent beat only
  advances at the next window opening, the only beat whose
  window a nod can precede while it is still pending is beat
  1: the beats phase starts at round start + 4000 ms (end of
  count-in) and beat 1's instant is at round start + 5000 ms,
  so a nod in the lead interval 4000–4700 ms is an early miss
  for beat 1. Later beats become pending exactly when their
  window opens (previous beat's + 700 ms = next beat's
  − 300 ms), so a pre-window nod for them cannot occur while
  pending — it is ignored as a post-verdict nod instead. The
  early rule is implemented generally, not special-cased to
  beat 1, and this bound is documented here rather than
  hidden.
- **Beat calls.** At each beat instant, while the beat is
  still pending, the voice speaks the beat number (Chinese
  numerals 1–16); a spent beat gets no beat call, so a
  verdict is never talked over by its own beat number. The
  beat indicator also flashes for 200 ms at every count-in
  beat, at the beats-phase start tick (+4000 ms), and at
  each scored beat instant.
- **Voice is primary.** Every step is spoken (count-in
  numbers, "开始", beat numbers, hit/miss calls "对 / 早了 /
  晚了 / 漏了", the final score). The screen mirrors the
  same lines plus the beat number x/16, the beat indicator
  and the score. TTS uses the fixed host voice; the
  utterance `lang` is never set (documented: it does not
  take effect).
- **Gestures:** single tap = Enter = start / play again;
  during playing, tap only re-speaks the hint on a real
  device and NEVER hits a beat (a beat is nod-only, so a
  tap cannot cheat a beat); double-tap = host back, never
  intercepted; no swipe handling, no other buttons.
- **Playing screen shows at most:** the current beat number
  x/16, a beat indicator (on-beat flash), the score (hits
  so far), and one short hint — plus the fleet-standard
  title, sensor line, main button and footer.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; the nod event and the sensor quaternion are the
  only head signals used.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  No other gesture event is claimed or used. The nod event is
  the primary beat signal here (documented, not invented);
  every other head signal in this game comes from the sensor
  quaternion as a fallback.
- **Tempo and windows (exact, as implemented):**
  - tempo: FIXED 1000 ms per beat, no acceleration
  - count-in: 4 beats, one per second, at round start
    +0 / +1000 / +2000 / +3000 ms, announced "准备，1、2、
    3、4"; no nod counted during count-in
  - beats phase starts at round start + 4000 ms ("开始");
    beat 1's instant is at +5000 ms, beat 16's at +20000 ms
  - hit window: ±300 ms around each beat instant
  - late zone: beat instant +300 ms to +700 ms (nod =
    "晚了"); a beat advances at +700 ms, which is exactly
    the next beat's window opening (1000 − 300 ms)
  - no nod by +700 ms = "漏了" miss, then advance (last
    beat: finish instead)
  - beat indicator flash: 200 ms at each beat instant
  - tick: 50 ms
  - fallback nod: pitch down past 20 deg, return inside 10 deg
- **Nod signals — primary vs fallback.** PRIMARY:
  `onHeadGesture('nod')`, officially documented for `'nod'` —
  the primary beat signal; it catches gentle nods.
  FALLBACK: pitch from `AbsoluteOrientationSensor` (GA01
  formula, relative to the center calibrated at round start):
  pitch down past ~20 deg and back inside 10 deg counts as
  one fallback nod, for hosts that do not deliver the nod
  event. A gentle real nod may not reach 20 deg — the
  fallback needs a CLEAR nod, and that limit is documented,
  not hidden. The fallback and the primary event share the
  same `_onNod()` guard, so a nod delivered by both paths
  still verdicts the beat once.
- **Pitch formula (same as GA01, fleet-consistent):**
  `pitch = asin(2*(w*x - y*z))`, clamped, from the sensor
  quaternion, in degrees. Only the RELATIVE pitch vs the
  calibrated center is used, so the host's absolute zero never
  matters.
- **DOWN-SIGN ASSUMPTION — device verification item (same as
  GA01).** Head-down is taken as negative relative pitch. If
  the first device test shows the sign inverted, the fallback
  simply never fires — it fails safe as "no fallback hit",
  never as a wrong hit — while the primary nod event still
  works. The device checklist must confirm: (1) the 4-beat
  count-in is spoken one per second and no nod during it
  counts, (2) a gentle nod delivered as a nod event inside
  ±300 ms of a beat hits (+1, voice "对"), (3) a nod in the
  lead before beat 1 misses as "早了" and spends beat 1,
  (4) a nod at +300 to +700 ms after a beat misses as
  "晚了" and spends that beat, (5) no nod by +700 ms misses
  as "漏了", (6) a second nod on the same beat (event or
  fallback) is ignored, (7) the fallback (clear nod past
  20 deg and return) hits when the host does not deliver nod
  events, (8) the tempo really feels like 1 second per beat
  with no acceleration, and the ±300 ms window feels fair.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo nod stepper ("演示点头") that
  goes through the same one-nod-per-beat verdict at the current
  beat timing, so the playing and done states can be previewed.
  On a real device with a nod event there is no DEMO path at
  all, and the done screen says 「演示对了」 only when demo nods
  were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, beat state and calibration live in page memory and die
  with the page.
- **No camera, no mic/ASR, no network, no LLM.** Nothing to SKIP.

## Permissions

None — `permissions` is an empty array. Sensor, nod-event and
TTS are not among the only three permissions (`GEOLOCATION`,
`CAMERA`, `RECORD_AUDIO`), and the code uses neither of those
three features, so nothing is declared. Verified by a successful
empty-permissions pack (see README).

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; the only gesture handler is `onHeadGesture`
  for `'nod'` (officially documented); permissions match the
  features actually used (empty, matching zero permission-gated
  features).
- Logic harness (10 checks, all passing): hit at beat instant,
  second nod ignored, early miss, late miss, nod at +800 ms
  ignored (pending), count-in nod ignored, tick expiry
  ("漏了" + advance), tick advance after a spent beat,
  last-beat hit finishes the round with the correct score.
- Preview screenshots in `screenshots/rhythm-nod/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
