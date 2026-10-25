# Cue Desk — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series CU03 (CUE 提示型， third of the group, series #33): sitting down at
the desk and scrolling the phone for ten minutes before getting into
gear, then standing up and forgetting where you left off. This agent
takes the resume check off your hands: look at the desk and hold
steady, and only then do today's three tasks light up; tick one off
as you finish it, and when you stand up it gives one resume line
naming the first unfinished task.

## Design contract

- **Standing up is a tap, never a detection.** TRIG opens the
  three tasks only from idle, and only with a steady head (the
  gaze trigger, judged on-device by head steadiness via
  `onOrientationStabilityChange`). GOT ticks the focused task.
  UP in the list is the stand-up: with pending tasks it speaks
  exactly one resume line — "回来从这继续：<first pending>" —
  counts the stand, and opens the summary with the line
  recorded; with all three done it says all three are done.
  UP never blocks: it reports and records, then the summary is
  the close. A stand-up the agent "detected" would be a lie
  about the hardware — there is no stand sensor — so the UI
  and README say plainly that standing up is your own tap.
- **The three tasks are a preset, never a calendar sync.** The
  agent does not read any calendar or task app: the three tasks
  （写报告 / 回邮件 / 整理桌面） are the wearer's preset, shown
  as a DEMO sample in preview. Claiming a sync would be a lie
  about the platform, so the agent never claims one.
- **A tick is a statement, never a sensor proof.** The agent
  does not detect whether any task is actually done: it has no
  camera, no microphone, no position, and no task sensor. GOT
  records that you said you did it. The UI and README say
  exactly that — "勾掉只是你本人的表态，不是传感器证明".
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to the list without deleting anything;
  the summary is rebuilt on UP. BACK from the list returns to
  idle with ticks kept, and re-triggering restores the same
  three tasks. Confirming the summary (UP while a summary is
  open, or a steady nod) is the only wipe. There is no DEL key:
  there is nothing to clear that would not also lie about
  what was ticked.
- **The three tasks live in session memory only — zero
  persistence, by design.** Tasks, ticks, stand count and the
  summary die when the summary is confirmed and when the agent
  closes (onUnload wipes everything). Close the agent and the
  desk round is gone.
- **A steady nod triggers, ticks, or clears — never picks.**
  A steady nod in idle triggers the three tasks, in the list
  ticks the focused task, in summary confirms and clears.
  An unsteady nod never arms the 1.2 s lock (the fleet fix,
  kept). A nod never changes focus: that is a selection, and a
  nod must not silently pick a task. Enter follows the same
  per-mode action; ArrowUp/Down walk focus; Backspace goes back.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in the
  list names the done count and the pending tasks (or the
  resume line, once stood up); it never reads a whole list
  aloud. There is no ticker: every transition is a tap, a nod
  or a key — a task list is event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `cue-door` (CU01) is the going-out checklist
  gate at the door: unconfirmed END blocks and never says
  "可以出门". Cue-desk is not a gate: standing up reports the
  resume line and records it, it never blocks leaving.
- Attention-series `cue-fridge` (CU02) is the fridge to-fetch
  checklist: tick as you take, mark out of stock, and before
  closing it names anything still unticked (a reminder, not a
  gate). Cue-desk is not fetching: its trigger is looking at
  the desk itself, and its close is a resume line, not a miss
  report.
- Attention-series `attention-diary` (RE05) is the attention bill:
  trigger entries grouped by category, closed with a counted
  verdict. Cue-desk has no categories and no bill: its units
  are the three tasks, and its close is a resume verdict.

## Permissions

Zero permissions (app.json `permissions` is `[]`, and the
static check asserts exactly that): a gaze trigger plus a
task reminder needs no camera, no microphone, no position.
No `CAMERA`: nothing is photographed. No `RECORD_AUDIO`:
nothing is listened to, there is no ASR path at all (no
onASRResult handler). No `GEOLOCATION`: this agent never knows
where anyone is.

## Validation

- Node harness (see `/tmp/cue-desk-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location APIs, no ASR/recorder/camera path, no
  utterance language assignment, no legacy Page/App;
  foot2 honesty lines asserted (standing up is your own tap
  not a detection, three tasks are a preset not a calendar
  sync, tick is a statement not a sensor proof, single
  session, cleared on close, no indoor positioning, zero
  persistence, gaze trigger judged by head steadiness);
  initial idle state (bigText 还没触发， placeholder row,
  countLine); bigCls thresholds; refusals in idle (UP naming
  TRIG, GOT refused, NEXT/PREV/BACK ignored, TRIG refused
  while head moving); steady event arms steady and TRIG opens
  the list at focus 0; tick flow (GOT ticks, re-GOT refused,
  NEXT/PREV wrap over 3 items, rowTap focus with
  out-of-range and missing-dataset guards); stand-up flow
  (UP with pending speaks the resume line exactly once and
  opens the summary with done/pending recorded honestly;
  BACK rebuilds, UP reopens, UP in summary confirms and
  clears; all-done UP says all three are done and speaks
  exactly once); BACK from list keeps ticks and re-TRIG
  restores them; DEMO seven-stage arc (trigger, 写报告，
  回邮件， stood up with resume 整理桌面， back to list,
  整理桌面， all-done summary) and refusal on user sessions;
  nod discipline (unsteady ignored without arming, steady nod
  in idle triggers, lock blocks a second nod, lock expiry
  works, non-nod gestures noted); key discipline (Enter
  triggers / ticks, ArrowUp/Down walk, Backspace returns to
  idle with ticks kept); SPEAK lines per mode; onUnload wipes
  everything; summary reports honestly with partial counts.
  Result: **84/84** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not triggered), list (DEMO stage 1,
  0/3), partial (DEMO stage 3, 2/3, 写报告/回邮件 done),
  resume (DEMO stage 4, summary naming 整理桌面 as the
  resume line), all-done summary (DEMO stage 7, 三件事都做
  完了）. Button coordinates were probed per state and every
  PNG re-verified by eye (see `shot-cue-desk.js` in
  `~/workspace/preview-tools/`).
