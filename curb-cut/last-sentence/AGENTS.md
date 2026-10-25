# Last Sentence — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series CC07 (REVIEW 回放型）: a replayable last sentence for deaf
and auditory-processing listeners.

## Design contract

- **The stream must be pausable.** A live caption stream scrolls
  past and never comes back; missing one sentence derails the
  whole thread that follows. LISTEN runs a far-field mic check
  FIRST, then host ASR (continuous where the host supports it);
  each completed transcript is split into sentences and appended
  to a rolling list of the last 6 — older sentences drop honestly,
  this is a short window, not a meeting transcript.
- **上一句 freezes the previous sentence, not the latest.** The
  sentence you missed is by definition the one before the one
  currently being spoken, so freeze targets index len-2. While
  frozen, the display stops advancing but new speech keeps
  accumulating behind the freeze; nothing is lost while you read.
  继续 (or a steady nod) unfreezes back to live.
- **Refusals are honest.** A freeze with fewer than 2 sentences
  is refused ("还没攒够两句"); with no host SpeechRecognition the
  agent says SKIP plainly and the DEMO still shows the flow. ASR
  text is shown as heard (only surrounding whitespace trimmed),
  never cleaned into a different meaning.
- **Nod = resume only, never freeze.** An accidental freeze
  mid-conversation would be the failure mode, so a steady nod
  unfreezes when frozen and does nothing otherwise. Freezing is
  always an explicit button / swipe action.
- **Zero persistence.** No storage calls anywhere; the roll, the
  frozen sentence and the phase live in page memory and 清除
  wipes them back to IDLE.

## Permissions

`RECORD_AUDIO` only. It covers the far-field mic check (its own
MIC CHECK line, mode read back) and host ASR capture. No camera
is used: this is a listening agent, not a reading one. Mic modes
apply only to getUserMedia streams and never shape host ASR —
both paths say so on their lines.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used;
  no pure-white / white-rgba colours in CSS (green scale only).
- Preview screenshots in `artifacts/` (index / live / frozen /
  cleared), generated with the local Ink runtime pipeline; DEMO
  click coordinate verified at canvas (400, 280) — this agent's
  shorter card puts the button rows higher than the CC06 layout.
