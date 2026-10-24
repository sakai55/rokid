# Tour Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series D04 (DUAL 并行型， fourth of the group): on a group tour, the
wearer's main line is looking at the sights and the side line is "did
the guide just call a meeting time, and where do I go back to". The
agent takes the listening: register the meeting point by facing it,
pick a meeting clock time, far-field listening passes every guide
announcement through a meeting-keyword gate, and only meeting
sentences are bannered, spoken once by keyword, and saved as notes —
everything else moves only a counter and is discarded on the spot.
Before meeting time it reminds the wearer to head back to the
registered direction, and the wearer confirms归队 with CHECK or a
steady nod.

## Design contract

- **The side line is a gate, a note and a reminder — never a
  detection.** REG records a direction the wearer faced; TIME
  picks a clock time; START requires both and names what is
  missing. The gate is the transcript: `_onSegment` matches one
  segment against the keyword list in list order (集合 / 出发 /
  上车 / 点名 / 集合点), first match wins. A hit saves the
  sentence itself plus minute mark and keyword, banners, and
  speaks exactly one short utterance naming the keyword — the
  sentence is shown in view, never read aloud whole, so a hit
  costs one short utterance, not a paragraph. A non-hit moves
  only `_segments` and is stored nowhere.
- **A due reminder is a threshold crossing, not a loop.** The
  meeting time is a clock time; the deadline is its next
  occurrence (today, or tomorrow if already passed). `_tick`
  (30 s interval, plus DEMO forcing) fires the 10-minute warning
  once and the overdue warning once; a reminder already on
  screen is never re-spoken. CHECK confirms归队, clears the
  banner, and counts the confirmation — it does not delete the
  note, and it does not claim the wearer actually arrived.
- **The registered direction is not navigation.** REG stores a
  label ("当前朝向" for a user, "停车场入口" for the DEMO
  sample) and the fact that the wearer faced that way when
  registering. The agent never knows where the meeting point is,
  never routes, and never claims otherwise —归队 still means
  the wearer walks there by looking. The README and the foot2
  line say this in plain words.
- **No speaker identification, no full transcript.** The gate
  matches ASR text only, so a misheard announcement can miss or
  false-hit, and the README says so. Notes hold hit sentences
  only; the rest of the tour's speech is never stored, which is
  both the privacy rule and the zero-persistence rule.
- **A nod never starts listening and never saves a note.** A
  steady nod registers the direction in idle (you are facing it
  — that is the gaze confirm), confirms归队 when a due reminder
  is on screen, or confirms the summary. In listening without a
  due reminder a nod is ignored with an explanation, because
  there is nothing safe for it to confirm. An unsteady nod never
  arms the 1.2 s lock (the fleet fix, kept).
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to listening without deleting anything;
  the summary is rebuilt on END. BACK elsewhere is ignored with
  an explanation. Confirming the summary (Enter / steady nod /
  CHECK) is the only wipe. There is no DEL key: there is no
  banner to clear without also lying about the note or the
  reminder state.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks five stages: direction + time registered (DEMO sample)
  and listening started → non-hit segment counted only →
  hit segment saved (keyword 集合) → due reminder forced by
  moving the deadline to the 10-minute threshold (labelled DEMO;
  in a real tour the same threshold is crossed by the clock) →
  归队 confirmed + END summary (segments 2, hits 1, due 1,
  归队 confirmed). A sixth DEMO tap reports the demo complete.
  DEMO refuses outright if a user direction/time is registered
  or a user tour is under way. Every step is labelled DEMO;
  the sample direction and time are labelled as samples.
- **The tour lives in session memory only — zero persistence,
  by design.** Direction, time, notes and counts die when the
  summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the tour is gone,
  which is the correct use for a tour happening right now.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). The 30 s
  ticker only checks due thresholds; every other transition is
  a tap, a nod or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `meeting-filter` (F04) is the keyword-gate
  template: same gate + one-TTS discipline — but its gate is
  "your name / your topics" and it keeps a 10-second pre-hit
  replay buffer. Tour-watch has no replay buffer at all: a hit
  saves the sentence as a note, and the gate is meeting
  information, not personal relevance.
- Attention-series `lecture-filter` (F05) is the signal-note
  template: same "hit sentence becomes a note, non-hit is
  counted and discarded" rule — but its signals are class
  signals (重点 / 考试 / 作业) and it has no direction, no
  clock time and no due reminder. Tour-watch adds the meeting
  direction, the meeting clock time and the归队 reminder,
  because a missed meeting point is a missed bus, not a missed
  sentence.
- Attention-series `dog-walk` (D03) is the sibling template:
  same nod discipline, same zero-persistence rule, same DEMO
  five-stage arc — but its side line is a checklist and a home
  gate with no listening at all. Tour-watch's side line is
  listening: the gate is the transcript, and the reminder is a
  clock threshold, not a checklist.

## Permissions

RECORD_AUDIO only — far-field listening plus ASR input. The
microphone mode (far-field) is an AIUI mic-API mode: it affects
only the getUserMedia stream's pickup, not the host ASR's
pickup, and the UI and README both say so (fleet audit
conclusion). No `CAMERA`: nothing is photographed — a meeting
point is registered by facing it, and the DEMO direction is a
labelled sample. No `GEOLOCATION`: a tour side line needs no
position, and this agent never knows where anyone or any
meeting point is — that ignorance is stated in the README.

## Validation

- Node harness (see `/tmp/tour-watch-harness.js`, not packed):
  app.json pages and permissions exactly [`RECORD_AUDIO`];
  zero storage/camera/geo APIs in the page source; no legacy
  Page/App/Widget; no utterance language assignment; foot2
  honesty lines asserted (no speaker identification, direction
  is not navigation, notes hold hit sentences only, mic mode
  does not change host ASR pickup, non-hit sentences counted
  and discarded); initial idle state (direction null, time
  unset, bigText 未登记集合点, counts 0, notes empty); bigCls
  thresholds; refusals in idle (START naming both missing items,
  then only time; END refused; CHECK refused with no due
  reminder; segments ignored in idle); TIME cycle and wrap
  (15:00 → 16:30 → 15:00); REG twice keeps direction; START
  sets a future deadline; REG/TIME refused in listening;
  transcript gate (non-hit counted only with zero TTS; hit
  saves the sentence verbatim with keyword 集合 and exactly one
  TTS naming the keyword only; second hit keyword order
  first-wins 上车； NEXT/PREV wrap; rowTap out-of-range
  guard); due thresholds (tick above 10 min silent; tick at
  10 min fires once with one TTS and no re-speak on re-tick;
  CHECK confirms归队 once and a second CHECK is refused;
  overdue fires a second reminder and CHECK confirms it);
  summary flow (END reaches summary with segments 3, hits 2,
  due 2, confirmed 2; BACK rebuilds; confirm wipes to idle);
  nod discipline (unsteady ignored without arming, steady nod
  in idle registers, lock blocks a second nod, lock expiry
  works, nod in listening without due ignored, nod with due
  confirms归队）; key discipline (Enter idle registers,
  ArrowUp/Down cycle idle rows, Backspace idle ignored); SPEAK
  lines per mode; DEMO five-stage arc and refusal on a user
  registration or user tour; onUnload wipes everything.
  Result: **81/81**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (direction + time unregistered),
  listening (DEMO stage 1, sample direction + 15:30),
  hit banner + note saved (DEMO stage 3, keyword 集合）,
  due reminder (DEMO stage 4, 该归队了）,
  summary (DEMO stage 5, segments 2, hits 1, due 1, 归队
  confirmed). Button coordinates were probed per state and
  every PNG re-verified by eye (see `shot-tour-watch.js` in
  `~/workspace/preview-tools/`): DEMO is the row-1 FIRST button
  (x=88); final DEMO tap sequence is recorded in that script's
  header comment, per the fleet lesson that a single hash probe
  can hit the wrong button and produce a byte-identical fake
  stage.
