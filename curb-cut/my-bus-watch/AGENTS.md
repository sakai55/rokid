# My Bus Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series K02 (FILTER 守望型）: a target-route bus watcher for blind /
low-vision wearers waiting for one specific bus.

## Design contract

- **The outsourced attention is filtering, not reading.** The wearer
  cannot stare at every approaching bus head sign. The agent holds
  ONE target route and speaks only the verdict for that route: this
  is your bus, or this is route X, not yours, keep waiting. It never
  describes the street, the bus, or the scene in general — that is
  Huiyan territory and is explicitly out of scope.
- **The route number comes from a photo check or from the wearer.**
  CHECK does: `telephoto` photo of the bus head sign (head aimed at
  the bus) + host `LanguageModel` reading, prompted to answer ONLY
  a route number (or NONE). The parsed number is compared with the
  target; no other text from the model is ever shown or spoken as a
  route. A manual fallback exists: the wearer (or a helper telling
  them) can step in / dictate the observed route number, and the
  same comparison runs. An unparseable photo answer is SKIP, not a
  guess, and the watch continues.
- **Target first, verdict second.** SETUP requires a target route
  (>0) before WATCH starts; a start with no target is refused
  honestly. Every new observed value is evaluated exactly once:
  match -> HIT spoken once, banner until GO (boarded); non-match ->
  spoken once per new value ("这辆是 X 路，不是你的 Y 路，继续等");
  repeating the same observed value does not re-speak.
- **Reminders only while open, fixed 2-minute look-out cadence.**
  A 250 ms tick engine counts ticks; every 2 minutes in WATCH it
  speaks once "留意一下有没有车来" until the next CHECK / observed
  update or a GO snooze (exactly one cadence). Nothing is persisted:
  no storage calls anywhere; target and checks live in page memory.
- **Voice is primary.** All instructions, verdicts and prompts are
  spoken once via TTS (fixed host voice; utterance `lang` never set,
  documented as not taking effect). The screen mirrors the same
  lines for a sighted helper and for preview.
- **Gestures:** single tap = Enter = contextual GO (setup->start,
  watch prompt pending->snooze, watch otherwise->SPEAK, hit->boarded,
  done->fresh setup); swipe up/down = active value +1/-1; steady nod
  in WATCH = CHECK (photo check), elsewhere = SPEAK; double-tap =
  host back, never intercepted.
- **DICT order is binding** (as in signal-watch): wearer-mode
  getUserMedia availability check FIRST (result on its own MIC CHECK
  line, stream stopped at once), THEN host SpeechRecognition for
  what the wearer says. Mic modes apply only to getUserMedia streams
  and never shape host ASR. Parsing accepts Arabic digits and
  Chinese numerals; anything unparsable is rejected visibly and the
  value stays unchanged.

## Permissions

`CAMERA` + `RECORD_AUDIO`. CAMERA is for the telephoto head-sign
photo check. RECORD_AUDIO is for the wearer's dictation of route
numbers they were told / read, preceded by the wearer-mode mic
check. The agent never listens to bus announcements or street audio
for route detection.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used.
- Preview screenshots in `artifacts/` (setup / watch / miss /
  hit), generated with the local Ink runtime pipeline.
