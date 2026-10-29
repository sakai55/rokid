---
name: "rokid-directional"
description: "Design directional （指向性） Rokid AIUI Agents for the sakai55/rokid fleet (DI numbering, directional/ directory): the glasses-vs-chest-device founding test, the design primitives (GAZE look-to-point, HEAD heading registration and relative direction, dwell = gaze confirmation, the mic array's honest position, SCAN turn-head sound search, GEO/GPS cardinal direction + position), the capability honesty boundaries from the 2026-10-24 audit, and the reusable fleet patterns (heading register, look-back confirmation, read cross-check, relative-course lock, DEMO seed discipline). Use together with rokid-agent-sop for any DI agent."
version: "1.0.1"
---

# Rokid Directional Design
[中文](SKILL.md) | English | [日本語](SKILL.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

The design layer for DI agents. The shared production pipeline (capability red lines, the governing three gates, the 9-step SOP, pack/preview/README/GitHub sync) lives in `rokid-agent-sop` — this skill adds only what is specific to the directional series: how a directional agent gets *conceived* and *checked*, not how it gets shipped. An agent is DI only if all three hold: DI number, project under `directional/<slug>/`, and it passes the founding test below using at least two directional primitives (the series PLAN requires ≥2, named in the agent's README).

## What "directional" means — the founding test (ask these when the project is scoped)

The fundamental difference between glasses and a chest-worn AI device (or a phone) is geometric: **the camera sits on the wearer's line of sight, head orientation is the pointer for attention, and the display lives inside the field of view.** A chest device sees neither what you look at nor where your attention is; it can only get information back to you by interrupting you. Every DI concept answers three questions before any design work:

1. **Take away "look at it to point at it" — does the agent still stand?** If it works just as well with taps, lists, and menus, directionality is decoration: not a DI agent.
2. **Could a phone or a chest-worn device do the same job just as well?** If yes, the glasses premise is going unused — reject the concept, or redesign it around the geometry (what you face, where you stand, what your head does).
3. **Does this scene gain from knowing absolute position / cardinal direction?** (Finding the car, heading back, meeting points, outdoors.) If yes, `GEOLOCATION` belongs in the minimal permission set *from the start*, declared with its purpose (see GEO below) — never contort a place-anchored task into relative-only guidance, and never bolt GPS on afterwards.

## The design primitives

- **GAZE — look-to-point.** The center of the camera's field of view *is* the gaze point: looking replaces pointing, tapping, and framing. `ImageCapture.takePhoto({mode})` — `telephoto` for distant small text, `wide` for barcodes / large fields, `default` for general use. Hands never do the selecting.
- **HEAD — heading registration & relative direction.** `AbsoluteOrientationSensor` quaternion → yaw, `onOrientationStabilityChange` (head steady), `onHeadGesture('nod')` — **`'nod'` is the only documented gesture value**; never design around shake/turn/tilt gesture events. In-the-moment direction is always **relative**: target heading − current heading, **+ = to your right**, spoken as "35 degrees to your front-left". (Cardinal directions belong to the *other* register — see GEO; the division of labour is spelled out there.)
- **Dwell = gaze confirmation.** Holding the head steady inside a cone (typically ±15°) for a sustained span (~1–2 s, accumulated in ticks) *is* the confirmation. Looking back at the thing is the acknowledgement — attention closes the loop, not a button. A fast sweep past never counts; leaving the cone restarts the span.
- **MIC array — the honest position.** The 4-mic array's `microphoneMode` (`wearer` / `far-field` / `near-field` / `omnidirectional`) shapes **only** the `getUserMedia` stream it is set on. In DI designs, a mic-mode stream is exactly one of two things: an **availability check** (open it, read the mode back via `track.getSettings()`, stop the tracks at once) or a **level-meter feed** (Web Audio `AnalyserNode` RMS). Host `SpeechRecognition` runs on the host's own microphone — a mode never denoises, prioritizes, or otherwise shapes recognition. The UI keeps the check result on its own `MIC CHECK:` line and labels listening `(host ASR)`.
- **SCAN — turn-head sound search.** There is no API for a sound's arrival angle. Sound location = mic **level × heading**, sampled while slowly turning the head; the loudest heading is where the sound is. Never present a beamforming angle, and level is only level — never claim what the sound *is* (no classification exists).
- **GEO — GPS: cardinal direction + position** (GO, 2026-10-28: "Directional design must use the GPS information — know the cardinal directions and the concrete position"). `GEOLOCATION` is one of the platform's seven permission names (the full table lives in the SOP's red lines); when a design uses position, declare it with the purpose stated (a publish red line). Direction has **two registers**, and the craft of the design is picking the right one:
  - **Relative** (target − current heading, + = right) for **in-the-moment guidance toward something you can turn to face**. The early fleet's "never cardinal" habit was a rule about *this wording* — in-view guidance — **not a ban on cardinal directions**.
  - **Cardinal + position** for **place-anchored tasks**: knowing where something *is* (north / northwest), the distance to a saved point, getting back to a parked car, a meeting point, home — "your car is about 300 metres northwest of you". When the task is about absolute place, GPS and cardinal directions are the design, from the start.
  - **Position patterns from the fleet**: save a point by standing there (GPS fix + optional heading); guide back by bearing + distance **recomputed from fresh fixes** — `watchPosition` where continuous updates matter (DI42 `transit-direction`'s pattern), one-shot fixes where they don't. Always surface fix accuracy and age honestly, and degrade into "positioning inaccurate / no signal" states instead of inventing precision. **GPS is weak indoors — say so in the design**, not as a footnote apology.
  - **Honesty of the bearing**: a cardinal bearing is only as good as the device's absolute heading reference. If that reference cannot be trusted on the device, the design degrades to relative guidance **and says why**. Never fake a fix; never round a distance into false precision ("about 300 metres" from a ±50 m fix — never "287 metres").

## Capability honesty boundaries (audit standard — from the 2026-10-24 audit; non-negotiable)

The audit of DI01–DI37 found no systemic fabrication at the code level (exactly one mechanism violation) — every other breach was in the *copy*. These are the lines both the copy and the design must hold:

- **No eye tracking.** "Gaze" is head orientation — everywhere, always.
- **No OCR API.** Reading text = telephoto photo + LLM image input (registry C3014–C3018: `image_url` parts, data: URLs included, user role only, `availability()` first, `destroy()` after). Data-URL image input is the documented path (the official LanguageModel example hand-writes `blob.arrayBuffer()` + chunked `btoa` for exactly this); `FileReader` does not exist in this runtime at all — device-proven, and banned under the SOP's API discipline lesson. The image path's behavior on device is still **real-device unverified**, so every image-path design keeps a fully usable non-image fallback (the wearer's own dictation / manual entry) and lists this first under "Not Yet Verified". The mirror-image claim is banned just as hard: "photos can't reach the LLM" is a *false platform claim* (it shipped in five agents' docs and was corrected); a design that sends text only says "text only — a product choice".
- **Mic modes never touch host ASR** (see MIC above). Six fleet agents' copy broke exactly this seam — the audit's most repeated finding.
- **No sound classification, no sound localization** — SCAN plus level-only wording is the whole honest toolkit.
- **No facial recognition.** "Recognizing a person" means reading the text on their badge (DI47 `badge-reader`) or matching a heading the wearer registered — never a face.
- **Photos never persist.** This runtime cannot store blobs; persist only wearer-confirmed **text**, and state "photos NOT saved" wherever a photo is taken (DI22 / DI29 copy claimed archived photos the code discarded — reworked).
- **TTS `lang` does not take effect** (11 fixed voices) — never set `utterance.lang`. ASR `rec.lang` is a real, separate property.
- **Host LLM location is not exposed** — never claim "on-device AI" (DI24's copy did; reworked).
- **No background presence.** Timers, reminders, and watchers exist only while the agent is open; a standing on-screen line says so wherever it applies. **Agents cannot invoke each other** (no `openAgent`; `window.open` cannot open another agent) — no router or multi-agent designs.
- **Platform claims must be true of the platform, not just of this agent.** DI33 called the orientation sensor "the only motion basis" (Accelerometer and Gyroscope are documented APIs) and printed a judging rule (240°/s) that was not the implemented one (60° within 3 s). Rules stated in the UI are the implemented rules, verbatim.
- **Health / safety copy is reminder framing only**, never efficacy claims (DI32).

## The pattern library

- **Heading register.** Face the thing once and bind its heading (plus a dictated label); from then on the agent refers to it by relative direction (DI07 `find-my-thing`, DI28 `home-patrol`, and the whole attention WATCH group). No heading reading → registration refuses, honestly; a direction is never invented. A registration is anchored to where you stood when you made it — say so.
- **Look-back confirmation.** An alert (timer done, state changed) speaks **once**, in relative-direction wording, and leaves a banner up until you turn and dwell on the target (face-ack) or tap. The directional series' signature closed loop.
- **Read cross-check.** Machine read (photo → LLM) against the wearer's own dictated version: a literal normalized compare → MATCH ✓ / DIFF ⚠; on DIFF the **wearer's version wins** and is announced as the source (DI41 `sign-reader`, DI47 `badge-reader`). Nothing machine-read is ever stored unconfirmed (DI39 `board-capture`'s keep-only filing).
- **Relative-course lock.** Lock the *current* heading as the course origin — purely relative, sidestepping the undocumented yaw zero. Sustained drift beyond a threshold earns **one** spoken correction per episode, re-arming inside a tight band (DI42 `transit-direction`; its harness caught a real bug — destinations anchored to the moving fix instead of the START origin, so the distance never shrank).
- **Answer quarantine.** When a read produces something the wearer must not glimpse by accident (an answer), gate it behind an explicit reveal action: strip the answer line at parse level, never display by default, and a nod never reveals (DI40 `homework-lens`).
- **DEMO seed discipline.** Demo state derives from **one** Date snapshot rendered as pure strings — the preview host's virtualized clock drifts between samples. Dwell and countdown timers accumulate ticks; they never re-sample the clock. DEMO restores the real state exactly and writes nothing to real storage.

## DI production lessons (on top of the SOP)

- **Gesture-first** (GO ruling, registry C8002–C8010): temple single-tap = confirm, double-tap = back, swipe = scroll; steady head and nod built into the main flow; on-screen buttons minimal. Device lesson: bindtap-only buttons cannot be triggered on the glasses — pages map the keys themselves (`onKeyDown`); check that wiring when device-testing each agent. Every README carries a Gesture Mapping section.
- **Short single-line status strings** (≤ ~60 chars): long wrapping text pushes controls down and breaks scripted preview clicks. The preview host hit-tests buttons on an offset strip — probe the hit coordinates for each layout state; never trust the painted centers.
- **Tick arithmetic.** All timing (countdowns, dwells, drift episodes) accumulates engine ticks at a fixed cadence; never compute durations from repeated wall-clock sampling — the preview clock drifts, and the habit hides exactly the race bugs the harness then has to catch.
- **Harness before pack.** Core logic gets a Node harness run with wx stubbed, and the assertion count is reported with the agent (fleet range: 55–154). Pack **LAST**, after the README is final, and verify the pack contents with `aix list` — the full pipeline is `rokid-agent-sop`'s; this is the one line that must never be skipped.
- Layout: main `directional/<slug>/` + `aix/<slug>.aix` + `screenshots/<slug>/`; branch `agent-<slug>` root holds exactly the agent's 7 files; the main README embeds `../../screenshots/<slug>/…`.

## Form & roster

- Numbering authority: `~/workspace/goals/50-agent-rokid-aiui/files/PLAN-50-Agents.md`. DI01–DI50 are built, pushed, and verified (series complete 2026-10-24); the DI series badge in the root README list is Directional (badge definitions are frozen — see the SOP).
- DI42 onwards were built gesture-first from the start. The fleet-wide UI unification for the earlier agents is **deliberately deferred** until GO's real-device testing defines the interaction (the MVP ruling) — do not pre-empt it with a UI rework.
- DI agents are the fleet's closest neighbours of the built-in capabilities (Smart Vision recognition / navigation / teleprompter / transcription): run any new DI concept through `rokid-conflict-audit` first. The 2026-10-25 audit put 10 of its 14 tier-1 conflicts in this series — a directional concept whose body *is* a built-in feature is out, and per the SOP governing rule it is not regrouped or submitted either.

## Versioning of this skill

This skill iterates in place, semver:

- **patch** (1.0.x): wording fixes, added examples, a new per-agent note.
- **minor** (1.x.0): a new reusable pattern, a new production lesson, a roster/status update.
- **major** (x.0.0): a founding-test, primitive, or honesty-boundary change — every shipped DI agent's README and copy must then be re-checked against it. (What a boundary clarification looks like in practice: the DI02 shake-branch removal and the 14 agents reworked to Build 1.0.1 after the 2026-10-24 audit.)

Every change: bump `version:` above, append a Change Log entry below (date, what production run taught it, what changed), update the installed mirror at `~/workspace/custom-skills/rokid-directional/SKILL.md` in the same turn, and push both in one commit. Lessons that apply to all agents (not just DI) go to `rokid-agent-sop` instead — do not duplicate them here.

## Change Log

- **1.0.1 (2026-10-29)** — Patch: two factual corrections from the full official-documentation audit (evidence: `rokid-agent-sop/API-AUDIT.md`). The platform has seven permission names, not three (the four media-library names were missing from this skill's GEO section); `FileReader` is not "real-device unverified" but proven absent from the Ink runtime and banned — the GEO/LLM honesty paragraph now states the documented `arrayBuffer()` + chunked `btoa` path instead.
- **1.0.0 (2026-10-28)** — Landed as a skill on GO's instruction. Distilled from DI01–DI50's design constitution and production experience: the glasses-vs-chest founding test (with the GPS founding question), the six primitives — GAZE / HEAD / dwell-confirmation / the mic array's honest position / SCAN / GEO, including GO's 2026-10-28 GPS ruling (cardinal + position for place-anchored tasks, relative for in-view guidance, fix honesty and indoor weakness stated) — the 2026-10-24 capability audit's honesty boundaries (14 agents reworked to Build 1.0.1), the pattern library (heading register, look-back confirmation, read cross-check, relative-course lock, answer quarantine, DEMO seed discipline), and the gesture-first / tick-arithmetic production lessons.
