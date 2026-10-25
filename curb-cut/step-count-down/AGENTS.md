# Step Count Down — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series CC03 (HOLD 倒数型）: a stair countdown for blind / low-vision
wearers on an unfamiliar flight.

## Design contract

- **The outsourced attention is holding the total, not seeing the
  stairs.** The wearer cannot count "how many steps are left" by
  looking. The agent holds ONE number — the total counted at the
  top — and counts it down. The last step is the danger: from 3
  remaining down, every step is spoken; the last step gets its own
  warning; the bottom gets a plain "已到底".
- **The total comes from a photo count or from the wearer.** COUNT
  does: `wide` photo of the flight (head aimed down the stairs) +
  host `LanguageModel`, prompted to answer ONLY a step count (or
  NONE). Fallbacks: stepper (+1/+10/−1, swipe) and DICT (wearer-mode
  mic check FIRST on its own MIC CHECK line, then host ASR; Arabic
  and Chinese numerals accepted; unparsable = rejected visibly, no
  guess). A start with no total (>0) is refused honestly.
- **No automatic advance — this is the safety decision.** Head pitch
  per step varies with gait, cane use and handrails, so deriving
  steps from pitch would silently drift, and a drifted count is
  exactly what makes someone step into air. Every step is therefore
  wearer-confirmed (STEP button, steady nod, or contextual GO).
  A missed confirmation is a visible off-by-one the wearer can
  correct with SPEAK + awareness, never a silent drift. Pitch is
  not read at all; `onOrientationStabilityChange` is used only to
  gate the nod (steady nod = STEP).
- **Voice is primary.** All instructions, warnings and the bottom
  announcement are spoken once via TTS (fixed host voice; utterance
  `lang` never set, documented as not taking effect). Mid-flight
  steps (remaining > 3) are deliberately NOT spoken on every step:
  the wearer initiated the step, so the tap/nod itself is the
  confirmation; SPEAK reads the full state on demand at any time.
  The screen mirrors the same lines for a sighted helper and for
  preview, with a giant remaining number and a descended/remaining
  block bar.
- **Gestures:** single tap = Enter = contextual GO (setup->start,
  counting->STEP, done->fresh setup); swipe up/down = total +1/−1
  (setup only, locked once counting); steady nod in counting =
  STEP, elsewhere = SPEAK; double-tap = host back, never
  intercepted.
- **Nothing is persisted:** no storage calls anywhere; total and
  count live in page memory. One flight per round.

## Permissions

`CAMERA` + `RECORD_AUDIO`. CAMERA is for the wide photo count of
the flight. RECORD_AUDIO is for the wearer's dictation of the total,
preceded by the wearer-mode mic check. The agent never records
anything else and never listens to the environment.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used;
  no pure-white / white-rgba colours in CSS (green scale only).
- Preview screenshots in `artifacts/` (index / demo setup /
  counting / warning zone / done), generated with the local Ink
  runtime pipeline.
