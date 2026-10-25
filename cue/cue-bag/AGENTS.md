# Cue Bag — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series P04 (CUE 提示型， fourth of the group, series #34): swapping bags
or jackets to go out and always leaving something in the last bag. This
agent takes the packing check off your hands: look at today's bag and
hold steady, and only then does the destination packing list open;
confirm each item into its compartment one by one, and if you close
early it names what's missing — a reminder, never a gate.

## Design contract

- **Closing early is a reminder, never a gate.** TRIG opens the
  packing list only from idle, and only with a steady head (the
  gaze trigger, judged on-device by head steadiness via
  `onOrientationStabilityChange`). GOT confirms the focused item
  as packed. END in the list is the reminder: the first END with
  missing items names them in the banner and in one TTS
  utterance, counts the warning, and stays in the list; the
  second END closes for real and the missing items are
  recorded honestly in the summary. This is the deliberate
  opposite of cue-door (P01), where an unconfirmed END blocks:
  packing happens at home where you can still turn back and
  fetch, and a warning that pretended to block would be a lie
  about what happens next. The banner says so in plain words —
  "再点 END 就结束（提醒，不是拦门）".
- **A confirmation is a statement, never a sensor proof; a
  compartment is a group label, never a measured position.**
  The agent does not detect whether anything is actually in
  the bag: it has no camera, no microphone, no position, and
  no inventory sensor. GOT records that you said you packed
  it; the compartment （主袋 / 侧袋 / 内袋） is only the list
  row's group label, not a measured position inside the bag.
  The UI and README say exactly that — "确认装入只是你本人
  的表态，不是传感器证明——Agent 不检测东西是不是真的在包
  里；格层只是清单分组标注，不是包内实测位置". Claiming
  detection or measured compartments would be a lie about the
  hardware, so the agent never claims either.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to the list without deleting anything;
  the summary is rebuilt on END. BACK from the list returns to
  idle with confirmations kept, and re-triggering restores the
  same packing list. Confirming the summary (END while a
  summary is open, or a steady nod) is the only wipe. There is
  no DEL key: there is nothing to clear that would not also
  lie about what was packed. A warning resets when the list
  changes (a GOT clears `_warned`): a warning names a
  moment's missing set, and a changed list deserves a fresh
  warning, not a stale one.
- **The packing list lives in session memory only — zero
  persistence, by design.** Items, confirmations, warning count
  and the summary die when the summary is confirmed and when
  the agent closes (onUnload wipes everything). Close the agent
  and the packing round is gone.
- **A steady nod triggers, confirms, or clears — never picks.**
  A steady nod in idle triggers the packing list, in the list
  confirms the focused item, in summary confirms and clears.
  An unsteady nod never arms the 1.2 s lock (the fleet fix,
  kept). A nod never changes focus: that is a selection, and a
  nod must not silently pick an item. Enter follows the same
  per-mode action; ArrowUp/Down walk focus; Backspace goes back.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in the
  list names the packed count and the missing items (or the
  warning, once warned); it never reads a whole list aloud.
  There is no ticker: every transition is a tap, a nod or a
  key — a packing list is event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `cue-door` (P01) is the going-out checklist
  gate at the door: unconfirmed END blocks and never says
  "可以出门". Cue-bag is not a gate: closing early reminds
  and then lets the round close, with the miss recorded
  honestly instead of blocking.
- Attention-series `pack-sweep` (C04) is the at-home packing
  checklist: items packed before leaving, counted at home.
  Cue-bag is not generic packing: its trigger is looking at
  today's bag itself, and its list is per destination with
  compartment-grouped confirmation.
- Attention-series `bag-watch` (D02) is the in-transit luggage
  side-line: a direction-registered bag watched while waiting,
  with a leave-gate that blocks on an unconfirmed bag. Cue-bag
  has no direction registration and no waiting watch: its
  work is the at-home packing list before leaving.
- Attention-series `cue-fridge` (P02) is the fridge to-fetch
  checklist: tick as you take, mark out of stock, and before
  closing it names anything still unticked (a reminder, not a
  gate). Cue-bag shares the reminder-not-gate shape but is not
  fetching: its trigger is looking at today's bag, and its
  close is a packed/missing verdict, not a miss report.
- Attention-series `attention-diary` (R05) is the attention bill:
  trigger entries grouped by category, closed with a counted
  verdict. Cue-bag has no categories and no bill: its units
  are the five packing items, and its close is a packed
  verdict.

## Permissions

Zero permissions (app.json `permissions` is `[]`, and the
static check asserts exactly that): a gaze trigger plus a
packing reminder needs no camera, no microphone, no position.
No `CAMERA`: nothing is photographed. No `RECORD_AUDIO`:
nothing is listened to, there is no ASR path at all (no
onASRResult handler). No `GEOLOCATION`: this agent never knows
where anyone is.

## Validation

- Node harness (see `/tmp/cue-bag-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location APIs, no ASR/recorder/camera path, no
  utterance language assignment, no legacy Page/App;
  foot2 honesty lines asserted (confirmation is a statement
  not a sensor proof, compartments are group labels not
  measured positions, single session, cleared on close, no
  indoor positioning, zero persistence, gaze trigger judged
  by head steadiness); initial idle state (bigText 还没触发，
  placeholder row, countLine); bigCls thresholds; refusals in
  idle (END naming TRIG, GOT refused, NEXT/PREV/BACK ignored,
  TRIG refused while head moving); steady event arms steady
  and TRIG opens the list at focus 0; pack flow (GOT packs,
  re-GOT refused, NEXT/PREV wrap over 5 items, rowTap focus
  with out-of-range and missing-dataset guards); close
  warning (first END warns, stays in list, exactly one TTS
  naming the missing items, bigText 未装 N 项； second END
  opens the summary with packed/missing recorded honestly;
  warned flag resets on GOT); all-packed close (summary
  都装好了， no TTS); BACK from list keeps confirmations and
  re-TRIG restores them; DEMO five-stage arc (trigger, 钥匙，
  手机， warned naming 钱包、工牌、耳机， summary packed 2 /
  missing 3) and refusal on user sessions; nod discipline
  (unsteady ignored without arming, steady nod in idle
  triggers, lock blocks a second nod, lock expiry works,
  non-nod gestures noted); key discipline (Enter triggers /
  packs, ArrowUp/Down walk, Backspace returns to idle with
  confirmations kept); SPEAK lines per mode; onUnload wipes
  everything; summary reports honestly with partial counts.
  Result: **86/86** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not triggered), list (DEMO stage 1,
  0/5), partial (DEMO stage 3, 2/5, 钥匙/手机 packed),
  warned (DEMO stage 4, still 2/5, banner names 钱包、工牌、
  耳机， warning 1, reminder not a gate), summary (DEMO stage
  5, packed 2 / missing 3). Button coordinates were probed
  per state and every PNG re-verified by eye (see
  `shot-cuebag.js` in `~/workspace/preview-tools/`): the DEMO
  band is y=180–190 at x=66 in idle; 150–170 miss, 200–220 is
  the NEXT row (EVT-only fake hits), 230–240 is SPEAK.
