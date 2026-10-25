# Last Glance — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series CO01 (COVER 覆盖型， first of the group): the leave-the-room archive
for the walk-away worry — hotel room, seat, campsite — where the question
"did I leave anything / close the window" returns the moment you have
walked too far to check cheaply.

## Design contract

- **Not a photo album, and not a room map: the product is coverage
  proof.** Six heading zones （前 / 右前 / 右后 / 后 / 左后 / 左前）
  are the whole model. A zone you never photographed stays visibly
  missing (○ 未拍） in the list, and only 6/6 lights the "you may
  leave" summary. The list IS the coverage: there is no other
  completeness signal, and no zone is ever inferred from another.
- **The archive lives in session memory only — zero persistence, by
  design.** There is no storage API anywhere in the page (no wx
  storage import use, no localStorage; harness-scanned). Each zone is
  an instance field: it dies when the archive is cleared (two-step
  DEL from the summary), when the agent closes (onUnload clears the
  fields, and nothing was ever written anywhere else). The useful
  window is "just left, worrying on the road", not a permanent
  archive — the UI count line says so constantly （只存本次会话内存 ·
  关掉即清 · 零落盘） and the README states the window honestly.
- **Replay is text, not photo playback — the honesty core of this
  agent.** The glasses display is monochrome green (480×352) and
  cannot replay colour photos. So each zone's replay shows its one
  short description plus a "photo archived" marker: the description
  IS the replay, the photo is the session archive that backs it.
  No screen, string or TTS line claims a photo is being shown back.
  (Harness scans the spoken strings for photo-playback claims.)
- **No indoor positioning, no room map.** Zones come only from the
  order you turn through them: focus moves by NEXT/PREV swipes, and
  after a confirmed zone it jumps to the next missing zone. There is
  no geolocation permission, no floor plan, no arrow, and no spoken
  or shown string claims to know where a zone is in the room
  (harness scans every spoken string for navigation/positioning
  claims). A zone's name is a heading relative to where you stood
  when you started the sweep, nothing more.
- **Reading is the official photo path, and it is gated twice.**
  SNAP takes a wide-field photo (`ImageCapture.takePhoto({mode:
  'wide'})`, wx camera-context fallback like the siblings); the Blob
  becomes a data: URL via `FileReader` and goes to the host
  `LanguageModel` as an `image_url` part of ONE user message (system
  prompt via `initialPrompts` only, `availability()` first, session
  `destroy()`ed after — dossier §2.9). One strict reply format
  (`ZONE: <one short line>`, with a `NONE` form); the parser accepts
  the clean format or one short salvage line (≤30 chars) and rejects
  prose — an unclear reply is a failed description, never a guess.
  There is no OCR on this platform and none is claimed. The photos
  live in memory only and are discarded after their describe attempt.
- **Nothing becomes an archive entry until the wearer confirms it.**
  A photo's description lands on a CONFIRM view, labelled as a
  machine read that may misread. OK (or a steady nod — the ONLY thing
  a nod means here, and only while a photo waits) archives it; DEL
  discards it in one tap — it was never archived. A failed
  description is not a dead end: OK still archives the zone as
  "已拍·未读出描述" (photographed, description unread), labelled as
  exactly that, so a zone is never blocked by the model. The wx
  fallback photo (no Blob) lands on the same path, honestly labelled.
- **Replay is a first-class mode, not an afterthought.** REPLAY from
  the summary (or from a partial sweep, once ≥1 zone is archived)
  opens zone-by-zone browsing: NEXT/PREV move, SNAP retakes the
  current zone (confirm overwrites it, staying in replay), DEL/OK
  return to wherever replay came from — the summary if the archive
  was complete, the sweep if it was partial (a partial replay must
  never fake a 6/6 summary; harness asserts this). Clearing the
  archive is two-step DEL from the summary, with a 6 s arm that any
  other action cancels.
- **DEMO is two stages and never overwrites real archives.** From a
  fresh sweep, DEMO first simulates 2 zones （前 / 右前）, then the
  remaining 4, landing on the summary — every step labelled DEMO,
  no camera used. If any real (non-DEMO) zone exists, DEMO refuses
  outright rather than mixing simulated zones into a real archive.
- TTS uses the fixed host voice; the utterance `lang` is never set
  (documented as not taking effect). No timers drive stored data —
  the only timers are the 1.2 s nod lock and the 6 s two-step disarm
  window.

## Permissions

`CAMERA` only — wide photos of each heading zone (every Blob lives
in memory only and is discarded after its describe attempt). No
`RECORD_AUDIO`: there is deliberately no dictation anywhere in this
agent (correction is confirm/discard/retake, not speech). No
`GEOLOCATION`: zones are heading-relative sweep order, and this agent
never knows where you are — that ignorance is stated in the UI
footer, the README and every hint it gives.

## Validation

- Node harness (90 assertions): app.json permissions exactly
  [CAMERA]; zero storage/geo/audio/ASR APIs in the page source; no
  legacy Page/App/Widget; no utterance lang assignment; no
  navigation/positioning/arrival/photo-playback claims in spoken
  strings; description parser battery (ZONE format, NONE forms,
  prose rejection, short-line salvage, 30-char slice); initial state
  (6 empty zones, focus 前）; navigation wrap (NEXT/PREV cycle);
  confirm gate (OK confirms, DEL discards, failed description kept
  as photographed); nod discipline (unsteady ignored, steady nod
  confirms only a pending photo, nod in done inert); DEMO arc
  (2 → 6 zones, summary, DEMO in done inert, DEMO refuses a real
  archive); replay (from done and from partial sweep, retake
  overwrites in place, partial replay returns to sweep — never a
  fake 6/6); two-step clear (arm, second DEL wipes, other actions
  cancel the arm); onUnload wipes the archive; prompt shape (text +
  image_url data: URL in user content, system only via
  initialPrompts); camera + LLM happy path with stubs (wide mode
  asserted, bytes on the CAP line, tracks stopped, session
  destroyed, zone archived); LLM throw → fail-kept path; no-camera
  host → fail-kept path.
- Preview screenshots 4, each visually verified (not just
  hash-compared): sweep 0/6, DEMO partial 2/6, summary 6/6, replay of
  the 前区 description. Hit coordinates were probed per state: the
  DONE state's hit strip sits ~15 px higher than the sweep state's
  (REPLAY at (400,205) in done, (400,195) in sweep) — the same
  box-growth shift seen in seat-catch, recorded in `shot-last.js`.
