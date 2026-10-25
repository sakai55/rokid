# Elder Ear — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series SO03 (SOCIAL 社交型， third of the group, series #38): chatting
with an elder whose repeated reminders (medicine, door lock, calling
the children) slip your mind the moment the chat ends. This agent
takes the remembering off your hands: it listens through the chat,
files only reminder/request sentences into a list, and reads the
list back aloud after the chat for you to confirm item by item.

## Design contract

- **The gate is keywords, never understanding.** Every ASR
  segment goes through one keyword table （吃药/门锁/电话/记得/
  别忘/明天/打电话/锁门） in table order: the earliest table
  keyword in the sentence files it, never all of them. A
  sentence with no keyword is counted in the heard total and
  immediately discarded — no full transcript is ever kept.
  A sentence with a keyword is not necessarily a real
  reminder: the list is candidates, and the UI and README say
  exactly that.
- **Listening never speaks.** A hit is a banner only. Speech
  happens only after you press DONE: replay reads the first
  item aloud, each CONF confirms the focused item and reads
  the next unconfirmed one, and the last CONF announces
  「叮嘱都确认了」 once. Speaking mid-chat would interrupt
  the very conversation the agent is supposed to stay out of.
- **No speaker identification.** The list does not attribute
  sentences to speakers: there is no voiceprint, and the
  keyword gate runs on transcript text alone. A sentence is
  filed because it contains a keyword, not because of who
  said it.
- **A nod never invents a sentence.** A steady nod in idle
  starts listening, in replay confirms the focused item, in
  summary confirms and clears. While listening a nod (and
  Enter) is ignored and noted: captions can only arrive from
  the talk itself, never from a gesture or a key. An unsteady
  nod never arms the 1.2 s lock (the fleet fix, kept). A nod
  never changes focus: that is a selection, and a nod must
  not silently pick an item. ArrowUp/Down walk items;
  Backspace goes back.
- **Correction is cheap, destruction is confirmed.** BACK from
  replay returns to listening with items and confirmations
  kept, and DONE replays from item 1. BACK from listening
  returns to idle with the list kept, and START resumes the
  same list. BACK from the summary returns to replay without
  deleting anything, and the summary is rebuilt on END.
  Confirming the summary (END while a summary is open, or a
  steady nod) is the only wipe. There is no DEL key: there
  is nothing to clear that would not also lie about what was
  saved.
- **The round lives in session memory only — zero persistence,
  by design.** Items, heard counts, confirmations and the
  summary die when the summary is confirmed and when the
  agent closes (onUnload wipes everything). Close the agent
  and the chat round is gone.
- **Mic mode is a stream setting, not an ASR setting.** MODE
  cycles wearer/far-field before listening only; it governs
  the getUserMedia stream's pickup and never the host ASR's
  pickup, and the UI and README say so (the fleet audit
  conclusion, kept). MODE is refused mid-chat.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK names
  counts, or reads the focused replay item, and never reads a
  whole list aloud. There is no ticker: every transition is a
  tap, a nod or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `lecture-filter` (FI05) is the classroom
  signal-sentence catcher: preset signal words become notes
  during a lesson. Elder-ear borrows the gate shape but is not
  a lesson tool: its keywords are reminders and requests in a
  chat with an elder, and its close is a spoken replay for
  confirmation, not a note list.
- Attention-series `talk-replay` (RE02) is the post-talk
  caption replay: subtitles tagged by speaker side, replayed
  as promise/number/deadline sentences. Elder-ear does not
  tag speakers and does not classify: it files keyword hits
  during the chat and reads them back aloud the moment the
  chat ends.
- Attention-series `chat-catchup` (SO01) is the mid-conversation
  silent catch-up: a rolling caption buffer served on HELP.
  Elder-ear keeps no rolling buffer and serves nothing
  mid-chat: it saves only hits, stays silent while listening,
  and speaks only in replay.

## Permissions

RECORD_AUDIO only (app.json `permissions` is exactly
`["RECORD_AUDIO"]`, and the static check asserts exactly
that): listening to a chat plus host ASR needs the
microphone. No `CAMERA`: nothing is photographed. No
`GEOLOCATION`: this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/elder-ear-harness.js`, not packed):
  app.json pages and permissions exactly `["RECORD_AUDIO"]`;
  zero storage/location/camera/recorder APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted (keyword match not semantic understanding, no
  speaker identification, replay only after DONE, single
  session, cleared on close, mic mode does not change host
  ASR, no indoor positioning, zero persistence); initial idle
  state (bigText 还没守听， placeholder row, countLine);
  bigCls thresholds; MODE cycles wearer/far-field and wraps,
  refused mid-chat; refusals in idle (DONE/CONF/END naming
  START, NEXT/PREV/BACK ignored); DONE refused with zero
  saved; gate (non-hit counted and discarded with zero TTS,
  empty and no-text ASR ignored, hit saved verbatim with
  HH:MM time and table-order keyword — 记得吃药 files under
  吃药， 出门记得锁门 files under 门锁， 明天记得给我打电话
  files under 电话 — hit banner only, zero TTS while
  listening); focus walks items (NEXT/PREV wrap, rowTap focus
  with out-of-range and missing-dataset guards); BACK keeps
  items and START resumes; replay flow (DONE reads item 1
  aloud exactly once, CONF advances and reads the next item,
  last CONF announces all confirmed once, re-CONF refused,
  BACK keeps confirmations, DONE replays from item 1);
  summary flow (saved/confirmed/heard recorded, BACK rebuilds
  replay, END confirms and clears; summary from listening
  records unconfirmed items); SPEAK lines per mode; nod
  discipline (unsteady ignored without arming, steady nod in
  idle starts listening, lock blocks a second nod, lock expiry
  works, nod in listening ignored, non-nod gestures noted);
  key discipline (Enter starts listening, Enter in listening
  ignored, Backspace returns); DEMO eight-stage arc (start,
  non-hit, hit 吃药， hit 门锁， replay, conf1, conf2 all
  confirmed, summary saved 2 confirmed 2 heard 3) and refusal
  on user sessions; onUnload wipes everything.
  Result: **95/95** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not listening), listening (DEMO stage
  2, heard 1 saved 0), hit (DEMO stage 4, saved 2, banner, no
  TTS), replay (DEMO stage 5, item 1 read aloud), summary
  (DEMO stage 8, saved 2 confirmed 2 heard 3). Button
  coordinates were probed per state and every PNG re-verified
  by eye (see `shot-elder-ear.js` in
  `~/workspace/preview-tools/`).
