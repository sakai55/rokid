# Chat Catchup — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series SO01 (SOCIAL 社交型， first of the group, series #36): you zone out
for ten seconds mid-conversation, come back, and have no idea what was
just said — and you do not want to ask the other person to repeat it.
This agent takes the catch-up off your hands: it silently buffers
conversation captions into a rolling ~15 s window, and when you shake
your head or tap HELP it shows the recent points in view, in silence,
so you can rejoin without interrupting.

## Design contract

- **The help view is silent by design, never spoken by default.**
  HELP (or a shake while listening) freezes the in-window buffer
  into points and shows them in view only — no TTS. Reading the
  summary aloud would interrupt the very conversation you zoned
  out of, so HELP never calls the speech path. The only spoken
  captions anywhere are from an explicit SPEAK tap inside the
  help view, and the README says so in plain words.
- **The summary is an excerpt, never a semantic digest.** The
  agent does not understand the conversation: the help view just
  lists the buffered caption sentences verbatim, in order. No
  keyword extraction, no LLM condensation, no "what they meant".
  Claiming understanding would be a lie about the hardware, so
  the UI and README say exactly that — "原句摘录，不是语义提炼".
- **The buffer is a rolling ~15 s window, not a transcript.**
  Every caption carries a timestamp; anything older than 15 s is
  dropped before it is ever shown, and HELP re-prunes at help
  time, so a segment that aged out while you were deciding to
  ask never appears. The buffer is not a recording of the talk.
- **Asking for help is shake or HELP, never nod.** A steady nod
  starts listening in idle, returns from the help view to
  listening, or confirms the summary — it never asks for help,
  and a nod in listening is ignored and noted: captions can
  only arrive from the conversation stream, a nod must not
  invent one. Shake asks for help only while listening; a shake
  in any other mode is ignored and noted. Shake handling is
  defensive: if the host never sends a shake event, the HELP
  button is the fallback, and the README says so.
- **No speaker identification.** The buffer does not separate
  speakers: there is no speaker recognition, and the help view
  never attributes a point to anyone. This is the deliberate
  opposite of talk-replay (RE02), which tags sides by user
  switching — chat-catchup tags nothing.
- **Correction is cheap, destruction is confirmed.** BACK from
  the help view returns to listening with the live buffer still
  rolling underneath; BACK from the summary returns to
  listening without deleting anything, and the summary is
  rebuilt on END. Confirming the summary (END while a summary
  is open, or a steady nod) is the only wipe. There is no DEL
  key: there is nothing to clear that would not also lie about
  what was heard.
- **The round lives in session memory only — zero persistence,
  by design.** Buffer, help points, counts and summary die when
  the summary is confirmed and when the agent closes (onUnload
  wipes everything, and stops the mic/recognition). Close the
  agent and the conversation round is gone.
- **A steady nod triggers, returns, or clears — never picks.**
  A steady nod in idle starts listening, in the help view
  returns to listening, in summary confirms and clears. An
  unsteady nod never arms the 1.2 s lock (the fleet fix,
  kept). A nod never changes focus: that is a selection, and
  a nod must not silently pick a help point. Enter follows the
  same per-mode action (idle START, listening HELP, help BACK,
  summary confirm); ArrowUp/Down walk help points (ignored
  outside the help view); Backspace goes back.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). SPEAK in
  listening names counts only and never reads captions aloud;
  SPEAK in the help view reads the frozen points, but only
  because you tapped it. There is no ticker: every transition
  is a tap, a nod, a shake or a key — a catch-up is
  event-driven, not time-driven.
- **Microphone mode honesty (fleet audit conclusion).** The
  far-field mode applies only to the getUserMedia stream; it
  does not change the host SpeechRecognition pickup. The UI and
  README say exactly that.

## Relation to the neighbours (kept distinct on purpose)

- Attention-series `meeting-filter` (FI04) is the meeting keyword
  gate plus a pre-hit ~10 s replay buffer: it only lights up on
  a name/topic keyword, and the buffer exists to serve the hit.
  Chat-catchup has no keyword gate: every caption enters the
  buffer, and the buffer exists to serve a help request you
  make yourself, mid-conversation.
- Attention-series `talk-replay` (RE02) is the post-talk replay:
  captions tagged by speaker side (user-switched), replayed
  after the talk filtered to promise/number/deadline sentences.
  Chat-catchup is not post-talk and not filtered: it is
  mid-talk, unfiltered, and speaker-blind.
- Attention-series `lecture-filter` (FI05) captures signal
  sentences into notes; `tour-watch` (DU04) gates guide
  announcements on集合 keywords. Chat-catchup captures nothing
  into notes and gates nothing on keywords: its only output is
  the silent recent-points view on demand.

## Permissions

RECORD_AUDIO only (app.json `permissions` is exactly
`["RECORD_AUDIO"]`, and the static check asserts exactly that):
far-field listening plus ASR captioning needs the microphone.
No `CAMERA`: nothing is photographed. No `GEOLOCATION`: this
agent never knows where anyone is.

## Validation

- Node harness (see `/tmp/chat-catchup-harness.js`, not packed):
  app.json pages and permissions exactly `["RECORD_AUDIO"]`;
  zero storage/location/camera APIs, no utterance language
  assignment, no legacy Page/App; getUserMedia microphoneMode
  present; foot2 honesty lines asserted (excerpt not semantic
  digest, HELP silent, no speaker recognition, single session,
  buffer expires, cleared on close, mic mode affects only the
  getUserMedia stream not host ASR, no indoor positioning,
  zero persistence); mic mode far-field; initial idle state
  (bigText 还没开始， placeholder row, countLine); bigCls
  thresholds; refusals in idle (END naming START, HELP
  refused, NEXT/PREV/BACK ignored, transcript in idle
  ignored); START flow (opens listening, refused while
  listening); transcript flow (empty ignored, 15 s prune
  verified by explicit timestamps, second segment kept after
  first aged out); HELP flow (opens help, exactly zero TTS,
  points frozen from buffer, refused in help, counts);
  focus walks help points only (NEXT/PREV wrap, rowTap focus
  with out-of-range and missing-dataset guards); BACK help
  returns to listening with buffer kept, second HELP recounts;
  shake discipline (listening shake asks, help shake ignored);
  nod discipline (unsteady ignored without arming, steady nod
  in idle starts, lock blocks a second nod, lock expiry works,
  steady nod in listening ignored with the conversation note,
  steady nod in help returns); key discipline (Enter per-mode,
  ArrowUp/Down walk, Backspace returns); END flows (help END
  to summary with helps, summary BACK rebuilds, summary END
  confirms and clears); SPEAK lines per mode (idle line,
  listening counts only and never captions, help reads points
  only on explicit tap); DEMO seven-stage arc (listening,
  3 captions, HELP with 3 points silent, back to listening,
  summary helps 1 heard 3) and refusal on user sessions;
  onUnload wipes everything.
  Result: **87/87** (first run 83/87, the 3 failures all
  harness-expectation bugs — a help-focus test built on
  segments the 15 s prune had correctly dropped, and a lock
  test asserting a lastEvent the early return never sets —
  fixed in the harness, page code untouched).
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (not started), listening (DEMO stage
  4, 3 captions buffered), help (DEMO stage 5, 3 points in
  silence), back to listening (DEMO stage 6, buffer keeps
  rolling, helps 1), summary (DEMO stage 7, helps 1 heard 3).
  Button coordinates were probed per state and every PNG
  re-verified by eye (see `shot-chat-catchup.js` in
  `~/workspace/preview-tools/`).
