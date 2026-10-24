# Eye Rest — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series B01 (BODY 身体型， first of the group, series #41): you read a
book or stare at a screen, two hours pass in one stretch, and only when
your eyes hurt do you remember to rest. This agent takes the remembering
off your hands: it times steady near gaze, reminds you in view at 20
minutes to look far away, and counts a far look complete when your head
pitches up — then restarts the timer.

## Design contract

- **There is no eye tracking, and the UI never pretends there is.**
  "Steady near gaze" is head steadiness (`onOrientationStabilityChange`)
  used as an approximation: the platform cannot see where your eyes
  point or how far away you are looking. A minute counts only while
  the head is steady; a moving head pauses the timer instead of
  guessing. The UI and README say exactly that.
- **A far look is a pitch approximation, never a measured distance.**
  Confirmation comes from an upward head-pitch event (or the LOOK
  button as fallback): the platform has no distance measurement, so
  "looked far" here means "head pitched up while a reminder was open".
  If the host never delivers a pitch event, LOOK is the fallback,
  and the README says so (the same defensive pattern as S01's shake).
- **A nod is never a far look.** A steady nod starts timing in idle
  and confirms the summary; in timing and in remind it is ignored and
  noted. Counting a nod as a far look would be a lie about what the
  wearer did, so the code refuses it in both modes.
- **One spoken reminder per reminder, then silence.** Reaching 20
  minutes speaks 「该远眺了」 exactly once; further ticks in remind
  mode never speak again, and BACK out of a reminder does not clear
  the debt — the stretch is kept, so the next steady minute re-raises
  it. Looking away from the banner is not a far look.
- **Correction is cheap, destruction is confirmed.** BACK from
  remind returns to timing with the reminder still owed; BACK from
  timing returns to idle with the round kept, and START resumes the
  same round; BACK from the summary returns to timing without
  deleting anything, and the summary is rebuilt on END. Confirming
  the summary (END while a summary is open, or a steady nod) is the
  only wipe. There is no DEL key.
- **The round lives in session memory only — zero persistence,
  by design.** Near-gaze minutes, reminder/rest counts and the
  summary die when the summary is confirmed and when the agent closes
  (onUnload wipes everything and stops the timer). Close the agent
  and the eye-rest round is gone.
- **Not medical advice.** The agent does not diagnose eye fatigue,
  does not promise any eye-protection effect, and does not set a
  medical schedule: 20 minutes is a plain timer threshold, and the
  UI and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK names
  counts in timing, reads the reminder in remind mode, and reads
  the summary — and never invents a reading. There is no ticker
  beyond the one-minute timer tick: every transition is a tap, a
  nod, a pitch event or a key.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `play-watch` (D01) is the playground timed
  glance-back: it reminds you to look back at a child zone on a
  schedule. Eye-rest borrows the timer shape but watches a body,
  not a place: its timer counts steady near gaze and its
  confirmation is a head pitch, not a glance.
- Attention-series `standup-echo` (S04) is the standup module-
  keyword gate: hits become notes, non-hits become digest rows.
  Eye-rest has no keywords and no notes: its only input is head
  steadiness plus minutes, its only output is a far-look
  reminder and a count.
- Attention-series `gift-clue` (S05) files silent clue cards from
  chat keywords. Eye-rest files nothing from chat and listens to
  nothing: it times, reminds, and counts far looks.

## Permissions

Empty array (app.json `permissions` is exactly `[]`, and the
static check asserts exactly that): head-orientation events plus
a timer plus a reminder need no permission. No `CAMERA`:
nothing is photographed. No `RECORD_AUDIO`: nothing is
listened to. No `GEOLOCATION`: this agent never knows where
anyone is.

## Validation

- Node harness (see `/tmp/eye-rest-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero storage/
  location/camera/recorder/getUserMedia APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted （没有眼动追踪、头部停稳、俯仰角、不是医疗建议、
  不诊断、不承诺护眼效果、只存本次会话、没有室内定位、
  没有摄像头、零落盘）; initial idle state （bigText 还没开始，
  3 info rows, countLine); idle refusals (END naming START,
  LOOK ignored, BACK ignored, NEXT/PREV wrap, rowTap
  out-of-range and missing-dataset guards); nod discipline
  (unsteady ignored without arming, steady nod in idle
  starts timing, lock blocks a second nod, lock expiry works,
  nod in timing ignored with the minutes note); tick
  discipline (unsteady tick pauses with minutes unchanged,
  steady tick accumulates, 12 min does not remind, START
  refused while timing, zero TTS while timing); threshold
  (20 min opens remind, reminds 1, exactly one spoken
  reminder, tick in remind never speaks again); LOOK
  confirms (rests 1, stretch reset, session total kept,
  LOOK ignored with no reminder open); pitch discipline
  (pitch 5 ignored, pitch 20 confirms, pitch up in timing
  noted without confirming, nod in timing still ignored);
  BACK from remind keeps the stretch owed and the next
  steady minute re-raises it; BACK timing->idle keeps the
  round and START resumes it (61 min in the harness arc);
  summary flow (END out with totals 61/4/3, BACK rebuilds,
  END confirms and clears, timer stopped); key discipline
  (Enter starts timing, Enter in timing ignored, Backspace
  returns, ArrowUp/Down walk, non-nod gesture noted); SPEAK
  lines per mode (idle, timing counts, remind line, summary
  line); DEMO five-stage arc (start, 12 min timing, remind
  at 20 min with exactly one TTS, pitch-up confirmed, summary
  20/1/1) and refusal on user sessions; onUnload wipes
  everything; bigCls thresholds.
  Result: **101/101** (first run 98/101, the 3 failures all
  harness-side: a nod fired inside the 1.2 s lock window, a
  hand-added minute total, and a bigCls test string that was
  exactly 13 chars — fixed in the harness, page code
  untouched).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not started), timing (DEMO stage 2,
  12 min), remind (DEMO stage 3, 20 min, banner open),
  confirmed (DEMO stage 4, pitch-up confirmed, rests 1),
  summary (DEMO stage 5, near 20 min, reminds 1, rests 1).
  Button coordinates were probed per state and every PNG
  re-verified by eye (see `shot-eye-rest.js` in
  `~/workspace/preview-tools/`).
