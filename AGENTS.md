# Voice Subtitle Lab — Agent Notes

AV06 (audio/video boundary series). One scene: before putting a spoken announcement on air in a shop or at home, the wearer picks the voice, rate and pitch that read clearly and keep up with word subtitles, compares A/B, and keeps the winning combo.

## Design contract

- Script library (index): 8 built-in broadcast scripts, countable in code; host `SpeechRecognition` dictation (interimResults on, transcript from `results[resultIndex][0]`) can append one spoken script; a mishear is fixed by dictating again.
- Synth (synth): all 11 official voice ids listed; rate (0.8/1.0/1.2), pitch (0.9/1.0/1.1), preferredFormat (mp3/ogg_opus/pcm) and sampleRate are stepped options; synthesis is `speechSynthesis.synthesize(utt, {subtitles:'word', audio:{...}})`; `task.onchunk` cues light up word by word with a big current-word stage; `SpeechAudioPlayer` plays/pauses; `task.abort()` aborts; synth time and `task.finished` duration are shown.
- A/B (ab): both combos side by side (voice/rate/pitch/synth time/duration/cue count); each side re-synthesizes for replay because a live task object cannot cross pages; Enter crowns the winner.
- Favs (favs): winning combos (script index + voice + rate + pitch) persist in wx storage `av06_favs` across sessions; single delete and clear supported.
- Handoff between pages uses wx storage temp keys `av06_script_tmp` / `av06_combo_tmp` / `av06_ab_tmp` / `av06_winner_tmp` (handoff only).

## Technical honesty

- The `speak()` queue has no pause/cancel, so all playback control goes through synthesize + player; the UI says so.
- `utterance.voice` is assigned the voice id string (the voice property exists per the capability dossier); if the host rejects the assignment, the error is shown and synthesis stops — no silent fallback voice.
- The utterance `lang` attribute is never set (documented as not taking effect).
- Every API call is guarded; on a host without synthesize/player/ASR the pages render and state the gap plainly. No fake cues, timings, or transcripts.

## Permissions

`RECORD_AUDIO` only: dictating a custom script on the library page. Synthesis itself needs no permission declaration beyond the host TTS.

## Validation

Static check pending batch acceptance: JSON parse of app.json/package.json, `node --check` on every extracted `<script setup>`, green-only palette scan, and API-wiring grep (synthesize / onchunk / SpeechAudioPlayer / abort / 11 voice ids / 8 scripts) to be run by the batch acceptance pass.
