# Door Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series W05 (WATCH 守望型）: a door watcher for people working in an inner
room or wearing headphones, who otherwise hear the doorbell, a knock or a
delivery only by luck.

## Design contract

- **No sound classification, no sound localisation — this is the core
  honesty boundary of this agent.** The platform offers neither. The PLAN
  row's original wording ("守听门铃/敲门特征声 + 转头 SCAN 报正门方向") was
  therefore adapted, not implemented literally: the agent reacts to
  loudness PATTERNS only, and every direction it reports comes from the
  wearer's registration, never from any sound.
- **The door is registered by heading.** Sitting in the usual seat, the
  wearer faces the door and SET binds the current heading plus a door
  label （正门/后门/院门）. No heading reading → registration is refused
  honestly; a heading is never invented (same discipline as the siblings).
  All later directions are relative (registered heading − current
  heading, + = right) and recomputed live from the wearer's current
  heading — the door's direction display works with LISTEN off, too.
- **LISTEN is a level-pattern watch, nothing more.** An omnidirectional
  `getUserMedia` stream feeds an AnalyserNode; only the RMS level number
  is used (analyser never connected to destination; tracks stopped on
  stop/hide/unload; OverconstrainedError → labelled default-mic fallback).
  On the 250 ms tick clock, segments at/above the bell floor are
  classified by SHAPE only:
  - spike candidate: peak ≥ spike threshold, duration ≤ 2 s;
  - burst: 2 spike candidates completing within 5 s (knock-shaped) →
    fires;
  - bell shape: one segment between the bell floor and the spike
    threshold sustained 1–3 s (bell-length) → fires;
  - a lone spike earns nothing; a segment over 3 s (sustained loud: TV,
    running water, a speakerphone call) earns nothing; a loud segment
    matching no shape is ignored and the EVT line says so.
- **One nudge per episode.** Firing speaks ONCE — "刚才有一阵响动 —
  正门在你右后方，去看一眼" (registered label + current relative
  direction) — and leaves a banner until the wearer FACES the door
  (±15° cone, head steady, 1 continuous second = face ack) or taps ACK.
  Patterns completing during cooldown are the same episode: no repeat.
  Re-arm needs 10 continuous seconds of quiet.
- **Sensitivity （灵敏/标准/安静屋） scales level thresholds only**
  (×0.75 / ×1.0 / ×1.25 of spike 0.60 / bell 0.50) and is labelled as
  such everywhere it appears.
- **This agent has NO speech recognition at all.** The mic mode only
  ever shapes the getUserMedia level stream; there is no host ASR for it
  to influence, and no wording anywhere suggests otherwise. TTS uses the
  fixed host voice; the utterance `lang` is never set (documented as not
  taking effect on this platform).
- A steady nod only speaks the status (door direction, listening state,
  sensitivity, nudges so far) — it never registers, never acks, never
  toggles listening. The watch exists only while the page is open; a
  constant on-screen line says so. Zero persistence by construction: no
  wx storage calls anywhere; registration and counters live in page
  memory and die with the page.
- DEMO registers a front door at 120° with the demo head at 0° and plays
  a simulated level feed: one lone spike (counted, explained on the EVT
  line, earns nothing), then a knock-shaped burst that fires the nudge
  with the registered direction. Each DEMO tap turns the demo head
  +45°; at 135° the door is inside the ack cone, the 1 s dwell runs and
  the face ack closes the loop; the next tap restores the real state
  exactly.

## Permissions

`RECORD_AUDIO` only — for the omnidirectional level stream that feeds
the pattern watch. The audio is never recorded, stored or sent anywhere;
only a loudness number is computed. No camera, no geolocation.

## Validation

- Node harness (57 assertions): registration refusal without a heading,
  full pattern matrix (single spike ignored with EVT explanation / burst
  fires once / bell shape fires once / sustained loud earns nothing /
  cooldown pattern = same episode / re-arm after 10 s quiet / long
  high segment matches no shape), direction wording always from the
  registration and recomputed from the current heading, face-ack dwell
  semantics (unsteady / out-of-cone / sweep-through all earn nothing),
  tap ack, sensitivity threshold scaling （标准 ignores 0.52 spikes,
  灵敏 fires on them), gesture-only walkthrough, nod = SPEAK only,
  DEMO arc (lone spike → burst → rotate → face ack → exact restore),
  OverconstrainedError fallback, onHide track release, zero wx calls,
  TTS lang never set, and a scan of every spoken string for any
  identification/localisation claim.
- Preview screenshots in `artifacts/` (index / demo nudge / face-acked),
  generated with the local Ink runtime pipeline; DEMO hit coordinates
  probed per layout state ((400,220) compact, (400,240) with the alert
  banner up).
