# Focus Shield — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`). Attention
series FI01 (FILTER 过滤型， first of the group): a session gate for deep
work — while a focus session runs, the world keeps making noise, and the
wearer is afraid of missing the one thing that actually matters.

## Design contract

- **The product is a gate with two tiers, and the tiers never mix.**
  Tier 1 (interrupt) is ASR transcript text matched against a
  whitelist: the wearer's own name plus custom keywords (DEMO sample
  name 小林， keywords 开会/找你； both changeable in idle only).
  A match interrupts at once: TTS says it and a banner stays on
  screen until DEL, NEXT or PREV clears it. Tier 2 (never
  interrupts) is a loudness spike: AnalyserNode RMS banded 低/中/高
  and logged silently to a timeline — no TTS, no banner, no
  vibration of attention. The break summary is the only place tier
  2 is read back. A design that let a loud noise interrupt would
  be the opposite of this agent: the gate would be the
  interruption.
- **No sound classification, and the ignorance is the headline.**
  This platform has no sound-classification API, no speaker
  recognition, and no way to tell a doorbell from a dropped pan.
  So tier 2 entries are always labelled 响动（未分类） and the UI
  footer, the README and every hint say so: doorbells, alarms and
  a child's cry can only appear as unclassified noise entries to
  review at the break — they are NOT recognised, and the agent
  never promises otherwise. The WA01 stove-watch precedent
  (电平 ≠ 沸腾识别） is followed verbatim: level ≠ identity.
  Tier 1 matches text only: it cannot tell who said the name, and
  it says so.
- **Settings are idle-only, and that is deliberate.** Duration
  (25/50 min presets), whitelist name and keyword set can only
  change before a session starts. Changing the gate mid-session
  would silently rewrite what counts as important while the
  wearer is trusting it — so every settings tap in session is
  refused with an explanation, never silently applied.
- **Pause is a real gate state, not a mute button.** While
  paused, transcript hits, noise spikes and manual NOTE are all
  ignored, and the status line says so. A paused shield that kept
  logging would lie about the timeline; a paused shield that kept
  interrupting would lie about the gate.
- **Correction is cheap, destruction is two-step.** DEL in a live
  session only clears the banner — it never deletes timeline
  entries or ends the session. Clearing a whole session is only
  possible from the summary screen, in two DEL taps, with a 6 s
  arm that any other action cancels — the same destructive-
  operation discipline as CO01–CO05. Back from the summary returns
  to the live session without deleting anything; the summary is
  rebuilt on END.
- **DEMO is staged and never overwrites a user session.** DEMO
  walks four stages: session started (25 min, name 小林，
  keywords 开会/找你） → whitelist hit banner + TTS → two noise
  notes logged silently → break summary (pass 1, note 2). A fifth
  DEMO tap reports the demo complete. DEMO refuses outright if a
  user session is running. Every step is labelled DEMO; no real
  listening happens in DEMO (the preview host cannot provide a
  microphone stream by design).
- **The session lives in session memory only — zero persistence,
  by design.** There is no storage API anywhere in the page (no
  wx storage import use, no localStorage; harness-scanned).
  Whitelist, timeline, banner and summary die when the summary
  is confirmed, when the agent closes (onUnload wipes
  everything), and when the session is cleared. Close the agent
  and the shield is gone, which is the correct use for a focus
  session happening right now — the next session starts from a
  blank gate.
- **Nod discipline, with one fix over the C-series pattern.** A
  steady nod confirms only where confirmation is safe: START in
  idle, CONFIRM on the summary screen. In a live session a steady
  nod is ignored on purpose — ending a session must never happen
  by accident while you are working. Unlike the C-series pages,
  an UNSTEADY nod does NOT arm the 1.2 s lock (harness-caught
  during FI01 development: an unsteady nod was eating the next
  steady one); the lock arms only after steadiness is confirmed.
- TTS uses the fixed host voice; the utterance `lang` is never
  set (documented as not taking effect). The only timers are the
  10 s display-only elapsed tick (refreshes the readout, never
  creates or edits data), the 1.2 s nod lock and the 6 s two-step
  disarm window.

## Relation to the neighbours (kept distinct on purpose)

- `name-call` reports WHERE a call came from (direction + words).
  Focus-shield never reports a direction: it only decides
  interrupt-or-log for a session you are already in.
- `cry-watch` is a baby-room listener: it watches one room for
  one kind of event. Focus-shield watches the wearer's own
  session, for any whitelisted word, and logs everything else.
- `sound-compass` turns the head to locate a sound. Focus-shield
  has no location question at all — a whitelisted word interrupts
  no matter where it came from, and a noise note carries no
  direction.
- Directional-series `ambient-captions` subtitles everything.
  Focus-shield subtitles nothing: the whole point is that most
  sound should NOT reach you during a session.

## Permissions

RECORD_AUDIO only — `permissions` is exactly `["RECORD_AUDIO"]`
in app.json, and the static check asserts exactly that. The
omnidirectional stream (getUserMedia microphoneMode
`omnidirectional`, guarded try/catch so the preview host fails
soft) feeds both tiers: AnalyserNode RMS for tier 2, ASR
transcript text for tier 1. No `CAMERA`: nothing is photographed
(no photo step anywhere in this agent). No `GEOLOCATION`: a
focus session needs no position, and this agent never knows
where you are — that ignorance is stated in the UI footer, the
README and every hint it gives.

## Validation

- Node harness (see `/tmp/focus-shield-harness.js`, not packed):
  app.json permissions exactly ["RECORD_AUDIO"]; zero storage/
  geo/camera/ASR-classification APIs in the page source; no
  legacy Page/App/Widget; no utterance lang assignment; initial
  idle state (25 min, name 小林， keywords 开会/找你）; DUR/NAME/
  KW cycles with wrap and session refusals; START double-start
  refusal; transcript whitelist (non-match ignored, name and
  keyword hits pass with banner + one TTS, banner renders big);
  noise bands (quiet ignored, 0.5 → 中， 0.8 → 高， never speaks,
  never banners, always labelled 未分类）; manual NOTE and the
  pause gate (paused ignores transcript, noise and NOTE);
  banner DEL clears banner only; NEXT/PREV wrap and rowTap
  focus; END summary counts, back-to-session rebuild, DEL
  two-step clear with arm; DEMO four-stage arc and refusal on a
  user session; nod discipline (unsteady ignored without arming
  the lock, steady nod starts in idle, ignored in session,
  confirms on summary, non-nod inert, 1.2 s lock); SPEAK lines
  per mode; onUnload wipes timeline, banner, mode and demo flag;
  elapsed math and bigCls thresholds. Result: **135/135**.
- Preview screenshots 4, each visually verified (not just
  hash-compared): idle (25 分钟待机）, session (DEMO stage 1),
  pass banner (DEMO stage 2, 放行打断 小林）, break summary
  (DEMO stage 4, 专注 12 分钟（DEMO）, pass 1, note 2). Hit
  coordinates probed per state (see `shot-focus.js`,
  `probe-focus*.js` in `~/workspace/preview-tools/`): DEMO is
  the row-1 first button (x=88); its true y moves with the
  info-box height — idle (88,177), session non-banner
  (88,155), banner/notes (88,172), notes-with-banner to
  summary (88,172). The trap is documented: (88,177) in
  session state hits KW, not DEMO, which produced one wrong
  banner.png before the re-probe; every final PNG was read
  back by eye.
