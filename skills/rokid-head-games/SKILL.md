---
name: "rokid-head-games"
description: "Produce head-movement mini-games for Rokid AIUI (GA numbering, games/ directory): the no-circling constitution (segmented motion only), the safety line, sensor honesty (nod-only gesture event, calibration-learned signs), judging patterns, and GA production lessons. Use together with rokid-agent-sop for any GA game or the head-games collection hub."
version: "1.0.1"
---

# Rokid Head-Movement Mini-Games

The craft layer for GA games. The shared production pipeline (capability red lines, governing three gates, 9-step SOP, preview/README/GitHub sync) lives in `rokid-agent-sop` — this skill adds only what is specific to games whose whole input is head movement. Under the governing rule the games pass the loop gate by the games relaxation (single mechanic + complete play loop: start / win-lose / score), and new production folds games into the single collection hub `head-games-hub` instead of shipping standalone games; the standalone GA01–GA26 stay archived as built.

## The constitution — never circle (GO, 2026-10-24)

The neck is not a ball joint. Circling loads the cervical spine at its extremes continuously and makes people dizzy, so the whole series uses **segmented motion only**:

> **Center → one direction → hold → return to center → next direction.** Never circle, never sweep directly from one extreme to the opposite extreme, never jerk the head fast.

Every round opens with a short spoken form of this rule, and every game's ready screen, AGENTS.md, README and review-submission copy states the same rule in the same words — no per-game rephrasing.

## Safety line (every game, not optional)

- Slow, small range: stop at a mild stretch, never at pain; no forcing, no breath-holding.
- Return-to-center is a mandatory step between any two directions; a move that skips it never scores.
- Sitting or standing steady before play; stop at once on pain, dizziness, numbness, nausea or palpitations.
- One round lasts 60–180 seconds; timeouts end the round and report the score rather than dragging on.
- Non-medical disclaimer everywhere (ready screen, README, submission copy): entertainment and daily activity, not diagnosis, treatment or rehabilitation; cervical disease, vertigo, post-op or head/neck injury → ask a doctor first.

## Technical honesty (sensor facts, verified 2026-10-24)

- **No eye tracking.** "Looking" in a game is head orientation plus steadiness, nothing else.
- **`onHeadGesture` is officially documented only for `'nod'`.** Never claim shake / turn / tilt gesture events. A "no" answer is a side-turn held steady (GA16), explicitly not a shake.
- Sensor readings are `null` until the first sample (`quaternion`, `timestamp`): judge sampling state from `activated` / `hasReading`, never treat a null reading as 0 (official device docs, confirmed in the 2026-10-29 full audit).
- Yaw / pitch / roll all derive from `AbsoluteOrientationSensor` quaternions relative to a center calibrated at round start. **Signs are learned, never assumed**: calibration prompts teach them ("请低一下头" learns down, "请向左转一下" learns left, "请向左贴一下" learns left tilt); the opposite direction is the reverse sign.
- Typical judging values (written down per game in its AGENTS.md, re-tuned only at the device stage): reach ≈ 27°, return-to-center < 10°, a direction counts only after ~0.8 s steady (stability-gated, with a documented elapsed-time fallback).
- The sensor is absent in web preview: that path is labelled SKIP / demo, never a fake pass. The glasses have **no breath sensor** — breathing games are voice-paced, breathing is never measured (GA17).

## Shape of a game

- One page (`pages/index/index`), three states only (ready / playing / done), one mechanic, nothing else: no menus, no settings, no multi-level structure. Difficulty moves by exactly one number (count or seconds).
- Playing screen shows at most three things — the big direction/target, the count/progress, one short hint; everything else is spoken. TTS guides, counts and announces the result.
- Temple tap = start / confirm / play again; nod = confirm only where the mechanic says so; double-tap is the host back and is never intercepted. Each README states its gesture mapping.
- **Zero permissions by design**: `permissions: []` (no name in the platform's seven-permission table gates sensors or TTS — both are ungated). If any step ever forces a permission, report it and record it in the plan — never add one silently.
- Green-shades-only CSS (brightest green `#7dff9e` plays the "white" role, no pure white or white rgba), buttons styled per each game's own UI form, canvas 480×352.

## Design rules

- **No reskins.** Before building, the game's AGENTS.md names the nearest existing GA game and states the one-mechanic difference. If the difference cannot be stated, the concept dies.
- Fixed, documented trial sequences (no runtime randomness): the order is part of the design and is written in AGENTS.md and the plan.
- Sequences obey the constitution too: clock points are positions to visit with a return between them, not a sweep (GA05); a follow sequence contains zero clockwise-adjacent steps (GA10).

## Judging patterns (the reusable craft)

- **Return gating** — the next target never appears until the head has actually returned inside the return band (GA10 strict form; a per-attempt grace is a documented variant, GA09).
- **Band + steady hold** — a hit = enter the target band and stay ~0.8 s (GA13; precision form: target angle ±5° band, GA21/GA22).
- **Stop-at-center** — the return itself judged: stop inside ±5° without overshooting past −5° to the other side (GA24).
- **Timing windows** — a move must take the stated time: turn 3.0–5.0 s (GA23), one scan pass ≥ 8 s with a too-fast restart (GA15), beat windows ±300 ms (GA11).
- **Stillness** — total angular change < 5° with a short grace and a capped number of resets, then a forced rest (GA07/GA14).
- **Distance bands only** — for hidden-target play, speak only the band (near / nearer / far), spoken on band change, never the answer (GA18).
- **Ladders** — progressive holds 2/3/4/5/6 s with a return between rungs (GA25); memory grows 3→4→5 steps (GA12; six-direction form GA26).

## Production lessons (GA-specific, on top of the SOP)

- **Logic harness before packing**: each game's judging logic gets a scripted harness run and the pass count (e.g. 33/33) is reported with the batch and recorded in the plan. A game without a harness count is not done.
- **Pack LAST** — pack only after README.md and AGENTS.md are final, and verify with `aix list` that the pack contains both (GA03/GA04 first shipped without them and had to be repacked; any README/AGENTS edit after packing means repack + re-verify).
- Screenshots: three states, exactly 480×352, mutually distinct. Near-white pixels confined to the preview frame's rounded-corner transparency (≈92 px per corner) are a known preview artifact, not UI white — the UI itself stays green-scale.
- Main layout: `games/<slug>/` + `aix/<slug>.aix` + `screenshots/<slug>/`, branch `agent-<slug>` root holding exactly the game's 7 files. The `games/README.md` line for the new game goes in the **same** main push batch (the GA24–GA26 batch commits missed it and the parent had to repair with a follow-up commit). Root README agent list is never hand-edited.

## Open device risks (never claim verified)

- **Chin-tuck band (GA06, also inside GA20)**: a true chin tuck is mostly horizontal translation, which an orientation sensor barely sees; the game detects its small pitch component (band 14–20°, ≥20° rejected). Device stage must confirm natural tucks land in the band, else adjust the threshold or honestly rework.
- Left/right tilt naming (GA14) is a display convention until device confirmation.
- All thresholds (reach / return / steady time) are preview-stage values; real-device feel governs the final tuning, and submission happens only after GO says 「真机测试完成了」.

## Roster & status

Numbering authority: `~/workspace/goals/20-rokid-aiui/files/PLAN-20-Head-Games.md` (section 六 for wave 2). GA01–GA26 standalone games are built and archived; GA27–GA40 mechanisms are reserved for the `head-games-hub` collection under the governing rule — do not build them as standalone games without GO's instruction.

## Versioning of this skill

This skill iterates in place, semver:

- **patch** (1.0.x): wording fixes, added examples, per-game notes.
- **minor** (1.x.0): a new judging pattern, a new production lesson, a roster/status update.
- **major** (x.0.0): a constitution or safety-line change — every shipped game's README and in-game copy must then be re-checked against it.

Every change: bump `version:` above, append a Change Log entry below (date, what production run taught it, what changed), update the installed mirror at `~/workspace/custom-skills/rokid-head-games/SKILL.md` in the same turn, and push both in one commit. Lessons that apply to all agents (not just GA) go to `rokid-agent-sop` instead — do not duplicate them here.

## Change Log

- **1.0.1 (2026-10-29)** — Patch: two corrections from the full official-documentation audit (evidence: `rokid-agent-sop/API-AUDIT.md`): sensor readings are `null` before the first sample (judge from `activated`/`hasReading`, never as 0), and the zero-permissions note now reflects the platform's seven-name permission table (sensors/TTS remain ungated).
- **1.0.0 (2026-10-28)** — Landed as a skill at GO's instruction. Distilled from GA01–GA26 production: GO's no-circling constitution and safety line (2026-10-24), calibration-learned sensor signs and threshold craft, the judging-pattern library, the GA03/GA04 pack-last incident, and the GA24–GA26 games/README omission lesson.
