# Noise Map — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series E03 (AMBIENT 环境型， third of the group, series #48): you want
the quietest corner at home or in the office to work in, and picking by
feel always picks wrong. This agent takes the picking off your hands:
you turn your head a full circle, one SCAN tap per sector records the
mic level, 8 sectors form a noise direction map, and the quietest
direction is announced once by voice.

## Design contract

- **Level is not recognition, and the UI never pretends it
  is.** The platform has no sound classification API. A level
  (low / mid / high) says only how loud a direction is, never
  what the sound is — speech, air conditioning and
  construction noise are indistinguishable, and the UI and
  README say exactly that.
- **Grades are relative, not decibels.** There is no
  calibrated sound-pressure meter on the platform. The RMS
  thresholds (low < 0.15, mid < 0.4, high above) are fixed
  grades, not dB readings, and the README says so.
- **The quietest direction is relative within this scan.**
  It is the lowest grade among the 8 sectors just scanned,
  first on ties — not an absolute guarantee of quiet. A
  louder room can still have a "quietest" corner.
- **Sectors are recorded in clockwise order, not verified
  by yaw angle.** You turn right one sector per SCAN tap and
  the agent records in fixed order (front, front right,
  right, ...). It does not verify that your head actually
  points at each sector, and the README says so.
- **One announcement per map.** The quietest direction is
  spoken exactly once when the 8th sector completes the map.
  RESCAN speaks nothing; SPEAK re-reads only on an explicit
  tap.
- **A nod never records a level and never completes a map.**
  A level comes from the microphone, a map from 8 recorded
  sectors — a nod must not invent either. A steady nod in
  idle starts a scan and in summary confirms it.
- **Correction is cheap, destruction is confirmed.** BACK
  from scanning or map returns to idle with the session
  kept, and START resumes the same round; BACK from the
  summary returns to the mode it came from without deleting
  anything, and the summary is rebuilt on END. Confirming
  the summary (END while a summary is open, or a steady
  nod) is the only wipe. There is no DEL key.
- **The session lives in session memory only — zero persistence,
  by design.** Sectors, maps, rounds and the quietest
  direction die when the summary is confirmed and when the
  agent closes (onUnload wipes everything). Close the agent
  and the noise-map round is gone.
- **Not a sound meter, not a health tool.** The agent does
  not measure decibels, does not identify sounds, and does
  not adapt its thresholds to the room: the thresholds are
  fixed grades, and the UI and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). The map
  announcement speaks once; SPEAK re-reads only on an
  explicit tap.
- **Microphone mode honesty (fleet audit conclusion).** Any
  mic mode applies only to the getUserMedia stream; it does
  not change the host SpeechRecognition pickup. The UI and
  README say exactly that.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `light-change` (E01) is timed camera
  metering plus a below-threshold lamp reminder. Noise-map
  uses no camera at all: it samples mic levels while you
  turn, and its output is a direction map, not a lamp
  reminder.
- Attention-series `sky-watch` (E02) registers a drying
  direction, meters the sky on a timer, and warns on a big
  brightness drop. Noise-map registers nothing and meters
  nothing on a timer: it scans 8 directions in one turn and
  names the quietest one.
- Attention-series `eye-rest` (B01) times near vision and
  reminds you to look far. Noise-map times nothing: it maps
  sound by direction in a single turn.

## Permissions

RECORD_AUDIO only (app.json `permissions` is exactly
`["RECORD_AUDIO"]`, and the static check asserts exactly
that): scanning sector levels needs the microphone. No
`CAMERA`: nothing is photographed. No `GEOLOCATION`: this
agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/noise-map-harness.js`, not packed):
  app.json pages and permissions exactly `["RECORD_AUDIO"]`;
  zero storage/location/camera APIs, no utterance language
  assignment, no legacy Page/App; mic level sampling via
  getUserMedia audio asserted; foot2 honesty lines asserted
  （电平不等于识别、没有声音分类、相对分级、不是分贝读数、
  相对最低、不是绝对安静保证、收音模式只影响 getUserMedia
  流的拾音、不改变宿主 ASR 的拾音、不单独验证每个方向角、
  只存本次会话、关掉即清、没有室内定位、零落盘）; initial
  idle state （bigText 还没开始， sectors all null, scanned
  0, rounds 0, quietest null, 8 info rows); idle refusals
  (SCAN/RESCAN/END/BACK naming START); start + scan
  discipline (START refused while scanning, RESCAN refused
  while scanning, 1/8 and 7/8 still scanning with zero TTS,
  8/8 completes the map with rounds 1, quietest 左后, exactly
  one TTS naming it, 9th record ignored); tie rule (first
  lowest wins); mic failure path (no mic on the Node host:
  failure noted, zero counts); _gradeRms thresholds
  (0.05 low, 0.149 low, 0.15 mid, 0.39 mid, 0.4 high, 0.9
  high); rescan discipline (clears sectors/scanned/
  quietest, keeps rounds, speaks nothing); summary flow
  (END from map, BACK rebuilds, END confirms and clears,
  END from scanning keeps scanned for BACK rebuild);
  BACK-to-idle keeps session with START resume; focus
  walks 8 rows with wrap, rowTap out-of-range and
  missing-dataset guards (missing dataset keeps focus,
  never jumps to 0 — the B05 page bug, fixed here by
  construction); nod discipline (unsteady ignored without
  arming, steady nod in idle starts, lock blocks a second
  nod, lock expiry works, nod in scanning ignored as not a
  level, nod in map ignored, steady nod in summary
  confirms); key discipline (Enter per-mode, ArrowUp/Down
  walk, Backspace returns); SPEAK lines per mode; DEMO
  three-stage arc (scanning 4/8, map complete quietest
  左后 with one TTS, summary rounds 1) and refusal on user
  sessions; onUnload wipes everything; bigCls thresholds.
  Result: **128/128** (first run 126/128, the 2 failures
  both harness-side character miscounts in bigCls test
  strings — fixed in the harness, page code untouched).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not started), scanning (DEMO stage
  1, 4/8 sectors), map complete (DEMO stage 2, quietest
  左后, one TTS), rescan (fresh map then RESCAN, scanning
  0/8 with rounds 1 kept), summary (DEMO stage 3, rounds 1,
  quietest 左后). A focus-walk frame (NEXT x5 to the
  quietest row) was shot but discarded: the 8-row list is
  80px tall, so the 左后 row sits below the fold and the
  frame shows only EVT focus -> 6.
  Button coordinates were probed per state and every PNG
  re-verified by eye (see `shot-noise-map.js` in
  `~/workspace/preview-tools/`).
  Probe finding worth keeping: DEMO is a staged sample, not
  a live scan — levels are staged grades, not mic readings.
