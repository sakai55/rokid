# Room Sweep — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series CO02 (COVER 覆盖型， second of the group): the bedtime sweep of a
child's room — window, socket covers, small objects on the floor, bed
rail, door, night light — where the nightly question "did I check
everything" returns even after you walked the room, because a walked
room is not a checked room.

## Design contract

- **Not a checklist that can be bulk-ticked, and not a sensor: the
  product is coverage proof with a refusal built in.** Six fixed
  items, in the order you walk the room from the door, are the whole
  model. An item turns green only when the wearer looked at it and
  confirmed it (OK, or a steady nod — the ONLY thing a nod means
  here, and only in sweep mode). A problem item is FLAGged, and a
  flagged item is NEVER counted as passed: `_countOk` counts only
  state `ok`, so a summary with a flag in it cannot be all-green by
  construction, only by a bug. Fixing means returning to the item
  and pressing OK after the problem is actually dealt with.
- **The summary is gated, not decorative.** FIN in sweep with any
  item still todo is REFUSED, and the refusal NAMES the missing
  items with their walk-order sectors （还差：插座（右前）、夜灯
  （左前）) — a summary with a hole in it would be exactly the
  false reassurance this agent exists to prevent. Only when all six
  items are decided (ok or flag) does FIN open a summary, and the
  summary then says one of two honest things: all-green （可以安心
  睡了） or pending （有待处理项：门） — never all-green with a
  flag hiding in the list. Summary OK returns to the sweep focused
  on the first flag, so fixing has somewhere to go.
- **The agent never judges a physical state, and says so everywhere.**
  Whether the window is shut or the socket is covered is the
  wearer's judgement, made by looking: there is no sensor link, no
  home-device connection, no photo analysis. SNAP takes a wide photo
  for the focused item and records ONLY a marker (bytes) in session
  memory — the Blob is discarded immediately, the photo is never
  analysed, never used to pass or flag an item, and the CAP line
  says "NOT analysed" on every shot. A failed or unavailable camera
  changes nothing about the checklist (OK/FLAG keep working); the
  photo path is an archive marker, never a gate. The UI footer, the
  README and every hint state the ignorance.
- **Sectors are walk order, not measured positions.** Item labels
  carry a sector （窗户·左， 插座·右前 …) that is the order you
  walk from the door. The agent has no indoor positioning and no
  room map, and never claims to know where anything really is: the
  sector helps the wearer orient while sweeping and names the
  missing items in FIN's refusal. No geolocation permission, no
  floor plan, no arrow.
- **The checklist lives in session memory only — zero persistence,
  by design.** There is no storage API anywhere in the page (no wx
  storage import use, no localStorage; harness-scanned). Items,
  flags and photo markers die when the checklist is cleared
  (two-step DEL from the summary, with a 6 s arm that any other
  action cancels), when the agent closes (onUnload wipes the list),
  and when DEL resets a single item in sweep. Tomorrow night you
  sweep again — that is the correct use, and the UI count line says
  so constantly （只存本次会话内存 · 关掉即清 · 零落盘）.
- **DEMO is staged and never overwrites real decisions.** DEMO
  refuses outright if any item carries a REAL decision. Otherwise
  it walks four stages: 2 ok → 4 ok + 1 flag → all decided with the
  flag (summary pending) → flag fixed (summary all-green). Every
  step is labelled DEMO, no camera is used. A DEMO flag is fixed by
  the same OK path a real flag is, so the demo teaches the real
  fix flow.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data —
  the only timers are the 1.2 s nod lock and the 6 s two-step disarm
  window.

## Relation to the neighbours (kept distinct on purpose)

- CO01 `last-glance` is the leave-the-room archive: photograph six
  heading zones, replay their descriptions later on the road. It
  archives what you SAW when leaving; it never judges safety items
  and has no pass/flag semantics.
- Directional-series `home-patrol` is the leaving-the-house generic
  check: doors, gas, taps, windows for the whole home, once, before
  going out. Room-sweep is the opposite end of the day and the
  opposite scale: one fixed room, the same six safety items, every
  night, with a problem item that refuses to be brushed green.
- The three share the coverage-table pattern and nothing else: a
  different room, a different moment, a different question.

## Permissions

`CAMERA` only — optional wide photos as session-only archive
markers per item (every Blob discarded immediately after the shot;
markers only, never analysed). No `RECORD_AUDIO`: there is
deliberately no dictation anywhere in this agent (confirm/flag/
reset are taps and nods). No `GEOLOCATION`: sectors are walk order,
and this agent never knows where anything is — that ignorance is
stated in the UI footer, the README and every hint it gives.

## Validation

- Node harness (109 assertions): app.json permissions exactly
  [CAMERA]; zero storage/geo/audio/ASR/LLM APIs in the page source;
  no legacy Page/App/Widget; no utterance lang assignment; no
  detection/positioning/connectivity claims in spoken strings;
  initial state (6 todo, focus 窗户， sweep mode, count line);
  navigation wrap (NEXT/PREV cycle); OK confirms and jumps to next
  todo, OK on an ok item inert; FLAG never counts as passed, OK on
  a flagged item fixes it; FIN refusal names missing items with
  sectors; FIN all-decided with flag → summary pending (never
  all-green, never 安心睡了）; FIN all ok → summary all-green;
  summary OK returns to sweep focused on first flag; summary DEL
  two-step clear with arm cancelled by other actions; DEL in sweep
  resets the focused item; nod discipline (unsteady ignored, steady
  nod confirms only in sweep, nod lock, non-nod documented, nod in
  summary inert); DEMO arc (4 stages, refusal on real decisions,
  pending then all-green summaries); SPEAK lines (todo/ok/flag/
  summary); bigCls sizing; onUnload wipes; camera happy path
  (wide mode, bytes on CAP line, tracks stopped, blob never
  stored); wx fallback path (bytes, marker); no-camera path (fail
  explained, checklist unaffected).
- Preview screenshots 5, each visually verified (not just
  hash-compared): sweep 0/6, DEMO partial 2 ok, DEMO flagged 4 ok +
  1 flag, summary pending （有待处理项：门）, summary all-green
  （可以安心睡了）. Hit coordinates probed per state: the first
  probe hit FLAG, not DEMO — the grid is rows 175/195/215 and
  columns 80/240/400, so DEMO (row 3, column 2) is (240,215),
  recorded in `shot-room.js`.
