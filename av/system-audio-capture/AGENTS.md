# System Audio Capture — Agent Notes

AV10, boundaries B10 (system-audio capture feeding a transcription chain) plus B4 (capture-source discipline).

## Design contract

- Source gate (index): the only audio request anywhere in this agent is the system-audio capture source; success reads back `getSettings()` and a one-second silence check runs through an Analyser.
- Capture (capture): reopens the stream under the same discipline, records with a preferred ogg/opus type when supported (fallback labelled), 250ms timeslices counted on screen, live level meter. The Blob crosses pages as a dataURL in the temp key `av10_tmp`.
- Transcribe (transcribe): the recognition session never opens a microphone; the restored Blob is sliced by a max chunk size and written serially through the session writer, then closed; interim and final results form the draft.
- Archive (archive): filings persist in `av10_archive` with time, duration estimate, full transcript and byte size; playback restores the Blob and uses the Web Audio decode path.

## Technical honesty

- No microphone fallback, ever: a failed source request stops the flow and says why. The code carries no mic-mode parameter and no echo-cancellation constraint.
- Oversize recordings are warned on screen at 500KB; a failed temp-key write is reported, not hidden. Front-segment-only transcription for oversize recordings is a placeholder, stated as such.
- The session writer is probed in three shapes and the step that fails is named; no transcript is ever invented.
- TTS never sets utterance `lang`; the recognition session language is a separate, documented parameter.

## Permissions

`RECORD_AUDIO` only (the system-audio source stream), exactly as declared in app.json. No camera, no location.

## Validation

- Static: JSON parse of app.json/package.json; `node --check` on every extracted setup script; green-only palette scan; grep that no mic-mode or echo-cancellation constraint appears in code.
- Device stage (pending): confirm the capture-source constraint behaviour, `getSettings()` read-back, MediaRecorder mime support, and the recognition session writer/result shapes.
