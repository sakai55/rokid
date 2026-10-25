# Day Lookback — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series RE01 (REVIEW 回顾型， first of the group): in the evening, replay
the day as an attention timeline — every gaze you registered during the
day (a scene, a number, a promise) with its time and the direction you
were facing, in time order, filterable by type, then a summary.

## Design contract

- **The timeline is a register, a replay and a filter — never a
  recording.** MARK records one entry: the current TYPE (画面 /
  数字 / 承诺), the current DESC (one sentence you chose), the
  current DIR (the direction you were facing when you marked it),
  and the clock time at the tap. Nothing is photographed,
  recorded or located: the description is a sentence you picked,
  the direction is a direction you picked, the time is the tap's
  clock time. REPLAY walks the entries in the order they were
  marked; FILTER cycles 全部 / 画面 / 数字 / 承诺 and shows only
  that type; END closes the day with a summary (counts per type,
  first and last time).
- **The timeline lives in one open session — zero persistence,
  by design, and the price is stated, not hidden.** "Mark during
  the day, replay in the evening" is naturally cross-session,
  but the fleet zero-persistence rule forbids every wx storage
  API, so this agent implements a single-session timeline:
  registering and replaying happen in the same open session, and
  everything dies on summary confirm and onUnload. The UI foot2
  and the README say so in plain words: to mark during the day
  and replay in the evening you keep it open that day (or open
  it per stretch and replay that stretch). No storage API was
  added to make cross-session work — whether to break the rule
  for this agent is GO's call, not this build's.
- **A nod never picks a type, a sentence or a direction.** A
  steady nod marks one entry (register), advances the timeline
  by one (replay), or confirms the summary. It never changes
  TYPE, DESC or DIR: those are selections, and a nod must not
  silently pick one. An unsteady nod never arms the 1.2 s lock
  (the fleet fix, kept).
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to replay without deleting anything; the
  summary is rebuilt on END. BACK from replay returns to
  registering with entries kept. Confirming the summary (END
  while a summary is open, Enter, or a steady nod) is the only
  wipe. There is no DEL key: there is nothing to clear that
  would not also lie about the timeline state.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks five stages: scene marked (DEMO sample, 前方) → number
  marked (DEMO sample, 右前方) → promise marked (DEMO sample,
  后方) → replay filtered to 承诺 (1 of 3 visible) → summary
  (3 entries: 画面 1, 数字 1, 承诺 1). A sixth DEMO tap reports
  the demo complete. DEMO refuses outright if user entries
  exist or a user replay is under way. Every step is labelled
  DEMO; the sample sentences and directions are labelled as
  samples.
- **The day lives in session memory only — zero persistence,
  by design.** Entries, filter, focus and counts die when the
  summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the day is gone,
  which is the honest price of the rule (see above).
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). There is no
  ticker: every transition is a tap, a nod or a key — a
  timeline is event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `last-glance` (CO01) is the leaving-archive
  template: it photographs zones on leaving and replays them.
  Day-lookback photographs nothing: its "scenes" are sentences
  you picked, and its timeline covers the whole day, not one
  departure.
- Attention-series `talk-replay` (RE02, next) is the
  conversation-replay template: it will replay a talk's
  subtitles filtered to promises + numbers + deadlines.
  Day-lookback is not a talk: it has no subtitles, no speakers
  and no deadlines — its entries are gazes you marked, typed
  画面 / 数字 / 承诺.
- Attention-series `queue-roam` (DU05) is the sibling template:
  same nod discipline, same zero-persistence rule, same DEMO
  five-stage arc, same button-band layout — but its gate is a
  ticket number and its reminder is a number gap. Day-lookback
  has no gate and no reminder: its core is mark → replay →
  filter → summary.

## Permissions

No permissions at all (`permissions` is `[]` in app.json, and
the static check asserts exactly that): marking a gaze and
replaying a timeline needs no camera, no microphone and no
position. No `CAMERA`: nothing is photographed — the "scene" is
a sentence you picked, and photographing zones is last-glance's
job. No `RECORD_AUDIO`: nothing is listened to — there are no
subtitles here, and talk subtitles are talk-replay's job. No
`GEOLOCATION`: a direction you picked is not a position, and
this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/day-lookback-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero
  storage/camera/microphone/location APIs in the page source;
  no legacy Page/App/Widget; no utterance language assignment;
  foot2 honesty lines asserted (single-session limit, direction
  is not navigation, description is not a photo/recording
  original, no indoor positioning, zero persistence); initial
  register-empty state (bigText 还没记, placeholder row);
  bigCls thresholds; refusals in register-empty (REPLAY and
  END naming the missing mark, FILTER refused, confirm
  refused); TYPE/DESC/DIR cycles and wraps; MARK entries
  (fields, HH:MM time format, counts per type); NEXT/PREV wrap
  and rowTap focus with out-of-range and missing-dataset
  guards; replay + filter (all three types, empty-filter view
  with placeholder, NEXT ignored on empty); summary flow (END
  from replay, counts, first/last times, BACK rebuilds, END in
  summary confirms and clears); mode refusals (TYPE/DESC/DIR/
  MARK/REPLAY refused in replay); nod discipline (unsteady
  ignored without arming, steady nod marks in register,
  advances in replay, confirms in summary, lock blocks a
  second nod, lock expiry works, non-nod gestures noted); key
  discipline (Enter marks/advances/confirms, ArrowUp/Down cycle,
  Backspace ignored in register, returns to register from
  replay); SPEAK lines per mode; DEMO five-stage arc and
  refusal on user entries or user replay; onUnload wipes
  everything. Result: **105/105**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (nothing marked yet), marked (DEMO
  stage 3, 3 entries), replay-all (timeline replay, all 3
  entries), replay-filtered (replay filtered to 承诺, 1 of 3),
  summary (DEMO stage 5, 3 entries: 画面 1, 数字 1, 承诺 1).
  Button coordinates were probed per state and every PNG
  re-verified by eye (see `shot-day-lookback.js` in
  `~/workspace/preview-tools/`).
