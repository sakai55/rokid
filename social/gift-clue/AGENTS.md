# Gift Clue — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series SO05 (SOCIAL 社交型， last of the group, series #40): a friend
mentions something they like or want in passing, you do not think much of
it at the time, and by their birthday you cannot remember any of it.
This agent takes the remembering off your hands: it listens to everyday
chats, silently files sentences matching want/like/need keywords into
clue cards, lets you assign each card to a person by hand, and replays
that person's cards when gift-giving time comes — inside this same
opening, never as a cross-day memory.

## Design contract

- **The gate is keywords, never preference understanding.** Every
  ASR segment goes through one keyword table （想要/喜欢/缺一个/
  想要一个/好想要/一直想要） in table order: the earliest table
  keyword in the sentence files the card, never all of them. Note
  想要 is a substring of 想要一个 and 一直想要， so table order
  files those under 想要. A sentence with a keyword is not
  necessarily a real want: the cards are candidates, and the UI
  and README say exactly that. ASR mishearing can also drop or
  misfile a sentence.
- **A hit is a silent card, never a banner or a voice.** Nothing
  lights up and nothing speaks while listening: noticing a clue
  must not interrupt the chat it came from. Non-hit sentences
  are counted and dropped on the spot — gift-clue keeps cards
  only, never a transcript.
- **The owner is assigned by hand, never recognised.** A card
  starts unassigned; PERSON cycles its owner （待归档 → 阿明 →
  小林 → 老陈 → 待归档） in listening, and PERSON cycles the
  replay filter in gift view. There is no speaker
  identification on this device, and the UI and README say
  the owner is hand-assigned. A card never auto-attributes
  itself to whoever was speaking.
- **Gift replay is same-opening replay, never cross-day memory.**
  GIFT replays one person's cards from this session's cards
  only. The agent stores nothing persistent, so "when
  gift-giving time comes" means "when you open GIFT in this
  same opening" — the README and the gift-view copy say so
  in plain words and never imply the cards survive the day.
- **A nod never invents a sentence.** A steady nod in idle
  starts listening, in gift moves focus to the next card, in
  summary confirms and clears. While listening a nod (and
  Enter) is ignored and noted: captions can only arrive from
  the chat itself, never from a gesture or a key. An unsteady
  nod never arms the 1.2 s lock (the fleet fix, kept). A nod
  never changes a card's owner: that is an assignment, and a
  nod must not silently reassign a card — only PERSON does.
- **Correction is cheap, destruction is confirmed.** BACK from
  gift returns to listening with cards kept, and GIFT reopens
  from the focused card's owner. BACK from listening returns
  to idle with the round kept, and START resumes the same
  round. BACK from the summary returns to gift without
  deleting anything, and the summary is rebuilt on END.
  Confirming the summary (END while a summary is open, or a
  steady nod) is the only wipe. There is no DEL key: there
  is nothing to clear that would not also lie about what
  was heard.
- **The round lives in session memory only — zero persistence,
  by design.** Clue cards, heard counts and the summary die
  when the summary is confirmed and when the agent closes
  (onUnload wipes everything). Close the agent and the
  gift-clue round is gone.
- **Mic mode is a stream setting, not an ASR setting.** MODE
  cycles wearer/far-field before listening only; it governs
  the getUserMedia stream's pickup and never the host ASR's
  pickup, and the UI and README say so (the fleet audit
  conclusion, kept). MODE is refused mid-chat.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK names
  counts in listening, reads the focused gift card in gift
  view, and reads the summary — and never reads a whole card
  list aloud. There is no ticker: every transition is a tap,
  a nod or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `elder-ear` (SO03) is the elder-chat
  reminder catcher: keyword hits become a list that is read
  aloud after the chat for confirmation. Gift-clue borrows
  the gate shape but is not a confirmation tool: its hits
  are clue cards assigned to people by hand, its close is a
  per-person visual replay, not a spoken confirmation.
- Attention-series `standup-echo` (SO04) is the standup
  module-keyword gate: hits become related notes, non-hits
  become one-line digest rows for post-meeting review.
  Gift-clue keeps no digest rows: its non-hits are counted
  and dropped, its hits are cards with a hand-assigned
  owner, and its close is a per-person gift replay.
- Attention-series `chat-catchup` (SO01) is the mid-conversation
  silent catch-up: a rolling caption buffer served on HELP.
  Gift-clue keeps no rolling buffer and serves nothing
  mid-chat: it files silent cards, stays silent while
  listening, and serves the replay only on GIFT.

## Permissions

RECORD_AUDIO only (app.json `permissions` is exactly
`["RECORD_AUDIO"]`, and the static check asserts exactly
that): listening to everyday chats plus host ASR needs the
microphone. No `CAMERA`: nothing is photographed. No
`GEOLOCATION`: this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/gift-clue-harness.js`, not packed):
  app.json pages and permissions exactly `["RECORD_AUDIO"]`;
  zero storage/location/camera/recorder APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted (keyword match not preference understanding,
  owner hand-assigned not recognised, same-opening replay not
  cross-day memory, single session, cleared on close, mic mode
  does not change host ASR, no indoor positioning, zero
  persistence); initial idle state (bigText 还没守听，
  placeholder row, countLine); bigCls thresholds; MODE cycles
  wearer/far-field and wraps, refused mid-chat; refusals in
  idle (GIFT/END naming START, NEXT/PREV/BACK ignored, PERSON
  refused); start refusals; GIFT refused with zero cards;
  PERSON ignored with zero cards; gate (non-hit counted and
  dropped with zero TTS, empty and no-text ASR ignored, hit
  saved verbatim with HH:MM time and table-order keyword —
  一直想要… files under 想要， 喜欢…缺一个… files under 喜欢 —
  hit silent, zero TTS while listening); focus walks cards in
  listening (NEXT/PREV wrap, rowTap focus with out-of-range
  and missing-dataset guards); PERSON owner cycle （待归档 →
  阿明 → 小林 → 老陈 → 待归档） and archived-person count;
  gift flow (opens filtered to focused card's owner, SPEAK
  reads focused card, PERSON cycles filter with empty-person
  placeholder, NEXT ignored on empty filter, BACK keeps
  cards, GIFT reopens); summary flow (END out, BACK rebuilds
  gift, END confirms and clears; summary from listening;
  BACK listening->idle keeps round, START resumes); nod
  discipline (unsteady ignored without arming, steady nod in
  idle starts listening, lock blocks a second nod, lock expiry
  works, nod in listening ignored with the chat note, non-nod
  gestures noted); key discipline (Enter starts listening,
  Enter in listening ignored, Backspace returns); DEMO
  seven-stage arc (start, non-hit dropped, card 1 想要，
  card 2 喜欢， card 2 assigned to 阿明 by hand, gift replay
  for 阿明 1 card, summary cards 2 persons 1 heard 3) and
  refusal on user sessions; onUnload wipes everything;
  SPEAK lines per mode (idle line, listening counts only
  and never card text, gift reads focused card, summary
  line).
  Result: **111/111** (first run, no harness fixes needed).
- Preview screenshots 6, each visually verified (not just
  hash-compared): idle (not listening), listening (DEMO stage
  3, 1 card), hit (DEMO stage 4, 2 cards unassigned),
  archived (DEMO stage 5, card 2 assigned to 阿明）,
  gift (DEMO stage 6, replay for 阿明 1 card), summary
  (DEMO stage 7, cards 2 persons 1 heard 3). Button
  coordinates were probed per state and every PNG re-verified
  by eye (see `shot-gift-clue.js` in
  `~/workspace/preview-tools/`).
