# Number Catch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series H01 (HOLD 默念型， first of the group): a glance-and-hold keeper for
the short-lived numbers of daily life — hotel room, parcel locker, food
pickup, parking bay — that you otherwise mutter to yourself all the way
there and lose the moment someone talks to you.

## Design contract

- **Reading is the official photo path, and it is gated.** SNAP takes a
  telephoto photo (`ImageCapture.takePhoto({mode:'telephoto'})`, wx
  camera-context fallback like the siblings); the Blob is encoded to a
  data: URL via `FileReader` and sent to the host `LanguageModel` as an
  `image_url` part of ONE user message (multimodal content in the user
  role only, system prompt via `initialPrompts`, `availability()` first,
  session `destroy()`ed after — dossier §2.9, same machinery as #39
  board-capture). The prompt asks for exactly `READ: <number or code>`
  (or `READ: NONE`); the parser accepts a clean digit-bearing token and
  rejects prose — an unclear reply is a failed read, never a guess.
  There is no OCR on this platform and none is claimed.
- **Nothing is stored until the wearer confirms.** The read lands on a
  CONFIRM screen, shown HUGE, labelled "LLM READ - may misread". Only
  OK/Enter (saveTap) ever writes storage. The wearer can correct first:
  DICT (dictate the right number) or the stepper (±1, pure-digit
  buffers only — letter codes refuse the stepper and point at DICT).
  A correction replaces the read before anything is saved.
- **The photo is never persisted.** Blobs cannot be stored by this
  runtime and are not: storage holds TEXT only — `{label, number,
  time}` in wx key `numberCatch`, max 6. A 7th save is refused out
  loud with the pending catch kept — never a silent overwrite. The
  constant footer says it: 照片不保存 · 存的是你确认过的号码.
- **The manual path is fully usable alone.** Every read failure (no
  model, model unavailable, FileReader missing, model error,
  unreadable photo, wx-fallback photo with no Blob, no camera at all)
  lands on the same CONFIRM screen, empty, with the reason stated —
  DICT or stepper fills it and OK saves. The photo path is an
  accelerator, never a gate.
- **DICT order is binding** (audit wording): wearer-mode `getUserMedia`
  availability check FIRST (settings read back, tracks stopped at
  once, result on its own "MIC CHECK:" line; an OverconstrainedError
  falls back to a labelled default-mic check), THEN host
  `SpeechRecognition` (zh-CN) on its own microphone, listening labelled
  "(host ASR)". Mic modes apply only to getUserMedia streams and never
  shape host ASR. Parsing: clean codes pass through (B2-137), pure
  Chinese digit strings parse digit-by-digit so leading zeros survive
  （零五零八 → "0508"), unit numerals parse as values （一千二百零八 →
  "1208"), garbage is rejected visibly with the buffer unchanged.
- **Recall is the point.** Stored entries live in a list; OK opens the
  selected one full-screen — HUGE number, stays in view while you
  walk. SPEAK (or a list-mode nod) reads label + number aloud.
- **Nod is the PLAN-sanctioned exception, two-step only.** In the
  recall display, a steady nod ARMS the clear ("再点头一次清除") and a
  second steady nod clears that entry and speaks "已清除" once. One
  nod never clears. DEL mirrors the same two-step in list and show.
  Any other action (selection move, mode change, 6 s timeout) disarms.
  Everywhere else a nod is non-destructive by construction: in list it
  only speaks, in confirm it never saves, in catch it is ignored —
  unlike #39, a nod here never files anything.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). Timers are not used for stored
  data: entry times come from ONE Date snapshot formatted "HH:MM".
- DEMO seeds two entries （房号 1208 / 车位 B2-137) plus one simulated
  read （快递柜 6631) waiting on the confirm screen — no camera, no
  mic, no model. Demo saves are suppressed from real storage
  (`_saveEntries` is a no-op in demo); leaving DEMO restores the real
  entries exactly.

## Permissions

`CAMERA` (telephoto photo of the number; the Blob lives in memory
only and is discarded after the read attempt) + `RECORD_AUDIO`
(wearer-mode mic check + the wearer's own dictation of a number or a
correction). No geolocation.

## Validation

- Node harness (153 assertions): confirm gating (unconfirmed read
  never reaches storage, no storage write before OK), prompt shape
  (2-part user content, data: URL, system via initialPrompts only,
  destroy after), stepper + DICT correction replacing the read before
  save, letter-code stepper refusal, all read-failure variants landing
  on a usable manual path (unavailable / no FileReader / throw / no
  LM / READ: NONE / junk reply), no-camera host fully usable, cap-6
  refusal with pending kept and no overwrite, two-nod clear semantics
  (unsteady nod ignored, one nod never clears, cleared spoken exactly
  once, nod in list speaks only, nod in confirm never saves), DEL
  two-step + disarm on other actions, key-driven arc (Enter/Arrows),
  parser battery (unit numerals, digit-by-digit with leading zeros,
  codes, garbage rejection, prose-reply rejection), DEMO arc with the
  real store byte-identical throughout, persistence roundtrip, entry
  shape exactly {label, number, time} all strings, TTS lang never set.
- Preview screenshots in `artifacts/` (index / demo confirm / demo
  list / recall display), generated with the local Ink runtime
  pipeline; button hit coordinates probed per layout state.
