# Cue Mirror — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series CU05 (CUE 提示型， last of the group, series #35): the most hectic
ten seconds of the morning are in front of the mirror — the weather,
the first thing today, and the thing you must not forget all crowd
in at once. This agent takes the mirror check off your hands: look
at the mirror and hold steady, and only then do three lines light
up — today's weather note, the first thing today, yesterday's line
for this morning — confirm each line read one by one, and when all
three are read it says "可以出门了"; closing early names the unread
lines — a reminder, never a gate.

## Design contract

- **Closing early is a reminder, never a gate.** TRIG lights the
  three lines only from idle, and only with a steady head (the
  gaze trigger, judged on-device by head steadiness via
  `onOrientationStabilityChange`). READ confirms the focused line
  as read. END in the list is the reminder: the first END with
  unread lines names them in the banner and in one TTS
  utterance, counts the warning, and stays in the list; the
  second END closes for real and the unread lines are
  recorded honestly in the summary. This is the deliberate
  opposite of cue-door (CU01), where an unconfirmed END blocks:
  a mirror glance must not hold the door hostage, and a
  warning that pretended to block would be a lie about what
  happens next. The banner says so in plain words — "再点
  END 就结束（提醒，不是拦门）".
- **All three lines are presets, never live data.** There is no
  weather API and no calendar sync: the weather note is not
  live weather and the first thing is not a calendar read.
  The PLAN row's "预设/语音登记" is implemented on the preset
  branch only — voice registration would need an ASR path
  and is out of scope for this task. Preset groups rotate on
  each fresh trigger (group A, then group B, then back to A);
  a kept list (BACK from the list) restores its own group on
  re-trigger instead of rotating. The UI and README say
  exactly that.
- **Yesterday's line lives in this session only.** The
  yesterday-to-this-morning line is a same-session note: it
  dies when the round is confirmed and when the agent closes
  (onUnload wipes everything). Yesterday-to-today persistence
  would need a storage exception decided by GO — the same
  treatment as RE01 day-lookback and RE04 route-replay — and
  this agent does not take it on its own. No storage API is
  called anywhere.
- **Looking at the mirror is not mirror recognition.** The
  trigger is looking toward the mirror's direction and holding
  steady — the agent has no mirror recognition and does not
  know where any mirror is. Claiming mirror detection would
  be a lie about the hardware, so the agent never claims it.
- **A read mark is a statement, never a sensor proof.** The
  agent does not detect whether anything was actually read:
  it has no camera, no microphone, no position, and no
  reading sensor. READ records that you said you read it.
  The UI and README say exactly that.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to the three lines without deleting
  anything; the summary is rebuilt on END. BACK from the list
  returns to idle with read marks kept, and re-triggering
  restores the same three lines and group. Confirming the
  summary (END while a summary is open, or a steady nod) is
  the only wipe. There is no DEL key: there is nothing to
  clear that would not also lie about what was read. A
  warning resets when the list changes (a READ clears
  `_warned`): a warning names a moment's unread set, and a
  changed list deserves a fresh warning, not a stale one.
- **The three lines live in session memory only — zero
  persistence, by design.** Lines, read marks, warn count and
  the summary die when the summary is confirmed and when the
  agent closes (onUnload wipes everything). Close the agent
  and the mirror round is gone.
- **A steady nod triggers, confirms, or clears — never picks.**
  A steady nod in idle lights the three lines, in the list
  confirms the focused line read, in summary confirms and
  clears. An unsteady nod never arms the 1.2 s lock (the fleet
  fix, kept). A nod never changes focus: that is a selection,
  and a nod must not silently pick a line. Enter follows the
  same per-mode action; ArrowUp/Down walk focus; Backspace
  goes back.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in the
  list names the read count and the unread lines (or the
  warning, once warned); it never reads all three lines aloud.
  There is no ticker: every transition is a tap, a nod or a
  key — a mirror check is event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `cue-door` (CU01) is the going-out checklist
  gate at the door: unconfirmed END blocks and never says
  "可以出门". Cue-mirror is not a gate: closing early reminds
  and then lets the round close, with the unread recorded
  honestly instead of blocking.
- Attention-series `cue-desk` (CU03) is the desk three things
  plus a stand-up resume line: look at the desk, light today's
  three tasks, and on standing up get "回来从这继续". Cue-mirror
  has no stand-up resume: its trigger is looking at the
  mirror, its lines are weather note + first thing + yesterday
  line, and its close is a read/unread verdict.
- Attention-series `cue-fridge` (CU02) is the fridge to-fetch
  checklist: tick as you take, mark out of stock, and before
  closing it names anything still unticked (a reminder, not a
  gate). Cue-mirror shares the reminder-not-gate shape but is
  not fetching: its trigger is looking at the mirror, and its
  close is a read verdict, not a miss report.
- Attention-series `attention-diary` (RE05) is the attention bill:
  trigger entries grouped by category, closed with a counted
  verdict. Cue-mirror has no categories and no bill: its units
  are the three mirror lines, and its close is a read verdict.
- Attention-series `day-lookback` (RE01) is the daytime gaze
  timeline. Cue-mirror is not a timeline: it lights only the
  three pre-departure mirror lines and does not register the
  day's gazes.

## Permissions

Zero permissions (app.json `permissions` is `[]`, and the
static check asserts exactly that): a gaze trigger plus a
mirror-line reminder needs no camera, no microphone, no
position. No `CAMERA`: nothing is photographed. No
`RECORD_AUDIO`: nothing is listened to, there is no ASR path
at all (no onASRResult handler — voice registration is out of
scope). No `GEOLOCATION`: this agent never knows where anyone
is.

## Validation

- Node harness (see `/tmp/cue-mirror-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location APIs, no ASR/recorder/camera path, no
  utterance language assignment, no legacy Page/App;
  foot2 honesty lines asserted (all three lines are presets,
  no weather API, no calendar sync, not live weather, not a
  calendar read, yesterday line same-session only, cleared on
  close, not mirror recognition, read is a statement not a
  sensor proof, no indoor positioning, zero persistence, gaze
  trigger judged by head steadiness); initial idle state
  (bigText 还没触发， placeholder row, countLine); bigCls
  thresholds; refusals in idle (END naming TRIG, READ refused,
  NEXT/PREV/BACK ignored, TRIG refused while head moving);
  steady event arms steady and TRIG opens the list at focus 0
  with preset group A lines; read flow (READ reads, re-READ
  refused, NEXT/PREV wrap over 3 lines, rowTap focus with
  out-of-range and missing-dataset guards); close warning
  (first END warns, stays in list, exactly one TTS naming the
  unread line and not the read lines, bigText 未读 1 行；
  READ clears warned; second END opens the summary with
  read/unread recorded honestly); all-read close (summary
  可以出门了， no TTS); preset rotation (second fresh trigger
  shows group B, third wraps back to group A); BACK from list
  keeps read marks and group and re-TRIG restores them;
  summary BACK rebuilds without re-warning; DEMO six-stage
  arc (trigger, weather read, first-thing read, warned naming
  昨日留给今早的一句话， yesterday line read 3/3, summary
  read 3/3 可以出门了） and refusal on user sessions; nod
  discipline (unsteady ignored without arming, steady nod in
  idle triggers, lock blocks a second nod, lock expiry works,
  non-nod gestures noted); key discipline (Enter triggers /
  reads, ArrowUp/Down walk, Backspace returns to idle with
  read marks kept); SPEAK lines per mode; onUnload wipes
  everything; summary reports honestly with partial counts.
  Result: **94/94** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not triggered), list (DEMO stage 1,
  0/3), partial (DEMO stage 3, 2/3, 天气要点/第一件事 read),
  all read (DEMO stage 5, 3/3, 可以出门了）, summary (DEMO
  stage 6, read 3/3, warns 1). The DEMO stage 4 warned frame
  (unread 昨日留给今早的一句话， warning 1, reminder not a
  gate) was captured to /tmp and eye-verified but is not
  delivered, keeping the fleet's 5-frame norm. Button
  coordinates were probed per state and every PNG re-verified
  by eye (see `shot-cuemirror.js` in
  `~/workspace/preview-tools/`): the DEMO band is y=180–190
  at x=66 in idle (150–170 miss, 200–220 NEXT-row fake hits
  that only change EVT, 230–240 SPEAK row); the same (66,180)
  held through all six DEMO stages with 2000 ms waits, all
  seven frames md5-distinct, no stalls.
