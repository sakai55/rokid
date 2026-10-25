# Snack Aware — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series BO05 (BODY 身体型， fifth of the group, series #45, closing the
group): you eat snacks without noticing — one hand keeps reaching while
you work, and by the time you look up the bag is gone. This agent takes
the counting off your hands: it registers the snack direction on a
steady gaze, shows "this is look N today" on every steady look at the
snack, counts only and never intervenes, then closes with a session
summary.

## Design contract

- **A look at the snack is not eating, and the UI never pretends
  it is.** The agent counts steady gazes toward the registered snack
  direction, not bites, not bags. A count here means "you looked at
  the snack and held steady", and the UI and README say exactly
  that — "看向零食不等于吃了".
- **It counts only and never intervenes.** It does not stop you,
  judge you, or give diet advice: whether you eat is your decision.
  The banner is information, not a verdict, and there is no advice
  copy anywhere in the page. It is not a health-management tool.
- **The snack position is a registered direction, not a tracked
  location.** Registration stores the direction you were facing
  when you held steady (the yaw angle, if the host delivered one;
  otherwise just "registered"). There is no indoor positioning, no
  camera tracking, and no way for the agent to know the snack
  moved. If the snack moves, re-register it, and the README says
  so. A look is confirmed by a steady gaze (LOOK), not by a yaw
  comparison — the page never pretends it can verify you are
  really looking at the snack.
- **A look is silent, never a spoken interruption.** Every steady
  look opens the "这是今天第 N 次" banner and speaks nothing;
  SPEAK reads the count only when you tap it. Silence is the
  point: the count must not break your work to announce itself.
- **"Today" means this session, not the calendar day.** The count
  lives in session memory only and dies when the summary is
  confirmed and when the agent closes. The banner's "今天第几次"
  is the session count, and the UI and README say so — it is
  not a cross-day total, and storing one would be misleading.
- **A nod is never a look.** A steady nod registers the snack in
  idle and confirms the summary. In watching a nod is ignored and
  noted: a look is a steady gaze at the snack, and counting a nod
  as a look would be a lie about what you did. LOOK (or Enter in
  watching) is the only count action, and only while watching
  with a steady head.
- **Correction is cheap, destruction is confirmed.** BACK from
  watching returns to idle with the session kept, and REG resumes
  it; BACK from the summary returns to watching without deleting
  anything, and the summary is rebuilt on END. Confirming the
  summary (END while a summary is open, or a steady nod) is the
  only wipe. There is no DEL key.
- **The session lives in session memory only — zero persistence,
  by design.** Registration, look count and the summary die when
  the summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the snack-watch round
  is gone.
- **Not health or diet advice.** The agent does not diagnose
  anything, does not promise any health effect, and does not set
  a dietary schedule: the count is a plain counter, and the UI
  and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). There is no
  ticker: every transition is a tap, a nod, a steady gaze or a
  key — a snack count is event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `water-watch` (BO02) is the cup-direction
  register plus a wall-clock drink interval plus a steady-gaze
  drink confirm. Snack-aware borrows the register shape but
  counts no habit and raises no reminder: its only input is a
  registered direction plus steady looks, its only output is
  the running count plus a session summary.
- Attention-series `stand-move` (BO04) is head-activity plus
  still-time monitoring with an over-threshold stand-up reminder
  and a look-around sweep confirm. Snack-aware watches no
  stillness and reminds nothing: it registers one snack
  direction and counts looks at it, silently.
- Attention-series `guest-watch` (SO02) is the guest seat register
  plus timed tea-level glance-backs plus a door SCAN.
  Snack-aware registers no guests and scans nothing: it
  registers one snack direction and counts your own looks.

## Permissions

Empty array (app.json `permissions` is exactly `[]`, and the
static check asserts exactly that): head-orientation events plus
a counter plus a banner need no permission. No `CAMERA`:
nothing is photographed. No `RECORD_AUDIO`: nothing is
listened to. No `GEOLOCATION`: this agent never knows where
anyone is.

## Validation

- Node harness (see `/tmp/snack-aware-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero storage/
  location/camera/recorder/getUserMedia APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted （看向零食不等于吃了、不是真的吃了几口、几包、只
  计数不干预、不阻止、不评判、不给饮食建议、不是健康管理
  工具、不是定位追踪、零食挪了位置要重新登记、本次会话内
  的次数、不是跨天累计、只存本次会话、关掉即清、没有室内
  定位、没有摄像头、零落盘）; initial idle state （bigText
  还没登记， registered false, looks 0, 3 info rows);
  idle refusals (END naming REG, LOOK ignored, BACK ignored,
  NEXT/PREV wrap, rowTap out-of-range and missing-dataset
  guards); REG discipline (unsteady refused, steady REG starts
  watching and records the snack yaw, refused while watching);
  LOOK discipline (unsteady refused, steady LOOK counts with
  the "这是今天第 N 次" banner and exactly zero TTS);
  BACK round-keeping (watching->idle keeps session, REG
  resumes it); summary flow (END out with looks, BACK
  rebuilds, END confirms and clears); nod discipline (unsteady
  ignored without arming, steady nod in idle registers, lock
  blocks a second nod, lock expiry works, nod in watching
  ignored with the not-a-look note, non-nod gesture noted,
  steady nod in summary confirms); key discipline (Enter
  registers in idle, counts in watching, Backspace returns,
  idle Backspace ignored); SPEAK lines per mode (idle,
  watching count, summary count); DEMO four-stage arc
  (registered, look 1, looks 3, summary looks 3) and refusal
  on user sessions; onUnload wipes everything; bigCls
  thresholds.
  Result: **119/119** (first run 118/119, the 1 failure was a
  real page bug, not a harness bug: rowTap on a missing
  dataset silently jumped focus to 0 instead of keeping it —
  fixed in the page to return early, harness untouched after
  that).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not registered), watching (DEMO stage
  1, snack registered, looks 0), look 1 (DEMO stage 2, "这是
  今天第 1 次"), looks 3 (DEMO stage 3, multiple counts),
  summary (DEMO stage 4, looks 3). Button coordinates were
  probed per state and every PNG re-verified by eye (see
  `shot-snack-aware.js` in `~/workspace/preview-tools/`).
  Probe finding worth keeping: DEMO is a staged sample, not
  a live watch — the steady flag and the direction are staged
  too, so the preview frames are deterministic.
