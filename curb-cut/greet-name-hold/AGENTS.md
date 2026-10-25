# Greet Name Hold — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series CC05 (HOLD 拿住型）: a spoken-name holder for people with
prosopagnosia (face blindness).

## Design contract

- **The outsourced attention is holding the name, not recognising
  the face.** There is no face-recognition API on this platform,
  and the agent never claims otherwise. A name enters the hold
  only through speech: the wearer dictates it (DICT), or the other
  person's self-introduction is captured (LISTEN) and the wearer
  adopts it (采用）. No name is ever inferred from a face, a
  voiceprint, or a guess.
- **Two capture paths, one honesty rule.** DICT: wearer-mode mic
  check FIRST (its own MIC CHECK line), then host ASR; the
  transcript is cleaned (punctuation/space stripped) and stored
  verbatim. LISTEN: far-field mic check FIRST, then host ASR; the
  transcript is shown as "听到的原话" and stored ONLY when the
  wearer taps 采用. 采用 into NAME requires name-length (<= 6
  characters); a longer utterance is refused for NAME and must go
  to NOTE or be dictated short. Mic modes apply only to
  getUserMedia streams and never shape host ASR — both paths say
  so on their lines.
- **Hold, then wipe.** GO starts the hold only with a non-empty
  name, else refused honestly. During HOLDING the name stays big
  in view with one note and an elapsed timer (250 ms tick engine,
  recompute every second). CLEAR wipes name + note and lands in
  DONE; GO from DONE starts fresh. Nothing survives the
  conversation by design, and nothing is persisted: no storage
  calls anywhere.
- **Voice is secondary here, deliberately.** The wearer's problem
  is in a live conversation: the screen is the channel (a big
  name card), TTS is only for setup confirmation and SPEAK/HELP
  (fixed host voice; utterance `lang` never set, documented as
  not taking effect). Speaking the name aloud mid-conversation
  would defeat the purpose, so the hold itself is silent.
- **Gestures are read-only by design.** Steady nod = SPEAK only,
  in every phase: it never starts a hold and never clears one
  (an accidental clear mid-conversation would be the failure
  mode). Single tap = Enter = contextual GO (setup->hold,
  holding->SPEAK, done->fresh); swipe up/down = FIELD toggle
  (name <-> note); double-tap = host back, never intercepted.

## Permissions

`RECORD_AUDIO` only. RECORD_AUDIO covers both the wearer's
dictation (DICT) and the far-field capture (LISTEN), each preceded
by its own mode-availability check. No camera is used at all:
this agent must not see faces, it holds spoken names.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used;
  no pure-white / white-rgba colours in CSS (green scale only).
- Preview screenshots in `artifacts/` (index / demo setup /
  holding / cleared), generated with the local Ink runtime
  pipeline.
