---
name: "rokid-curb-cut"
description: "Produce curb-cut-effect (路缘坡效应) Rokid AIUI Agents for the sakai55/rokid fleet (CC numbering, curb-cut/ directory): the three founding questions (坡道本体 / 通道改造 / 溢出地图), channel transformation per disability, the 慧眼 exclusion rule (recognition only as one step inside a register→watch/count/verify→replay loop), spillover discipline and the no-dilution rule. Use together with rokid-agent-sop for any CC agent."
version: "1.0.0"
---

# Rokid Curb-Cut Design

[中文](SKILL.md) | English | [日本語](SKILL.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

The design layer for CC agents. The shared production pipeline (capability red lines, the governing three gates, the 9-step SOP, pack/preview/README/GitHub sync) lives in `rokid-agent-sop` — this skill adds only what is specific to the curb-cut series. An agent counts as CC only if all three hold: a CC number, a project under `curb-cut/<slug>/`, and a pass on the three founding questions below.

## The effect

The curb cut effect (GO specified the Wikipedia article, 2026-10-24): features designed for disabled people end up used and loved by far more people than the group they were built for — curb ramps built for wheelchairs serve strollers, carts, and luggage; captions built for the deaf serve hearing people in noisy bars. It is a subset of universal design, and the spillover is usually unintentional. Reid's warning, quoted in the series PLAN, governs this series: when accessibility is subordinated to "good for everyone", the individualized design for disabled people is exactly what gets rejected. So here the disabled user's barrier comes first and is never diluted for the sake of general benefit; spillover is an effect, not the goal.

## The three founding questions (立项三问) — every CC README carries all three

1. **坡道本体 (the ramp itself).** Which specific population, and which channel is broken (see / hear / speak / move / remember / attend)? The test: take that population away and the agent must immediately stop making sense. If it still works as a generic agent with a disability label pasted on, it is rejected.
2. **通道改造 (channel transformation).** The broken channel is designed out, not accommodated:
   - Blind / low vision → **zero screen dependence**: the whole flow runs on TTS + nod/shake, and the screen only mirrors state for a sighted helper.
   - Deaf / severe hearing loss → **zero voice dependence**: all information is visual (banners, direction arrows); TTS is useless to this user and must not carry content.
   - One hand / hemiplegia → **zero hand operation** of the glasses: head + voice only, and the task steps themselves are rewritten for one hand (a table edge, the body, the knees serve as the fixture).
   - Aphasia → input by looking + nodding, output by **TTS speaking to other people** on the user's behalf.
   - Cognitive / attention → one item at a time, minimal information on screen, evidence replay instead of reminders (see CC11).
3. **溢出地图 (spillover map).** Name only the *situational* disability in which a non-disabled person would use it: carrying a baby = temporarily one-handed, a noisy market = temporarily deaf, a foreign language = temporarily aphasic, hauling luggage = the wheelchair user's twin. "Everyone can use it" is a banned sentence in this section.

## The 慧眼 exclusion rule

The glasses already ship generic visual intelligence (慧眼辨识: recognize / read text and signs / describe scenes), plus translation, a teleprompter, meeting transcription, map navigation, and AI Q&A. None of that gets built here. The working test, applied to every concept: **if one question to 慧眼 gets the answer on the spot, do not build it.** Recognition may appear only as one step inside a closed loop — register a target → watch / cover / count / verify → replay or verdict. Loop shapes proven in this series:

- **Coverage proof** — CC01 `drop-search`: the floor is cut into 6 sectors, checked off one by one; "not found" is a verdict that must be earned at 6/6, never a default.
- **Register → watch → verdict** — CC02 `my-bus-watch`: only the registered bus route is watched for; every arrival gets exactly one verdict (yours / not yours / unreadable = an honest SKIP, never a guess).
- **Count the process** — CC03 `step-count-down`: the total is registered at the head of the stairs, then counted down step by step, ending with an explicit "已到底" (bottom reached).
- **Sequence verification table** — CC04 `color-order-check`: colors are reported as spoken names into an ordered table, then re-verified position by position (never correct a broken color channel using color itself).
- **Evidence replay** — CC11 `left-home-proof`: checkpoints are photographed on the way out, so the replay after leaving breaks the go-back-and-check loop.

## Conflict-audit discipline

Before building, check the concept against the default-capability baseline (the 2026-10-25 audit in `~/workspace/rokid/audit-builtin-conflicts/REPORT.md`): a concept whose body *is* a built-in feature plus a small twist is tier 1 — out — and under the SOP governing rule it is not regrouped or submitted either. Lesson on record: CC07 `last-sentence` was built in the exploration phase, and its distinction from the built-in transcription/captions was flagged as pending GO's confirmation. When a concept sits that close to a built-in, re-examine the distinction *before* building and surface it to GO — do not let production momentum settle the question.

## Fit with the governing rule (2026-10-26)

CC01–CC08 are exploration-fleet shape (one mechanic, thin) and stay archived as such. New CC work goes through the SOP's three gates (scenario / loop / thickness) on top of the three founding questions: thicken or merge by scenario — the boutique line's CC rebuilds are the model (CC10 `freeze-step-cue` rebuilt in place as v2.0.0, with rhythm sets and session records; CC12–CC14 built as 3-page boutique versions). Never reproduce the thin one-feature shape under a CC number.

## Health boundary

Agents that touch health (CC03 stairs, CC10 gait-freeze cueing, CC16 aphasia, CC18 voice volume) are life-assistance only: rhythm cues, feedback, and reminders — never diagnosis or treatment. The README and the review-submission copy must say so.

## Form & roster

- Roster and numbering authority: `~/workspace/goals/20-agent-rokid-aiui/files/PLAN-20-CurbCut-Agents.md` (CC01–CC20) plus the `curb-cut/` directory. Series badge in the root README list: 路缘坡 (badge definitions are frozen — see the SOP).
- Why glasses rather than a chest-worn device is part of every CC design: the camera is co-axial with the user's own line of sight, the display sits inside the (remaining) visual field, and head orientation is the attention pointer. For this series' users a chest device is not a worse option — it is a non-option: it cannot see what a seated user sees on a high shelf, and it cannot show anything to a user whose hands are on wheelchair rims.

## Versioning of this skill

This skill iterates in place, semver:

- **patch** (1.0.x): wording fixes, added examples, a new proven loop shape from a shipped CC agent.
- **minor** (1.x.0): a new channel-transformation rule, a new exclusion case, a new audit lesson.
- **major** (x.0.0): a change to a founding question or the no-dilution rule.

Every change: bump `version:` above, append a Change Log entry below (date, what production run taught it, what changed), update the installed mirror at `~/workspace/custom-skills/rokid-curb-cut/SKILL.md` in the same turn, and push the repo copy in the same commit. Lessons that apply to all agents (not just CC) go to `rokid-agent-sop` instead — do not duplicate them here.

## Change Log

- **1.0.0 (2026-10-28)** — Landed as a skill on GO's instruction. Distilled from CC01–CC14 production: the three founding questions and the no-dilution rule, channel transformations per disability, the 慧眼 exclusion test with five proven loop shapes, the CC07 distinction-flag lesson, the boutique thickening turn, and the health boundary.
