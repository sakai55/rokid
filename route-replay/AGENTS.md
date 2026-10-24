# Route Replay — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series R04 (REVIEW 回顾型， fourth of the group): on the commute you
notice roadwork and hazard spots and forget them by the next morning —
this agent takes the route replay off your hands. Look at a spot, mark
its direction, snap a photo of it, register it; before the next outing,
preview the spots in registration order, confirming each one as known,
and close with a summary of how many were registered and confirmed.

## Design contract

- **The preview is a register, never a detection result.**
  MARK registers one spot: the current DESC selection, the current
  DIR selection, the clock time, and the pending photo state (shot /
  none). SNAP takes a wide photo into the pending slot
  (ImageCapture.takePhoto, `wide` mode, wx camera context as
  fallback); the shot is converted to a data URL and kept in session
  memory on the spot it gets MARKed onto. It is never written to
  storage, and it dies with the page (onUnload / summary confirm).
  The fleet UI is text only, so the preview shows a shot as
  "已拍（会话内）" plus its byte size rather than rendering a
  gallery; the data itself is retained in-session, not just a flag.
  A DEMO spot carries no real photo: its label says DEMO 示例占位,
  never a fake shot. A spot registered without a photo says 未拍
  and still previews.
- **No hazard detection, no positioning.** A spot exists because
  you looked at it and registered it — the agent never detects
  roadwork, never knows where you are, and never verifies that the
  spot is still there the next day. DIR marks the head direction
  you were facing when you registered the spot. Preview shows it
  so you remember "that pothole was off to the left-front" — it is
  not a position and not a route.
- **The preview is a confirmation walk, not a checklist gate.**
  PREVIEW opens the spots in registration order; GOT confirms the
  focused spot as known and advances to the next still-unknown
  spot (wrapping); confirming a spot you already know is refused;
  when every spot is known the status says so. END from preview
  still produces a summary even if some spots are unconfirmed —
  the summary reports the confirmed count honestly (e.g. 1/3)
  instead of pretending the route is fully previewed. Nothing
  here blocks you from leaving: this is a reminder, not a gate.
- **The "next day" preview is single-session, by discipline.**
  Registering and previewing happen in the same open session;
  the DEMO arc shows the preview format with seeded spots. The
  fleet zero-persistence rule forbids storage APIs, so a spot
  registered today cannot survive the agent closing and reappear
  tomorrow — the UI and README say exactly that, and cross-day
  keeping is left as a decision for GO, not smuggled in through
  storage. Claiming otherwise would be a lie about the fleet's
  core discipline.
- **A nod confirms a selection, never picks one.** A steady
  nod in register MARKS the current DESC/DIR selection (gaze
  confirm of an explicit selection, the day-lookback precedent);
  in preview it confirms the focused spot as known; in summary
  it confirms and clears. An unsteady nod never arms the 1.2 s
  lock (the fleet fix, kept). A nod never changes DESC or DIR:
  those are selections, and a nod must not silently pick one.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to preview without deleting anything; the
  summary is rebuilt on END. BACK from preview returns to
  registering with spots kept. Confirming the summary (END while
  a summary is open, or a steady nod) is the only wipe. There
  is no DEL key: there is nothing to clear that would not also
  lie about the route round.
- **The round lives in session memory only — zero persistence,
  by design.** Spots, photos, focus and counts die when the
  summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the route round is
  gone.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in
  preview reads the focused spot's short line; it never reads a
  whole list aloud. There is no ticker: every transition is a
  tap, a nod or a key — a preview is event-driven, not
  time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `shop-replay` (R03) is the shopping replay:
  candidates with prices and on-the-spot photos, ending in a
  cheapest comparison. Route-replay has no prices and no
  cheapest jump: its units are hazard spots, and its close is a
  confirmed-count summary.
- Attention-series `day-lookback` (R01) is the day timeline:
  gazes you marked, typed 画面 / 数字 / 承诺, pictures as text
  descriptions. Route-replay is not a day: its units are route
  spots with directions and on-the-spot photos, and its replay
  is a confirmation walk, not a timeline.
- Attention-series `last-glance` (C01) is the leaving archive:
  one photo per zone with an LLM one-line description, 6/6
  required to leave. Route-replay has no LLM description and no
  leaving gate: its photos are per-spot shots, and its close is
  a preview confirmation, not a completeness check.

## Permissions

Exactly one permission (`CAMERA` in app.json, and the
static check asserts exactly that): taking the on-the-spot
photo. No `RECORD_AUDIO`: nothing is listened to, there is
no ASR path at all (no onASRResult handler). No
`GEOLOCATION`: a direction you marked is not a position,
and this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/route-replay-harness.js`, not packed):
  app.json pages and permissions exactly `["CAMERA"]`;
  zero storage/location APIs, no ASR/recorder path, no
  utterance language assignment, no legacy Page/App/Widget;
  foot2 honesty lines asserted (no hazard detection, no
  positioning, direction is not navigation, single session,
  cross-day keeping named as GO's decision, no indoor
  positioning, zero persistence); camera path asserted
  (ImageCapture.takePhoto wide mode, FileReader data-URL
  conversion, DEMO photo labelled placeholder); initial
  register-empty state (bigText 还没登记， placeholder row);
  bigCls thresholds; refusals in register-empty (PREVIEW/
  GOT/END naming the missing MARK, NEXT/PREV/BACK ignored);
  DESC/DIR cycles and wraps; SNAP failing honestly with no
  camera host and no pending photo; MARK flow (selections,
  photo none, HH:MM time, counts); preview + GOT flow
  (open at focus 0, confirm advances to next unknown,
  all-known status, re-confirm refused); preview flow
  (NEXT/PREV wrap, rowTap focus with out-of-range and
  missing-dataset guards); summary flow (END from preview,
  known/total, BACK rebuilds, END in summary confirms and
  clears); nod discipline (unsteady ignored without arming,
  steady nod in register MARKs, lock blocks a second nod,
  lock expiry works, steady nod in preview GOTs, in summary
  confirms, non-nod gestures noted); key discipline (Enter
  MARKs in register / GOTs in preview / confirms in
  summary, ArrowUp/Down wrap, Backspace returns, ignored in
  register); SPEAK lines per mode; DEMO six-stage arc and
  refusal on user spots; onUnload wipes everything.
  Result: **76/76** (first run 75/76: one failure was
  harness-side — a nod asserted inside the fresh 1.2 s lock
  armed by the previous MARK nod; the page code was not
  changed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (nothing registered), marked (DEMO
  stage 3, 3 spots), preview (focus spot 1, roadworks front),
  confirmed (spot 1 confirmed, focus spot 2, pothole
  left-front), summary (3 spots, 1 confirmed). Button
  coordinates were probed per state and every PNG re-verified
  by eye (see `shot-route-replay.js` in
  `~/workspace/preview-tools/`).
