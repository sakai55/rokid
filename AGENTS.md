# Light Change — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series E01 (AMBIENT 环境型， first of the group, series #46): you get so
absorbed in reading or handwork that night falls and you are still
working in dim light without noticing. This agent takes the light
watch off your hands: it meters the light on a timer, warns in view
when it drops below threshold, and closes with a session summary.

## Design contract

- **There is no ambient light sensor, and the UI never pretends
  there is.** A "reading" is one camera photo graded by average
  brightness into bright / dim / dark. It is not a lux value, it
  is not calibrated, and the thresholds are fixed grades. The UI
  and README say exactly that — "照片亮度只是近似估计，不是
  精确光照度".
- **The photo is used for one reading and discarded.** It is
  never stored, never uploaded, never shown anywhere: the page
  keeps only the grade (bright / dim / dark) and the counts.
  A photo that survived the reading would be a different agent
  and a different permission story.
- **Dim warns nothing; dark warns once.** A dim reading only
  shows "偏暗" and keeps watching. A dark reading opens the
  reminder and speaks exactly once ("光线暗了，开灯吧"); later
  dark readings while the reminder is open raise no second
  reminder and no second announcement.
- **A lamp confirm is LIGHT or a later bright reading.** Tapping
  LIGHT closes the reminder and counts a confirm. A later bright
  reading also lifts the reminder and counts a confirm, because
  the room is bright again. A nod never meters and never
  confirms the lamp: a reading comes from the camera, and a
  lamp confirm comes from LIGHT or a bright reading — a nod
  must not invent either.
- **Timed re-metering is a timer, and DEMO stops it.** While
  watching, a 10-minute timer attempts a reading. DEMO stops
  the timer so real ticks cannot drift the staged frames:
  DEMO is a staged sample, not a live watch, and the readings
  in it are staged grades.
- **Correction is cheap, destruction is confirmed.** BACK from
  watching returns to idle with the session kept, and START
  resumes it; BACK from the summary returns to watching without
  deleting anything, and the summary is rebuilt on END.
  Confirming the summary (END while a summary is open, or a
  steady nod) is the only wipe. There is no DEL key.
- **The session lives in session memory only — zero persistence,
  by design.** Readings, reminders and confirmations die when
  the summary is confirmed and when the agent closes (onUnload
  wipes everything and stops the timer). Close the agent and
  the light-watch round is gone.
- **Not medical advice.** The agent does not diagnose vision
  problems, does not promise any eye-protection effect, and
  does not adapt its threshold to your eyes: the threshold is
  a fixed grade, and the UI and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). A dark
  reminder speaks once; SPEAK re-reads only on an explicit tap.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `room-sweep` (C02) is the pre-leaving room
  sweep: look at each item in turn and confirm it before you
  go out. Light-change photographs nothing for confirmation:
  its only photo use is a brightness grade, discarded at once.
- Attention-series `eye-rest` (B01) is near-vision timing plus
  a 20-minute look-far reminder plus a look-up confirm.
  Light-change times no gaze and asks for no look-up: it
  meters light on a timer and reminds you to turn the lamp on.
- Attention-series `snack-aware` (B05) is a registered snack
  direction plus silent look counts. Light-change registers
  no direction and counts no looks: it meters light and
  counts reminders and lamp confirms.

## Permissions

CAMERA only (app.json `permissions` is exactly `["CAMERA"]`,
and the static check asserts exactly that): timed metering
needs one photo per reading. No `RECORD_AUDIO`: nothing is
listened to. No `GEOLOCATION`: this agent never knows where
anyone is.

## Validation

- Node harness (see `/tmp/light-change-harness.js`, not packed):
  app.json pages and permissions exactly `["CAMERA"]`;
  zero storage/location/recorder APIs, no utterance language
  assignment, no legacy Page/App; foot2 honesty lines asserted
  （没有环境光传感器、不是勒克斯读数、照片亮度只是近似、
  照片只用于当次测光、会话内即弃、不存档、不上传、不是
  医疗建议、不诊断视力问题、不承诺护眼效果、阈值是固定
  档位、只存本次会话、关掉即清、没有室内定位、零落盘）;
  initial idle state （bigText 还没开始， checks/reminds/
  lights 0, level null, 3 info rows, timer null); idle
  refusals (END naming START, METER/LIGHT ignored naming
  START, BACK ignored, NEXT/PREV wrap, rowTap out-of-range
  and missing-dataset guards); START discipline (timer set,
  refused while watching, BACK stops timer and keeps
  session, START resumes); meter failure path (no camera on
  the Node host: failure noted, zero counts); _applyReading
  rules (bright counts with zero TTS, dim counts with no
  reminder and zero TTS, dark opens the reminder with
  exactly one TTS, a second dark raises nothing new, a
  bright reading lifts the reminder and counts a confirm,
  LIGHT ignored with no reminder, LIGHT confirms);
  _gradePhoto thresholds (stubbed canvas: 255 -> bright,
  100 -> dim, 10 -> dark); summary flow (END out with
  counts, BACK rebuilds, END confirms and clears, timer
  stopped); nod discipline (unsteady ignored without arming,
  steady nod in idle starts, lock blocks a second nod, lock
  expiry works, nod in watching ignored with the not-a-meter
  note, steady nod in summary confirms); key discipline
  (Enter starts in idle and meters in watching, ArrowUp/Down
  walk, Backspace returns); SPEAK lines per mode (idle,
  watching per level, reminder re-read, summary counts);
  DEMO six-stage arc (bright, dim, dark reminder with one
  TTS, lamp confirmed, summary checks 3 reminds 1 lights 1)
  and refusal on user sessions; onUnload wipes everything
  and clears the timer; bigCls thresholds.
  Result: **145/145** (first run 142/145, the 3 failures all
  harness-expectation bugs — a foot2 phrase the page worded
  differently, a summary count I miscounted, a bigCls test
  string of the wrong length — the foot2 wording was also
  tightened in the page, page logic untouched otherwise).
- Preview screenshots 6, each visually verified (not just
  hash-compared): idle (not started), watching bright (DEMO
  stage 1, checks 1), dim (DEMO stage 2, checks 2, no
  reminder), dark reminder (DEMO stage 3, checks 3, reminder
  open), lamp confirmed (DEMO stage 4, lights 1), summary
  (DEMO stage 5, checks 3 reminds 1 lights 1). Button
  coordinates were probed per state and every PNG
  re-verified by eye (see `shot-light-change.js` in
  `~/workspace/preview-tools/`).
  Probe finding worth keeping: DEMO is a staged sample, not
  a live watch — the timer is stopped in DEMO so staged
  frames cannot drift, and the readings are staged grades.
  Idle DEMO band probed at y170-185 (x=66); y150-165 miss and
  y190 hits NEXT (EVT focus only, a fake hit). Unlike B01,
  the band did not shift across states here: y170 drove all
  six DEMO stages, each frame eye-verified.
