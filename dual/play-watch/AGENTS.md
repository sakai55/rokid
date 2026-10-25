# Play Watch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series D01 (DUAL 并行型， first of the group): at a playground, the
parent's main line is resting on a bench and the side line is "is the
child still in the play area". The parent cannot watch continuously
and rest at the same time, so the agent takes the remembering: register
the area once by looking at it and holding steady, then a timer
reminds the parent to look back every 5 minutes (DEMO interval). A
look-back confirmed by tap or steady nod resets the timer; a reminder
left unconfirmed escalates — banner, then one TTS plus a brighter
banner, then a strong "go and look in person" reminder — and the
outing ends with a small summary of confirmed and missed look-backs.

## Design contract

- **The side line is a registered heading, never a tracked
  position.** REG stores only a label ("活动区", or the DEMO sample
  "滑梯区 · 红外套") and the fact that it was registered while the
  wearer looked at it and held steady. There is no camera, no mic,
  no location, no person detection anywhere in the agent, so there
  is nothing that could know where the child is — and the agent
  never claims otherwise. The heading is a reminder anchor, not a
  location.
- **The timer is the whole mechanism, and it only moves in one
  place.** Every interval step goes through `_checkDue`: due with
  level 0 raises a banner-only reminder; a further due interval
  with the reminder still open escalates to level 2 (one TTS,
  missed +1) and then level 3 (one TTS, missed +1); at level 3 a
  further due interval only increments missed. The DEMO clock
  (TICK adds one interval) and the real 30-second ticker share
  exactly this path, so the preview and the device cannot drift
  apart in ladder behaviour.
- **Confirmation is the wearer's attestation, stated as such.**
  SEEN (tap) or a steady nod confirms "I looked at the area". A
  nod is never sensor proof that the child was seen: the page has
  no sensor that could prove that, and the UI footer, the README
  and every hint say so. An unsteady nod never arms the 1.2 s lock
  (the fleet fix, kept). Confirmation resets the timer and logs
  one entry; an early confirmation (before any reminder) counts
  as an early look-back and is labelled as such, never hidden
  inside the reminder count.
- **Escalation is capped in display, honest in counting.** Level
  stops at 3, but missed keeps counting expired intervals, so the
  summary cannot understate how many reminders went unanswered.
  Level 1 deliberately has no TTS: a banner is enough for a parent
  who is merely resting, and a voice call for every single
  reminder would turn the side line into the interruption it is
  supposed to prevent. TTS is spent only on escalation.
- **Correction is cheap, destruction is confirmed.** BACK from
  the summary returns to watching without deleting anything; the
  summary is rebuilt on END. Confirming the summary (Enter /
  steady nod) is the only wipe. DEL is deliberately absent: there
  is no banner to clear without also lying about the reminder
  state — a dismissed banner that stays "reminded" in the timer
  would be worse than an honest open reminder.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks four stages: watching registered (slide area, red jacket
  DEMO sample) → level-1 reminder (banner only, no TTS) →
  escalated (one confirmed look-back, then one missed reminder,
  level 2 with one TTS) → summary (confirmed 1, missed 1). A fifth
  DEMO tap reports the demo complete. DEMO refuses outright if a
  user side line is being watched. Every step is labelled DEMO;
  the sample zone is labelled as a sample.
- **The outing lives in session memory only — zero persistence,
  by design.** There is no storage API anywhere in the page
  (harness-scanned). Zone, counts, log, level and summary die
  when the summary is confirmed and when the agent closes
  (onUnload wipes everything). Close the agent and the outing is
  gone, which is the correct use for an outing happening right
  now — and the only use, since a stored play-area heading from
  last week would be a lie about today.
- TTS uses the fixed host voice; the utterance language attribute
  is never set (documented as not taking effect). The only timers
  are the 30-second ticker, the 5-minute look-back interval and
  the 1.2 s nod lock.

## Relation to the neighbours (kept distinct on purpose)

- Directional-series `cry-watch` is **indoor baby-room sound
  guarding**: far-field listening for a cry in another room.
  Play-watch listens to nothing and guards no room — it is an
  outdoor timer that reminds a resting parent to look.
- Directional-series `baby-care-hands` is **hands-full feeding
  Q&A while holding the baby**: the parent's main line is the
  baby itself. Play-watch is the opposite geometry: the child is
  away in a play area and the parent's main line is rest.
- Attention-series `door-watch` (W05) is also a "listen while you
  do something else" agent, but it guards a doorbell/knock sound
  with a microphone. Play-watch has no microphone at all: its
  only input is the parent's own confirmation.

## Permissions

None — `permissions` is exactly `[]` in app.json, and the static
check asserts exactly that (precedent: shelf-sweep and pack-sweep
ship with empty permissions). No `CAMERA`: nothing is
photographed — the area is registered by looking at it and
holding steady, and the DEMO zone is a labelled sample. No
`RECORD_AUDIO`: escalation TTS is output only, and there is no
voice input anywhere. No `GEOLOCATION`: a playground side line
needs no position, and this agent never knows where anyone is —
that ignorance is stated in the README.

## Validation

- Node harness (see `/tmp/play-watch-harness.js`, not packed):
  app.json pages and permissions exactly []; zero storage/camera/
  geo/mic APIs in the page source; no legacy Page/App/Widget; no
  utterance language assignment; 5-minute interval asserted;
  foot2 honesty lines asserted (not a supervision device, no
  tracking, no face/person recognition, confirmation is
  attestation not sensor proof, session memory only, no
  permission); initial idle state (unregistered, level 0, counts
  0, log empty, big shows unregistered); REG discipline (SEEN/
  END/TICK refused in idle, double REG refused, nextDue one
  interval ahead); reminder ladder (tick 1 banner no TTS missed
  0, tick 2 level 2 one TTS missed 1, tick 3 level 3 strong one
  TTS missed 2, tick 4 level 3 stays missed 3 no new TTS); SEEN
  resets timer and counts (level-named log, early look-back
  labelled, nextDue reset, re-arm to level 1); END/summary/back/
  confirm wipe; log focus NEXT/PREV/rowTap wrap; SPEAK lines per
  mode and level; nod discipline (unsteady ignored without
  arming, steady nod registers in idle, lock blocks a second nod,
  nod after lock expiry confirms, non-nod inert); key discipline
  (Enter register/confirm/confirm-summary, Backspace
  summary-to-watching and ignored in watching); DEMO four-stage
  arc and refusal on a user session; onUnload wipes everything;
  bigCls thresholds. Result: **79/79**.
- Preview screenshots 5, each visually verified (not just
  hash-compared): register (idle, area unregistered), watching
  (DEMO stage 1, slide area registered, next look-back in 5
  minutes), reminder banner (DEMO stage 2, level 1, no TTS),
  escalated banner (DEMO stage 3, level 2, one TTS, confirmed 1,
  missed 1), summary (DEMO stage 4, confirmed 1, missed 1).
  Button coordinates were probed per state and every PNG
  re-verified by eye (see `shot-play-watch.js` in
  `~/workspace/preview-tools/`), per the fleet lesson that a
  single hash probe can hit the wrong button and produce a
  byte-identical fake stage.
