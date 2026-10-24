# Signal Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series W04 (WATCH 守望型）: a queue-number look-back watcher for clinics,
banks and food counters.

## Design contract

- **The numbers come from the wearer's eyes, always.** MY (your number)
  and NOW (the number currently called) are entered by stepper or by the
  wearer dictating the number THEY saw. The agent never reads the hall
  screen (no screen capture, no OCR claim) and never listens to the PA
  system (no broadcast recognition is claimed anywhere — UI, speech or
  docs).
- SETUP edits one active field (FIELD cycles 你的号 → 当前号 → 场馆）.
  步进器 +1/+10/−1 and swipes (↑ +1 / ↓ −1) adjust it; the venue chip
  （医院/银行/取餐/其他） is a display label only and never enters math.
  GO/Enter advances the field, then starts: both numbers are required
  and MY > NOW, otherwise an honest refusal ("你的号已经过了？") — the
  watch never starts on numbers that already passed.
- WATCH is a 250 ms tick engine; all timing is tick counts, never
  re-sampled wall-clock deltas. A look-back cadence (CAD chip: 1/2/5
  min, default 2) fires once per interval: TTS "回看一下大屏，更新当
  前号" + a banner that stays until NOW is updated (any entry path) or
  GO snoozes it for exactly one cadence (LATER).
- Every NOW update recomputes gap = MY − NOW, stamps the update, and
  re-evaluates states. Pace = numbers advanced between the first
  stamped update and the latest ÷ tick time between them, shown with
  the counted update number and labeled as coming from YOUR updates;
  stepper bursts within 10 s count as one update. ETA = gap ÷ pace,
  shown only when ≥2 updates produced a positive pace, else the line
  honestly says rate unknown.
- READY at gap ≤ 3 (gap 4 is not ready): spoken once per approach
  ("只差 N 个号了，准备过去"), re-arms when the gap grows past 3 again.
  CALLED at gap 0: spoken once ("到你的号了"), banner until DONE.
  PASSED when an update shows NOW > MY: spoken once ("已经过号了，去
  服务台问问"), shown plainly, never papered over.
- GO (Enter) is the only contextual primary: setup field-advance/start,
  CALLED/PASSED → DONE, pending look-back → LATER, otherwise SPEAK.
  A steady nod only reads gap/ETA aloud — it never starts, updates,
  snoozes or finishes. SPEAK works in every state.
- DICT order is binding: wearer-mode availability check on
  `getUserMedia` FIRST (result on its own "MIC CHECK:" line, mode read
  back from track settings, tracks stopped at once), THEN host
  `SpeechRecognition` for what the wearer says. Mic modes apply only to
  getUserMedia streams and never shape host ASR; listening is labeled
  "(host ASR)". Parsing accepts Arabic digits and Chinese numerals
  （一百二十八， 一千二， 二百五）; anything unparsable is rejected
  visibly and the value stays unchanged — a number is never guessed.
- Reminders exist only while the page is open; a constant on-screen
  line says so. Zero persistence by construction: no wx storage calls
  anywhere; numbers live in page memory and die with the page.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect on this platform).
- DEMO seeds MY 128 / NOW 117 （医院） in memory with the look-back
  reminder up; each extra DEMO tap fast-forwards the tick clock one
  cadence and applies one scripted update (+3/+3/+3/+2/+1), walking
  READY → CALLED → PASSED; the next tap restores the real state exactly.

## Permissions

`RECORD_AUDIO` only — for the wearer's own dictation of numbers they
saw, preceded by the wearer-mode mic check. No camera (the agent does
not read the screen), no geolocation.

## Validation

- Node harness (105 assertions): setup validation incl. MY≤NOW refusal,
  stepper/DICT entry incl. Chinese-numeral parse + garbage rejection +
  mic-check-before-ASR ordering, cadence firing once per interval +
  snooze + update reset, gap/pace/ETA math from tick-stamped updates,
  READY at gap 3 (not 4) with re-arm, CALLED at 0, PASSED on overshoot,
  gesture-only walkthrough (swipes + Enter), nod = SPEAK only, DEMO arc
  + exact restore, zero wx calls, TTS lang never set.
- Preview screenshots in `artifacts/` (setup / demo look-back / ready /
  called), generated with the local Ink runtime pipeline.
