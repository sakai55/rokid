# Guest Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series S02 (SOCIAL 社交型， second of the group, series #37): you are
hosting guests at home, busy in the kitchen, and who needs a refill or
a second helping is all peripheral vision. This agent takes the
watching off your hands: register each guest seat by steady gaze,
get timed reminders to look back at tea levels, and SCAN reports the
preset door direction when you notice something at the door.

## Design contract

- **The reminder ladder is time only, never a measurement.**
  A look-back timer runs while watching (30 s poll, 5 min
  ladder): 5 min banner only, 10 min banner + exactly one TTS,
  15 min strong banner + exactly one TTS, then capped — no
  further TTS. A reminder never claims a cup is empty: it only
  says it is time to look. SEEN (confirming a look-back)
  resets the timer and the level. The timer is real
  (`setInterval` + `Date.now()`); the DEMO stage 5 fires it by
  ageing the last look-back past 5 min, labelled as a DEMO
  state, not a faked banner.
- **No water-level detection, no motion detection.** "水空了"
  can only be judged by you when you look back; "门口有动静"
  is something you noticed and then logged with SCAN, not
  something the agent detected. SCAN reports the preset door
  direction （玄关方向）, not a sensor reading, and says so in
  plain words. This agent is not a monitor or a security
  device, and the UI and README say exactly that.
- **A seat is a gaze registration, not a position.** Each seat
  （沙发左/沙发右/餐桌） is a preset direction you looked at
  when the guest sat down. REG only registers on a steady head
  (judged on-device by head steadiness via
  `onOrientationStabilityChange`); an unsteady REG is refused
  and noted. Seat directions are not indoor positioning.
- **SCAN is a deliberate tap, never a nod.** SCAN reports the
  door direction only while watching, and only because you
  tapped it after noticing something. A nod never SCANs: a nod
  registers seats in idle/register, confirms a look-back
  while watching, or confirms the summary.
- **Correction is cheap, destruction is confirmed.** BACK from
  watching returns to register with seats kept and the timer
  stopped; BACK from register returns to idle with seats kept,
  and REG resumes the same list without duplicating. BACK from
  the summary returns to watching without deleting anything,
  and the summary is rebuilt on END. Confirming the summary
  (END while a summary is open, or a steady nod) is the only
  wipe. There is no DEL key: there is nothing to clear that
  would not also lie about what was registered.
- **The round lives in session memory only — zero persistence,
  by design.** Seats, look-back counts, SCAN counts, reminder
  levels and the summary die when the summary is confirmed
  and when the agent closes (onUnload wipes everything and
  stops the ticker). Close the agent and the hosting round is
  gone.
- **A steady nod registers, confirms, or clears — never picks.**
  A steady nod in idle/register registers the next seat, in
  watching confirms a look-back, in summary confirms and
  clears. An unsteady nod never arms the 1.2 s lock (the fleet
  fix, kept). A nod never changes focus: that is a selection,
  and a nod must not silently pick a seat. Enter follows the
  same per-mode action; ArrowUp/Down walk seats; Backspace
  goes back.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK names
  counts only and never claims a measurement. There is no
  ticker besides the look-back poll: every other transition
  is a tap, a nod or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `play-watch` (D01) is the playground side-line:
  a child activity direction registered, with timed look-back
  reminders and the same three-level escalation shape. Guest-watch
  borrows the ladder but is not a child watch: its units are
  guest seats at home, and it adds SCAN for the door.
- Attention-series `bag-watch` (D02) is the in-transit luggage
  side-line: a direction-registered bag watched while waiting,
  with a leave-gate that blocks on an unconfirmed bag. Guest-watch
  has no leave-gate: its close is a summary, not a block —
  hosting ends when you say so, and the summary records what
  was and was not looked back at.
- Attention-series `chat-catchup` (S01) is the mid-conversation
  silent catch-up: a rolling caption buffer served on HELP.
  Guest-watch listens to nothing and buffers nothing: it
  watches seats on a timer and reports a preset door direction.

## Permissions

Zero permissions (app.json `permissions` is `[]`, and the
static check asserts exactly that): seat registration plus a
timer plus a preset direction needs no camera, no microphone,
no position. No `CAMERA`: nothing is photographed. No
`RECORD_AUDIO`: nothing is listened to, there is no ASR path
at all (no onASRResult handler). No `GEOLOCATION`: this agent
never knows where anyone is.

## Validation

- Node harness (see `/tmp/guest-watch-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/location/camera/recorder/ASR APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted (no water-level detection, no motion detection,
  SCAN direction is a preset not a sensor reading, not a
  monitor device, single session, cleared on close, no indoor
  positioning, zero persistence); initial idle state (bigText
  还没登记， placeholder row, countLine); bigCls thresholds;
  refusals in idle (END naming REG, SEEN/SCAN refused, WATCH
  naming REG, NEXT/PREV/BACK ignored, REG refused while head
  moving); steady event arms steady and REG registers seats
  one by one （沙发左/沙发右/餐桌）, refused when all 3
  registered; focus walks seats (NEXT/PREV wrap, rowTap focus
  with out-of-range and missing-dataset guards); BACK keeps
  seats and REG resumes without duplicating; WATCH starts
  watching + ticker; reminder ladder with injected time (no
  reminder before 5 min, level 1 banner only with zero TTS,
  level 2 banner + exactly one TTS, level 3 strong + one more
  TTS, capped with no further TTS); SEEN resets level and
  timer; SCAN reports the preset door direction with exactly
  one TTS; BACK watching->register keeps seats and stops the
  ticker, WATCH restarts it; summary flow (seats/seens/scans/
  reminds recorded, ticker stopped, BACK rebuilds watching,
  END confirms and clears); nod discipline (unsteady ignored
  without arming, steady nod registers, lock blocks a second
  nod, lock expiry works, non-nod gestures noted); key
  discipline (Enter registers, ArrowUp walks, Backspace
  returns); DEMO seven-stage arc (3 seats, watching, reminder
  level 1, SCAN, summary seats 3 seens 0 scans 1 reminds 1)
  and refusal on user sessions; SPEAK lines per mode;
  onUnload wipes everything and stops the ticker.
  Result: **88/88** (first run, no harness fixes needed).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not registered), registered (DEMO
  stage 3, 3 seats), reminder (DEMO stage 5, level 1 banner,
  未出声， reminds 1), scan (DEMO stage 6, door direction
  玄关方向， scans 1), summary (DEMO stage 7, seats 3 seens 0
  scans 1 reminds 1). Button coordinates were probed per state
  and every PNG re-verified by eye (see `shot-guest-watch.js`
  in `~/workspace/preview-tools/`): DEMO band y=180-190 at x=66
  in idle, all 8 stage frames md5-distinct, no stalled stage.
