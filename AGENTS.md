# Attention Diary — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series R05 (REVIEW 回顾型， last of the group, series #30): at the end of
the day you want to know who stole your attention — this agent takes the
day's attention bill off your hands. Log one trigger per category as the
day goes (watch reminder, silent save, shield block, filter hit, replay
confirmation, side-line reminder), open the bill for per-category counts,
and close with a summary naming the category that stole the most.

## Design contract

- **The bill is a ledger, never a collection result.**
  MARK logs one entry: the current CAT selection, the clock time, and
  the note "手动记一格". BILL totals the entries per category; the
  top category is the one with the most entries (ties go to the
  earliest category in the list, and the tie is shown, not hidden).
  END produces a summary with the total, the per-category counts,
  and the top category. Nothing here measures anything: the counts
  are arithmetic over entries you logged, not sensor statistics.
- **No cross-agent collection — the platform limit, stated plainly.**
  AIUI agents do not share data and there is no background
  aggregation, so attention-diary cannot read other agents'
  trigger records. The bill is therefore a manual ledger: entries
  come from you (or from the labelled DEMO arc), and the UI and
  README say exactly that — "账单是你自己记的分类计数，不是自动
  采集的全天统计；跨 Agent 自动汇总需要平台级数据通道，目前没有".
  Claiming automatic whole-day collection would be a lie about
  the platform, so the agent never claims it and never calls any
  storage or cross-agent API to fake it.
- **The "whole day" is single-session, by discipline.** The fleet
  zero-persistence rule forbids storage APIs, so entries logged
  today cannot survive the agent closing and reappear at night.
  The bill covers the entries logged in this open session; the
  DEMO arc shows the bill format with seeded entries. Cross-day
  keeping is a decision for GO, not something smuggled in through
  storage.
- **A nod logs or walks, never picks a category.** A steady nod
  in log MARKS the current CAT selection (gaze confirm of an
  explicit selection, the day-lookback precedent); in the bill it
  walks to the next category (walking only — it never logs and
  never changes a count); in summary it confirms and clears.
  An unsteady nod never arms the 1.2 s lock (the fleet fix,
  kept). A nod never changes CAT: that is a selection, and a nod
  must not silently pick one.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to the bill without deleting anything; the
  summary is rebuilt on END. BACK from the bill returns to
  logging with entries kept. Confirming the summary (END while
  a summary is open, or a steady nod) is the only wipe. There
  is no DEL key: there is nothing to clear that would not also
  lie about the day's bill.
- **The day lives in session memory only — zero persistence,
  by design.** Entries, counts, focus and the summary die when
  the summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the day's bill is gone.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in the
  bill reads the focused category's count plus the top category;
  it never reads a whole list aloud. There is no ticker: every
  transition is a tap, a nod or a key — a bill is event-driven,
  not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `day-lookback` (R01) is the day timeline:
  gazes you marked, typed 画面 / 数字 / 承诺, ordered by time.
  Attention-diary is not a timeline: its units are trigger
  entries grouped by category, and its close is a counted bill
  with a single "stole the most" verdict, not a replay.
- Attention-series `talk-replay` (R02) is the talk replay:
  conversation captions tagged by speaker, replayed as only
  承诺 / 数字 / 期限 sentences. Attention-diary has no captions
  and no sentence classes: its categories are trigger sources
  across the whole fleet (watch, silent save, shield, filter,
  replay, side-line), and its output is counts, not sentences.
- Attention-series `route-replay` (R04) is the route preview:
  hazard spots with directions and on-the-spot photos, walked
  in registration order. Attention-diary has no directions and
  no photos: its units are counted triggers, and its walk is
  across categories, not places.

## Permissions

Zero permissions (app.json `permissions` is `[]`, and the
static check asserts exactly that): logging and counting need
no camera, no microphone, no position. No `CAMERA`: nothing is
photographed. No `RECORD_AUDIO`: nothing is listened to, there
is no ASR path at all (no onASRResult handler). No
`GEOLOCATION`: this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/attention-diary-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location APIs, no ASR/recorder/camera path, no
  utterance language assignment, no legacy Page/App/Widget;
  foot2 honesty lines asserted (manual ledger not auto-collected,
  no cross-agent sharing, no background aggregation, platform-level
  channel named as missing, counts are not sensor statistics,
  single session, cleared on close, no indoor positioning, zero
  persistence); initial log-empty state (bigText 还没记，
  placeholder row, countLine); bigCls thresholds; refusals in
  log-empty (BILL/END naming the missing MARK, NEXT/PREV/BACK
  ignored); CAT cycle and wrap; MARK flow (current CAT, manual
  note, HH:MM time, counts, tie top goes to earliest category);
  bill flow (open at focus 0, per-category rows, bigText and
  bigNote naming top, BILL refused when open, NEXT/PREV wrap
  over 6 categories, rowTap focus with out-of-range and
  missing-dataset guards, CAT/MARK refused in bill, BACK keeps
  entries); summary flow (END from bill, total/top, BACK rebuilds,
  END in summary confirms and clears); DEMO eight-stage arc
  (6 entries, counts [2,1,3,0,0,0], top shield 3, bill, summary,
  refused after complete) and refusal on user entries; nod
  discipline (unsteady ignored without arming, steady nod in log
  MARKs, lock blocks a second nod, lock expiry works, steady nod
  in bill walks without logging, in summary confirms, non-nod
  gestures noted); key discipline (Enter MARKs in log / walks in
  bill / confirms in summary, ArrowUp/Down wrap, Backspace
  ignored in log); SPEAK lines per mode; onUnload wipes
  everything; summary reports honestly with partial counts.
  Result: **84/84** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (nothing logged), logged (DEMO stage 6,
  6 entries), bill (focus category 1, watch 2, top line names
  shield 3), top (focus category 3, shield 3 — the category
  that stole the most), summary (6 entries, top shield 3).
  Button coordinates were probed per state and every PNG
  re-verified by eye (see `shot-attention-diary.js` in
  `~/workspace/preview-tools/`).
