# Pack Sweep — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series CO04 (COVER 覆盖型， fourth of the group): packing a bag by feel —
you only discover the missing ID, charger or medicine at the destination.

## Design contract

- **Not a packing list app, not a reminder: the product is a
  departure gate.** One list is a set of items (8 in the DEMO sample,
  plus up to 5 spares via ADD). An item counts as packed only when
  the wearer marks it packed (PACK, a steady nod, or a tap on its own
  row). The FIN summary is gated, not decorative: with any item
  still todo, FIN is REFUSED and the refusal NAMES the unpacked
  items （还有没装的：药、钥匙、水杯……）. Only when every item is
  packed does FIN open the "行李齐了" summary. A summary with a hole
  in it would be exactly the false reassurance this agent exists to
  prevent.
- **Browsing never packs.** Tapping a row that is not the focus only
  moves the focus there; packing is always an explicit confirmation
  (PACK / nod / tap on the focused row). This is deliberate: in a
  bag, "I looked at the list" is not "I put it in".
- **Correction is cheap, destruction is two-step.** DEL on a packed
  item unchecks it; DEL on a todo item deletes it from this packing
  session. Clearing the whole list is only possible from the summary
  screen, in two DEL taps, with a 6 s arm that any other action
  cancels — the same destructive-operation discipline as CO01–CO03.
- **ADD grows the list, and exits DEMO.** ADD appends the next item
  from a fixed spare pool （耳机、充电宝、纸巾、笔记本、墨镜）; when
  the pool is exhausted it says so and adds nothing. Adding your own
  item means the list is no longer the sample, so staged DEMO steps
  stop applying until the list is cleared from the summary screen.
- **DEMO is staged and never overwrites a user-edited list.** DEMO
  refuses outright if a non-DEMO list already exists. Otherwise it
  walks four stages: list loaded (0/8) → 3 items packed → summary
  blocked naming the 5 missing items → all packed, summary
  complete. Stage 3 → 4 runs FROM the summary screen (pack the rest
  there), so the summary guard exempts exactly that transition; a
  fifth DEMO tap reports the demo complete. Every step is labelled
  DEMO, no camera is used.
- **"Packed" is the wearer's own confirmation, never object
  recognition.** This platform has no object recognition, and this
  agent never pretends otherwise: it cannot see what is in the bag,
  it can only record that you said you packed it. The UI footer,
  the README and every hint state the ignorance.
- **The list lives in session memory only — zero persistence, by
  design.** There is no storage API anywhere in the page (no wx
  storage import use, no localStorage; harness-scanned). Items,
  packed marks and the spare counter die when the list is cleared
  (two-step DEL from the summary, with a 6 s arm that any other
  action cancels), when the agent closes (onUnload wipes everything),
  and when the last item is deleted. Close the agent and the packing
  proof is gone, which is the correct use for a bag you are packing
  right now — next trip you pack again from scratch.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data —
  the only timers are the 1.2 s nod lock and the 6 s two-step disarm
  window.

## Relation to the neighbours (kept distinct on purpose)

- CO02 `room-sweep` is the same coverage-table pattern applied to
  safety items in a room: pass/flag semantics on physical checks
  before sleep. Pack-sweep applies the pattern to a bag: packed/todo
  semantics on luggage items, with a departure gate.
- HO03 `voice-list` is a spoken shopping/errand list ticked off at
  the shop shelf. Pack-sweep is not spoken and not about shopping:
  it is the pre-departure bag check, and its gate (FIN refuses with
  names) is about leaving, not buying.
- CO01 `last-glance` archives what you SAW when leaving a room for
  later replay. Pack-sweep never archives anything: it only decides
  whether the bag is complete right now.
- CO03 `proof-sweep` tracks line coverage in a document with a skip
  detector. Pack-sweep has no skip detector (there is no order to
  skip in a bag) and no coverage percentage as its verdict — its
  verdict is binary: 行李齐了, or the named missing items.

## Permissions

None — `permissions` is an empty array in app.json, and the static
check asserts exactly that. Looking at an item and confirming it is
packed needs only head orientation (steady nod) plus taps; there is
no photo, no dictation, no position anywhere in this agent. No
`CAMERA`: nothing is photographed. No `RECORD_AUDIO`: there is
deliberately no voice input (packing confirmations are taps, row
taps and nods). No `GEOLOCATION`: a bag needs no position, and this
agent never knows where you are — that ignorance is stated in the UI
footer, the README and every hint it gives.

## Validation

- Node harness (see `/tmp/pack-sweep-harness.js`, not packed):
  app.json permissions exactly []; zero storage/geo/audio/camera/
  ASR APIs in the page source; no legacy Page/App/Widget; no
  utterance lang assignment; initial idle state; PACK/FIN/NEXT/
  PREV/ADD/DEL/SPEAK/row-tap refusals before any list; DEMO stage
  1 (8 items, all todo); PACK advance and focus to next todo;
  NEXT/PREV wrap; row tap moves focus only, focused row packs;
  DEL unchecks packed / deletes todo / deleting all returns to
  idle; ADD spare pool in order, pool exhausted, ADD exits demo,
  DEMO refused on a user-edited list; FIN blocked names missing
  items and never says ready; PACK in summary returns to first
  todo; FIN complete only when all packed; summary DEL two-step
  clear with arm cancelled by other actions; DEMO arc (4 stages,
  stage 3 → 4 from the summary screen, fifth tap complete); nod
  discipline (unsteady ignored, steady nod packs, 1.2 s lock,
  non-nod documented, nod in summary inert); SPEAK lines (empty,
  focus item, blocked summary, complete summary); onUnload wipes
  items and spare counter; bigCls thresholds.
- Preview screenshots 4, each visually verified (not just
  hash-compared): empty (no list loaded), DEMO packing (3 items
  packed), DEMO blocked summary (5 items named missing), DEMO
  complete summary (8/8, 行李齐了). Hit coordinates probed per
  state (see `shot-pack.js`, `probe-pack.js` in
  `~/workspace/preview-tools/`): the DEMO button is the row-1 first
  button (x=88); its true y moves with the info-box height —
  empty (88,167), packing states (88,167), blocked summary
  (88,181, taller two-line note). The first probe round proved the
  lesson again: y=208/213 landed on SPEAK (row 3), not DEMO; only
  the second round (150–184) found DEMO. Every final PNG was read
  back by eye.
