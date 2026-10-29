# AV Capture (av/)

[中文](README.md) | English | [日本語](README.ja.md)
Translated from the Chinese version (as of 2026-10-29).

AV capture series · IDs AV01–AV11. Built around the camera, video, and voice, each agent pushes on one platform limit — the three photo modes, grabFrame sampling, chunked MediaRecorder recording, the four mic modes and internal audio capture, external-stream ASR, the TTS synthesis side, barcode detection, multimodal LLM input, dual-track A/V capture, and the internal-recording transcription pipeline — and closes the loop: register → verify/compare → settle/replay, with audio and video as the primary channel. AV11 is a later add-on verification build: core pipeline first, deeper features deferred.

- AV01 [tri-shot-lab](tri-shot-lab/) — Shoots the same scene in all three photo modes back to back and measures the decode results to tell you which mode actually works
- AV02 [motion-frame-watch](motion-frame-watch/) — Watches a spot via timed grabFrame frame-diff sampling; saves evidence and calls out when something changes
- AV03 [chunk-rec-studio](chunk-rec-studio/) — Probes supported recording formats and the real duration ceiling first, then records in chunks
- AV04 [mic-mode-arena](mic-mode-arena/) — Records the same scene in all four mic modes and picks the best one for the environment
- AV05 [hotword-forge](hotword-forge/) — Checks ASR capability first, then tunes hotwords and segmentation settings and measures the hit rate
- AV06 [voice-subtitle-lab](voice-subtitle-lab/) — Synthesizes word-level subtitles; pick a voice and rate, A/B them, and save favorites
- AV07 [barcode-rally](barcode-rally/) — Scans barcodes continuously and checks them off against a target list, settled per symbology
- AV08 [dual-shot-verify](dual-shot-verify/) — Pairs a wide shot with a telephoto shot; only cross-checked results get booked
- AV09 [av-sync-check](av-sync-check/) — Captures audio and video together and checks both; a hand clap marks the event used to compute the A/V sync offset
- AV10 [system-audio-capture](system-audio-capture/) — Records only what the device itself plays; the internal recording is chunked, transcribed, and archived
- AV11 [stop-motion-studio](stop-motion-studio/) — Stop-motion verification build: shoot frame by frame with an onion-skin overlay, then composite and play back at frame rate to read out the results

For the full list, see the Agent index at the end of the [root README](../README.md).
