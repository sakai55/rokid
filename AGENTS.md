# Curb Ramp Scout — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series CC08 (WATCH 守望型）: a curb-ramp scout for wheelchair users —
the series' literal origin story.

## Design contract

- **Discover the ramp BEFORE rolling to the kerb.** At an
  unfamiliar crossing the ramp is usually off to one side, not
  straight ahead; discovering steps at the kerb means backing into
  traffic to look. 定向 calibrates the crossing direction (the
  wearer faces the road; the current AbsoluteOrientationSensor yaw
  becomes the reference), then 左扫 / 右扫 record facings by head
  turn, CHECK photographs each facing, and 结论 reports the side.
- **Both hands stay on the wheels.** Calibration, scanning,
  checking and verdict are head + tap only — never a two-hand
  operation, never a step that asks the wearer to let go.
- **A facing is 坡道 / 台阶 / 看不清， nothing else.** CHECK uses
  telephoto + host LanguageModel prompted to answer ONLY one of
  those three about THIS kerb. The LLM never writes a generic
  description, and no manual override exists: a guessed ramp
  verdict at a road crossing would be dangerous, so a facing
  without a photo verdict stays 未核 forever.
- **看不清 is a verdict, not a hidden failure.** It means "this
  facing could not be read — check it another way", and 结论
  reports incomplete sets plainly (which facings are still
  unexamined) instead of rounding them to a guess.
- **Sensor honesty.** With no AbsoluteOrientationSensor, facings
  are wearer-declared (the wearer turned, then tapped) and the
  sensor line says so; with a sensor, relative yaw is shown per
  facing. A declared facing is never dressed up as a measurement.
- **Nod = 结论 only.** A steady nod reads the verdict; it never
  scans a facing and never checks a photo, because an accidental
  scan at a crossing would corrupt the facing set.
- **Zero persistence.** No storage calls anywhere; calibration,
  facings and verdicts live in page memory and 清除 returns to
  IDLE for the next crossing.

## Permissions

`CAMERA` only. It covers the telephoto kerb photographs. No
microphone is used: this agent is eyes + head, not ears. TTS
needs no permission and only reads the verdict aloud.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used;
  no pure-white / white-rgba colours in CSS (green scale only).
- Preview screenshots in `artifacts/` (index / scanning / verdict /
  cleared), generated with the local Ink runtime pipeline; DEMO
  click coordinate verified at canvas (400, 280) — this agent's
  shorter banner puts the button rows higher than the CC06 layout.
