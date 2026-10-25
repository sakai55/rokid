# Nod Quiz （点头问答） — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Head-movement mini-game series G16, Group C
(observation/control): a yes/no quiz answered by head motion
only. Extreme simplicity: 3 states only (ready / playing /
done), one page, one main button.

Distinct from G08/G11: those games time a nod; this game gives
the nod a meaning (YES) and pairs it with a sensor-only NO
(a single side turn), so one question has exactly two head
answers and no spoken or tapped answer exists.

## Series constitution — neck safety (GO's rule)

**Turning the neck in circles is WRONG.** This game uses only
small, segmented motions: a gentle nod for YES, a single side
turn for NO, each followed by a return to center before the
next question. Never fast jerking, never shaking the head back
and forth — shaking is explicitly NOT the NO signal (see
below). Slow, small range, stop at mild stretch, never pain.
Stop at once on pain / dizziness / numbness / nausea. Sit or
stand steady first. One game is 10 questions, short. This is
entertainment / daily activity, NOT medical diagnosis,
treatment or a rehab prescription; people with cervical
disease, vertigo, post-op or head/neck injury history should
ask a doctor first. The short version is on the in-game ready
screen; the full text is here and in the README.

## Design contract

- **One mechanic.** 10 fixed questions in a fixed order
  (never random; the exact list with answers is below).
  Per question: TTS reads the question, the screen shows it;
  the player answers YES (gentle nod) or NO (turn to either
  side past ~27 deg and hold ~0.8 s). Correct = +1 (voice
  "答对了"), wrong = 0 (voice "答错了，正确答案是是 / 否"),
  no answer within 10 seconds = miss (voice "超时了", 0).
  After each answer the player returns to center before the
  next question (see the return rule below). Done shows
  correct x/10 and "再来一局" (tap restarts, same questions
  in the same order).
- **The 10 fixed questions (5 yes / 5 no):**
  1. 水是液体吗 — 是
  2. 猫会飞吗 — 否
  3. 一天有24小时吗 — 是
  4. 太阳从西边升起吗 — 否
  5. 鱼能在水里呼吸吗 — 是
  6. 冰是热的吗 — 否
  7. 一年有12个月吗 — 是
  8. 人有三只眼睛吗 — 否
  9. 月亮会自己发光吗 — 否（月光是反射的太阳光，月亮本身不发光）
  10. 鸟有翅膀吗 — 是
  Every item is unambiguously true or false; Q9 was kept
  deliberately (not swapped): the moon emits no visible light
  of its own, its light is reflected sunlight, so "否" is
  defensible and the reasoning is stated here and in the
  README rather than hidden. Because the split is 5/5, neither
  answer can win a round by guessing one side.
- **Return rule (exact, like G10/G13).** After every verdict
  (right, wrong or timeout) the game enters `returnwait`: the
  next question is NEVER announced until the return actually
  happens — |relative yaw| < 10 deg AND |relative pitch| <
  10 deg vs the round-start center. If the head is not back
  within 4 seconds, TTS prompts "请回正", then repeats every
  4 seconds until the return happens. A nod or turn delivered
  during `returnwait` is ignored and can never leak into the
  next question.
- **Voice is primary.** Every step is spoken (questions,
  "答对了" / "答错了，正确答案是…" / "超时了", "请回正",
  the final score). The screen mirrors the same lines plus
  the question number x/10 and the score. TTS uses the fixed
  host voice; the utterance `lang` is never set (documented:
  it does not take effect).
- **Gestures:** single tap = Enter = start / play again;
  during playing, tap only re-speaks the question (or
  "请回正" while waiting for the return) and NEVER answers
  (an answer is nod/turn-only, so a tap cannot cheat a
  question); double-tap = host back, never intercepted; no
  swipe handling, no other buttons.
- **Playing screen shows at most:** the current question
  (short text), the question number x/10, the score so far,
  the verdict line (after an answer), and one short hint
  ("点头=是，转头=否") — plus the fleet-standard title,
  sensor line, main button and footer.

## Technical honesty

- **No eye tracking.** There is no eye-tracking API on this
  platform; the nod event and the sensor quaternion are the
  only head signals used.
- **`onHeadGesture` is officially documented ONLY for `'nod'`.**
  No other gesture event is claimed or used. In particular
  there is NO documented shake gesture, so NO is NEVER
  claimed as a shake event and shaking the head back and
  forth is explicitly NOT the NO signal — the ready screen,
  this file and the README all say so. NO comes from the
  sensor only (below).
- **YES signals — primary vs fallback (G08/G11 pattern).**
  PRIMARY: `onHeadGesture('nod')` — the primary YES signal;
  it catches gentle nods. FALLBACK: pitch from
  `AbsoluteOrientationSensor` (G01 formula, relative to the
  center calibrated at round start): pitch down past ~20 deg
  and back inside 10 deg counts as one fallback nod, for
  hosts that do not deliver the nod event. A gentle real nod
  may not reach 20 deg — the fallback needs a CLEAR nod, and
  that limit is documented, not hidden. The fallback and the
  primary event share the same `_answer()` guard, so a nod
  delivered by both paths still verdicts the question once.
- **NO signal — sensor only, sign-free.** NO = |relative yaw|
  past ~27 deg, held ~0.8 s (hold resets if |yaw| drops below
  22 deg first). Yaw uses the G15 quaternion formula, relative
  to the round-start center. Because only the ABSOLUTE yaw is
  used, the left/right sign does not matter for NO: turning
  to either side counts, so a host yaw-sign inversion cannot
  break NO the way it could break a left-vs-right game. A
  shake (left-right-left) never satisfies the hold by itself:
  each crossing below 22 deg resets the hold timer, and the
  verdict requires one continuous 0.8 s hold past 27 deg on
  one side.
- **Mutual exclusion (exact).** YES and NO are mutually
  exclusive per question: the first valid signal wins. After
  any verdict `_answered` is true and the sub-state leaves
  `question`, so a nod and a side turn in the same question
  window cannot both count, and signals during `returnwait`
  are ignored until the next question starts. The 10-second
  timeout is itself a verdict (miss) and likewise closes the
  question.
- **Thresholds (encoded and documented here):**
  - questions: FIXED 10, fixed order, 5 yes / 5 no
  - answer window: 10000 ms per question
  - NO: |relative yaw| >= 27 deg, hold >= 800 ms, reset < 22 deg
  - return to center: |relative yaw| < 10 deg AND
    |relative pitch| < 10 deg
  - return prompt: first "请回正" at 4000 ms without a return,
    then every 4000 ms
  - fallback nod: pitch down past 20 deg, return inside 10 deg
  - tick: 50 ms
  - demo/sensorless return auto-pass: 1200 ms after the verdict
- **Pitch formula (same as G01, fleet-consistent):**
  `pitch = asin(2*(w*x - y*z))`, clamped, from the sensor
  quaternion, in degrees. **Yaw formula (same as G15):**
  `yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))`, in degrees.
  Only RELATIVE values vs the calibrated center are used, so
  the host's absolute zero never matters.
- **DOWN-SIGN ASSUMPTION — device verification item (same as
  G01).** Head-down is taken as negative relative pitch. If
  the first device test shows the sign inverted, the fallback
  nod simply never fires — it fails safe as "no fallback
  YES", never as a wrong YES — while the primary nod event
  still works. NO is unaffected by any pitch-sign question
  (it uses yaw only, absolute value). The device checklist
  must confirm: (1) a gentle nod delivered as a nod event
  answers YES and scores correctly, (2) a single side turn
  past 27 deg held 0.8 s answers NO (both sides), (3) a turn
  that drops back before 0.8 s does NOT answer, (4) shaking
  the head back and forth does NOT answer NO, (5) the first
  signal wins when a nod and a turn fall in the same window,
  (6) no answer in 10 s scores a "超时了" miss, (7) the next
  question is never announced before an actual return, and
  "请回正" is spoken at 4 s without one, (8) the fallback
  (clear nod past 20 deg and return) answers YES when the
  host does not deliver nod events, (9) a tap during playing
  never answers.
- **Sensor missing = SKIP/demo, never a fake pass.** In the web
  preview there is no `AbsoluteOrientationSensor`: the screen says
  「传感器：SKIP（网页预览无方向传感器，演示模式）」, and the main
  button becomes a labeled demo answer stepper ("演示回答")
  that submits the CORRECT answer for the current question, so
  the playing and done states can be previewed. On a real device
  with a nod event there is no DEMO path at all, and the done
  screen says 「演示答对」 only when demo answers were used.
  Documented sensorless caveat: if a real device somehow had no
  sensor readings at all, NO could not be detected (it needs the
  sensor) while YES via the nod event still would work, and the
  return gate would auto-pass 1.2 s after the verdict instead of
  blocking forever — a fallback, not a silent pass.
- **Zero persistence by construction:** no storage calls anywhere;
  score, question state, calibration and hold timers live in page
  memory and die with the page.
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
  for `'nod'` (officially documented); no shake/turn gesture
  event is claimed anywhere; permissions match the features
  actually used (empty, matching zero permission-gated
  features).
- Logic harness (checks, all passing): constants read from the
  real .ink file; 10 questions, fixed order, 5 yes / 5 no;
  correct YES scores +1, wrong YES scores 0, correct NO scores
  +1, wrong NO scores 0; second signal after a verdict ignored;
  timeout at exactly 10 s is a miss; NO hold of 0.8 s at 27 deg
  answers, a hold cut short below 22 deg resets; return gate
  requires both axes < 10 deg and blocks the next question
  until met; return prompt at 4 s; fallback nod needs past
  20 deg and back inside 10 deg; demo answers are labeled and
  never counted as real.
- Preview screenshots in `screenshots/nod-quiz/` (ready /
  playing / done), generated with the local Ink runtime pipeline
  and read back to confirm each shows its own state.
