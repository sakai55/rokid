# Dual Shot Verify — Agent Notes

AV08, boundary B8 (two photos, one LLM session, three serial rounds).

## Design contract

- Wide registration (index): hub menu plus a real wide capture; the spoken item name is dictated and re-speaking is the correction path.
- Detail (detail): capture is gated by head stability from `onOrientationStabilityChange`; unsteady means no photo, only a prompt.
- Verify (verify): one session, three serial rounds — wide alone, detail alone, then both photos plus both answers via `promptStreaming` polled with `read()`. A local ITEM/VALUE compare settles disagreement on top of the model's AGREE line.
- Ledger (ledger): filing is gated on an agreeing, completed verdict; records persist in `av08_records`. Photos and round results travel between pages in the temp key `av08_tmp` (hand-off, not persistence).

## Technical honesty

- Single-photo judgement is never shown as a conclusion; that is the stated difference from generic visual recognition.
- Any failed or ambiguous round yields "verification incomplete" and blocks filing; nothing is invented.
- Shrink failures fall back to the original dataURL and are labelled; all hardware APIs are guarded and fail visibly in Web preview.
- TTS never sets utterance `lang`.

## Permissions

`CAMERA` (both photos) and `RECORD_AUDIO` (dictated name and the rerun voice command), exactly as declared in app.json.

## Validation

- Static: JSON parse of app.json/package.json; `node --check` on every extracted setup script; green-only palette scan.
- Device stage (pending): confirm wide/telephoto modes, head-stability gating, streaming round 3, and the mismatch TTS line on real glasses.
