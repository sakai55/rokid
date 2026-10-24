# Sky Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series E02 (AMBIENT 环境型， second of the group, series #47): you hang
laundry or bedding out, go out, and never notice when the sky clouds
over — you come home to everything soaked. This agent takes the sky
watch off your hands: it registers the drying area before you go out,
reminds you on a timer to look back at the sky, warns once by voice
when the brightness drops a lot, and closes with a session summary.

## Design contract

- **It cannot tell the weather, and the UI never pretends it
  can.** There is no weather forecast and no rain sensor. A
  "reading" is one camera photo graded by average brightness
  into bright / dim / dark. A warning fires only on a BIG drop:
  two grade steps down from the last reading (bright -> dark).
  A one-step slide (bright -> dim, dim -> dark) is shown but
  warns nothing. The brightness drop is a proxy signal for
  thicker cloud, not a rain forecast, and the UI and README say
  exactly that.
- **The photo is used for one reading and discarded.** It is
  never stored, never uploaded, never shown anywhere: the page
  keeps only the grade (bright / dim / dark) and the counts.
  A photo that survived the reading would be a different agent
  and a different permission story.
- **Timed reminder is silent; cloud warning speaks once.** A
  timed sky-check reminder opens a banner and speaks nothing.
  A big-drop warning opens and speaks exactly once ("天空变暗了，
  可能是云层变厚，回去看看晾晒"); later dark readings while the
  warning is open raise no second warning and no second
  announcement. One open banner at a time: a timed reminder
  while a banner is open is skipped, not double-counted.
- **A bright reading lifts a warning but counts no look-back.**
  If the sky is bright again, the warning has no reason to
  stay, so it lifts. Only SKY counts a look-back: the agent
  never invents one from a reading.
- **The mark is your decision, never the agent's.** MARK cycles
  已看 -> 要收 -> 不收, and SKY records whichever one is
  showing. The agent never decides whether the laundry comes
  in; "收不收衣服最终由你回看判断" is in the UI and README.
- **Registration needs a steady look.** REG in idle requires a
  steady head (look at the drying area and hold steady); a
  moving head is refused. START requires registration first:
  watching without a registered drying area is refused. A
  steady nod in idle registers (or starts once registered).
- **A nod never meters and never confirms a look-back.** A
  reading comes from the camera, and a look-back comes from
  SKY — a nod must not invent either. A nod in watching is
  ignored and noted.
- **Timed metering and timed reminders are timers, and DEMO
  stops them.** While watching, a 10-minute timer attempts a
  reading and a 30-minute timer raises a sky-check reminder.
  DEMO stops both timers so real ticks cannot drift the staged
  frames: DEMO is a staged sample, not a live watch, and the
  readings in it are staged grades.
- **Correction is cheap, destruction is confirmed.** BACK from
  watching returns to idle with the session and the
  registration kept, and START resumes it; BACK from the
  summary returns to watching without deleting anything, and
  the summary is rebuilt on END. Confirming the summary (END
  while a summary is open, or a steady nod) is the only wipe,
  and it clears the registration too: a new outing registers
  again. There is no DEL key.
- **The session lives in session memory only — zero persistence,
  by design.** Registration, readings, reminders, warnings and
  look-backs die when the summary is confirmed and when the
  agent closes (onUnload wipes everything and stops both
  timers). Close the agent and the sky-watch round is gone.
- **Not a weather tool.** The agent does not forecast, does not
  diagnose anything, and does not adapt its threshold to the
  weather: the threshold is a fixed grade, and the UI and README
  say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). A cloud warning
  speaks once; SPEAK re-reads only on an explicit tap.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `light-change` (E01) is timed camera metering
  plus a below-threshold lamp reminder. Sky-watch reuses the
  same brightness grading but registers a drying area first,
  adds timed sky-check reminders, and warns only on a big
  two-step drop — it never mentions a lamp.
- Attention-series `eye-rest` (B01) is near-vision timing plus
  a 20-minute look-far reminder plus a look-up confirm.
  Sky-watch times no gaze and asks for no look-up: it meters
  the sky on a timer and warns on a big brightness drop.
- Attention-series `snack-aware` (B05) is a registered snack
  direction plus silent look counts. Sky-watch registers a
  drying direction too, but its counts are readings, timed
  reminders, cloud warnings and marked look-backs — not looks
  at a snack.

## Permissions

CAMERA only (app.json `permissions` is exactly `["CAMERA"]`,
and the static check asserts exactly that): timed metering
needs one photo per reading. No `RECORD_AUDIO`: nothing is
listened to. No `GEOLOCATION`: this agent never knows where
anyone is.

## Validation

- Node harness (see `/tmp/sky-watch-harness.js`, not packed):
  app.json pages and permissions exactly `["CAMERA"]`;
  zero storage/location/recorder APIs, no utterance language
  assignment, no legacy Page/App; foot2 honesty lines asserted
  （没有天气预报、没有雨滴传感器、亮度下降只是云层变厚的
  代理信号、不是下雨预报、照片只用于当次测光、会话内即弃、
  不存档、不上传、不是气象工具、收不收衣服最终由你回看判断、
  阈值是固定档位、只存本次会话、关掉即清、没有室内定位、
  零落盘）; initial idle state （bigText 还没登记， registered
  false, checks/reminds/alerts/looks 0, level null, 3 info rows,
  both timers null); idle refusals (START naming REG, END
  naming REG, METER/SKY/MARK ignored naming START, BACK naming
  REG, NEXT/PREV wrap, rowTap out-of-range and missing-dataset
  guards); REG discipline (moving refused, steady registers,
  double REG refused); START discipline (timer pair set,
  refused while watching, REG refused while watching, BACK
  stops timers and keeps session + registration, START resumes);
  meter failure path (no camera on the Node host: failure noted,
  zero counts); _applyReading rules (bright zero TTS, dim no
  warning, dim->dark one step warns nothing, bright->dark big
  drop warns exactly once with the cloud text, second dark
  raises nothing new, bright lifts the warning with no
  look-back counted); _reminderTick rules (silent banner,
  no double count while open); SKY + MARK rules (SKY ignored
  with nothing open, MARK cycles 已看 -> 要收 -> 不收 -> 已看,
  SKY records the mark and clears both banners, counts one
  look); _gradePhoto thresholds (stubbed canvas: 255 -> bright,
  100 -> dim, 10 -> dark); summary flow (END out with counts,
  BACK rebuilds, END confirms and clears including
  registration); nod discipline (unsteady ignored without
  arming, steady nod in idle registers then starts, lock
  blocks a second nod, lock expiry works, nod in watching
  ignored with the not-a-meter note, steady nod in summary
  confirms); key discipline (Enter registers/starts/meters per
  mode, ArrowUp/Down walk, Backspace returns); SPEAK lines per
  mode (idle unregistered/registered, watching per state,
  alert re-read, summary counts); DEMO six-stage arc
  (registered + bright, timed reminder silent, big-drop cloud
  warning with one TTS, look-back confirmed mark 已看, summary
  checks 2 reminds 1 alerts 1 looks 1) and refusal on user
  sessions; onUnload wipes everything and clears both timers;
  bigCls thresholds.
  Result: **192/192** (first run, no harness fixes, page code
  untouched).
- Preview screenshots 6, each visually verified (not just
  hash-compared): idle (not registered), watching bright (DEMO
  stage 1, registered, checks 1), timed reminder (DEMO stage 2,
  reminds 1, silent), cloud warning (DEMO stage 3, big drop
  bright->dark, alerts 1, one TTS), look-back confirmed (DEMO
  stage 4, looks 1, mark 已看, banners cleared), summary (DEMO
  stage 5, checks 2 reminds 1 alerts 1 looks 1). Button
  coordinates were probed per state and every PNG
  re-verified by eye (see `shot-sky-watch.js` in
  `~/workspace/preview-tools/`).
  Probe finding worth keeping: DEMO is a staged sample, not
  a live watch — both timers are stopped in DEMO so staged
  frames cannot drift, and the readings are staged grades.
