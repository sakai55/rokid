# AV Capture (av/)

[中文](README.md) | English | [日本語](README.ja.md)
Translated from the Chinese version (as of 2026-10-29).

AV capture series · IDs AV01–AV11: built around photo, video and voice interaction, each unit pushes on one platform boundary (three photo modes / grabFrame sampling / MediaRecorder chunking / four microphone modes and internal recording / external-stream ASR / the TTS generation side / barcode detection / LLM multimodality / dual-track audio-video capture / the internal-recording transcription chain), closing a "register → verify/compare → settle/replay" loop with AV as the main interaction channel. AV11 is an added verification edition (core chain first, deep features deferred).

- AV01 [tri-shot-lab](tri-shot-lab/) — Three photo modes shoot the same scene in a row; decoding is measured to judge which lens is usable
- AV02 [motion-frame-watch](motion-frame-watch/) — grabFrame samples frame differences on a timer to watch a point; changes are saved as evidence and announced
- AV03 [chunk-rec-studio](chunk-rec-studio/) — Probe recording formats and the real ceiling first, then record formally in chunks
- AV04 [mic-mode-arena](mic-mode-arena/) — Four microphone modes record the same scene for testing; pick the best mode per environment
- AV05 [hotword-forge](hotword-forge/) — Check ASR capability first, then forge hotwords and segmentation parameters; hits are measured
- AV06 [voice-subtitle-lab](voice-subtitle-lab/) — Synthesize word-level subtitles, choose voice and speed, A/B compare and save favorites
- AV07 [barcode-rally](barcode-rally/) — Continuous scanning checked off against a target list, settled by barcode symbology
- AV08 [dual-shot-verify](dual-shot-verify/) — Wide plus telephoto dual shots paired; only cross-verified results are booked
- AV09 [av-sync-check](av-sync-check/) — Audio and video tracks captured and checked together; a clap event computes the sync offset
- AV10 [system-audio-capture](system-audio-capture/) — Records only the device's playback sound; internal recording is chunked, transcribed and archived
- AV11 [stop-motion-studio](stop-motion-studio/) — Stop-motion verification edition: shoot frame by frame (onion skin), composite and play back at frame rate for verification readings

For the full list, see the Agent list at the end of the [repository root README](../README.md).
