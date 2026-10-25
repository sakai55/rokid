# Stand Move — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series B04 (BODY 身体型， fourth of the group, series #44): you sit all
morning and only notice you never stood up when your back already aches.
This agent takes the noticing off your hands: it watches head activity
plus still time, reminds you to stand up once a still threshold is
crossed, and takes one look-around sweep as the activity confirm, then
closes with a session summary.

## Design contract

- **A sweep is only a head-turn proxy, never proof you stood
  up.** There is no body sensor: the agent does not know
  whether you actually stood, walked, or stretched. A
  look-around (yaw past -20 and past +20, or the SWEEP button
  fallback) is the confirm the page accepts, and the UI and
  README say exactly that — "环视一圈只是头部转动代理，不
  是站立证明".
- **Head movement resets the still timer.** Any delivered
  orientation change while watching counts as activity: the
  still minutes reset to zero and the longest stretch is kept.
  This is deliberate — a head that keeps moving is not a
  still head — and it is why the threshold is a still-time
  threshold, not a clock-time one.
- **The reminder fires exactly once per threshold crossing.**
  Crossing into remind speaks "该起身活动了" once and opens
  the banner; further ticks while the reminder stands
  unconfirmed never speak again, so an unconfirmed reminder
  nags visually but never shouts repeatedly. BACK to idle
  keeps the session (and the standing reminder, if the
  summary came from remind); START resumes it.
- **A nod is never a stand-up.** A steady nod starts watching
  in idle and confirms the summary. In watching or remind a
  nod is ignored and noted: standing up is a look-around
  sweep, and counting a nod as a stand-up would be a lie
  about what you did. SWEEP is the only button confirm, and
  only while a reminder stands.
- **Yaw sweep is defensive.** If the host never delivers yaw
  events, the SWEEP button is the confirm, and the README
  says so — the agent never pretends yaw arrives on every
  device. A yaw event without a yaw value still counts as
  head movement while watching, but never advances the sweep.
- **The threshold is a fixed preset, not adaptive.** Two
  presets only: 45 and 60 minutes. MODE switches presets
  before starting only — never mid-watch, so a watch in
  progress is never silently re-timed.
- **Correction is cheap, destruction is confirmed.** BACK from
  watching or remind returns to idle with the session kept,
  and START resumes it; BACK from the summary returns to the
  mode it came from (watching, or remind with the reminder
  still standing) without deleting anything, and the summary
  is rebuilt on END. Confirming the summary (END while a
  summary is open, or a steady nod) is the only wipe. There
  is no DEL key.
- **The session lives in session memory only — zero
  persistence, by design.** Still minutes, stand-ups,
  reminders and the summary die when the summary is confirmed
  and when the agent closes (onUnload wipes everything and
  stops the timer). Close the agent and the sitting session
  is gone.
- **Not medical advice.** The agent does not diagnose back
  problems, does not promise any activity benefit, and does
  not set a medical schedule: the thresholds are plain timer
  presets. Severe discomfort means seeking professional help,
  dizziness means stopping at once — and the UI and README
  say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). There is no
  ticker beyond the one-minute timer tick: every transition
  is a tap, a nod, a key, a head movement, or the timer
  crossing the threshold.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `eye-rest` (B01) is the near-gaze timer: it
  counts steady near gaze and confirms a far look by head
  pitch. Stand-move borrows the timer shape but watches
  stillness, not gaze: its timer counts minutes since the
  last head movement, and its confirm is a yaw sweep, not a
  pitch-up.
- Attention-series `water-watch` (B02) is the cup-direction
  register plus a wall-clock drink interval plus a steady-gaze
  drink confirm. Stand-move registers no direction and counts
  no habit: its only input is head movement, its only output
  is a stand-up reminder plus a session summary. Its interval
  is still-time (head movement resets it), not wall-clock
  time like water-watch.
- Attention-series `breath-pace` (B03) is the in-view
  inhale-hold-exhale beat: it plays a fixed rhythm and counts
  rounds. Stand-move plays no beat: it watches for the
  absence of movement and asks for one sweep.

## Permissions

Empty array (app.json `permissions` is exactly `[]`, and the
static check asserts exactly that): head-activity monitoring
plus a timer plus a spoken reminder needs no permission. No
`CAMERA`: nothing is photographed. No `RECORD_AUDIO`:
nothing is listened to. No `GEOLOCATION`: this agent never
knows where anyone is.

## Validation

- Node harness (see `/tmp/stand-move-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero storage/
  location/camera/recorder/getUserMedia APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted （测不出你是不是真的站起来了、只是头部转动代理、
  不是站立证明、固定档位、不是医疗建议、不诊断腰背问题、
  不承诺活动效果、严重不适请寻求专业帮助、头晕立即停下、
  只存本次会话、关掉即清、没有室内定位、没有摄像头、
  零落盘）; initial idle state （bigText 还没开始， threshold
  45, still 0, 3 info rows); idle refusals (END naming START,
  SWEEP ignored, NEXT/PREV wrap, rowTap out-of-range and
  missing-dataset guards); MODE discipline (45 <-> 60 wrap,
  refused while watching); START discipline (starts watching,
  zero TTS on start, refused while watching, refused with a
  summary open); still clock (30 min no remind, 44 min no
  remind, movement resets still and keeps longest 44, 45 min
  crosses to remind with exactly one spoken reminder, remind
  ticks never speak again); sweep discipline (left-only
  yaw stays in remind, small yaw no right, left+right
  confirms to watching with stands 1 and still reset, SWEEP
  button fallback confirms, BACK keeps session and START
  resumes with still kept, re-cross reminds again); summary
  flow (END out with reminds/stands/longest, BACK rebuilds,
  END confirms and clears, summary from remind returns to
  remind on BACK); SPEAK lines per mode (idle, watching
  still minutes, remind stand-up line, summary counts);
  nod discipline (unsteady ignored without arming, steady
  nod in idle starts, lock blocks a second nod, lock expiry
  works, nod in watching and in remind ignored with the
  not-a-stand-up note, non-nod gesture noted, steady nod in
  summary confirms); key discipline (Enter starts, ignored
  in watching, sweeps in remind, Backspace returns, idle
  Backspace ignored); DEMO four-stage arc (watching still
  30, remind at 45 with 1 reminder, sweep-confirmed stands
  1, summary reminds 1 stands 1 longest 45) and refusal on
  user sessions; onUnload wipes everything; bigCls
  thresholds.
  Result: **135/135** (first run, no harness fixes).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not started), watching (DEMO stage
  1, still 30 min), remind (DEMO stage 2, threshold crossed,
  banner open), confirmed (DEMO stage 3, sweep confirmed,
  stand-ups 1), summary (DEMO stage 4, reminds 1, stands 1,
  longest 45 min). Button coordinates were probed per state
  and every PNG re-verified by eye (see
  `shot-stand-move.js` in `~/workspace/preview-tools/`).
  Probe finding worth keeping: DEMO is a staged sample, not
  a live watch — it stops the one-minute timer, otherwise
  live ticks would drift the still minutes between the DEMO
  tap and the screenshot.
