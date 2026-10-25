# Seat Catch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series HO05 (HOLD 默念型， last of the group): a find-your-seat keeper for
the walk from the ticket check to your seat — cinema, theatre, hall,
train carriage — where the row/seat pair is seen once, forgotten twice,
and the stub gets checked again and again with your head down.

## Design contract

- **Not number-catch for seats: storing the seat is step one, the
  product is the hunt.** HO01 `number-catch` keeps a number and shows it
  back. This agent keeps the target only to GUIDE against it: after
  the confirm, it walks you relatively — current row vs target row,
  current seat number vs target seat number — until you say you are
  seated. Its screens are hints and differences, not a recall display.
- **The target lives in session memory only — zero persistence, by
  design.** There is no storage API anywhere in the page (no wx storage
  import use, no localStorage; harness-scanned). The confirmed target
  is an instance field: it dies when you sit down (wiped on the seated
  confirm), when you abandon (two-step DEL), when you discard the
  read, and when the agent closes (onUnload clears the fields, and
  nothing was ever written anywhere else). One trip, one seat, then
  it is gone — a seat assignment is the shortest-lived number there
  is, and the UI count line says so constantly （只存本次会话内存 ·
  关掉/坐下即清 · 零落盘）.
- **Reading is the official photo path, and it is gated three
  times.** SNAP/ROW/SEAT each take a telephoto photo
  (`ImageCapture.takePhoto({mode:'telephoto'})`, wx camera-context
  fallback like the siblings); the Blob becomes a data: URL via
  `FileReader` and goes to the host `LanguageModel` as an `image_url`
  part of ONE user message (system prompt via `initialPrompts` only,
  `availability()` first, session `destroy()`ed after — dossier
  §2.9). Three strict reply formats (`SEAT: <zone>|<row>|<seat>`,
  `ROW: <n>`, `SEATNO: <n>`, each with a `NONE` form); the parsers
  accept the clean format or a tight `N排M座`-style salvage and reject
  prose — an unclear reply is a failed read, never a guess. There is
  no OCR on this platform and none is claimed. The photos live in
  memory only and are never persisted.
- **Nothing becomes the target until the wearer verifies and presses
  OK.** A ticket read lands on a CONFIRM screen, huge, labelled as a
  machine read that may misread. Correction is stepper-based (FIELD
  toggles 排/座 focus, +1/−1 step, letter suffixes on seat tokens
  survive stepping, ZONE cycles 左区/中区/右区/无区） — deliberately no
  dictation, so this agent needs no microphone at all. An OK on an
  incomplete read (row or seat missing) is refused out loud with the
  pending read kept. DEL discards an unconfirmed read in one tap — it
  was never the target.
- **Guidance is relative difference only — the honesty core of this
  agent.** There is NO indoor positioning: no geolocation permission,
  no map, no floor plan, no arrow that points at your seat, and no
  spoken or shown string claims to know where you are (harness scans
  every spoken string for navigation/positioning/arrival claims).
  Row stage: you photo each row sign as you pass it; the hint is the
  arithmetic difference （还差 3 排，继续向前 / 走过 1 排，往回走 /
  就是这一排）. Seat stage: you photo the nearest seat-back number;
  the hint is the count difference toward bigger or smaller seat
  numbers （再往里 4 个（往号码变大的方向）) — a direction that exists
  on the seat backs themselves. When a row read matches, the seat
  stage opens automatically; OK at the row stage also enters the row
  on the WEARER's judgement, logged and announced as exactly that
  （未经读数核对）, never as a detected arrival.
- **Every read failure lands on a usable manual path.** No camera,
  no model, model unavailable/empty/error, unreadable photo,
  FileReader missing, wx-fallback photo with no Blob: the ticket
  stage lands on the confirm screen empty with the reason stated —
  steppers fill row/seat and OK still starts the hunt. The row and
  seat stages fall back to +1/−1 as a manual current-row/seat report,
  labelled 手动 wherever it is used. The photo path is an accelerator,
  never a gate.
- **Seated is a two-step confirm, shared by nod and SIT.** A steady
  nod means ONE thing in this agent — "I am seated" — and only at the
  seat stage: the first steady nod (or first SIT/OK) only ARMS it
  ("再点头一次确认就座"), the second wipes the target and lands on
  the done screen. One nod never wipes anything. An unsteady nod
  earns nothing. Everywhere else a nod is inert and says why: it
  never stores a target (confirm), never advances a row, never
  confirms a read. Abandoning a hunt is likewise two-step DEL.
- **DEMO is one full simulated hunt, labelled at every step.** From
  the ticket screen, DEMO seeds a simulated ticket read （中区 8排
  12座） on the confirm screen (cap line: simulated, not a real
  photo); OK starts the hunt; DEMO taps then simulate row reads
  (3 → 6 → 8) and seat reads (5 → 12) through the real guidance code;
  SIT ×2 finishes on the done screen; DEMO there (or after backing
  out to the ticket screen) exits and restores the parked real state
  exactly. No camera is used in DEMO.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data —
  the only timers are the 6 s two-step disarm windows.

## Permissions

`CAMERA` only — telephoto photos of the ticket stub, of each row sign
while guiding, and of the nearest seat-back number inside the row
(every Blob lives in memory only and is discarded after its read
attempt). No `RECORD_AUDIO`: the correction path is steppers, there
is deliberately no dictation to correct with. No `GEOLOCATION`: a
seat hunt needs no position, and this agent never knows where you
are — that ignorance is stated in the UI footer, the README and
every hint it gives.

## Validation

- Node harness (137 assertions): app.json permissions exactly
  [CAMERA]; zero storage/geo/audio/ASR APIs in the page source; no
  legacy Page/App/Widget; parser batteries for all three read formats
  (piped values, letter seat tokens, zone salvage, NONE forms, prose
  rejection, row-0/alpha rejection); confirm gating (an unconfirmed
  read is never the target, OK on an incomplete read refused with the
  pending kept); stepper correction (focus toggle, ±1 on row and seat,
  letter suffix preserved, zone cycling, correction flag, steppers from
  blank landing on 1); manual fill reaching a target; guidance math
  (row 3-to-go / overshoot / match auto-advancing to the seat stage,
  seat counts toward bigger/smaller numbers, match announcements);
  nod discipline (unsteady ignored, nod never stores, nod in grow
  inert, two steady nods seat and wipe); SIT two-step sharing the same
  arm; speak-back of the seated wipe; DEL paths (confirm discard,
  two-step abandon, disarm on other actions); DEMO arc end-to-end with
  simulated reads labelled and the parked real target restored
  byte-identical after a mid-demo back-out; camera+LLM happy path
  (telephoto mode asserted, bytes on the CAP line, tracks stopped,
  prompt shape = text + image_url data: URL in user content, system
  only via initialPrompts); row and seat reads through the same
  machinery; every LLM failure variant 
...[truncated 409 chars]