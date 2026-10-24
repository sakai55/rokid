# Shelf Sweep — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series C05 (COVER 覆盖型， fifth of the group): finding one thing on a
big shelf — you sweep the same row three times and still miss what is
right in front of you.

## Design contract

- **Not a finder, not a map: the product is a coverage map with a
  gate.** One shelf is 3 layers (上/中/下) × 3 segments (左/中/右) =
  9 cells. A cell counts as scanned only when the wearer marks it
  scanned (SCAN, a steady nod, or a tap on its own row). The FIN
  summary is gated, not decorative: with any cell still unseen, FIN
  is REFUSED and the refusal NAMES the unscanned cells （还有没扫的：
  中中、中右、下左……）. Only a fully scanned map may reach a verdict,
  and the verdict is honest about not finding: 「9 格都扫过了，没找到
  ——建议问店员或换货架」. A summary that said "done" with holes in
  it would be exactly the false reassurance this agent exists to
  prevent.
- **Browsing never scans.** Tapping a row that is not the focus only
  moves the focus there; scanning is always an explicit confirmation
  (SCAN / nod / tap on the focused row). This is deliberate: on a
  shelf, "I looked at the map" is not "I looked at that segment".
- **Repeat scans warn, never double-count.** Scanning an already
  scanned cell says so out loud （这段扫过了） and leaves the count
  untouched. A map that counted the same segment twice would be
  worse than no map: it would certify coverage that never happened.
- **Found is the wearer's own confirmation, never object
  recognition.** This platform has no object recognition, and this
  agent never pretends otherwise: it cannot see the item on the
  shelf, it can only record that you said you found it in this
  cell (FOUND). The UI footer, the README and every hint state the
  ignorance. One gesture never means two things: a steady nod scans
  the focused cell; FOUND (a tap) declares the item found — so a
  nod can never accidentally end the search.
- **Correction is cheap, destruction is two-step.** DEL on a scanned
  cell unscans it; DEL on an unseen cell explains there is nothing
  to unscan. Clearing the whole sweep is only possible from the
  summary screen, in two DEL taps, with a 6 s arm that any other
  action cancels — the same destructive-operation discipline as
  C01–C04.
- **TARGET cycles sample targets, DEMO is staged and never
  overwrites a user-edited sweep.** TARGET works only in idle and
  cycles four sample targets （某品牌酱油 → 某本书 → 折叠雨伞 →
  洗发水 → 回到酱油）; DEMO loads the currently selected target.
  DEMO walks five stages: grid loaded (0/9) → 4 cells scanned →
  summary blocked naming the 5 unseen cells → all scanned,
  not-found summary → found summary (found at 中右）. A sixth DEMO
  tap reports the demo complete. Any hand scan or FOUND ends the
  DEMO walkthrough, and DEMO refuses outright if a non-DEMO sweep
  already exists. Every step is labelled DEMO, no camera is used.
- **The map lives in session memory only — zero persistence, by
  design.** There is no storage API anywhere in the page (no wx
  storage import use, no localStorage; harness-scanned). Cells,
  scanned marks, target and found cell die when the sweep is
  cleared (two-step DEL from the summary, with a 6 s arm that any
  other action cancels), when the agent closes (onUnload wipes
  everything), and when the last cell is unscanned. Close the agent
  and the sweep is gone, which is the correct use for a shelf you
  are searching right now — the next shelf starts from a blank map.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data —
  the only timers are the 1.2 s nod lock and the 6 s two-step disarm
  window.

## Relation to the neighbours (kept distinct on purpose)

- Directional series `shelf-compare` is "look at products one by one
  and compare prices/specs" — it compares things you can already
  see. Shelf-sweep does not compare anything: it proves you looked
  everywhere for one thing you cannot find.
- C03 `proof-sweep` is the same coverage-table pattern applied to
  lines in a document, with a skip detector for reading order. A
  shelf has no reading order, so shelf-sweep has no skip detector
  and no coverage percentage as its verdict — its verdict is one
  of three: blocked (named unseen cells), found (named cell), or
  not found after a full sweep.
- C04 `pack-sweep` applies the pattern to a bag (packed/todo
  semantics, departure gate). Shelf-sweep applies it to a shelf
  (scanned/unseen semantics, finish gate) plus two things a bag
  never needs: a repeat-scan warning and a found stop.
- C01 `last-glance` archives what you SAW when leaving a room for
  later replay. Shelf-sweep never archives anything: it only
  decides whether this shelf has been fully swept right now.

## Permissions

None — `permissions` is an empty array in app.json, and the static
check asserts exactly that. Looking at a cell and confirming it is
scanned needs only head orientation (steady nod) plus taps; there
is no photo, no dictation, no position anywhere in this agent. No
`CAMERA`: nothing is photographed. No `RECORD_AUDIO`: there is
deliberately no voice input (scan confirmations are taps, row
taps and nods). No `GEOLOCATION`: a shelf needs no position, and
this agent never knows where you are — that ignorance is stated in
the UI footer, the README and every hint it gives.

## Validation

- Node harness (see `/tmp/shelf-sweep-harness.js`, not packed):
  app.json permissions exactly []; zero storage/geo/audio/camera/
  ASR APIs in the page source; no legacy Page/App/Widget; no
  utterance lang assignment; initial idle state; SCAN/FIN/FOUND/
  NEXT/PREV refusals before any grid; TARGET pool cycle in order
  with wrap, TARGET refused in sweep mode; DEMO stage 1 (9 cells,
  all unseen, row-major order); SCAN advance and focus to next
  unseen; repeat-scan warning without double count; row tap moves
  focus only, focused row scans; NEXT/PREV wrap; DEL unscan /
  DEL on unseen explains; manual scan exits DEMO, DEMO refused on
  a user-edited sweep; FIN blocked names unseen cells and never
  says done/found; SCAN in summary returns to first unseen; FOUND
  manual stop names the cell; full DEMO arc (5 stages, stage 3 →
  4 and 4 → 5 from the summary screen, sixth tap complete); DEMO
  in non-arc summary refused; summary DEL two-step clear with arm
  cancelled by other actions; nod discipline (unsteady ignored,
  steady nod scans, 1.2 s lock, non-nod documented, nod in summary
  inert); SPEAK lines (empty, focus cell, blocked summary, found
  summary, not-found summary); onUnload wipes cells, target, demo
  and found cell; bigCls thresholds.
- Preview screenshots 5, each visually verified (not just
  hash-compared): target loaded (0/9), sweeping (4 cells scanned),
  repeat-scan warning, found summary (found at 中右）, not-found
  summary (9/9 scanned, not found). Hit coordinates probed per
  state (see `shot-shelf-sweep.js`, `probe-shelf*.js` in
  `~/workspace/preview-tools/`): DEMO is the row-1 first button
  (x=88); its true y moves with the info-box height — idle
  (88,183), sweep states and blocked summary (88,175), not-found
  summary (88,163). The not-found trap is documented: (88,175)
  there hits NEXT, not DEMO, which produced one wrong found.png
  before the re-probe; every final PNG was read back by eye.
