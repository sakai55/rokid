# Bag Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series D02 (DUAL 并行型， second of the group): at a station or a
cafe, the wearer's main line is waiting or buying and the side line
is "is my bag still there, and will I remember it when I leave".
The wearer cannot keep one eye on a bag behind them and do the main
line at the same time, so the agent takes the remembering: register
the bag once by looking toward it and holding steady, then a timer
reminds the wearer to look back every 5 minutes (DEMO interval). A
look-back confirmed by tap or steady nod resets the timer; a
reminder left unconfirmed escalates — banner, then one TTS plus a
brighter banner, then a strong "go and look at the bag" reminder.
When the wearer wants to leave, the leave gate takes over: ending
without the gate only stops the wearer on the spot and names the
bag as unconfirmed — it never says "you may go". Only after turning
to the registered heading, holding steady and confirming GOT
("I have it") may the wait end with a summary of confirmed
look-backs, missed reminders, blocks, and whether the gate passed.

## Design contract

- **The side line is a registered heading, never a detected bag.**
  REG stores only a label ("行李", or the DEMO sample "黑色背包")
  and the fact that it was registered while the wearer looked
  toward it and held steady. There is no camera, no mic, no
  location, no step or movement sensing anywhere in the agent,
  so there is nothing that could know whether the bag is really
  in hand — and the agent never claims otherwise. The heading is
  a reminder anchor, not a bag, and the gate attestation is the
  wearer's own statement, not detection.
- **The timer is the watching mechanism, and it only moves in one
  place.** Every interval step goes through `_checkDue`: due with
  level 0 raises a banner-only reminder; a further due interval
  with the reminder still open escalates to level 2 (one TTS,
  missed +1) and then level 3 (one TTS, missed +1); at level 3 a
  further due interval only increments missed. The DEMO clock
  (TICK adds one interval) and the real 30-second ticker share
  exactly this path, so the preview and the device cannot drift
  apart in ladder behaviour.
- **The leave gate is the whole point of the second half, and it
  cannot be bypassed.** END is not a way out: in watching or at
  the gate, END without a passed gate only increments `blocked`,
  raises the blocked banner, speaks one "行李还没确认，先过离开门",
  and stays put. LEAVE opens the gate; GOT at the gate sets
  `gatePassed` and returns to watching, where END finally works.
  BACK cancels a leave attempt (not counted as blocked) and BACK
  from the summary returns to watching with the gate still
  passed, so the summary is rebuilt on END. No path from any
  state reaches the summary with `gatePassed === false`, and no
  status or speak line in a blocked state says "you may go".
- **Confirmation is the wearer's attestation, stated as such.**
  GOT (tap) or a steady nod confirms "I looked at the bag" while
  watching, and "I have it" at the gate. A nod is never sensor
  proof that the bag was seen or is in hand: the page has no
  sensor that could prove either, and the UI footer, the README
  and every hint say so. An unsteady nod never arms the 1.2 s
  lock (the fleet fix, kept).
- **Escalation is capped in display, honest in counting.** Level
  stops at 3, but missed keeps counting expired intervals, so
  the summary cannot understate how many reminders went
  unanswered. Level 1 deliberately has no TTS: a banner is
  enough for a wearer who is merely waiting, and a voice call
  for every single reminder would turn the side line into the
  interruption it is supposed to prevent. TTS is spent only on
  escalation and on the blocked stop.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to watching without deleting anything; the
  summary is rebuilt on END. Confirming the summary (Enter /
  steady nod) is the only wipe. There is no DEL key: there is
  no banner to clear without also lying about the reminder or
  gate state.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks five stages: watching registered (black backpack DEMO
  sample) → level-1 reminder (banner only, no TTS) → look-back
  confirmed + leave gate opened → END blocked on the spot
  (blocked 1) → summary (confirmed 1, missed 0, blocked 1, gate
  passed). A sixth DEMO tap reports the demo complete. DEMO
  refuses outright if a user side line is being watched or a
  user gate is open. Every step is labelled DEMO; the sample
  bag is labelled as a sample.
- **The wait lives in session memory only — zero persistence,
  by design.** There is no storage API anywhere in the page
  (harness-scanned). Bag, counts, log, level, gate and summary
  die when the summary is confirmed and when the agent closes
  (onUnload wipes everything). Close the agent and the wait is
  gone, which is the correct use for a wait happening right
  now — and the only use, since a stored bag heading from last
  week would be a lie about today.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). The only timers
  are the 30-second ticker, the 5-minute look-back interval and
  the 1.2 s nod lock.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `pack-sweep` (C04) is **packing at home
  before leaving**: a checklist of items to put in the bag,
  confirmed one by one while packing. Bag-watch starts after
  the bag is already packed and in transit — it never lists
  contents.
- Attention-series `last-glance` (C01) is **leaving a place
  with a photographic record per zone, replayed later when
  anxiety strikes**: its value is after the fact. Bag-watch
  is live and preventive: it watches during the wait and
  physically intercepts the departure at the gate.
- Attention-series `play-watch` (D01) is the sibling template:
  same timer ladder, same nod discipline, same zero-persistence
  rule — but its side line is a play area and it has no gate
  at all. Bag-watch adds the leave gate and the blocked count,
  because "forgetting to look" and "walking off without the
  bag" are two different failures.

## Permissions

None — `permissions` is exactly `[]` in app.json, and the static
check asserts exactly that (precedent: shelf-sweep, pack-sweep
and play-watch ship with empty permissions). No `CAMERA`:
nothing is photographed — the bag is registered by looking
toward it and holding steady, and the DEMO bag is a labelled
sample. No `RECORD_AUDIO`: escalation/blocked TTS is output
only, and there is no voice input anywhere. No `GEOLOCATION`:
a waiting side line needs no position, and this agent never
knows where anyone or anything is — that ignorance is stated
in the README.

## Validation

- Node harness (see `/tmp/bag-watch-harness.js`, not packed):
  app.json pages and permissions exactly []; zero storage/camera/
  geo/mic APIs in the page source; no legacy Page/App/Widget; no
  utterance language assignment; 5-minute interval asserted;
  30-second ticker asserted; foot2 honesty lines asserted (not
  an anti-theft device, does not know whether the bag is really
  in hand, cannot guarantee the bag is not lost, gate
  attestation is not sensor proof, session memory only, no
  permission); initial idle state (unregistered, level 0, counts
  0, log empty, gate not passed, big shows unregistered);
  REG discipline (GOT/LEAVE/END/TICK refused in idle, double REG
  refused, nextDue one interval ahead); reminder ladder (tick 1
  banner no TTS missed 0, tick 2 level 2 one TTS missed 1, tick 3
  level 3 strong one TTS missed 2, tick 4 level 3 stays missed 3
  no new TTS); GOT resets timer and counts (level-named log,
  early look-back labelled, nextDue reset); leave gate (LEAVE
  opens gate, double LEAVE refused, END in gate blocked with one
  TTS and banner, blocked never says "you may go", GOT in gate
  passes and returns to watching, END after gate reaches
  summary with gate passed); END without gate from watching
  blocked and stays watching, watching GOT does not pass the
  gate; BACK cancels gate without counting and returns from
  summary with gate kept; END/summary/back/confirm wipe; log
  focus NEXT/PREV/rowTap wrap; SPEAK lines per mode, level, gate
  and blocked state; nod discipline (unsteady ignored without
  arming, steady nod registers in idle, lock blocks a second
  nod, nod after lock expiry confirms, non-nod inert); key
  discipline (Enter register/confirm/gate/summary, Backspace
  summary-to-watching and gate-cancel and ignored in watching);
  DEMO five-stage arc and refusal on a user session; TICK
  refused outside watching; onUnload wipes everything;
  bigCls thresholds. Result: **86/86**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): register (idle, bag unregistered), watching
  (DEMO stage 1, black backpack registered, next look-back in 5
  minutes), reminder banner (DEMO stage 2, level 1, no TTS),
  blocked on the spot (DEMO stage 4, gate open, END attempted,
  blocked 1, banner "还没确认！"), summary (DEMO stage 5,
  confirmed 1, missed 0, blocked 1, gate passed). Button
  coordinates were probed per state and every PNG re-verified
  by eye (see `shot-bag-watch.js` in `~/workspace/preview-tools/`):
  DEMO tap sequence [170, 160, 160, 170, 170] at x=88 — per the
  fleet lesson that a single hash probe can hit the wrong
  button and produce a byte-identical fake stage.
