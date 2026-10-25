# Meeting Filter — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series F04 (FILTER 过滤型， fourth of the group): a two-hour meeting
contains perhaps ten minutes that concern you, and the rest of the time
you dare not zone out yet cannot really listen. This agent inverts the
work: you declare the gate first — your name plus topic keywords — then
listen, and only a transcript segment that hits a keyword is allowed to
surface, carrying the ~10 seconds of transcript that came before it.

## Design contract

- **Declare first, filter second, and the gate never changes
  mid-meeting.** The keyword set (DEMO sample pools: 王磊·预算·上线 /
  李娜·招聘·排期 / 张伟·发布·复盘） and the mic mode (far-field /
  omnidirectional) can only change in idle. Changing the gate
  mid-meeting would silently rewrite what counts as a hit while the
  wearer is trusting the filter — so every KW/MODE tap while
  listening is refused with an explanation, never silently applied.
  This is the same idle-only-settings discipline as F01's whitelist,
  F02's target and F03's filter.
- **The match rule is a keyword gate on transcript text, and it is
  the headline.** A segment hits only when its normalised text
  contains a keyword from the declared set (first keyword in set
  order wins and is named). There is no speaker identification, no
  diarisation, no meeting-minutes engine: the gate tests text, not
  people. A misheard word means a missed or false hit, and the UI
  footer, the README and every hint say so.
- **A hit is banner + exactly one TTS + the pre-hit ~10 s context.**
  The rolling buffer keeps only segments from the last ~10 seconds;
  anything older is dropped before the match is tested, so the
  context shown on a hit is genuinely the ten seconds before it.
  The TTS names only the keyword and points at the replay ("命中：
  王磊，请看前十秒回放") — it does not read the whole buffer aloud,
  because re-reading the buffer would itself steal the attention
  the filter just saved.
- **Non-hit segments only ever touch a counter.** A non-hit
  segment increments the heard count and produces no banner and no
  TTS. A filter that announced every non-hit would be the opposite
  of a filter. An empty transcript is not counted at all: nothing
  was actually heard, so counting it would lie about coverage.
- **A transcript segment is a deliberate listen, and a nod never
  starts or stops one.** A steady nod confirms only where
  confirmation is safe: START in idle, CONFIRM on the summary
  screen. In live listening a steady nod is ignored on purpose —
  starting or stopping the gate must be a deliberate tap. An
  unsteady nod never arms the 1.2 s lock (the F01 fix, kept).
- **Correction is cheap, destruction is confirmed.** DEL in live
  listening only clears the hit banner — it never deletes the hit
  list or ends the listening; DEL with no banner is ignored, not
  silently "cleared". Back from the summary returns to live
  listening without deleting anything; the summary is rebuilt on
  END. Confirming the summary (Enter / steady nod) is the only
  wipe.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks four stages: listening started (keywords 王磊·预算·上线，
  mic far-field) → two non-hit segments counted silently (coffee
  machine, access cards — no banner, no TTS) → hit segment ("预算
  这块王磊说下周要重新核一遍", banner 王磊 + one TTS + the two
  earlier segments as the pre-10 s context) → summary (heard 3,
  hits 1, keyword 王磊）. A fifth DEMO tap reports the demo
  complete. DEMO refuses outright if a user listening session is
  running. Every step is labelled DEMO; no real ASR happens in
  DEMO (the preview host cannot provide a mic stream by design).
- **The meeting lives in session memory only — zero persistence,
  by design.** There is no storage API anywhere in the page (no wx
  storage import use, no localStorage; harness-scanned). The
  rolling buffer, heard count, hits, banner and summary die when
  the summary is confirmed, when the agent closes (onUnload wipes
  everything), and never survive to the next meeting. There is no
  full-meeting recording to leak: the buffer is ~10 seconds by
  construction, and non-hits are discarded on expiry. Close the
  agent and the meeting is gone, which is the correct use for a
  meeting happening right now.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). The only timers are the 1.2 s
  nod lock and the ASR/mic soft-fail paths.
- **Mic mode honesty (fleet audit finding, kept).** The mode
  selector governs the getUserMedia audio stream's pickup only
  (far-field for a meeting room, omnidirectional for a round
  table). Host SpeechRecognition ASR uses the host mic and is NOT
  steered by the mode — the UI perm line and the README say so
  plainly, and the agent never claims the mode "aims the
  recognition" at a speaker.

## Relation to the neighbours (kept distinct on purpose)

- Directional-series `speaker-focus` builds meeting minutes
  annotated by seat direction (who spoke, from which direction) —
  it is a **minutes engine**. Meeting-filter never writes minutes:
  it is a gate that only lets keyword hits through, with the ten
  seconds before each hit.
- Directional-series `far-ear` turns far-field speech into live
  on-screen subtitles so you can hear clearly — it is a **hearing
  aid**. Meeting-filter does the opposite for non-hits: it
  deliberately does NOT subtitle everything, because the whole
  point is that you do not have to read the whole meeting.
- `focus-shield` (F01) is the sound twin of the same gate: a
  whitelist interrupts, everything else is logged to a timeline.
  Meeting-filter is the meeting twin, with a pre-hit replay buffer
  instead of a timeline: a hit is only useful if you know what was
  said just before it.
- `sign-filter` (F02) and `buy-filter` (F03) are the visual twins:
  a declared target / three conditions interrupt, everything else
  is counted. Meeting-filter applies the same gate to sound, with
  the idle-only-settings discipline and the zero-persistence
  discipline shared on purpose.

## Permissions

RECORD_AUDIO only — `permissions` is exactly `["RECORD_AUDIO"]`
in app.json, and the static check asserts exactly that. The
mode-selected getUserMedia audio stream plus host SpeechRecognition
ASR (final results only) is the only input path, both guarded
try/catch so the preview host fails soft. No `CAMERA`: nothing is
photographed in this agent (keywords are picked from pools,
confirmation is a gesture). No `GEOLOCATION`: a meeting needs no
position, and this agent never knows where you are — that
ignorance is stated in the README.

## Validation

- Node harness (see `/tmp/meeting-filter-harness.js`, not packed):
  app.json permissions exactly ["RECORD_AUDIO"]; zero storage/geo/
  camera APIs in the page source; no legacy Page/App/Widget; no
  utterance lang assignment; mic modes far-field + omnidirectional
  passed to getUserMedia; host ASR path present; initial idle state
  (keywords 王磊·预算·上线， mic far-field, buffer empty, hits
  empty, idle big shows keywords); KW/MODE cycles with wrap and
  idle-only refusals (mid-listening and on summary); START double-
  start refusal, END refusal in idle, summary counts, back-to-
  listening rebuild, confirm clears; transcript inert in idle and
  empty ignored; non-hit counted silently (no banner, no TTS);
  hit battery (banner + exactly one TTS naming the keyword,
  context includes pre-hit segments, first keyword in set wins,
  space-stripped matching, keyword-set retargeting after KW
  change); buffer pruning (a segment older than ~10 s drops out of
  the hit context, a segment within 10 s stays); second hit
  appends with one TTS each, DEL banner-only and DEL-with-no-
  banner ignored; NEXT/PREV wrap and rowTap focus; nod discipline
  (unsteady ignored without arming the lock, steady nod starts in
  idle, ignored in listening, confirms on summary, non-nod inert,
  1.2 s lock); key discipline (Enter start/end/confirm,
  Backspace summary-to-listening and ignored in listening);
  SPEAK lines per mode; DEMO four-stage arc and refusal on a user
  session; startListening soft-fail without host APIs; onUnload
  wipes buffer, hits, banner and heard count; bigCls thresholds.
  Result: **138/138**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (keywords 王磊·预算·上线 / far-field),
  listening (DEMO stage 1), non-hit counted silently (DEMO stage
  2, heard 2, no banner, no TTS), hit banner + pre-10 s replay
  (DEMO stage 3, keyword 王磊）, summary (DEMO stage 4, heard 3,
  hits 1). Hit coordinates probed per state (see
  `shot-meeting-filter.js` in `~/workspace/preview-tools/`): DEMO
  is the row-1 first button (x=88), but its y moves with the
  status/info-box height, so coordinates were probed per state
  and every PNG was re-verified by eye after the fix, per the
  recorded F01/H02/F03 lesson that a single hash probe can hit
  the wrong button.
