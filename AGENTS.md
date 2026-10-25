# Code Hold — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series HO02 (HOLD 默念型）: a hear-it-once keeper for the codes of daily
life — a friend's WiFi password, a temporary door-lock code, a meeting
number — dictated to you once and gone from your head before you reach
the keyboard.

## Design contract

- **The mic hears YOU, never the friend.** Capture is the wearer
  repeating the code aloud in their own voice. The agent never claims
  to listen to, record or transcribe the other person; every capture
  path (UI line, EVT wording, README) says the wearer repeats it. The
  friend says it once, you say it once, the glasses hold it from there.
- **Nothing is stored until the wearer confirms.** The dictated text
  lands on a CONFIRM screen labelled "ASR 听写 — may mishear"; only
  OK/Enter (saveTap) ever writes storage. Corrections replace the
  capture BEFORE saving: re-DICT (dictate again), or the per-character
  stepper for pure-digit codes (cursor picks one digit, +1/−1 change
  just that digit, wrapping 0↔9). Letter codes refuse the stepper and
  point at re-DICT — there is no text keyboard on this runtime, so a
  letter code's only correction channel is your voice, stated plainly.
- **Verbatim, case preserved.** Unlike number-catch, the parser never
  upper-cases: passwords are case-sensitive, so `sunny4829` stays
  `sunny4829` and `Sunny4829` stays `Sunny4829`. The confirm screen is
  where ASR case/letter errors get caught — by the wearer's eyes.
- **Codes are stored as PLAIN TEXT — no encryption is claimed.**
  Storage holds `{label, code, time}` in wx key `codeHold`, max 4,
  written to this app's local storage on the glasses as readable text.
  This honesty is first-class: it is on the constant footer, on the
  info-box security line, in the count line, and in the README. It is
  exactly why the burn flow exists, and why the agent never keeps a
  code "just in case" beyond the wearer's own burn decision. A 5th
  save is refused out loud with the pending capture kept — never a
  silent overwrite, never an auto-burn of an old entry to make room.
  The agent only ever DISPLAYS a code; no autofill exists or is
  implied anywhere.
- **Chunked display, silent by default.** In show mode the code is
  shown in chunks of 4 (`4829 · 7713`), one chunk huge at a time;
  swipes or Enter advance the chunk while the wearer types on the
  other device. Opening an entry speaks NOTHING — a password read
  aloud unprompted is a leak, not a feature. SPEAK is on demand only:
  in show mode it spells the CURRENT chunk character by character; in
  the list it reads only the label and chunk count, never the code.
- **Burn is two-step and never automatic.** Viewing the last chunk
  raises a suggestion banner ("输完 BURN 两下焚掉（不会自动焚）") —
  the entry survives however long you look at it. BURN in list or
  show: first tap arms, second tap deletes and speaks "已焚" exactly
  once. Any other action (or 6 s) disarms. BURN on the confirm screen
  discards the unstored pending in one tap (it was never saved).
- **Nod is SPEAK only in this agent — a deliberate difference from
  HO01.** number-catch's PLAN sanctioned a two-step nod clear; here the
  brief and the stakes differ: a head movement must never delete a
  code the wearer may still need mid-typing. A steady nod reads the
  current chunk (show) or the label summary (list); in confirm it
  never saves; while capturing it is ignored. Documented in the
  README's gesture map.
- **逐位念 (digit-by-digit) is the reliable path.** Letters and
  symbols are ASR-fragile; digits dictated one at a time
  （零五零八 → "0508", leading zeros survive) parse exactly. The DIG
  button toggles a strict digit mode; digit-by-digit parsing also
  engages automatically for all-Chinese-digit utterances. Chinese
  unit numerals parse as values （二千五 → "2500") for meeting
  numbers. Garbage is rejected visibly with the buffer unchanged —
  a code is never guessed, and results under 2 characters are
  rejected as mishears.
- **DICT order is binding** (audit wording): wearer-mode
  `getUserMedia` availability check FIRST (settings read back, tracks
  stopped at once, result on its own "MIC CHECK:" line; an
  OverconstrainedError falls back to a labelled default-mic check),
  THEN host `SpeechRecognition` (zh-CN) on its own microphone,
  listening labelled "(host ASR)". Mic modes apply only to
  getUserMedia streams and never shape host ASR.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). Timers are not used for stored
  data: entry times come from ONE Date snapshot formatted "HH:MM".
- DEMO seeds two entries (WiFi密码 `sunny4829` / 门锁码 `0508`) plus
  one simulated dictation （会议号 `90214478`) waiting on the confirm
  screen — no microphone used. Demo saves are suppressed from real
  storage (`_saveEntries` is a no-op in demo); leaving DEMO restores
  the real entries exactly.

## Permissions

`RECORD_AUDIO` only — the wearer-mode mic availability check plus the
wearer's own dictation of a code or a correction. No camera (a code
you hear is not a photo), no geolocation.

## Validation

- Node harness (see the build report for the count): confirm gating
  (unconfirmed dictation never reaches storage, no storage write
  before OK), verbatim capture with case preserved, re-DICT and
  per-digit stepper corrections replacing the capture before save,
  digit-by-digit parsing incl. leading zeros and strict digit mode,
  garbage rejection with the buffer unchanged, cap-4 refusal with
  pending kept, chunking math (7/8/12-char codes), burn two-step in
  list and show + disarm on other actions, last-chunk suggestion that
  never auto-deletes, SPEAK chunk order and spelling, zero speech on
  opening show mode, list SPEAK never voicing the code, nod = SPEAK
  only everywhere, gesture-only walkthrough (Enter/Arrows),
  key-driven cursor/stepper in confirm, DEMO arc with the real store
  byte-identical throughout, persistence roundtrip, entry shape
  exactly {label, code, time} all strings, plain-text honesty line
  present in the UI strings, TTS lang never set.
- Preview screenshots in `artifacts/` (index / demo confirm / demo
  list / show chunks), generated with the local Ink runtime pipeline;
  button hit coordinates probed per layout state.
