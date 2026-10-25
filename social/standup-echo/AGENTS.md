# Standup Echo — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series S04 (SOCIAL 社交型， fourth of the group, series #39): the daily
standup before your turn is mostly other people's progress, and the item
that is actually related to you slips past unheard. This agent takes the
filtering off your hands: it listens through the standup, lights up only
sentences matching your module keywords into related notes, and silently
condenses every non-hit sentence into one truncated digest line that the
post-meeting review can show.

## Design contract

- **The gate is keywords, never relevance.** Every ASR segment
  goes through one keyword group (default 支付/订单/风控，
  rotatable in idle to 库存/物流/配送） in table order: the
  earliest table keyword in the sentence files it, never all
  of them. A sentence with a keyword is not necessarily
  really related to you: the notes are candidates, and the UI
  and README say exactly that. ASR mishearing can also drop
  or misfile a sentence.
- **A digest row is a truncation, never a paraphrase.** Each
  non-hit segment becomes exactly one line: the first 14
  characters of the original sentence plus an ellipsis when
  cut. Nothing is summarised, nothing is reworded, and no
  full transcript is ever kept — the digest is a pointer
  back to what was said, not a claim about what it meant.
- **Listening never speaks.** A hit is a banner only. Speech
  happens only via SPEAK (counts, or the focused review row)
  and never while listening: speaking mid-standup would
  interrupt the very meeting the agent is supposed to stay
  out of.
- **No speaker identification.** Notes and digest rows are
  not attributed to speakers: there is no voiceprint, and
  the gate runs on transcript text alone. A sentence is
  filed because it contains a keyword, not because of who
  said it.
- **A nod never invents a sentence.** A steady nod in idle
  starts listening, in review moves focus to the next row,
  in summary confirms and clears. While listening a nod (and
  Enter) is ignored and noted: captions can only arrive from
  the talk itself, never from a gesture or a key. An unsteady
  nod never arms the 1.2 s lock (the fleet fix, kept). A nod
  never changes focus in listening: that is a selection, and
  a nod must not silently pick an item — in review the nod
  walks focus because review is a reading mode, not an
  ingest mode. ArrowUp/Down walk rows; Backspace goes back.
- **Correction is cheap, destruction is confirmed.** BACK from
  review returns to listening with notes and digest rows
  kept, and REVIEW reopens from row 1. BACK from listening
  returns to idle with the round kept, and START resumes the
  same round. BACK from the summary returns to review
  without deleting anything, and the summary is rebuilt on
  END. Confirming the summary (END while a summary is open,
  or a steady nod) is the only wipe. There is no DEL key:
  there is nothing to clear that would not also lie about
  what was saved.
- **The round lives in session memory only — zero persistence,
  by design.** Hit notes, digest rows, heard counts and the
  summary die when the summary is confirmed and when the
  agent closes (onUnload wipes everything). Close the agent
  and the standup round is gone.
- **Mic mode is a stream setting, not an ASR setting.** MODE
  cycles wearer/far-field before listening only; it governs
  the getUserMedia stream's pickup and never the host ASR's
  pickup, and the UI and README say so (the fleet audit
  conclusion, kept). MODE is refused mid-standup, as is KW.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK names
  counts, or reads the focused review row, and never reads a
  whole list aloud. There is no ticker: every transition is a
  tap, a nod or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `meeting-filter` (F04) is the meeting
  keyword gate with a 10-second pre-hit replay buffer: it
  replays what was said just before a keyword hit. Standup-echo
  keeps no rolling buffer and replays nothing mid-meeting:
  its non-hits become one-line digest rows for a post-meeting
  review, and its hits are notes, not replay triggers.
- Attention-series `elder-ear` (S03) is the elder-chat
  reminder catcher: keyword hits become a list that is read
  aloud after the chat for confirmation. Standup-echo borrows
  the gate shape but is not a confirmation tool: its hits
  are module-related notes, its non-hits are kept (not
  discarded) as digest rows, and its close is a visual
  review, not a spoken replay.
- Attention-series `chat-catchup` (S01) is the mid-conversation
  silent catch-up: a rolling caption buffer served on HELP.
  Standup-echo keeps no rolling buffer and serves nothing
  mid-standup: it files hits and digest rows, stays silent
  while listening, and serves the review only after REVIEW.

## Permissions

RECORD_AUDIO only (app.json `permissions` is exactly
`["RECORD_AUDIO"]`, and the static check asserts exactly
that): listening to a standup plus host ASR needs the
microphone. No `CAMERA`: nothing is photographed. No
`GEOLOCATION`: this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/standup-echo-harness.js`, not packed):
  app.json pages and permissions exactly `["RECORD_AUDIO"]`;
  zero storage/location/camera/recorder APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted (keyword match not relevance understanding,
  digest row is truncation not paraphrase, no speaker
  identification, single session, cleared on close, mic mode
  does not change host ASR, no indoor positioning, zero
  persistence); initial idle state (bigText 还没守听，
  placeholder row, countLine); bigCls thresholds; MODE cycles
  wearer/far-field and wraps, refused mid-standup; KW cycles
  keyword groups and wraps, refused mid-standup; refusals in
  idle (REVIEW/END naming START, NEXT/PREV/BACK ignored);
  REVIEW refused with zero rows; gate (non-hit kept as one
  truncated digest row with zero TTS, empty and no-text ASR
  ignored, hit saved verbatim with HH:MM time and table-order
  keyword — 支付链路…订单… files under 支付， 订单…风控…
  files under 订单 — hit banner only, zero TTS while
  listening); focus walks hits in listening and combined rows
  in review (NEXT/PREV wrap, rowTap focus with out-of-range
  and missing-dataset guards); BACK keeps notes and digest
  rows, START resumes; review flow (hits first, digest after,
  SPEAK reads focused row); summary flow (hits/digest/heard
  recorded, BACK rebuilds review, END confirms and clears;
  summary from listening records unreviewed rows); SPEAK lines
  per mode; nod discipline (unsteady ignored without arming,
  steady nod in idle starts listening, lock blocks a second
  nod, lock expiry works, nod in listening ignored, nod in
  review advances focus, non-nod gestures noted); key
  discipline (Enter starts listening, Enter in listening
  ignored, Backspace returns); DEMO seven-stage arc (start,
  digest 1, hit 支付， digest 2, hit 订单， review 4 rows,
  summary hits 2 digest 2 heard 4) and refusal on user
  sessions; onUnload wipes everything.
  Result: **101/101** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not listening), listening (DEMO stage
  2, digest 1, heard 1, hits 0), hit (DEMO stage 5, hits 2,
  banner, no TTS), review (DEMO stage 6, hits 2 + digest 2),
  summary (DEMO stage 7, hits 2 digest 2 heard 4). Button
  coordinates were probed per state and every PNG re-verified
  by eye (see `shot-standup-echo.js` in
  `~/workspace/preview-tools/`).
