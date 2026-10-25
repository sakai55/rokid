# Shop Replay — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series RE03 (REVIEW 回顾型， third of the group): after a shopping round,
replay the candidates you hesitated over — each with the product you
picked, the price you wrote down, the shop direction you marked and
the photo taken on the spot — so "which shop was that one in, and how
much was it" stops being a matter of trying to remember.

## Design contract

- **The replay is a register, never a recognition result.**
  MARK registers one candidate: the current NAME selection, the
  current PRICE selection, the current DIR selection, the clock
  time, and the pending photo state (shot / none). SNAP takes a
  wide photo into the pending slot (ImageCapture.takePhoto,
  `wide` mode, wx camera context as fallback); the shot is
  converted to a data URL and kept in session memory on the
  candidate it gets MARKed onto. It is never written to
  storage, and it dies with the page (onUnload / summary
  confirm). The fleet UI is text only, so the replay shows a
  shot as "已拍（会话内）" plus its byte size rather than
  rendering a gallery; the data itself is retained in-session,
  not just a flag. A DEMO candidate carries no real photo: its
  label says DEMO 示例占位, never a fake shot. A candidate
  registered without a photo says 未拍 and still replays.
- **The cheapest item is arithmetic over your own numbers,
  not a recommendation.** CHEAP jumps focus to the minimum
  price among registered candidates; ties go to the first
  registered. The summary names the cheapest item and its shop
  direction. Nothing here reads a price tag, compares shops or
  recommends a purchase — the minimum of numbers you wrote
  down is all it is, and the UI says so.
- **No OCR, no product recognition.** The price is a number
  you wrote down (PRICE cycles sample values; the cycle is the
  input method, not a reading). The photo is the original shot,
  not a recognition result. A price the user mis-remembered
  stays mis-remembered — the agent cannot check it against
  the shelf, and the README says so.
- **Direction is a memory cue, not navigation.** DIR marks
  the head direction you were facing when you registered the
  candidate. Replay shows it so you remember "that shop was
  off to the left-front" — it is not a position and not a
  route. There is no positioning in this agent.
- **A nod confirms a selection, never picks one.** A steady
  nod in register MARKS the current NAME/PRICE/DIR selection
  (gaze confirm of an explicit selection, the day-lookback
  precedent); in replay it advances by one; in summary it
  confirms and clears. An unsteady nod never arms the 1.2 s
  lock (the fleet fix, kept). A nod never changes NAME,
  PRICE or DIR: those are selections, and a nod must not
  silently pick one.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to replay without deleting anything; the
  summary is rebuilt on END. BACK from replay returns to
  registering with candidates kept. Confirming the summary
  (END while a summary is open, or a steady nod) is the only
  wipe. There is no DEL key: there is nothing to clear that
  would not also lie about the shopping round.
- **The round lives in session memory only — zero persistence,
  by design.** Candidates, photos, focus and counts die when
  the summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the shopping round is
  gone.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in
  replay reads the focused candidate's short line; it never
  reads a whole list aloud. There is no ticker: every
  transition is a tap, a nod or a key — a replay is
  event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `last-glance` (CO01) is the leaving archive:
  one photo per zone with an LLM one-line description, 6/6
  required to leave. Shop-replay has no LLM description and no
  leaving gate: its photos are per-candidate shots, and its
  close is a price comparison, not a completeness check.
- Attention-series `day-lookback` (RE01) is the day timeline:
  gazes you marked, typed 画面 / 数字 / 承诺, pictures as text
  descriptions. Shop-replay is not a day: its units are
  shopping candidates with prices and on-the-spot photos, and
  its replay ends in a cheapest comparison.
- Attention-series `talk-replay` (RE02) is the talk replay:
  subtitles filtered to promises / numbers / deadlines.
  Shop-replay has no subtitles and no keyword filter: its
  replay is registration order plus a cheapest jump.

## Permissions

Exactly one permission (`CAMERA` in app.json, and the
static check asserts exactly that): taking the on-the-spot
photo. No `RECORD_AUDIO`: nothing is listened to, there is
no ASR path at all (no onASRResult handler). No
`GEOLOCATION`: a direction you marked is not a position,
and this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/shop-replay-harness.js`, not packed):
  app.json pages and permissions exactly `["CAMERA"]`;
  zero storage/location APIs, no ASR/recorder path, no
  utterance language assignment, no legacy Page/App/Widget;
  foot2 honesty lines asserted (no OCR, price is your number,
  direction is not navigation, no indoor positioning, single
  session, zero persistence); camera path asserted
  (ImageCapture.takePhoto wide mode, FileReader data-URL
  conversion, DEMO photo labelled placeholder); initial
  register-empty state (bigText 还没登记， placeholder row);
  bigCls thresholds; refusals in register-empty (REPLAY/
  CHEAP/END naming the missing MARK, NEXT/PREV/BACK ignored,
  confirm refused); NAME/PRICE/DIR cycles and wraps; SNAP
  failing honestly with no camera host and no pending photo;
  MARK flow (selections, photo none, counts); cheapest
  arithmetic (min price, tie keeps first); replay flow
  (NEXT/PREV wrap, rowTap focus with out-of-range and
  missing-dataset guards, CHEAP jump, refusals in replay);
  summary flow (END from replay, cheapest name/price/dir,
  BACK rebuilds, END in summary confirms and clears);
  nod discipline (unsteady ignored without arming, steady
  nod in register MARKS, lock blocks a second nod, lock
  expiry works, steady nod in replay advances, in summary
  confirms, non-nod gestures noted); key discipline (Enter
  MARKS in register / advances in replay / confirms in
  summary, ArrowUp/Down wrap, Backspace returns, ignored in
  register); SPEAK lines per mode; DEMO six-stage arc and
  refusal on user candidates; onUnload wipes everything.
  Result: **99/99** (first run 96/99: three failures were
  harness-side — a nod asserted inside the 1.2 s lock window
  and two focus expectations that forgot MARK leaves focus on
  the last item; the page code was not changed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (nothing registered), marked (DEMO
  stage 3, 3 candidates), replay (focus item 1, coat 899元),
  cheap (cheapest jump to item 3, bag 459元）, summary (3
  candidates, cheapest bag 459元）. Button coordinates were
  probed per state and every PNG re-verified by eye (see
  `shot-shop-replay.js` in `~/workspace/preview-tools/`):
  idle DEMO y=170, stage-1/2 DEMO y=180, replay-state REPLAY
  y=190 / CHEAP y=190, summary-trigger END (row3 col4) y=210.
  The probe sequence worked first try with no fake frames.
