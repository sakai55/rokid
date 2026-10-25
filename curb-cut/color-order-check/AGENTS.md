# Color Order Check — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series CC04 (COVER 核对型）: a wire / cable colour-sequence checker
for red-green colour-weak wearers.

## Design contract

- **The outsourced attention is the order table, not colour vision.**
  The wearer can see the wires; what fails is reading colour codes
  reliably in sequence. The agent holds the registered order and
  re-checks it position by position. A mismatch stops the run and
  names position, registered colour and observed colour — the three
  facts needed to fix it.
- **Colours are never communicated by colour alone.** Every result
  is a spoken and written colour NAME (from a fixed 11-colour
  palette: 红橙黄绿蓝紫棕黑白灰粉）. Correcting a broken channel
  with the broken channel itself is not a fix; a UI that only
  coloured the rows would fail its own user. The ledger shows
  numbered names, never bare swatches.
- **CHECK is one question only.** `telephoto` photo + host
  `LanguageModel`, prompted to answer ONLY a colour name (or
  NONE). The answer is normalised against the palette (substring
  match, so "红色" -> 红）; anything outside the palette is SKIP,
  never a guess. In REGISTER a recognised colour appends; in
  VERIFY it compares at the pointer: match advances, mismatch
  stays at the position until corrected (re-CHECK) or skipped.
- **SKIP is honest, not a pass.** Skipping a verify position
  records it as skipped and advances; the DONE summary reports
  verified vs skipped separately, so a skipped wire can never
  masquerade as a checked one.
- **Manual fallback is first-class.** COLOR cycles the palette,
  ADD appends the manual colour, DEL removes the last entry
  (register only). When the photo path is unavailable the same
  register -> verify loop runs on manual entries with the same
  mismatch semantics.
- **Gate rules.** VERIFY requires >= 2 registered entries, else
  refused honestly. The sequence locks when VERIFY starts; CLEAR
  is the only way to restart. Nothing is persisted: no storage
  calls anywhere.
- **Voice is primary.** All verdicts are spoken once via TTS
  (fixed host voice; utterance `lang` never set, documented as
  not taking effect). Gestures: single tap = Enter = contextual
  GO (register->verify, verify->CHECK, done->fresh); swipe up/down
  = manual colour cycle (register); steady nod = CHECK, elsewhere
  = SPEAK; double-tap = host back, never intercepted.

## Permissions

`CAMERA` only. CAMERA is for the telephoto wire photo in CHECK.
No audio is recorded at all: there is no dictation in this agent,
and TTS output needs no permission.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used;
  no pure-white / white-rgba colours in CSS (green scale only).
- Preview screenshots in `artifacts/` (index / demo register /
  verify / mismatch / done), generated with the local Ink
  runtime pipeline.
