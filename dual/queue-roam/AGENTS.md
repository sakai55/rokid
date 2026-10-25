# Queue Roam — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series DU05 (DUAL 并行型， last of the group): on a ticket queue, the
wearer's main line is roaming and the side line is "don't miss your
number". The agent takes the listening: register your ticket number,
far-field listening passes every call announcement through a
ticket-number gate, and only your own number banners hard — plus a
manual progress report when you pass the call screen, and a near
threshold that calls you back before your turn.

## Design contract

- **The side line is a gate, a manual report and a threshold —
  never a detection.** NUM cycles to your number; START requires
  it and names what is missing. The gate is the transcript:
  `_onSegment` extracts the first ticket pattern (`[A-Z]` +
  three digits) from one segment and compares it to your number
  exactly. A hit banners hard, speaks exactly one short
  utterance ("到你了，马上回去"), and is recorded as an event.
  Any other segment — including a broadcast calling somebody
  else's number — moves only the counter: the sentence is
  discarded here and stored nowhere, and it never moves the
  progress. That last point is deliberate: a misheard number in
  ASR must not corrupt the progress.
- **Progress is a manual report, never a reading.** PROG cycles
  the reported "currently called" number while listening. There
  is no screen reading and no OCR: the agent never sees the
  call screen, so the only honest progress is the one you report
  when you pass the screen. PROG is refused in idle and in
  summary, because a progress report belongs to a roam under
  way.
- **The gap is arithmetic, not a queue system.** `_gap` subtracts
  the reported progress from your number, only when both share
  the same letter prefix (otherwise null — no banner, no claim).
  A gap of 1–5 fires the near reminder once per progress value
  ("快到你了，回去等着", one TTS, one event); a gap of 0 on a
  manual report banners as called ("进度报到你的号"). A
  negative gap (progress past your number) fires nothing: the
  agent does not invent an "already missed" verdict from two
  hand-supplied strings. The official call is still whatever the
  screen and the broadcast say, and the README says so.
- **A nod never starts listening and never reports progress.** A
  steady nod switches the ticket number in idle (cycling to your
  number), confirms going back when a near/called banner is on
  screen (listening), or confirms the summary. In listening
  without a banner a nod is ignored with an explanation, because
  there is nothing safe for it to confirm — and progress is a
  manual report, not a head gesture. An unsteady nod never arms
  the 1.2 s lock (the fleet fix, kept).
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to listening without deleting anything;
  the summary is rebuilt on END. BACK elsewhere is ignored with
  an explanation. Confirming the summary (Enter / steady nod /
  CHECK) is the only wipe. There is no DEL key: there is no
  banner to clear without also lying about the reminder state.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks five stages: ticket A047 registered (DEMO sample) and
  listening started → non-hit segment (A030) counted only →
  two manual progress reports (A040 silent, A042 gap 5, near
  reminder fires once) → hit segment (A047) banners called →
  going-back confirmed + END summary (segments 2, near 1,
  called 1, confirmed 1, progress A042). A sixth DEMO tap
  reports the demo complete. DEMO refuses outright if a user
  number is registered or a user roam is under way. Every step
  is labelled DEMO; the sample number and progress are labelled
  as samples.
- **The roam lives in session memory only — zero persistence,
  by design.** Number, progress, events and counts die when the
  summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the queue is gone,
  which is the correct use for a queue happening right now.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). There is no
  ticker: every transition is a tap, a nod or a key — a queue
  is event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `tour-watch` (DU04) is the sibling template:
  same gate + one-TTS discipline, same nod discipline, same
  zero-persistence rule, same DEMO five-stage arc — but its gate
  is meeting information, it registers a meeting direction and a
  clock time, and its reminder is a clock threshold. Queue-roam
  has no direction and no clock: its gate is a ticket number,
  its progress is a manual report, and its reminder is a number
  gap.
- Attention-series `meeting-filter` (FI04) is the keyword-gate
  template: same gate + one-TTS discipline — but its gate is
  "your name / your topics" and it keeps a 10-second pre-hit
  replay buffer. Queue-roam has no replay buffer at all: a hit
  is recorded as an event, and the gate is a number, not a
  topic.
- Attention-series `lecture-filter` (FI05) is the signal-note
  template: same "hit is recorded, non-hit is counted and
  discarded" rule — but its signals are class signals and it has
  no progress, no gap and no go-back confirmation. Queue-roam
  adds the manual progress, the gap threshold and the go-back
  confirmation, because a missed number is a missed turn, not a
  missed sentence.

## Permissions

RECORD_AUDIO only — far-field listening plus ASR input. The
microphone mode (far-field) is an AIUI mic-API mode: it affects
only the getUserMedia stream's pickup, not the host ASR's
pickup, and the UI and README both say so (fleet audit
conclusion). No `CAMERA`: nothing is photographed — the call
screen is never read, and the DEMO progress is a labelled
sample. No `GEOLOCATION`: a queue side line needs no position,
and this agent never knows where anyone or any screen is.

## Validation

- Node harness (see `/tmp/queue-roam-harness.js`, not packed):
  app.json pages and permissions exactly [`RECORD_AUDIO`];
  zero storage/camera/geo APIs in the page source; no legacy
  Page/App/Widget; no utterance language assignment; foot2
  honesty lines asserted (no screen reading / manual report /
  no OCR, no speaker identification, gap is arithmetic not an
  official queue system, mic mode does not change host ASR
  pickup, non-hit segments counted and discarded); initial idle
  state (number/progress unset, bigText 未登记你的号, counts 0,
  events empty, banner null); bigCls thresholds; refusals in
  idle (START naming the missing number, END refused, CHECK
  refused, PROG refused, segments ignored); NUM cycle and wrap
  (A047 → A052 → B008 → C120 → A047); START listening and
  refusals in listening (START/NUM); gap arithmetic (gap null
  without progress, A040 gap 7 silent, A042 gap 5 near fires
  once with one TTS, CHECK confirms, CHECK twice refused,
  A044/A046 refire per new progress value, wrap to A040 silent
  then A042 refires, prefix mismatch gap null); progress
  reaching your number via report banners called; call-number
  gate (other number counted only with zero TTS and progress
  untouched, own number banners called with exactly one TTS,
  second own hit counts again, NEXT/PREV wrap, rowTap focus and
  out-of-range guard); summary flow (END reaches summary with
  segments 2, near 1, called 1, confirmed 2, number A047,
  progress A042; BACK rebuilds; confirm wipes to idle); nod
  discipline (unsteady ignored without arming, steady nod in
  idle switches number, lock blocks a second nod, lock expiry
  works, nod in listening without banner ignored, nod with near
  banner confirms going back); key discipline (Enter idle
  switches number, ArrowUp/Down cycle idle rows, Backspace idle
  ignored); SPEAK lines per mode; DEMO five-stage arc and
  refusal on a user registration or user roam; onUnload wipes
  everything. Result: **91/91**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (number unregistered), listening (DEMO
  stage 1, sample number A047), near banner (DEMO stage 3,
  progress A042, gap 5), called banner (DEMO stage 4, own
  number A047), summary (DEMO stage 5, segments 2, near 1,
  called 1, confirmed 1, progress A042). Button coordinates
  were probed per state and every PNG re-verified by eye (see
  `shot-queue-roam.js` in `~/workspace/preview-tools/`): DEMO is
  the row-1 FIRST button (x=88); final DEMO tap sequence is
  [185, 180, 180, 180, 180] — in listening state y=190 hit START
  (refused, only the EVT line changed) and y=210 hit SPEAK,
  while the true DEMO band was y=170-180; in idle state y=170
  missed and y=200+ missed.
