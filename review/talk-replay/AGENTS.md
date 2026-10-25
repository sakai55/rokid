# Talk Replay — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series R02 (REVIEW 回顾型， second of the group): after a talk with a
landlord, a client or a technician, replay the talk's subtitles filtered
to three kinds of sentences — promises, numbers, deadlines — so what
the other party promised, and by when, stops being a matter of
trying to remember.

## Design contract

- **The replay is a filter over subtitles, never a recording.**
  SEG receives one transcript segment (on device, host ASR feeds
  `onASRResult` into the same `_addSegment` path; in preview,
  SEG and DEMO feed it with labelled samples). Each segment
  carries the SIDE you marked （对方 / 自己）, the DIR you marked
  （前方 / 左前方 / 右前方 / 左方 / 右方 / 后方） and the clock time
  at receipt. REPLAY walks the segments in receipt order;
  FILTER cycles 全部 / 承诺 / 数字 / 期限 and shows only that
  kind; END closes the talk with a summary (counts per kind,
  counts per side, and the other party's promise sentences one
  by one). Nothing is photographed, recorded or located.
- **Three kinds are keyword matches, not semantic
  understanding.** A sentence is 承诺 if it contains 会 / 保证 /
  答应 / 负责 / 包 / 一定；数字 if it contains a digit or 元 /
  块 / 万 / 千 / 百；期限 if it contains 周 / 号 / 天内 / 之前 /
  月底 / 下周 / 明天 / 后天 / 截止. A sentence with 会 in it is
  not necessarily a promise, and a sentence the ASR misheard
  can be mis-sorted or missed. Replay lists candidates; the
  talk's real meaning is the user's call. The UI foot2 and the
  README say so in plain words.
- **The speaking side is a mark you switch, not voiceprint
  recognition.** SIDE defaults to 对方 and stays there until
  you tap it; every segment received takes the current SIDE.
  A segment received while SIDE was wrong is attributed to the
  wrong side — there is no speaker identification to correct
  it, and the README says so. Segments never carry a side the
  user did not mark.
- **A nod never adds a subtitle and never picks a side or a
  direction.** A steady nod advances the replay by one, or
  confirms the summary. In listen mode it is ignored with an
  explanation: subtitles arrive from the talk itself, and a nod
  must not invent one. An unsteady nod never arms the 1.2 s
  lock (the fleet fix, kept). SIDE and DIR are selections;
  a nod must not silently pick one.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to replay without deleting anything; the
  summary is rebuilt on END. BACK from replay returns to
  listening with segments kept. Confirming the summary (END
  while a summary is open, or a steady nod) is the only wipe.
  There is no DEL key: there is nothing to clear that would
  not also lie about the talk state.
- **The talk lives in session memory only — zero persistence,
  by design.** Segments, filter, focus and counts die when the
  summary is confirmed and when the agent closes (onUnload
  wipes everything). Close the agent and the talk is gone.
- **The mic-mode disclosure is kept, not hidden.** The
  permission line and the README state that the mic mode
  affects only the getUserMedia stream, not the host ASR
  pickup (the fleet audit conclusion): this agent listens
  through host ASR, so it claims no far-field beamforming
  advantage for recognition itself.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in
  replay reads the focused segment's short line; it never reads
  a whole transcript aloud. There is no ticker: every
  transition is a tap, a nod or a key — a replay is
  event-driven, not time-driven.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `meeting-filter` (F04) is the meeting gate:
  name/topic keywords plus a ~10 s pre-hit replay buffer.
  Talk-replay has no gate and no buffer: it keeps every
  subtitle of one talk and replays only three kinds.
- Attention-series `day-lookback` (R01) is the day timeline:
  gazes you marked, typed 画面 / 数字 / 承诺. Talk-replay is
  not a day: it has no gaze marks and no scene type — its
  units are talk subtitles, typed by keyword kind.
- Attention-series `lecture-filter` (F05) is the lecture gate:
  signal sentences captured as notes. Talk-replay does not
  capture notes during the talk: it replays the talk itself,
  filtered, after the talk.

## Permissions

Exactly one permission (`RECORD_AUDIO` in app.json, and the
static check asserts exactly that): talk listening plus host
ASR transcription. No `CAMERA`: nothing is photographed —
reading a contract or a notice is not this agent's job. No
`GEOLOCATION`: a direction you marked is not a position, and
this agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/talk-replay-harness.js`, not packed):
  app.json pages and permissions exactly `["RECORD_AUDIO"]`;
  zero storage/camera/location APIs and zero getUserMedia
  calls in the page source (the disclosure text mentions
  getUserMedia by name, which the harness allows; only a call
  is banned); no legacy Page/App/Widget; no utterance language
  assignment; foot2 honesty lines asserted (keyword match is
  not semantics, side is not voiceprint, single-session limit,
  mic mode does not change host ASR, no indoor positioning,
  zero persistence); classification units (promise+deadline,
  number, deadline-only, none); initial listen-empty state
  (bigText 还没收， placeholder row); bigCls thresholds;
  refusals in listen-empty (REPLAY/END naming the missing
  segment, FILTER refused, confirm refused, NEXT/BACK
  ignored); SIDE/DIR cycles and wraps; SEG receipt (fields,
  HH:MM time format, counts per side and per kind); the real
  ASR path (onASRResult appends non-demo, empty/no-text
  ignored); NEXT/PREV wrap and rowTap focus with
  out-of-range and missing-dataset guards; replay + filter
  (all three kinds, empty-filter view with placeholder, NEXT
  ignored on empty); summary flow (END from listen, counts,
  other-party promise rows, BACK rebuilds, END in summary
  confirms and clears, placeholder when the other party made
  no promise); nod discipline (unsteady ignored without
  arming, steady nod in listen ignored and adds nothing, lock
  blocks a second nod, lock expiry works, steady nod in
  replay advances, in summary confirms, non-nod gestures
  noted); key discipline (Enter ignored in listen, advances
  in replay, confirms in summary, ArrowUp/Down cycle,
  Backspace returns, ignored in listen); SPEAK lines per
  mode; DEMO five-stage arc and refusal on user segments or
  user replay; onUnload wipes everything. Result: **98/98**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (nothing received), listening (DEMO
  stage 3, 3 segments), replay-promise (replay filtered to
  承诺， 2 of 3), replay-deadline (replay filtered to 期限，
  2 of 3), summary (3 segments, 对方承诺 2 句 listed one by
  one). Button coordinates were probed per state and every
  PNG re-verified by eye (see `shot-talk-replay.js` in
  `~/workspace/preview-tools/`): idle DEMO y=170, stage-1
  DEMO y=180–185 (the band moves down when the status line
  wraps), stage-2 DEMO y=180 (y=190 already hits REPLAY),
  replay-state REPLAY/FILTER/END y=190.
