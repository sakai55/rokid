# Tomorrow Stage — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series AM05 (AMBIENT 环境型， last of the group, series #50 — the series
finale): tomorrow morning's first-task items are the ones you forget to
stage tonight and then scramble for at the door. This agent takes the
staging off your hands: the night before, you look steady at each item
and tap REG to stage it; in the morning, CUE walks you through the
staged items one by one, and the gate never says you may leave while
anything is still missing.

## Design contract

- **The night staging and the morning CUE are two phases of ONE
  open session — not overnight storage.** The fleet's zero-persistence
  discipline forbids storage APIs, so a staged list dies when the
  agent closes (onUnload wipes everything). "Stage tonight, check
  tomorrow morning" therefore means: keep this agent open across
  the two phases in one session. True cross-night storage would
  need GO's decision to break the discipline, and this agent never
  sneaks a storage call in — the static check asserts zero
  storage APIs, and the UI and README say exactly this.
- **The gate never says you may leave while anything is missing.**
  With unconfirmed items, END warns and names the missing items
  by name; only when every staged item is confirmed does the
  summary say 可以出门. This is the cue-door gate discipline
  (CU01), applied to the morning check.
- **The gate does not stop you leaving.** It only refuses to say
  you may leave: there is no lock, no forced flow, no blocking.
  The final decision is always yours, and the README says so.
- **Looking steady stages an item; it does not verify the item.**
  REG records that you looked steady at the item and tapped — the
  agent cannot see whether the keys are really there. The UI and
  README say exactly that.
- **A nod never stages an item and never confirms one.** Staging
  comes from looking steady and tapping REG, confirming from
  standing with the item and tapping CONFIRM — a nod must not
  invent either. A steady nod in idle starts staging and in
  summary confirms it.
- **Correction is cheap, destruction is confirmed.** BACK from
  staging or cue returns to idle with the session kept, and START
  resumes the same round; BACK from the summary returns to the
  mode it came from without deleting anything, and the summary is
  rebuilt on END. Confirming the summary (END while a summary is
  open, or a steady nod) is the only wipe. There is no DEL key.
- **The session lives in session memory only — zero persistence,
  by design.** Items, confirmations and the gate result die when
  the summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the staged list is gone.
- **Not a packer, not a tracker.** The agent does not know where
  your items are, does not watch them, and does not adapt
  anything: the item cap (8) and the preset names are fixed,
  and the UI and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). The morning CUE
  speaks once when it opens; SPEAK re-reads only on an explicit
  tap.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `cue-door` (CU01) is the exit gate: items
  confirmed before leaving, and it never says you may leave
  while anything is missing. Tomorrow-stage reuses that gate
  discipline, but its list is staged the night before by
  looking steady at each item — cue-door stages nothing.
- Attention-series `cue-bag` (CU04) is an exit luggage check:
  items confirmed as packed into the bag. Tomorrow-stage
  checks nothing into a bag: it stages tomorrow's first-task
  items the night before and re-checks them at the door.
- Attention-series `trail-back` (AM04) records a way back with
  direction + photo crumbs. Tomorrow-stage records no route
  and takes no photos: its only input is your REG at an item
  and your CONFIRM in the morning.

## Permissions

Empty array (app.json `permissions` is exactly `[]`, and the
static check asserts exactly that): staging by looking and
confirming by tapping need no device capability. No `CAMERA`:
nothing is photographed. No `RECORD_AUDIO`: nothing is
listened to. No `GEOLOCATION`: this agent never knows where
anyone is.

## Validation

- Node harness (see `/tmp/tomorrow-stage-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location/camera/audio APIs, no utterance language
  assignment, no legacy Page/App; foot2 honesty lines
  asserted （同一打开会话、不是跨夜存档、关掉即清、不是验证
  物品本身、不阻止出门、门只是不说可以出门、最终决定在你、
  没有室内定位、没有摄像头、只存本次会话、零落盘）; initial
  idle state （bigText 还没开始， placeholder row, countLine);
  idle refusals (REG ignored, CUE/END refused missing, BACK
  ignored, CONFIRM ignored); start + steady discipline
  (START refused while staging, unsteady REG refused, steady
  REG records, preset order 钥匙/工牌/雨伞/水杯/文件袋 then
  物品6, 8 item cap, 9th refused); focus walks rows with
  wrap, rowTap out-of-range and missing-dataset guards
  (missing dataset keeps focus, never jumps to 0 — the BO05
  page bug, fixed here by construction); BACK to idle keeps
  the session with START resume; CUE + confirm discipline
  (CUE speaks once, CUE refused while cue, double CONFIRM
  refused); the gate (END with missing warns and names them
  and never says 可以出门， BACK rebuilds cue without
  deleting, all confirmed END says 可以出门， summary END
  confirms and clears, staging END gives an all-missing
  summary); CUE with zero items refused; nod discipline
  (unsteady ignored without arming, steady nod in idle
  starts, lock blocks a second nod, lock expiry works, nod
  in staging/cue ignored as not-a-stage/not-a-confirm, non-nod
  gesture noted); key discipline (Enter per-mode, ArrowUp/Down
  walk, Backspace returns); SPEAK lines per mode; DEMO
  six-stage arc (staged 2, staged 3, cue 1 confirmed,
  summary missing 工牌、雨伞 mayLeave false, summary staged 3
  confirmed 3 mayLeave true) and refusal on user sessions;
  onUnload wipes everything; bigCls thresholds.
  Result: **118/118** (first run 117/118, the 1 failure a
  harness-side miscount — a bigCls test string counted as 13
  chars was really 16 — fixed in the harness, page code
  untouched).
- Preview screenshots 6, each visually verified (not just
  hash-compared): idle (not started), staging (DEMO stage 1,
  2 items), staged (DEMO stage 2, 3 items), cue (DEMO stage 3,
  1 confirmed of 3), missing warning (DEMO stage 4, missing
  工牌、雨伞）, all-confirmed summary (DEMO stage 5, staged 3,
  confirmed 3, may leave). Button coordinates were probed per
  state and every PNG re-verified by eye (see
  `shot-tomorrow-stage.js` in `~/workspace/preview-tools/`).
  DEMO is a staged sample, not a live night: items and
  confirmations are staged values, not sensor readings.
