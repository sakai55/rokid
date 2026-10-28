# Barcode Rally — Agent Notes

AV07 (audio/video boundary series). One scene: a hands-busy shelf/storeroom stocktake — scan codes continuously, verify them against a 10-item target list, correct mistakes by voice, and settle counts by format.

## Design contract

- Format gate (index): `BarcodeDetector.getSupportedFormats()` lists the real host formats with a count; the 10-item target list (name + expected canonical format + example value) is always visible.
- Scan (scan): `getUserMedia({video:true})` -> `ImageCapture` -> `grabFrame()` ImageBitmap fed directly to `BarcodeDetector.detect()`; on grab failure it falls back to `takePhoto({mode:'wide'})` Blob and labels the fallback. Results show format/rawValue/boundingBox numbers; the same rawValue inside a 3-second dedup window only prompts, never double-counts; every accepted code is spoken (first 20 chars of rawValue). Tracks are always stopped in `finally`.
- Tally (tally): a target verifies automatically only when BOTH format and value match; a format-only match is reported as "same format, different value". Manual verification (Enter applies the latest scan to the selected target) is the honest correction path. Voice correction via host `SpeechRecognition`: "delete item X" by index or by barcode tail deletes a bad scan.
- Settle (settle): counts by format plus verification progress x/10, written into wx storage `av07_tally` on explicit settle only (guarded against double-counting); clear starts a fresh round.
- Round state travels via wx storage temp keys `av07_scans_tmp` / `av07_manual_tmp` / `av07_formats_tmp` (handoff only).

## Technical honesty

- `detect()` is only ever fed an ImageBitmap or a Blob — never a VideoFrame or an element (per the capability dossier).
- Target example values are samples printed in the README; real items rule on device. The agent never pretends an automatic match it did not make: format-only matches and manual verifies are labelled as such on screen.
- Every API call is guarded; on a host without camera/detector/ASR the pages render and state the gap plainly. No fake formats, codes, or counts.

## Permissions

`CAMERA` only: scanning needs camera frames/photos. Voice correction uses the host recognizer; no separate audio permission name exists for it in the declaration set used here beyond the host ASR path, and no location is used.

## Validation

Static check pending batch acceptance: JSON parse of app.json/package.json, `node --check` on every extracted `<script setup>`, green-only palette scan, and API-wiring grep (getSupportedFormats / grabFrame / takePhoto wide / detect / dedup window) to be run by the batch acceptance pass.
