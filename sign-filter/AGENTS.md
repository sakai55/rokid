# Sign Filter — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series F02 (FILTER 过滤型， second of the group): in an unfamiliar street,
every shop sign shouts for attention and the one you want hides among them.
This agent inverts the work: you declare the target first, then walk — only
a sign whose read text contains the target is allowed to surface.

## Design contract

- **Declare first, filter second, and the filter rule never changes
  mid-walk.** The target (DEMO sample pool: 全家 / 星巴克 / 中山路128号 /
  7-ELEVEN, all labelled DEMO samples) can only change in idle. Changing
  the target mid-walk would silently rewrite what counts as a hit while
  the wearer is trusting the filter — so every TGT tap while scanning is
  refused with an explanation, never silently applied. This is the same
  idle-only-settings discipline as F01's whitelist.
- **The match rule is one line, and it is the headline.** Normalised
  sign text (uppercase, spaces and hyphens stripped) must CONTAIN the
  normalised target string. There is no sign database, no fuzzy match,
  no brand recognition, no positioning: a misread character can cause a
  miss or a false hit, and the UI footer, the README and every hint say
  so. Examples the harness pins: 全家便利店 contains 全家 (hit);
  肯德基 does not (silent count); 星巴克咖啡 contains 星巴克 (hit);
  an empty read is never counted.
- **Non-matches only ever touch a counter.** A non-matching sign
  increments the seen count, is listed as 已看过， and produces no banner
  and no TTS. A filter that announced every non-match would be the
  opposite of a filter. A failed photo or failed read is NOT counted
  at all: the wearer did not actually see a sign's text, so counting
  it would lie about coverage.
- **Direction is declared, not positioned.** The hit banner reports
  the direction the wearer faced when the photo was taken (左/正前/右，
  set with DIR before PHOTO). There is no indoor/outdoor positioning
  in this agent, and the banner, the footer and the README say so —
  never "the shop is 30 m to your left", only "在你右手边" as the
  facing direction at capture time. The hit direction is stored with
  the hit itself (`_bannerDir`): the banner and its SPEAK line must
  never fall back to the current DIR setting, which may already have
  moved on to the next sign.
- **A photo is a deliberate tap, never an accidental nod.** A steady
  nod confirms only where confirmation is safe: START in idle, CONFIRM
  on the summary screen. In a live walk a steady nod is ignored on
  purpose — snapping a photo must be a deliberate tap. An unsteady nod
  never arms the 1.2 s lock (the F01 fix, kept).
- **Correction is cheap, destruction is confirmed.** DEL in a live
  walk only clears the hit banner — it never deletes the seen list or
  ends the walk. Back from the summary returns to the live walk
  without deleting anything; the summary is rebuilt on END. Confirming
  the summary (Enter / steady nod) is the only wipe.
- **DEMO is staged and never overwrites a user walk.** DEMO walks
  four stages: walk started (target 全家） → non-match sign 肯德基
  counted silently (seen 1, no banner, no TTS) → hit sign 全家便利店
  at 右， banner + one TTS → summary (seen 2, hit 1). A fifth DEMO tap
  reports the demo complete. DEMO refuses outright if a user walk is
  running. Every step is labelled DEMO; no real photo happens in DEMO
  (the preview host cannot provide a camera stream by design).
- **The walk lives in session memory only — zero persistence, by
  design.** There is no storage API anywhere in the page (no wx storage
  import use, no localStorage; harness-scanned). Target, seen list,
  banner and summary die when the summary is confirmed, when the agent
  closes (onUnload wipes everything), and never survive to the next
  walk. Close the agent and the filter is gone, which is the correct
  use for a walk happening right now.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). The only timers are the 1.2 s
  nod lock and the photo/LLM timeouts (9 s camera, 9 s photo,
  12 s convert, 30 s LLM read).

## Relation to the neighbours (kept distinct on purpose)

- Directional-series `sign-reader` reads ANY sign you look at, out
  loud — it is a reader. Sign-filter reads signs only to test them
  against a declared target and surfaces only the match — it is a
  filter. Same camera, opposite attention contract.
- `focus-shield` (F01) is a session gate for sound: whitelist words
  interrupt, everything else is logged. Sign-filter is the visual
  twin of that gate: a declared target interrupts, every other sign
  is counted. The idle-only-settings discipline and the
  zero-persistence discipline are shared on purpose.
- `shelf-sweep` (C05) proves coverage of a shelf you already face.
  Sign-filter proves nothing about coverage — it only answers
  "is the thing I want among the signs I have looked at so far".

## Permissions

CAMERA only — `permissions` is exactly `["CAMERA"]` in app.json, and
the static check asserts exactly that. The telephoto photo
(ImageCapture `telephoto`, guarded try/catch so the preview host
fails soft) plus the host LLM image input is the only read path.
No `RECORD_AUDIO`: nothing is spoken into this agent (targets are
picked from the pool, directions are tapped, confirmation is a
gesture). No `GEOLOCATION`: a street walk needs no position, and
this agent never knows where you are — that ignorance is stated in
the UI footer, the README and every hint it gives.

## Validation

- Node harness (see `/tmp/sign-filter-harness.js`, not packed):
  app.json permissions exactly ["CAMERA"]; zero storage/geo/audio
  APIs in the page source; no legacy Page/App/Widget; no utterance
  lang assignment; initial idle state (target 全家， direction 正前，
  seen list empty, idle big shows target); TGT cycles with wrap and
  mid-walk refusal; DIR cycles 左/正前/右 with wrap and summary
  refusal; START double-start refusal; match rule battery
  (contains hit, non-match silent, case/space/hyphen normalisation,
  empty read ignored, target-in-sign vs sign-in-target asymmetry);
  _onSignRead paths (hit banner + exactly one TTS + focus, non-match
  silent count, banner DEL clears banner only, END summary counts,
  back-to-walk rebuild, confirm clears); NEXT/PREV wrap and rowTap
  focus; DEMO four-stage arc and refusal on a user walk; nod
  discipline (unsteady ignored without arming the lock, steady nod
  starts in idle, ignored in scanning, confirms on summary, non-nod
  inert, 1.2 s lock); SPEAK lines per mode; onUnload wipes seen
  list, banner, mode and demo flag; photo path soft-fails without a
  camera (no entry counted, busy released); bigCls thresholds.
  Result: **142/142** (including the banner-direction regression:
  the hit banner and its SPEAK line must report the direction of the
  hit photo, never the current DIR setting — caught during preview
  when a hit at 右 rendered as 正前方）.
- Preview screenshots 5, each visually verified (not just
  hash-compared): idle (target 全家）, scanning (DEMO stage 1),
  non-match counted (DEMO stage 2, 肯德基 counted silently),
  hit banner (DEMO stage 3, 全家便利店 · 右）, summary (DEMO stage 4,
  seen 2, hit 1). Hit coordinates probed per state (see
  `shot-sign-filter.js`, `probe-sign-filter*.js` in
  `~/workspace/preview-tools/`): DEMO is the row-1 first button
  (x=88); its true y moves with the info-box height — probe every
  state and verify every PNG by eye, per the recorded F01/H02
  lesson that a single hash probe can hit the wrong button.
