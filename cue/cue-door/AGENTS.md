# Cue Door — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series P01 (CUE 提示型， first of the group, series #31): leaving the
house and forgetting something is daily, and a list taped to the door is
easy to ignore. This agent takes the going-out check off your hands:
look at the door and hold steady, and only then does the checklist
open; confirm each preset item one by one, and only when every item
is confirmed does it release you.

## Design contract

- **The door is a gate, never a reminder that can be swiped away.**
  TRIG opens the checklist only from idle, and only with a steady
  head (the gaze trigger, judged on-device by head steadiness via
  `onOrientationStabilityChange`). CONF confirms the focused item.
  END in the list is the gate: with any item unconfirmed it blocks,
  counts the block, names the missing items in the banner and in
  one TTS utterance, and stays in the list — it never says
  "可以出门" while anything is missing. Only a 5/5 END opens the
  summary with released=true.
- **A confirmation is a statement, never a sensor proof.** The
  agent does not detect whether anything is actually packed: it
  has no camera, no microphone, no position, and no inventory
  sensor. CONF records that you said you have it. The UI and
  README say exactly that — "确认只是你本人的表态，不是传感器
  证明——Agent 不检测东西是不是真的在包里；它不是防丢设备，
  不能保证出门不忘带". Claiming detection would be a lie about
  the hardware, so the agent never claims it.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to the checklist without deleting anything;
  the summary is rebuilt on END. BACK from the list returns to
  idle with confirmations kept, and re-triggering restores the
  same checklist. Confirming the summary (END while a summary
  is open, or a steady nod) is the only wipe. There is no DEL
  key: there is nothing to clear that would not also lie about
  what was confirmed.
- **The checklist lives in session memory only — zero persistence,
  by design.** Items, confirmations, block count and the summary
  die when the summary is confirmed and when the agent closes
  (onUnload wipes everything). Close the agent and the going-out
  round is gone.
- **A steady nod triggers, confirms, or clears — never picks.**
  A steady nod in idle triggers the checklist, in the list
  confirms the focused item, in summary confirms and clears.
  An unsteady nod never arms the 1.2 s lock (the fleet fix,
  kept). A nod never changes focus: that is a selection, and a
  nod must not silently pick an item. Enter follows the same
  per-mode action; ArrowUp/Down walk focus; Backspace goes back.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in the
  list names the confirmed count and the missing items; it never
  reads a whole list aloud. There is no ticker: every transition
  is a tap, a nod or a key — a checklist is event-driven, not
  time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `pack-sweep` (C04) is the at-home packing
  checklist: items packed before leaving, counted at home.
  Cue-door is not packing: its trigger is looking at the door
  itself, and its close is a release gate, not a packing count.
- Attention-series `bag-watch` (D02) is the in-transit luggage
  side-line: a direction-registered bag watched while waiting,
  with a leave-gate that blocks on an unconfirmed bag. Cue-door
  has no direction registration and no waiting watch: its gate
  is the going-out checklist at the door, confirmed item by item.
- Attention-series `attention-diary` (R05) is the attention bill:
  trigger entries grouped by category, closed with a counted
  verdict. Cue-door has no categories and no bill: its units are
  the five going-out items, and its close is a release verdict.

## Permissions

Zero permissions (app.json `permissions` is `[]`, and the
static check asserts exactly that): a gaze trigger plus a
checklist gate needs no camera, no microphone, no position.
No `CAMERA`: nothing is photographed. No `RECORD_AUDIO`:
nothing is listened to, there is no ASR path at all (no
onASRResult handler). No `GEOLOCATION`: this agent never knows
where anyone is.

## Validation

- Node harness (see `/tmp/cue-door-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location APIs, no ASR/recorder/camera path, no
  utterance language assignment, no legacy Page/App/Widget;
  foot2 honesty lines asserted (confirmation is a statement not
  a sensor proof, not an anti-loss device, single session,
  cleared on close, no indoor positioning, zero persistence,
  gaze trigger judged by head steadiness); initial idle state
  (bigText 还没触发， placeholder row, countLine); bigCls
  thresholds; refusals in idle (END naming TRIG, CONF refused,
  NEXT/PREV/BACK ignored, TRIG refused while head moving);
  steady event arms steady and TRIG opens the list at focus 0;
  confirm flow (CONF confirms, re-CONF refused, NEXT/PREV wrap
  over 5 items, rowTap focus with out-of-range and
  missing-dataset guards); gate (END with missing items blocks,
  stays in list, block counted, missing items named in event
  and in exactly one TTS utterance, bigText never says 可以出门
  while blocked); full confirm -> release -> summary (5/5,
  blocks kept, BACK rebuilds, END in summary confirms and
  clears); BACK from list keeps confirmations and re-TRIG
  restores them; DEMO eight-stage arc (trigger, 钥匙， 手机，
  blocked naming 钱包、工牌、雨伞， 钱包， 工牌， 雨伞 5/5
  可以出门， summary released) and refusal on user sessions;
  nod discipline (unsteady ignored without arming, steady nod
  in idle triggers, lock blocks a second nod, lock expiry works,
  non-nod gestures noted); key discipline (Enter triggers /
  confirms, ArrowUp/Down walk, Backspace returns to idle with
  confirmations kept); SPEAK lines per mode; onUnload wipes
  everything; summary reports honestly with partial counts.
  Result: **80/80** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not triggered), list (DEMO stage 1,
  0/5), partial (DEMO stage 3, 2/5, 钥匙/手机 confirmed),
  blocked (DEMO stage 4, still 2/5, banner names 钱包、工牌、
  雨伞， block 1), summary (DEMO stage 8, released 5/5, blocks
  1). Button coordinates were probed per state and every PNG
  re-verified by eye (see `shot-cue-door.js` in
  `~/workspace/preview-tools/`).
