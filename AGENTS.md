# Proof Sweep — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series C03 (COVER 覆盖型， third of the group): reading a long contract or
manual without skipping lines — where the finished page feels done, but
three lines in the middle were never actually read.

## Design contract

- **Not a checklist, not a note-taker: the product is line coverage
  with a skip detector built in.** One page is a list of lines (8 in
  the DEMO sample, up to 12 from a real photo read). A line counts as
  read only when the wearer marks it read (READ, a steady nod, or a
  tap on its own row). Tapping a row AHEAD of the focus is the jump:
  every unread line between the focus and the tapped row is marked
  MISSED on the spot, and the status names them at that moment. A
  missed line is never silently forgiven: it stays ⚠漏读 until the
  wearer goes back and reads it, exactly like a flagged item in
  room-sweep. Moving BACK to an earlier line is re-reading, never a
  skip — no state changes.
- **The summary is gated, not decorative.** FIN with any unread
  line is REFUSED, and the refusal NAMES the unread lines by number
  （还差 3 行没读：第 5、7、8 行）. Only when every line is decided
  (read or missed) does FIN open a summary, and the summary then
  says one of two honest things: all lines read （本页全部读完，
  覆盖率 100%) or missed lines listed with the page coverage
  percentage — never all-read with a missed line hiding in the list.
  Summary READ returns to reading focused on the first missed line,
  so fixing has somewhere to go.
- **Multi-page documents accumulate, honestly.** PAGE archives the
  current page's read/total into running totals and starts the next
  page empty (a fresh LOAD or DEMO, never a copy). The count line
  always shows both the page percentage and the cumulative
  percentage across archived pages plus the current one. There is no
  backward page: pages only move forward, and restarting the
  document is the two-step DEL from the summary.
- **The page text comes from the official photo path, and it is
  gated three times.** LOAD takes a default photo
  (`ImageCapture.takePhoto({mode:'default'})`, wx camera-context
  fallback like the siblings); the Blob becomes a data: URL via
  `FileReader` and goes to the host `LanguageModel` as an `image_url`
  part of ONE user message (system prompt via `initialPrompts` only,
  `availability()` first, session `destroy()`ed after — dossier
  §2.9). The reply format is strict (`L1: ...` one per line, with a
  `NONE` form); the parser accepts the L-format or a tight plain-line
  salvage and rejects anything under 3 lines — an unclear reply is a
  failed read, never a guess. There is no OCR on this platform and
  none is claimed. Every read failure lands on a usable path: the
  page stays empty, the reason is stated, and DEMO is offered. The
  photos live in memory only and are never persisted.
- **"Read to here" is the wearer's own stepping, never eye
  tracking.** This platform has no eye tracking, and this agent never
  pretends otherwise: "read to line N" means the wearer pressed
  READ, nodded, or tapped that row. The UI footer, the README and
  every hint state the ignorance. A line the model misread can be
  corrected by re-reading it (the line text is what the model
  returned; the wearer judges it against the paper).
- **The page lives in session memory only — zero persistence, by
  design.** There is no storage API anywhere in the page (no wx
  storage import use, no localStorage; harness-scanned). Lines,
  missed marks and page totals die when the document is cleared
  (two-step DEL from the summary, with a 6 s arm that any other
  action cancels), when the agent closes (onUnload wipes lines and
  totals), and when PAGE archives a page (the archive totals are
  also session-only). Close the agent and the proof is gone, which
  is the correct use for a document you were reading.
- **DEMO is staged and never overwrites real decisions.** DEMO
  refuses outright if any line carries a REAL (LLM) decision.
  Otherwise it walks four stages: 3 lines read → jump simulated
  (lines 4–6 missed) → summary with missed lines (5/8, 63%) →
  missed lines fixed → summary all-read (8/8, 100%). Every step is
  labelled DEMO, no camera is used. Note the DEMO stage machine:
  stage 3 → 4 runs FROM the summary screen (fix the missed lines
  there), so the summary guard exempts exactly that transition;
  every other DEMO tap in summary is refused, and a fifth DEMO tap
  reports the demo complete.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data —
  the only timers are the 1.2 s nod lock and the 6 s two-step disarm
  window.

## Relation to the neighbours (kept distinct on purpose)

- C01 `last-glance` is the leave-the-room archive: photograph six
  heading zones, replay their descriptions later. It archives what
  you SAW when leaving; it never tracks reading progress.
- C02 `room-sweep` is the same coverage-table pattern applied to
  safety items in a room: pass/flag semantics on physical checks.
  Proof-sweep applies the pattern to TEXT: read/missed semantics on
  document lines, with a skip detector and a coverage percentage.
- Directional-series `board-capture` photographs board writing into
  notes; `word-look` looks up unfamiliar words. Neither tracks
  whether you read every line, neither names skipped lines, neither
  reports coverage. Proof-sweep does only that.

## Permissions

`CAMERA` only — default photos of the page being read (every Blob
lives in memory only and is discarded after its read attempt). No
`RECORD_AUDIO`: there is deliberately no dictation anywhere in this
agent (read/skip/fix are taps, row taps and nods). No `GEOLOCATION`:
a document needs no position, and this agent never knows where you
are — that ignorance is stated in the UI footer, the README and
every hint it gives.

## Validation

- Node harness (see `/tmp/proof-sweep-harness.js`, not packed):
  app.json permissions exactly [CAMERA]; zero storage/geo/audio/ASR
  APIs in the page source; no legacy Page/App/Widget; no utterance
  lang assignment; default photo mode asserted; LLM path shape
  (availability + initialPrompts + image_url part + session
  destroy); parser battery (L-format, plain-line salvage, single
  prose rejected, under-3-lines rejected, empty rejected, 12-line
  cap, empty L-lines dropped); initial empty state; READ advance
  and focus to next todo; NEXT/PREV wrap; row-tap jump marks skipped
  lines missed and names them; row tap back changes nothing; tap on
  the focused missed line fixes it; FIN refusal names unread lines;
  full arc jump → summary missed (63%) → fix → summary all-read;
  DEL resets a line; summary DEL two-step clear with arm cancelled
  by other actions; DEMO arc (4 stages, refusal on real lines,
  stage 3 → 4 from the summary screen, fifth tap complete);
  PAGE archive + cumulative coverage (8+3)/(8+8) = 69%; nod
  discipline (unsteady ignored, steady nod reads, 1.2 s lock,
  non-nod documented, nod in summary inert); camera + LLM happy
  path (default mode, bytes on CAP line, tracks stopped, session
  destroyed, image_url prompt part); every LLM failure variant
  (empty, NONE, too few lines, no LM) keeps the page empty with the
  reason stated; wx fallback photo (read n/a, lines empty);
  no-camera path (FAIL on CAP line, lines empty); SPEAK lines
  (empty, focus line, summary); onUnload wipes lines and totals.
- Preview screenshots 5, each visually verified (not just
  hash-compared): empty (no page loaded), DEMO reading (3 lines
  read), DEMO missed (jump simulated, lines 4–6 missed), summary
  missed (5/8, 63%), summary all-read (8/8, 100%). Hit coordinates
  probed per state (see `shot-proof.js`, `probe-proof.js`,
  `probe-proof-s3.js`): the DEMO button is the row-3 middle button,
  but its true y moves with the info-box height — empty state
  (240,215), read states (240,205), summary states (240,218). The
  first shot run proved the lesson again: a single coordinate
  (240,215) landed on a list row after stage 1 (EVT "row tap
  without index"), producing three byte-identical PNGs; only the
  per-state probe fixed it. Every final PNG was read back by eye.
