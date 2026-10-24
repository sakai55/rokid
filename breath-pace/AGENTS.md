# Breath Pace — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series B03 (BODY 身体型， third of the group, series #43): when you are
nervous or anxious your breathing falls apart, and counting the beats
yourself only makes you panic more. This agent takes the counting off
your hands: it shows an in-view breathing beat (inhale-hold-exhale),
you just follow it with your eyes, and it counts the beats and closes
with a session summary.

## Design contract

- **It cannot measure your breathing, and the UI never pretends
  it can.** There is no breath sensor: the agent does not know
  whether you are actually inhaling, holding, or exhaling along
  with the beat. It is a metronome in view, not a measurement.
  "Rounds followed" means "beats the timer played through",
  and the UI and README say exactly that.
- **The beat is fixed presets, not adaptive.** Two presets only:
  4-2-6 (inhale 4 s, hold 2 s, exhale 6 s) and 4-4-6. The beat
  never adjusts to your real state, because it cannot see it.
  MODE switches presets before starting only — never mid-beat,
  so a beat in progress is never silently re-timed.
- **Phase names are spoken once per change, and never when
  muted.** Crossing into a new phase speaks its name (吸/停/呼)
  exactly once; MUTE silences all phase announcements and the
  beat becomes look-only. SPEAK reads the current phase on
  demand in any mode. No other speech exists in this agent.
- **A nod is never a breath.** A steady nod starts pacing in
  idle and confirms the summary. In pacing a nod is ignored and
  noted: the beat is counted by the timer, not by nodding, and
  counting a nod as a breath would be a lie about what you did.
  PAUSE is the only way to stop the beat mid-round.
- **Correction is cheap, destruction is confirmed.** BACK from
  pacing returns to idle with the round kept, and START resumes
  the same round; BACK from the summary returns to pacing
  without deleting anything, and the summary is rebuilt on END.
  Confirming the summary (END while a summary is open, or a
  steady nod) is the only wipe. There is no DEL key.
- **The round lives in session memory only — zero persistence,
  by design.** Phase, rounds, total seconds and the summary die
  when the summary is confirmed and when the agent closes
  (onUnload wipes everything and stops the timer). Close the
  agent and the breathing round is gone.
- **Not medical advice.** The agent does not treat anxiety, does
  not promise any calming effect, and does not set a medical
  schedule: the presets are plain timer beats. Severe discomfort
  means seeking professional help, dizziness means stopping at
  once — and the UI and README say so.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). There is no
  ticker beyond the one-second timer tick: every transition is
  a tap, a nod, a key, or the timer crossing a phase boundary.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `eye-rest` (B01) is the near-gaze timer: it
  counts steady near gaze and confirms a far look by head pitch.
  Breath-pace borrows the timer shape but paces a body rhythm,
  not a gaze: its timer plays a fixed inhale-hold-exhale beat
  and its only output is the beat plus a session summary.
- Attention-series `water-watch` (B02) is the cup-direction
  register plus a wall-clock drink interval plus a steady-gaze
  drink confirm. Breath-pace registers no direction and counts
  no habit: its only input is START/PAUSE/MODE/MUTE, its only
  output is the beat.
- Attention-series `standup-echo` (S04) is the standup module-
  keyword gate: hits become notes, non-hits become digest rows.
  Breath-pace has no keywords and no notes: it plays a beat.

## Permissions

Empty array (app.json `permissions` is exactly `[]`, and the
static check asserts exactly that): a beat light plus a timer
plus TTS phase names need no permission. No `CAMERA`:
nothing is photographed. No `RECORD_AUDIO`: nothing is
listened to. No `GEOLOCATION`: this agent never knows where
anyone is.

## Validation

- Node harness (see `/tmp/breath-pace-harness.js`, not packed):
  app.json pages and permissions exactly `[]`; zero storage/
  location/camera/recorder/getUserMedia APIs, no utterance
  language assignment, no legacy Page/App; foot2 honesty lines
  asserted （测不出你的呼吸、只是一个节拍器、不是医疗建议、
  不治疗焦虑、不承诺平复效果、严重不适请寻求专业帮助、头晕
  立即停下、固定档位、只存本次会话、关掉即清、没有室内定位、
  没有摄像头、零落盘）; initial idle state （bigText 还没开始，
  preset 4-2-6, phase inhale, muted false, 3 info rows);
  idle refusals (END naming START, PAUSE ignored, NEXT/PREV
  wrap, rowTap out-of-range and missing-dataset guards);
  MODE discipline (4-2-6 <-> 4-4-6 wrap, refused while
  pacing); START discipline (starts pacing inhale, zero TTS
  on start, refused while pacing, refused with a summary
  open); beat discipline (partial tick keeps phase and stays
  silent, 4 s inhale -> hold spoken once, 2 s hold -> exhale
  spoken once, 6 s exhale -> inhale with round 1 and 12 s
  total); MUTE discipline (muted phase change zero TTS with
  a look-only note, unmuted resumes speaking); PAUSE
  discipline (paused tick ignored, resume works); SPEAK
  lines per mode (idle, pacing phase + remaining + rounds,
  summary rounds + seconds); BACK round-keeping (pacing->
  idle keeps round, START resumes it, summary BACK ->
  pacing keeps, END rebuilds); summary flow (END out with
  rounds/total/preset, END confirms and clears, timer
  stopped); nod discipline (unsteady ignored without arming,
  steady nod in idle starts, lock blocks a second nod, lock
  expiry works, nod in pacing ignored with the not-a-breath
  note, non-nod gesture noted, steady nod in summary
  confirms); key discipline (Enter starts/pauses/resumes,
  ArrowUp/Down walk, Backspace returns, idle Backspace
  ignored); DEMO five-stage arc (inhale, hold, exhale,
  inhale round 2 with 12 s, summary rounds 1 total 12 s)
  and refusal on user sessions; onUnload wipes everything;
  bigCls thresholds.
  Result: **116/116** (first run, no harness fixes).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not started), inhale (DEMO stage 1),
  hold (DEMO stage 2), exhale (DEMO stage 3), summary (DEMO
  stage 5, rounds 1, total 12 s). Button coordinates were
  probed per state and every PNG re-verified by eye (see
  `shot-breath-pace.js` in `~/workspace/preview-tools/`).
  Two probe findings worth keeping: (1) the DEMO band moves
  with the status line — idle DEMO (66,170), pacing DEMO
  (66,165), and in pacing states y180 already hits the END
  row (it closed a round into a 0-round summary), so pacing
  DEMO taps must stay at y<=170; (2) DEMO stops the live
  one-second timer, otherwise live ticks drift the phase
  between the DEMO tap and the screenshot and the staged
  frames are not reproducible.
