# Cue Fridge — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series P02 (CUE 提示型， second of the group, series #32): standing in
front of the fridge, blanking on what you came to fetch, and remembering
only after the door closes. This agent takes the to-fetch check off your
hands: look at the fridge and hold steady, and only then does the
checklist open; tick one item as you take it, mark what is out of
stock, and before closing it names anything still unticked out loud.

## Design contract

- **The close warning is a reminder, never a gate.** TRIG opens the
  checklist only from idle, and only with a steady head (the gaze
  trigger, judged on-device by head steadiness via
  `onOrientationStabilityChange`). GOT ticks the focused item.
  MISS toggles the focused item's out-of-stock mark (out items
  never count as missed; a taken item cannot be marked out).
  CLOSE in the list is the reminder: the first CLOSE with
  pending items names them in the banner and in one TTS
  utterance, counts the warning, and stays in the list; the
  second CLOSE closes for real and the missed items are
  recorded honestly in the summary. This is the deliberate
  opposite of cue-door (P01), where an unconfirmed END blocks:
  a fridge door must not be held hostage by a checklist, and a
  warning that pretended to block would be a lie about what
  happens next. The banner says so in plain words — "再点
  CLOSE 就关门（提醒，不是拦门）".
- **A tick is a statement, never a sensor proof; an out mark is
  a report, never an inventory count.** The agent does not
  detect whether anything is actually in hand: it has no camera,
  no microphone, no position, and no inventory sensor. GOT
  records that you said you took it; MISS records that you
  said it is not there. The UI and README say exactly that —
  "勾掉只是你本人的表态，不是传感器证明——Agent 不检测东西
  是不是真的拿在手里；它不是库存管理系统，缺货是你标的，
  不是 Agent 盘点的". Claiming detection or stock counting
  would be a lie about the hardware, so the agent never claims
  either.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to the checklist without deleting anything;
  the summary is rebuilt on CLOSE. BACK from the list returns to
  idle with ticks and out marks kept, and re-triggering restores
  the same checklist. Confirming the summary (CLOSE while a
  summary is open, or a steady nod) is the only wipe. There is
  no DEL key: there is nothing to clear that would not also lie
  about what was ticked. A warning resets when the list changes
  (a GOT or a MISS toggle clears `_warned`): a warning names a
  moment's pending set, and a changed list deserves a fresh
  warning, not a stale one.
- **The checklist lives in session memory only — zero persistence,
  by design.** Items, ticks, out marks, warning count and the
  summary die when the summary is confirmed and when the agent
  closes (onUnload wipes everything). Close the agent and the
  fridge round is gone.
- **A steady nod triggers, ticks, or clears — never picks.**
  A steady nod in idle triggers the checklist, in the list
  ticks the focused item, in summary confirms and clears.
  An unsteady nod never arms the 1.2 s lock (the fleet fix,
  kept). A nod never changes focus: that is a selection, and a
  nod must not silently pick an item. Enter follows the same
  per-mode action; ArrowUp/Down walk focus; Backspace goes back.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in the
  list names the taken count and the pending items (or the
  warning, once warned); it never reads a whole list aloud.
  There is no ticker: every transition is a tap, a nod or a
  key — a checklist is event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `cue-door` (P01) is the going-out checklist
  gate at the door: unconfirmed END blocks and never says
  "可以出门". Cue-fridge is not a gate: its close warning
  reminds and then lets the door close, with the miss recorded
  honestly instead of blocking.
- Attention-series `pack-sweep` (C04) is the at-home packing
  checklist: items packed before leaving, counted at home.
  Cue-fridge is not packing: its trigger is looking at the
  fridge itself, and its close is a miss report, not a packing
  count.
- Attention-series `attention-diary` (R05) is the attention bill:
  trigger entries grouped by category, closed with a counted
  verdict. Cue-fridge has no categories and no bill: its units
  are the five to-fetch items, and its close is a
  taken/out/missed verdict.

## Permissions

Zero permissions (app.json `permissions` is `[]`, and the
static check asserts exactly that): a gaze trigger plus a
checklist reminder needs no camera, no microphone, no position.
No `CAMERA`: nothing is photographed. No `RECORD_AUDIO`:
nothing is listened to, there is no ASR path at all (no
onASRResult handler). No `GEOLOCATION`: this agent never knows
where anyone is.

## Validation

- Node harness (see `/tmp/cue-fridge-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location APIs, no ASR/recorder/camera path, no
  utterance language assignment, no legacy Page/App;
  foot2 honesty lines asserted (tick is a statement not a
  sensor proof, not an inventory system, out is the wearer's
  own report, single session, cleared on close, no indoor
  positioning, zero persistence, gaze trigger judged by head
  steadiness); initial idle state (bigText 还没触发，
  placeholder row, countLine); bigCls thresholds; refusals in
  idle (CLOSE naming TRIG, GOT/MISS refused, NEXT/PREV/BACK
  ignored, TRIG refused while head moving); steady event arms
  steady and TRIG opens the list at focus 0; tick flow (GOT
  ticks, re-GOT refused, NEXT/PREV wrap over 5 items, rowTap
  focus with out-of-range and missing-dataset guards); MISS
  flow (mark out, toggle back, GOT on out refused, MISS on
  taken refused); close warning (first CLOSE warns, stays in
  list, exactly one TTS naming the missed items and not the
  out item, bigText 漏拿 N 项； second CLOSE opens the
  summary with taken/out/missed recorded honestly; warned
  flag resets on GOT); all-taken close (summary 都拿齐了，
  no TTS); BACK from list keeps ticks/out and re-TRIG restores
  them; DEMO six-stage arc (trigger, 牛奶， 鸡蛋， 面包 out,
  warned naming 水果、酸奶， summary taken 2 / out 1 /
  missed 2) and refusal on user sessions; nod discipline
  (unsteady ignored without arming, steady nod in idle
  triggers, lock blocks a second nod, lock expiry works,
  non-nod gestures noted); key discipline (Enter triggers /
  ticks, ArrowUp/Down walk, Backspace returns to idle with
  ticks kept); SPEAK lines per mode; onUnload wipes
  everything; summary reports honestly with partial counts.
  Result: **89/89** (first run 88/89, the one failure a harness
  expectation bug — two PREV taps from focus 1 go 1→0→4, not
  0 — fixed in the harness, page code untouched).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not triggered), list (DEMO stage 1,
  0/5), partial (DEMO stage 3, 2/5, 牛奶/鸡蛋 ticked),
  warned (DEMO stage 5, still 2/5, banner names 水果、酸奶，
  面包 marked out and not counted as missed, warning 1),
  summary (DEMO stage 6, taken 2 / out 1 / missed 2). Button
  coordinates were probed per state and every PNG re-verified
  by eye (see `shot-cue-fridge.js` in
  `~/workspace/preview-tools/`): the DEMO row is y=180-190 in
  idle; y=185 with a 1200 ms wait silently missed after stage
  1 (frames byte-identical to stage 1) — the verified
  sequence uses y=180 with a 2000 ms wait.
