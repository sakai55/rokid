# Alarm Triage Visual — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series CC06 (FILTER 守望型）: a visual alarm triage board for people
with severe hearing loss.

## Design contract

- **The screen is the alarm.** Smoke alarms, doorbells, kettles,
  washer-end tones, a crying baby — for this wearer they are all
  invisible unless something turns sound into light. LISTEN opens
  an omnidirectional getUserMedia stream; an Analyser watches its
  level (250 ms tick engine); a loud event (level >= 6) flips the
  whole screen into a big banner. No speech, no beep, no hearing
  required anywhere in the wearer's own flow.
- **Direction is sampled, not guessed.** After an alert the wearer
  turns the head toward a facing (DIR cycles 左 / 正前方 / 右 —
  the wearer turns, then taps) and SCAN stores the live level at
  that facing. The facing with the highest sampled level is the
  direction verdict. A facing with no sample stays 未测, never
  invented.
- **Type is wearer-confirmed, never auto-recognised.** A level
  meter cannot identify which appliance is sounding, and this
  agent never claims otherwise. The wearer — who can see the
  kitchen, the door, the baby — picks the type from a fixed list
  (TYPE cycles 烟感 / 门铃 / 水壶 / 洗衣机 / 宝宝哭声 /
  其他声响） and 确认定格s it into a banner reading TYPE +
  DIRECTION in huge type. A triage with no confirmed type stays
  未确认.
- **SPEAK is not for the wearer.** TTS reads the banner aloud
  only so a hearing person nearby can hear the triage; the deaf
  wearer's channel is always the screen. HELP likewise speaks for
  a nearby helper. Nod (steady) = SPEAK only in every phase: it
  never confirms a triage and never clears one.
- **Zero persistence.** No storage calls anywhere; samples, type
  and banner live in page memory and 清除 returns to IDLE.

## Permissions

`RECORD_AUDIO` only. It covers the omnidirectional mic check
(its own MIC CHECK line, mode read back) and the level monitor.
No camera is used: triage is sound → light, not vision. Mic
modes apply only to getUserMedia streams and never shape host
ASR — this agent does not use ASR at all.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used;
  no pure-white / white-rgba colours in CSS (green scale only).
- Preview screenshots in `artifacts/` (index / alert / triaged /
  cleared), generated with the local Ink runtime pipeline; DEMO
  click coordinate verified at canvas (400, 300).
