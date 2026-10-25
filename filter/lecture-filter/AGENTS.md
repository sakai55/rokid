# Lecture Filter — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series F05 (FILTER 过滤型， fifth of the group, closing the group): a
class or lecture has uneven information density, and the few sentences
that matter — "this is a key exam point", "the homework is due Friday"
— are exactly the ones most easily missed while you are trying to
listen to everything. This agent inverts the work: you declare the
signal words first — key point / exam / homework / deadline /
must-test / review — then listen, and only a transcript segment that
hits a signal word is allowed to surface, as a banner plus one TTS
call, and the sentence itself is stored as a lesson note. Every
non-hit segment only moves the heard counter and is discarded
immediately: it is never stored, because a lesson note needs only
the signal sentences, and keeping the rest would mean keeping
speech you deliberately chose not to keep.

## Design contract

- **Declare first, filter second, and the gate never changes
  mid-lesson.** The signal-word set (DEMO sample pools:
  重点·考试·作业 / 截止日·必考·复习 / all six) and the mic mode
  (far-field / omnidirectional) can only change in idle. Changing
  the gate mid-lesson would silently rewrite what counts as a hit
  while the wearer is trusting the filter — so every SIG/MODE tap
  while listening is refused with an explanation, never silently
  applied. This is the same idle-only-settings discipline as F01's
  whitelist, F02's target, F03's filter and F04's keyword gate.
- **The match rule is a signal-word gate on transcript text, and
  it is the headline.** A segment hits only when its normalised
  text contains a signal word from the declared set (first word in
  set order wins and is named). There is no speaker
  identification, no diarisation, no lecture-minutes engine: the
  gate tests text, not people. A misheard word means a missed or
  false hit, and the UI footer, the README and every hint say so.
- **A hit is banner + exactly one TTS + the sentence stored as a
  note.** The TTS names only the keyword ("命中：重点，已记入本
  课笔记") — it does not read the sentence aloud, because
  re-reading it would itself steal the attention the filter just
  saved. The note keeps the sentence verbatim plus a minute label
  （第1分钟）, so the summary is a readable list, not just counts.
- **There is deliberately NO rolling transcript buffer.** F04
  keeps ~10 seconds of context because a meeting hit is only
  useful with what was said just before it. A lesson note does
  not need that: the signal sentence is self-contained, and a
  buffer would mean retaining non-hit speech the wearer chose not
  to keep. So non-hit sentences are discarded at the decision
  point, immediately, and the page source contains no buffer at
  all (harness-scanned).
- **Non-hit segments only ever touch a counter.** A non-hit
  segment increments the heard count and produces no banner and
  no TTS. An empty transcript is not counted at all: nothing was
  actually heard, so counting it would lie about coverage.
- **A transcript segment is a deliberate listen, and a nod never
  starts or stops one.** A steady nod confirms only where
  confirmation is safe: START in idle, CONFIRM on the summary
  screen. In live listening a steady nod is ignored on purpose —
  starting or stopping the gate must be a deliberate tap. An
  unsteady nod never arms the 1.2 s lock (the F01 fix, kept).
- **Correction is cheap, destruction is confirmed.** DEL in live
  listening only clears the hit banner — it never deletes the
  note list or ends the listening; DEL with no banner is ignored,
  not silently "cleared". Back from the summary returns to live
  listening without deleting anything; the summary is rebuilt on
  END. Confirming the summary (Enter / steady nod) is the only
  wipe.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks four stages: listening started (signals 重点·考试·作业，
  mic far-field) → two non-hit segments counted silently
  (weather, club recruitment — no banner, no TTS, sentences
  discarded) → hit segment ("这道题是考试重点，下周复习要
  看", banner 重点 + one TTS + sentence stored as note 1) →
  summary (heard 3, notes 1, keyword 重点）. A fifth DEMO tap
  reports the demo complete. DEMO refuses outright if a user
  listening session is running. Every step is labelled DEMO; no
  real ASR happens in DEMO (the preview host cannot provide a mic
  stream by design).
- **The lesson lives in session memory only — zero persistence,
  by design.** There is no storage API anywhere in the page (no wx
  storage import use, no localStorage; harness-scanned). The heard
  count, notes, banner and summary die when the summary is
  confirmed, when the agent closes (onUnload wipes everything),
  and never survive to the next lesson. There is no full-lesson
  recording to leak: non-hits are discarded at once, and only hit
  sentences are ever held, in memory, for this lesson only. Close
  the agent and the lesson is gone, which is the correct use for
  a lesson happening right now.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). The only timers
  are the 1.2 s nod lock and the ASR/mic soft-fail paths.
- **Mic mode honesty (fleet audit finding, kept).** The mode
  selector governs the getUserMedia audio stream's pickup only
  (far-field for a lecture hall, omnidirectional for a round
  table). Host SpeechRecognition ASR uses the host mic and is NOT
  steered by the mode — the UI perm line and the README say so
  plainly, and the agent never claims the mode "aims the
  recognition" at a speaker.

## Relation to the neighbours (kept distinct on purpose)

- F04 `meeting-filter` is the **gate with a pre-hit replay
  buffer**: a name/topic keyword hit surfaces with the ~10
  seconds before it, because a meeting hit is only useful with
  context. Lecture-filter has no buffer and no replay: a lesson
  hit is a self-contained signal sentence, stored as a note.
- Directional-series `board-capture` photographs the blackboard
  into notes — it is a **visual note-taker**. Lecture-filter
  never photographs anything: it captures **spoken** signal
  sentences, and it captures only the sentences that hit.
- Directional-series `far-ear` turns far-field speech into live
  on-screen subtitles so you can hear clearly — it is a **hearing
  aid**. Lecture-filter is the opposite for non-hits: it
  deliberately does NOT subtitle everything, because the whole
  point is that you do not have to read the whole lesson.
- `focus-shield` (F01) is the sound twin of the same gate: a
  whitelist interrupts, everything else is logged to a timeline.
  Lecture-filter is the lesson twin, with a note list instead of
  a timeline: a hit is only useful if it is kept as a sentence
  you can re-read at the end of the lesson.

## Permissions

RECORD_AUDIO only — `permissions` is exactly `["RECORD_AUDIO"]`
in app.json, and the static check asserts exactly that. The
mode-selected getUserMedia audio stream plus host SpeechRecognition
ASR (final results only) is the only input path, both guarded
try/catch so the preview host fails soft. No `CAMERA`: nothing is
photographed in this agent (signal words are picked from pools,
confirmation is a gesture). No `GEOLOCATION`: a lesson needs no
position, and this agent never knows where you are — that
ignorance is stated in the README.

## Validation

- Node harness (see `/tmp/lecture-filter-harness.js`, not packed):
  app.json permissions exactly ["RECORD_AUDIO"]; zero storage/geo/
  camera APIs in the page source; no legacy Page/App/Widget; no
  utterance language assignment; mic modes far-field +
  omnidirectional passed to getUserMedia; host ASR path present;
  no rolling transcript buffer in the source; initial idle state
  (signals 重点·考试·作业， mic far-field, heard 0, notes 0,
  banner empty, idle big shows signals); SIG/MODE cycles with wrap
  and idle-only refusals (mid-listening and on summary); START
  double-start refusal, END refusal in idle, summary counts,
  back-to-listening rebuild, confirm clears; transcript inert in
  idle and empty ignored; non-hit counted silently (no banner, no
  TTS, sentence not stored); hit battery (banner + exactly one
  TTS naming the keyword and not reading the sentence aloud,
  note stored verbatim with minute label, first signal word in
  set order wins, space-stripped matching, signal-set retargeting
  after SIG change); second hit appends with one TTS each,
  DEL banner-only and DEL-with-no-banner ignored; NEXT/PREV wrap
  and rowTap focus; elapsed minute label; SPEAK lines per mode;
  nod discipline (unsteady ignored without arming the lock, steady
  nod starts in idle, ignored in listening, confirms on summary,
  non-nod inert, 1.2 s lock arms and expires); key discipline
  (Enter start/end/confirm, Backspace summary-to-listening and
  ignored in listening); DEMO four-stage arc and refusal on a user
  session; startListening soft-fail without host APIs; onUnload
  wipes notes, heard count, banner and summary; bigCls thresholds.
  Result: **96/96**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (signals 重点·考试·作业 / far-field),
  listening (DEMO stage 1), non-hit counted silently (DEMO stage
  2, heard 2, sentences discarded, no banner, no TTS), hit banner
  + sentence stored as note (DEMO stage 3, keyword 重点）,
  summary (DEMO stage 4, heard 3, notes 1). Hit coordinates
  probed per state (see `shot-lecture-filter.js` in
  `~/workspace/preview-tools/`): DEMO is the row-1 first button
  (x=88), but its y moves with the status/info-box height, so
  coordinates were probed per state and every PNG was re-verified
  by eye after the fix, per the recorded F01/H02/F03/F04 lesson
  that a single hash probe can hit the wrong button.
