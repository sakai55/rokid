# Dog Walk — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series DU03 (DUAL 并行型， third of the group): walking the dog, the
wearer's main line is the road and the dog at their feet and the side
line is "did I bring everything, what did the dog just do, and did I
miss anything before going home". Both hands are on the leash, so the
agent takes the remembering: confirm the going-out checklist item by
item (poop bags, water, leash), tap STOP when the dog stops and
resolve it on the spot (poop cleaned, water given, or mark the spot
as a pending cleanup point by gaze direction), and pass the home gate
before ending — bags dealt with, water given, every pending point
cleared one by one. Ending without the gate only stops the wearer on
the spot and names the missing items — it never says "you may go
home". There is no dog-behaviour detection, no location, no step or
movement sensing anywhere in the agent, so a stop is only ever the
wearer's own tap and a cleanup is only ever the wearer's own
attestation.

## Design contract

- **The side line is a checklist, a stop report and a gate — never
  a detection.** CHECK confirms a checklist or gate item the wearer
  selected; STOP reports a stop the wearer saw; POOP/DRINK/MARK
  resolve it the way the wearer says it happened. A pending point
  stores only a label ("待清理点位1") and the fact that it was
  marked while the wearer faced the stopping direction — it is a
  reminder anchor, not a record of where anything is, and the
  agent never claims otherwise.
- **The going-out checklist gates departure, and it names what is
  missing.** WALK with any item unconfirmed is refused and the
  refusal names the missing items; only a 3/3 checklist starts the
  walk. Checking the list after the walk has started is impossible
  by construction (CHECK in walking is refused), so the list
  cannot be rewritten mid-walk to fake a clean departure.
- **A stop must be resolved on the spot — there is no "later"
  option.** Stopped mode offers exactly four exits: POOP (cleaned
  +1), DRINK (drinks +1), MARK (pending +1), BACK (sniff-and-go,
  logged as such). END in stopped is refused without counting a
  block, because the wearer is not trying to leave — they are
  mid-decision. The stop count stays honest: a sniff-and-go still
  counts as a stop, it just does not count as a cleanup.
- **Pending points are the PLAN's "回程逐个提醒清理", made
  concrete.** Each MARK creates one gate item of its own; HOME
  builds the gate from bags + water + every pending point, and
  confirming a point item deletes that point. A gate cannot pass
  with a point still on it, and cancelling the gate (BACK) keeps
  the points — the next HOME rebuilds the same gate from them.
  The gate is rebuilt from pending points every time, never from
  a stale copy.
- **The home gate is the whole point of the second half, and it
  cannot be bypassed.** END is not a way out: in walking or at
  the gate, END without a passed gate only increments `blocked`,
  raises the blocked banner, speaks one TTS naming the missing
  items, and stays put. CHECK confirming the last gate item sets
  `gatePassed` and returns to walking, where END finally works.
  No path from any state reaches the summary with `gatePassed
  === false`, and no status or speak line in a blocked state says
  "you may go home" — the "可以回家了 ✓" big text appears only
  in the gate-passed walking state, and the README says it is the
  wearer's attestation, not a detection.
- **A nod never reports a dog stop and never picks a resolution.**
  A steady nod confirms only where confirmation is safe — CHECK
  on the checklist (idle) or the home gate (home), CONFIRM on the
  summary screen. In walking and stopped, a steady nod is ignored
  with an explanation, because a stop is a report and
  poop/water/mark are choices, not a default a nod could
  accidentally pick. An unsteady nod never arms the 1.2 s lock
  (the fleet fix, kept).
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to walking without deleting anything; the
  summary is rebuilt on END. BACK from the gate cancels the
  attempt (not counted as blocked) but keeps the points.
  Confirming the summary (Enter / steady nod) is the only wipe.
  There is no DEL key: there is no banner to clear without also
  lying about the checklist, point or gate state.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks five stages: checklist done + walk started (DEMO sample
  list) → dog stopped (stop 1) → poop cleaned + home gate opened
  (2 items: bags, water) → END blocked on the spot (blocked 1)
  → gate items confirmed + END summary (stops 1, cleaned 1,
  blocked 1, gate passed). A sixth DEMO tap reports the demo
  complete. DEMO refuses outright if a user checklist item is
  confirmed or a user walk is under way. Every step is labelled
  DEMO; the sample list is labelled as a sample.
- **The walk lives in session memory only — zero persistence,
  by design.** There is no storage API anywhere in the page
  (harness-scanned). Checklist, stops, points, gate and summary
  die when the summary is confirmed and when the agent closes
  (onUnload wipes everything). Close the agent and the walk is
  gone, which is the correct use for a walk happening right
  now — and the only use, since last walk's points would be a
  lie about today's walk.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). There are no
  timers at all in this agent — no ticker, no interval — because
  nothing here is time-driven; every transition is a tap, a
  nod or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `play-watch` (DU01) is the sibling template:
  same nod discipline, same zero-persistence rule — but its side
  line is a play area watched on a timer, and it has no gate at
  all. Dog-walk adds the going-out checklist, the on-the-spot
  stop resolution and the home gate, because "forgot to bring",
  "forgot to pick up" and "forgot to check" are three different
  failures.
- Attention-series `bag-watch` (DU02) is the gate template: same
  blocked-count + banner + one-TTS stop, same "never says you may
  go" rule — but its gate is a heading gate (turn to the
  registered direction and attest "I have it"). Dog-walk's gate
  is a checklist gate (bags, water, every pending point
  confirmed one by one); the two gates answer different
  questions, and neither reuses the other's attestation.
- Attention-series `pack-sweep` (CO04) is **packing at home
  before leaving**: a checklist of items to put in the bag,
  confirmed one by one while packing. Dog-walk's going-out list
  covers only the three walk items (bags, water, leash) and the
  agent keeps going after departure — stops and the home gate
  happen on the road, not at home.

## Permissions

None — `permissions` is exactly `[]` in app.json, and the static
check asserts exactly that (precedent: shelf-sweep, pack-sweep,
play-watch and bag-watch ship with empty permissions). No
`CAMERA`: nothing is photographed — a point is marked by facing
the stopping direction, and the DEMO list is a labelled sample.
No `RECORD_AUDIO`: blocked-stop TTS is output only, and there is
no voice input anywhere. No `GEOLOCATION`: a walk side line needs
no position, and this agent never knows where anyone, any dog or
anything is — that ignorance is stated in the README.

## Validation

- Node harness (see `/tmp/dog-walk-harness.js`, not packed):
  app.json pages and permissions exactly []; zero storage/camera/
  geo/mic APIs in the page source; no legacy Page/App/Widget; no
  utterance language assignment; foot2 honesty lines asserted
  (not a pet health/behaviour monitor, no dog-behaviour
  detection, stop only reported by your own STOP tap,
  attestation not sensor proof); initial idle state (checklist
  3 undone, bigText 出门清单 0/3, counts 0, pending 0, gate null,
  gate not passed, log empty); bigCls thresholds; refusals in
  idle (WALK naming missing items, STOP/POOP/DRINK/MARK/HOME/END
  refused); checklist flow (CHECK per item, double CHECK no-op,
  NEXT/PREV focus, WALK refused until 3/3, then started);
  stop resolutions (POOP cleaned, DRINK drinks, MARK pending
  point 1, BACK sniff-and-go logged); home gate with a pending
  point (3 items, point confirm deletes the point, all confirmed
  passes and returns to walking); END after gate reaches summary
  and BACK/END rebuild it; confirm wipes to idle; blocked path
  (END in walking blocked 1 with one TTS, END in home blocked 2
  naming missing items, BACK cancels gate without counting,
  blocked never says go home); gate cancel keeps pending points
  and re-HOME rebuilds the same gate; END refused while stopped
  without counting; nod discipline (unsteady ignored without
  arming, steady nod confirms in idle, lock blocks a second nod,
  nod after lock expiry works, nod ignored in walking and
  stopped); key discipline (Enter = CHECK in idle, ArrowUp/Down
  focus cycle, Backspace ignored in idle); rowTap focus incl.
  out-of-range guard; SPEAK lines per mode; DEMO five-stage arc
  and refusal on a user checklist or user walk; onUnload wipes
  everything. Result: **86/86**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (checklist 0/3, three items unconfirmed),
  walking (DEMO stage 1, sample list 3/3, stops 0), dog stopped
  prompt (DEMO stage 2, "看一眼在做什么"), home-gate blocked
  (DEMO stage 4, "还没通过！", missing bags + water, blocked 1),
  summary (DEMO stage 5, stops 1, cleaned 1, blocked 1, gate
  passed). Button coordinates were probed per state and every
  PNG re-verified by eye (see `shot-dog-walk.js` in
  `~/workspace/preview-tools/`): DEMO tap sequence [175, 160,
  190, 170, 165] at x=88 — per the fleet lesson that a single
  hash probe can hit the wrong button and produce a
  byte-identical fake stage. Two probe traps were caught live:
  a visual-grounding point for the blocked state (y=128) missed
  on test, and blocked-state taps at 180–225 all missed; the
  real blocked band is y=165.
