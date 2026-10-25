# Route Hold — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series HO04 (HOLD 默念型）: a hear-it-once route keeper for the directions a
stranger rattles off in one breath — "左转、直行、第二个灯右转" — that you
otherwise recite to yourself the whole way and still get wrong.

## Design contract

- **The mic hears YOU, never the stranger.** The route is dictated by the
  wearer repeating what they were told, in their own voice. The agent
  never claims to listen to, record or transcribe the other person; the
  UI line, the EVT wording and the README all say the route comes from
  YOUR repetition.
- **No positioning of any kind — deliberate, and the core honesty
  boundary of this agent.** There is no geolocation permission, no map,
  no position tracking; the agent cannot know where you are, and
  nothing anywhere claims otherwise. Advancement is a judgement the
  WEARER makes: a steady nod (or Enter / swipe) means "I judge this
  step done". The route never advances on its own, and when the steps
  run out it says "路线走完了，应该到了" — the steps are finished;
  whether you have arrived is your judgement, never its claim. No
  spoken string ever contains a navigation, positioning or arrival
  claim (harness-scanned).
- **Nothing joins the route unconfirmed.** Every heard step lands on a
  CONFIRM chip (labelled as an ASR hearing that may be wrong); only
  OK/Enter saves it. Re-dictating replaces the pending step (it was
  never saved), DEL drops it, a steady nod in confirm mode is
  deliberately ignored — a nod never saves.
- **SPLIT is a proposal, not a save.** Dictating the whole route at
  once splits it on step markers （然后/接着/其次/最后， sentence
  breaks, a comma right before a turn verb or an ordinal landmark
  like 第二个灯， and 再 only when a turn verb follows — 再走一百米
  stays one step) and shows ALL proposed steps on a review screen.
  The wearer prunes wrong steps with DEL, then OK accepts the rest.
  If the split finds fewer than 2 steps, the utterance is honestly
  kept whole as ONE pending step through the normal confirm gate —
  never chopped up by guessing. Steps are capped at 8; a 9th save is
  refused out loud with the pending step kept, and a review accept
  that overflows the cap saves what fits and SPEAKS how many did
  not fit — overflow is stated, never silent.
- **Parsing stays close to the wearer's words.** Only bare sequence
  markers at the very start of a step and trailing punctuation are
  stripped — they are connectors, not the step itself. Steps longer
  than 30 chars are truncated with the cut stated on the EVT line;
  empty after stripping is rejected as not heard; nothing is guessed.
- **Display truncation is honest.** A step longer than 12 characters
  displays as its first 12 + "…"; the full text stays in storage and
  is what the walk advance / SPEAK reads out.
- **The steps persist as TEXT — that is their job.** `{text}` entries
  in wx key `routeHold`, max 8, saved on every mutation, so the
  route survives closing the agent: dictate at the corner, walk
  later. The WALK POSITION is deliberately not stored — reopening
  starts in build, and a walk restarts at step 1. No audio is ever
  stored. Persistence is stated plainly in the UI and README.
- **The walk shows ONLY the current step.** Per the PLAN, the next
  step is not previewed by default. PEEK is the documented exception:
  a toggle that shows the next step small; it defaults OFF, and any
  advance, back or reset turns it off again — a glance, not a mode.
  Swipe up (ArrowUp) goes back one step, spoken; going back from the
  finish re-arms the finish line. RESET is a two-step DEL in walk
  mode, back to step 1. Steps can be re-dictated only in BUILD mode —
  in walk, DICT/SPLIT are refused out loud.
- **Nod = "this step is done", walk mode only.** One steady nod, one
  step, the new step spoken as it lands. An unsteady nod earns
  nothing. A nod never goes back, never saves a step, never accepts
  a review, never deletes.
- **Delete is two-step in build.** DEL arms on the focused step,
  second DEL deletes; any other action, or 6 s, disarms. In review,
  DEL prunes a proposal in one tap — proposals were never saved, so
  there is nothing to protect.
- **DICT/SPLIT order is binding** (audit wording): wearer-mode
  `getUserMedia` availability check FIRST (settings read back,
  tracks stopped at once, result on its own "MIC CHECK:" line; an
  OverconstrainedError falls back to a labelled default-mic check),
  THEN host `SpeechRecognition` (zh-CN) on its own microphone,
  listening labelled "(host ASR)". Mic modes apply only to
  getUserMedia streams and never shape host ASR.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data.
- DEMO seeds the PLAN's own route （左转 / 直行 / 第二个灯右转） in
  memory, already walking; further DEMO taps advance it with the
  same advance a nod would make, through the finish line, and the
  next tap restores the real route exactly. Demo saves are
  suppressed (`_saveSteps` is a no-op in demo).

## Permissions

`RECORD_AUDIO` only — the wearer-mode mic availability check plus the
wearer's own dictation of steps and routes. Deliberately NO
`GEOLOCATION`: a route you hold in your head needs no positioning,
and this agent never knows where you are. No camera (spoken
directions need no photo).

## Validation

- Node harness (113 assertions): app.json permissions exactly
  [RECORD_AUDIO]; single-step parse battery; split battery (the
  PLAN's own route via commas + ordinal landmark, marker variants,
  再 before a turn verb splits while 再走一百米 stays whole,
  no-marker utterance kept whole, bare marker/empty rejected);
  dictation confirm flow for both DICT and SPLIT (unconfirmed never
  saved, zero storage writes before confirm/accept), re-DICT
  replacement, garbage rejection; review propose → prune → accept
  with persisted texts exact; split finding <2 steps routed to the
  single-step confirm gate; pruning a review empty returns to build
  with the route unchanged; cap-8 refusal with pending kept, accept
  refused at full, partial accept saving what fits and speaking the
  overflow; entry shape exactly {text}; persistence roundtrip across
  a simulated reopen (steps restored, build mode, storage not
  rewritten); walk discipline (unsteady nod earns nothing, one
  steady nod advances exactly once and speaks the new step, finish
  line spoken once per arrival and re-armed by going back, back at
  step 1 earns nothing); PEEK default-off / toggle / auto-off on
  advance / last-step and finished behaviour; two-step walk RESET
  with disarm-on-advance; SPEAK in walk reading the current step
  only; nod discipline outside walk (never saves, never accepts);
  DICT refused in walk; a keys + nod only walkthrough to the finish;
  DEMO arc with real storage byte-identical throughout; mic-check
  before ASR with check tracks stopped first, labelled
  OverconstrainedError fallback; a scan of every spoken string for
  navigation / positioning / arrival claims; TTS lang never set.
- Preview screenshots in `artifacts/` (build index / demo walking
  step 1 / demo walking step 2 / demo steps finished), generated
  with the local Ink runtime pipeline; button hit coordinates
  probed per layout state.
