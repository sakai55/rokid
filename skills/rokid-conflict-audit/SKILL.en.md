---
name: "rokid-conflict-audit"
description: "Audit Rokid AIUI Agents against the glasses' built-in (default) capabilities: any agent whose core mechanic IS a built-in feature is a conflict, no matter how it is dressed up. Produces the three-tier verdict (direct conflict / high overlap / to be tested) that drives the root README conflict badges and the SOP thickness gate. Use when tiering a new agent, re-auditing the fleet, or before any submission."
version: "1.0.1"
---

# Rokid Built-in Capability Conflict Audit
[中文](SKILL.md) | English | [日本語](SKILL.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

**Version: 1.0.1** — See the versioning rules at the end of this document. Origin of the first version: the first audit of all 122 agents in the fleet on 2026-10-25 (at GO's instruction); the full report is in the maintainer's workspace at `~/workspace/rokid/audit-builtin-conflicts/REPORT.md`.

## Why this skill exists

The glasses ship with a complete set of built-in features. If an agent rebuilds a built-in feature under a different name, it is reinventing the wheel: the user can simply open the built-in feature and does not need the agent, and it will not hold up in review either (the thickness gate of the SOP Governing rule: anything whose core is the same as a default capability is out immediately). This skill fixes the criteria for what counts as a conflict, so every new agent can check itself at project setup, the whole fleet can be re-audited, and the conflict badges in the root README have a single source of truth.

## The default capability baseline (always check the latest version before judging)

The baseline comes only from official/public sources, never from impressions. Current baseline (set on 2026-10-25; sources: the official capability registry `docs/CAPABILITIES.md` entries C1017 and C8013, the official global product page, and public hands-on reviews):

1. **Real-time translation** (89 languages): conversation translation captions, photo translation of text/menus/signs; the AI shortcut commands already include a preset "take a photo and translate it into Chinese".
2. **Real-time captions (Intelligent Captioning)**: same-language conversations shown on screen in real time, with the captions kept in history and available for later review.
3. **Meeting transcription + AI summary**: transcription with speaker identification, automatically generated smart summaries; voice notes are also built in.
4. **Teleprompter**: the script is shown on screen and scrolls automatically, following the reading speed and pauses.
5. **Smart-vision recognition / AI visual Q&A**: the "Hi Rokid" assistant plus the camera — recognize objects, read text and signs, and answer questions about the scene.
6. **Visual AR navigation**: direction arrows plus speed/duration/arrival time shown on screen.
7. **Personal-assistant AI Q&A, notification display, photo/video capture, calls/music**.

When re-auditing, first verify whether the baseline has changed (a new model, a new system version, or a new official feature can all expand it); if the baseline has changed, bump the version following the rules at the end of this document and re-tier the affected agents.

## Judging criteria (three tiers, mutually exclusive)

What is judged is the agent's **core mechanic** (the thing it does for the user itself), not the channel it borrows.

- **Tier 1 · Direct conflict**: the core is a default feature, with only a small twist added (a different trigger, a small filter, a slice of a time window). GO's named example: `chat-catchup` (SO01) — the built-in captions already keep history that can be reviewed, so "shake your head to get a summary of the last 15 seconds" is only a small twist and is judged redundant. Disposition: it must not be reorganized and submitted for review (an SOP hard rule); whether it is taken down or its draft deleted waits for GO's ruling and is not executed automatically.
- **Tier 2 · High overlap**: most of the core can be done by a default feature with "just ask / just open it", leaving only a thin closed loop (for example, one extra registration/comparison step after reading text, or one extra step-by-step guidance step after a Q&A). Whether each stays or goes is ruled on by GO cluster by cluster; do not submit for review before that ruling.
- **Tier 3 · To be tested**: every numbered agent that is neither Tier 1 nor Tier 2 goes into this tier — the meaning is "its relationship to the default capabilities will be determined after real-device testing", not "verified to have no conflict". New agents enter this tier by default and move tiers only after an audit.

Cases that do not count as a conflict (place in Tier 3 and state the reason in the report): the default capability is only one step in a closed loop, and the loop itself — register → watch/cover by zone/count step by step/replay afterwards — is something the built-in features do not have (for example, the zone-coverage search of `drop-search`, or the target-route watching and filtering of `my-bus-watch`).

## Audit procedure

1. **List the full set**: enumerate all agents under the repository's category directories (check the difference against the root README list; retired-but-retained agents are not in the list and do not take part in tiering).
2. **Read the core**: for each agent, read its PLAN registry line and the mechanism description in its README, and write down its core in one sentence; where the mechanism implementation cannot be read there, verify it from `pages/index/index.ink` and AGENTS.md — never guess from the slug.
3. **Compare against the baseline**: compare the core item by item against the seven baseline items and assign a tier by the criteria above; for borderline cases, write out clearly "how far the default feature can go, and what the extra layer the agent adds is", then decide between Tier 2 and Tier 3.
4. **Write the report**: update the workspace report (an item-by-item comparison table: Tier 1 listed in full, Tier 2 listed by cluster, Tier 3 summarized), noting the baseline version and the version of this skill used.
5. **Sync the badges**: the conflict badges in the root README list follow the report's tiers (Tier 1 = direct conflict, Tier 2 = high overlap, Tier 3 = to be tested); the badge definitions are frozen, and no badge definition may be added or changed under the cover of syncing (GO's ruling, 2026-10-25).
6. **Leave the ruling to GO**: report the disposition of Tier 1 and the keep-or-drop decisions for Tier 2, cluster by cluster, to GO for a ruling; before a ruling, do not delete, do not submit for review, and do not write "awaiting ruling" as "disposed of".

## Current tiers (under the v1.0.0 baseline, tiered on 2026-10-25)

- Tier 1, 14: DI series `gaze-translate`, `head-nav`, `parking-return`, `baby-care-hands`, `far-ear`, `ambient-captions`, `sign-reader`, `transit-direction`, `speaker-focus`, `teleprompter-gaze`; attention series `chat-catchup`(SO01), `standup-echo`(SO04), `meeting-filter`(FI04), `talk-replay`(RE02).
- Tier 2, 40: image Q&A cluster / text-reading and registration cluster / notes and reminders cluster / captions and transcription cluster / screen- and number-reading cluster (details in the report).
- Tier 3: the remaining numbered agents (68 of the fleet's 122; the root README legend count of 88 includes the 20 active JP/KR agents).
- Pre-screening lesson: curb-cut CC07 `last-sentence` was set up using "captions can be replayed" to distinguish it from smart vision; under the SO01 criteria that distinction does not hold — any new project that uses "a sub-feature of a built-in feature" as its distinction must pass this skill before work starts.

## Versioning rules

This skill iterates with a version number. Any change must do three things at the same time: bump the version number, append an entry to the Change Log below, and state the skill version relied on in the report.

- **PATCH (x.y.Z)**: fixes to wording, examples, or process details; the judging criteria and the baseline do not change.
- **MINOR (x.Y.0)**: an item added to or removed from the baseline, a new case added to the judging criteria, or a step added to the procedure — these may change tiers, and the Change Log entry must name the affected agents.
- **MAJOR (X.0.0)**: a fundamental change to the tier system or the criteria (for example, GO changes the judging standard); the whole fleet must then be re-tiered under the new criteria and all badges fully synced.

## Change Log

- **v1.0.1 (2026-10-29)**: Wording generalized — references to a specific AI assistant removed (the report's location is now described as the maintainer's workspace), so any AI agent can adopt it directly. The judging criteria, the baseline, and the tiers are unchanged (PATCH).
- **v1.0.0 (2026-10-28)**: First version landed. Content from the first full-fleet audit on 2026-10-25 (122 agents, report `~/workspace/rokid/audit-builtin-conflicts/REPORT.md`): the seven-item default capability baseline, the three-tier judging criteria, the six-step audit procedure, and the current tiers (14 / 40 / 68). Before this version, the method existed only in a one-off report and memory entries; from this version on it is maintained as a skill.
