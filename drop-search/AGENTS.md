# Drop Search — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Curb-Cut
series K01 (COVER 覆盖型）: a floor-sector search for blind / low-vision
wearers who dropped a small item.

## Design contract

- **The outsourced attention is coverage, not recognition.** The wearer
  loses the map of which floor patches around their feet have been
  swept. The agent holds that map: 6 sectors (正前方 / 左前方 /
  右前方 / 左侧 / 右侧 / 身后）, one spoken instruction at a time,
  one checked box per sector. It never says "look, there it is" from
  a generic scene description — that is Huiyan territory and is
  explicitly out of scope.
- **Voice is primary, zero screen dependency.** Every sector change,
  check and outcome is spoken once via TTS (fixed host voice; the
  utterance `lang` is never set, documented as not taking effect).
  The screen mirrors the same lines for a sighted helper and for
  preview only. A blind wearer can run the whole sweep by voice +
  nod + temple tap/swipe.
- **FOUND has exactly two honest sources:** (1) the wearer confirms
  with FOUND, (2) the optional PHOTO path (ImageCapture `wide` +
  LanguageModel) actually reports the item in this sector's photo.
  PHOTO "yes" is still labeled tentative ("请用手确认") — the hand
  is the final check. Any missing step (no camera path, no photo,
  no LLM, LLM "no") is reported as SKIP / not-a-find, never as a
  find, and the sector stays hand-sweep only.
- **NOT FOUND is an earned verdict, not a default.** It only fires
  after all 6 sectors are checked, and it says plainly "6 区全查完，
  没找到" plus the honest possibility the item rolled elsewhere.
  A sector is never marked checked by a photo alone.
- **Gestures:** single tap = Enter = contextual GO (setup→start,
  sweep→SPEAK, found/notfound→fresh setup); swipe up = next sector,
  swipe down = previous sector; steady nod = CHECK current sector
  (never a find by itself); double-tap = host back, never intercepted.
- **Zero persistence by construction:** no storage calls anywhere;
  sectors live in page memory and die with the page. The search
  restarts fresh every time — that is the point: the map is for
  THIS search only.

## Permissions

`CAMERA` + `RECORD_AUDIO`. CAMERA is only for the optional PHOTO
check (wide photo + LLM, guarded, SKIP on any failure); the core
sweep needs no camera at all. RECORD_AUDIO is declared because the
agent uses the host voice path / TTS context; no dictation or
recording is performed in v1.0.0 and no audio is stored.

## Validation

- Static check: app.json parses; `<script setup>` and app.js pass
  `node --check`; no `Page(`/`App(`/`Widget(` legacy usage; no
  invented APIs; permissions match the features actually used
  (CAMERA only in PHOTO, RECORD_AUDIO declared for the voice path).
- Preview screenshots in `artifacts/` (setup / sweep / demo found /
  demo not-found), generated with the local Ink runtime pipeline.
