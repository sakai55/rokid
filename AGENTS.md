# Tri Shot Lab — Design Contract

## Design contract

- `pages/index` — hub menu over a fixed, countable set of 6 shoot targets (distant sign / small print / barcode / price tag / meter / packaging text). Voice selection via `SpeechRecognition` transcript matching against the 6 names; Enter or nod confirms and navigates to shoot. Selection persists to wx storage `av01_target`.
- `pages/shoot` — one `getUserMedia({video:true})` stream, one `ImageCapture`; `takePhoto` in `wide`, `telephoto`, `default` order; each Blob decoded with `createImageBitmap` for real pixels and measured with `Blob.size`; centre crop via document canvas `drawImage` 9-arg + `convertToBlob` jpeg 0.7, then data URL via `blob.arrayBuffer()` + chunked `String.fromCharCode` + `btoa` (conversion failure raises E2005; fallback: raw photo data URL). Results persist to `av01_current`; all tracks stopped in `finally`.
- `pages/verdict` — `LanguageModel` session; the three crops are judged SERIALLY, one awaited multi-modal `session.prompt` per crop (multi-image single prompt is not assumed); prompt contract is `READ: <text|NONE>` + `LEGIBLE: YES/NO`; conclusion derives from LEGIBLE plus measured pixels, is spoken via TTS, and is appended to `av01_history`.
- `pages/history` — reads `av01_history`, shows the latest 8, speaks the selected entry, can clear.

## Technical honesty

- Every hardware call is guarded and try/caught; a host without camera, canvas or LLM renders normally and states the capability is missing — no fake photos, no invented readings.
- LLM unavailable degrades the verdict to a pixel/byte comparison and says exactly that.
- TTS helper never sets `utterance.lang`. ASR copy never implies the host recogniser consumes a microphone mode.

## Permissions

- `CAMERA` — three-mode shooting. `RECORD_AUDIO` — voice target selection.

## Validation

- Static check pending batch acceptance.
