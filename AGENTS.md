# Nod Catch （点头接球） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series GA08: a nod-catch timing game,
Group B (head-as-controller). Extreme simplicity: 3 states only
(ready / playing / done), one page, one main button.

Distinct from Group A (GA01–GA06) and from GA07: those games count
head motions or stillness. This game times a nod against a
falling ball — the head is a timing controller, not an exercise
motion, and the only head action is one gentle nod per ball.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** This game uses only
small nods: no circling, no sweeping, no fast jerking. The catch
nod is a GENTLE nod, never a throw of the head. Slow, small
range, stop at mild stretch, never pain. Stop at once on pain /
dizziness / numbness / nausea. Sit or stand steady first. One
round is 10 balls, short. This is entertainment / daily
activity, NOT medical diagnosis, treatment or a rehab
prescription; people with cervical disease, vertigo, post-op or
head/neck injury history should ask a doctor first. The short
version is on the in-game ready screen; the full text is here
and in the README.

## Design contract

- **One mechanic.** 10 balls, one at a time. Each ball falls
  from top to bottom over a FIXED 3 seconds (no acceleration —
  learnable and fair), past a visible center catch line. Catch
  window: the ball's center within ±15% of screen height around
  the line, i.e. fall progress 35%–65%, i.e. roughly ±0.45 s
  around the line crossing at 1.5 s. A nod inside the window =
  catch (+1, voice "接住了"). A nod outside the window = a miss
  for that ball (voice "早了" before the window, "晚了" after
  it); the ball keeps falling and is then gone. No nod at all =
  miss when the ball passes the bottom (voice "没接住").
  Between balls, a 1-second pause with the next ball announced
  ("下一个"). Done shows catches x/10 and "再来一局" (tap
  restarts).
- **One nod per ball, no second chance, no double-count.** A
  ball is verdict-ed at most once: `_onNod()` acts only while
  the ball is falling AND `_attempted` is false; after a catch
  or a miss-nod, further nod signals are ignored until the next
  ball starts (`_attempted` reset at ball start). A catch goes
  straight to the 1-second pause; an early/late miss lets the
  ball keep falling to the bottom, then the pause. A nod during
  the pause, ready or done is ignored and can never leak into
  the next ball.
- **Nod signals — primary vs fallback.** PRIMARY:
  `onHeadGesture('nod')`, officially documented for `'nod'` —
  this is the one game family where the nod event is the action,
  so it is the primary catch signal and it catches gentle nods.
  FALLBACK: pitch from `AbsoluteOrientationSensor` (GA01
  formula, relative to the center calibrated at round start):
  pitch down past ~20 deg and back inside 10 deg counts as one
  fallback nod, for hosts that do not deliver the nod event. A
  gentle real nod may not reach 20 deg — the fallback needs a
  CLEAR nod, and that limit is documented, not hidden. The
  fallback and the primary event share the same `_onNod()` guard,
  so a nod delivered by both paths still verdicts the ball once.
- **Voice is primary.** Every step is spoken (ball starts are
  announced by the "第 N 个球" screen line, catches/misses are
  called aloud, "下一个" announces the next ball, the final
  score is spoken). The screen mirrors the same lines plus the
  falling ball, the catch line and the score. TTS uses the fixed
  host voice; the utterance `lang` is never set (documented: it
  does not take effect).
- **Gestures:** single tap = Enter = start / play again; during
  playing, tap only re-speaks the hint on a real device and
  NEVER catches (catch is nod-only, so a tap cannot cheat a
  ball); double-tap = host back, never intercepted; no swipe
  handling, no other buttons.
- **Playing screen shows at most:** the falling ball + center
  catch line (9-row track, line row in the middle), the score
  x/10, and one short hint — plus the fleet-standard title,
  sensor line, main button and footer.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; the nod event and the sensor quaternion are the only
  head signals used.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  No other gesture event is claimed or used. The nod event is
  the primary catch signal here (documented, not invented);
  every other head signal in this game comes from the sensor
  quaternion as a fallback.
- **Fall and window (exact, as implemented):**
  - fall time: FIXED 3000 ms per ball, no acceleration
  - catch line: middle of the fall path (50% of the fall)
  - catch window: fall progress 35%–65% (ball center within
    ±15% of screen height around the line, ±0.45 s around the
    1.5 s line crossing)
  - pause between balls: 1000 ms, next ball announced once
    ("下一个") at pause start
  - tick: 50 ms
  - fallback nod: pitch down past 20 deg, return inside 10 deg
- **Track display vs verdict.** The 9-row track is DISPLAY
  only: the ball's row is `floor(progress * 9)` clamped to 8,
  so it visibly drops from the top row to the bottom row over
  3 s and crosses the line row (row 4) at mid-fall. The catch
  verdict ALWAYS uses the exact progress window 35%–65%, never
  the row — the row is an approximation for the eye, not the
  judge.
- **Pitch formula (same as GA01, fleet-consistent):**
  `pitch = asin(2*(w*x - y*z))`, clamped, from the sensor
  quaternion, in degrees. Only the RELATIVE pitch vs the
  calibrated center is used, so the host's absolute zero never
  matters.
- **DOWN-SIGN ASSUMPTION — device verification item (same as
  GA01).** Head-down is taken as negative relative pitch. If the
  first device test shows the sign inverted, the fallback
  simply never fires — it fails safe as "no fallback catch",
  never as a wrong catch — while the primary nod event still
  works. The device checklist must confirm: (1) a gentle nod
  delivered as a nod event catches a ball in the window,
  (2) a nod event outside the window misses with the correct
  早了/晚了 call and no second chance, (3) a second nod on the
  same ball (event or fallback) is ignored, (4) no nod = miss
  at the bottom, (5) the fallback (clear nod past 20 deg and
  return) catches when the host does not deliver nod events,
  (6) the fall really takes 3 s and the window feels fair at
  ±0.45 s.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo nod stepper ("演示点头") that
  goes through the same one-nod-per-ball verdict at the current
  ball position, so the playing and done states can be previewed.
  On a real device with a nod event there is no DEMO path at
  all, and the done screen says 「演示接住」 only when demo nods
  were used.
- **Zero persistence by construction:** no storage calls anywhere;
  score, ball state and calibration live in page memory and die
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
- Preview screenshots in `screenshots/nod-catch/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
