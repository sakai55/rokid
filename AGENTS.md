# Mic Mode Arena — Design Contract

## Design contract

- `pages/index` — hub over a fixed set of 3 environments (street / meeting room / near-whisper); the first menu row cycles the environment (persisted to wx storage `av04_env`). The page states plainly: microphone modes apply only to `getUserMedia`; host ASR does not consume a mode; transcription is a reference score only.
- `pages/rounds` — a fixed set of 4 test sentences, TTS-read aloud per round. Four modes `wearer / far-field / near-field / omnidirectional` run in order: `getUserMedia({audio:{microphoneMode:{exact:mode}}})`, on `OverconstrainedError` retry with `{ideal:mode}` and flag the round; `track.getSettings()` reads back the actual mode; `MediaRecorder` records ~3 s (`audio/ogg;codecs=opus` when `isTypeSupported`, else host default); the Blob is decoded with `AudioContext.decodeAudioData` and RMS/peak are computed directly over the decoded channel data. Each round persists `{mode, actual, fellBack, rms, peak}` to `av04_rounds`. A parallel `SpeechRecognition` pass records a reference character count that never enters the ranking.
- `pages/board` — ranks rounds by score = RMS + peak × 0.25, speaks the conclusion, and on Enter/nod writes `av04_best[env] = mode`.
- `pages/memory` — lists the three environments from `av04_best` (untested shown as untested), speak selected, clear.

## Technical honesty

- A failed round is recorded with zero level and its failure reason; levels are never invented.
- exact→ideal fallback is labelled on the round and on the board; ranking uses the measured (fallback) take.
- The measurement method (decode + channel-data statistics) is named in code and README; it is not an AnalyserNode estimate.

## Permissions

- `RECORD_AUDIO` — mode-constrained capture, test-sentence recording, reference transcription.

## Validation

- Static check pending batch acceptance.
