# Water Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series B02 (BODY 身体型， second of the group, series #42): you get busy
and go a whole day without two glasses of water, and only when you are
thirsty do you remember the cup was right beside you. This agent takes
the remembering off your hands: it registers the cup direction when you
look at it and hold steady, watches the minutes since the last drink,
raises a gentle silent banner at 60 minutes, and counts a drink complete
when you gaze at the cup steadily after drinking — then restarts the
timer.

## Design contract

- **Drinking itself is not measured, and the UI never pretends it
  is.** "Looking at the cup" is only a proxy for drinking: the
  agent records that you looked toward the registered cup direction
  and held steady, not that water passed your lips. A drink count
  here means "you confirmed a drink by gazing at the cup", and the
  UI and README say exactly that.
- **The cup position is a registered direction, not a tracked
  location.** Registration stores the direction you were looking
  when you held steady — there is no indoor positioning, no camera
  tracking, and no way for the agent to know the cup moved. If the
  cup moves, re-register it, and the README says so.
- **The gentle reminder is a silent banner, never a spoken
  interruption.** Reaching 60 minutes opens the banner in view and
  speaks nothing; SPEAK reads the reminder only when you tap it.
  "轻轻" is implemented as silence, not as a quieter voice.
- **A nod is never a drink.** A steady nod registers the cup in
  idle and confirms the summary; in watching and in remind it is
  ignored and noted. Counting a nod as a drink would be a lie
  about what you did, so the code refuses it in both modes.
- **The interval is wall-clock time, not gaze time.** Unlike
  eye-rest, where a moving head pauses the timer, the minutes
  since the last drink pass whether or not the head is moving.
  Only the registration and the drink confirm need a steady gaze.
- **One reminder per interval, then silence until the next
  drink.** Reaching the threshold raises the banner once; BACK
  out of a reminder does not clear the debt — the interval is
  kept, so the next tick re-raises it. Looking away from the
  banner is not a drink.
- **Correction is cheap, destruction is confirmed.** BACK from
  remind returns to watching with the interval still owed; BACK
  from watching returns to idle with the round kept, and REG
  resumes the same round; BACK from the summary returns to
  watching without deleting anything, and the summary is rebuilt
  on END. Confirming the summary (END while a summary is open,
  or a steady nod) is the only wipe. There is no DEL key.
- **The round lives in session memory only — zero persistence,
  by design.** Cup position, interval, drink/reminder counts and
  the summary die when the summary is confirmed and when the
  agent closes (onUnload wipes everything and stops the timer).
  Close the agent and the water-watch round is gone.
- **Not health advice.** The agent does not diagnose dehydration,
  does not promise any hydration effect, and does not set a
  medical schedule: 60 minutes is a plain timer threshold, and
  the UI and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK names
  counts in watching, reads the reminder in remind mode, and
  reads the summary — and never invents a reading. There is no
  ticker beyond the one-minute timer tick: every transition is
  a tap, a nod, a steady gaze or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `eye-rest` (B01) is the near-gaze timer: it
  counts steady near gaze and confirms a far look by head pitch.
  Water-watch borrows the timer shape but watches a body habit,
  not a gaze: its timer is wall-clock since the last drink and
  its confirmation is a steady gaze at the cup, not a pitch.
- Attention-series `guest-watch` (S02) is the guest seat register
  plus timed tea-level glance-backs plus a door SCAN. Water-watch
  registers no guests and scans nothing: it registers one cup
  direction and counts your own drinks.
- Attention-series `standup-echo` (S04) is the standup module-
  keyword gate: hits become notes, non-hits become digest rows.
  Water-watch has no keywords and no notes: its only input is a
  registered direction plus minutes, its only output is a gentle
  banner and a count.

## Permissions

Empty array (app.json `permissions` is exactly `[]`, and the
static check asserts exactly that): head-orientation events plus
a timer plus a banner need no permission. No `CAMERA`:
nothing is photographed. No `RECORD_AUDIO`: nothing is
listened to. No `GEOLOCATION`: this agent never knows where
anyone is.

## Validation

- Node harness (see `/tmp/water-watch-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero storage/
  location/camera/recorder/getUserMedia APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted （喝水本身测不出来、看向水杯只是代理、不是你真的喝
  了水、水杯挪了位置要重新登记、不是健康建议、不承诺补水
  效果、只存本次会话、没有室内定位、没有摄像头、零落盘）;
  initial idle state （bigText 还没登记， 3 info rows,
  countLine); idle refusals (END naming REG, DRINK ignored,
  BACK ignored, NEXT/PREV wrap, rowTap out-of-range and
  missing-dataset guards); REG discipline (refused while head
  moving, steady REG starts watching, refused while watching);
  tick discipline (wall-clock 45 min no reminder, 65 min opens
  remind, reminds 1, zero TTS throughout, tick ignored in
  remind); DRINK discipline (refused while head moving, steady
  DRINK confirms, interval 65 recorded as longest, timer
  reset, second drink keeps longest); BACK round-keeping
  (watching->idle keeps round, REG resumes it) and remind
  debt (BACK keeps the interval, next tick re-raises);
  summary flow (END out with totals 1/70/1, BACK rebuilds,
  END confirms and clears, timer stopped); nod discipline
  (unsteady ignored without arming, steady nod in idle
  registers, lock blocks a second nod, lock expiry works, nod
  in watching/remind ignored with the not-a-drink note, steady
  nod in summary confirms); key discipline (Enter registers
  in idle, ignored in watching, ArrowUp/Down walk, Backspace
  returns); SPEAK lines per mode (idle, watching counts,
  remind line only on explicit tap, summary line); DEMO
  five-stage arc (registered, 45 min watching, remind at
  65 min with zero TTS, drink confirmed, summary 1/65/1) and
  refusal on user sessions; onUnload wipes everything;
  bigCls thresholds.
  Result: **97/97** (first run 95/97, the 2 failures both
  harness-side: two nods fired inside the 1.2 s lock window —
  fixed in the harness with a lock-expiry wait, page code
  untouched).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not registered), watching (DEMO stage
  2, 45 min since last drink), remind (DEMO stage 3, 65 min,
  silent banner open), confirmed (DEMO stage 4, drink 1
  confirmed, timer reset), summary (DEMO stage 5, drinks 1,
  longest 65 min, reminds 1). Button coordinates were probed
  per state and every PNG re-verified by eye (see
  `shot-water-watch.js` in `~/workspace/preview-tools/`).
