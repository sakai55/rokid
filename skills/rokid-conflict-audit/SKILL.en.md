---
name: "rokid-conflict-audit"
description: "Audit Rokid AIUI Agents against the glasses' built-in (default) capabilities: any agent whose core mechanic IS a built-in feature is a conflict, no matter how it is dressed up. Produces the three-tier verdict (direct conflict / high overlap / to be tested) that drives the root README conflict badges and the SOP thickness gate. Use when tiering a new agent, re-auditing the fleet, or before any submission."
version: "1.0.1"
---

# Rokid Built-in Capability Conflict Audit
[中文](SKILL.md) | English | [日本語](SKILL.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

**Version: 1.0.1** — Versioning rules are at the end of this document. Where the first version came from: the first audit of the whole fleet — 122 agents — run on 2026-10-25 on GO's instruction; the full report lives in the maintainer's workspace at `~/workspace/rokid/audit-builtin-conflicts/REPORT.md`.

## Why this skill exists

The glasses ship with a complete feature set of their own. An agent that rebuilds a built-in feature under a new name is reinventing the wheel: the user can just open the built-in, so the agent earns nothing — and it will not survive review either (the SOP governing rule's thickness gate: same body as a default capability is out, immediately). This skill pins down what counts as a conflict, so a new agent can self-check at proposal time, the fleet can be re-audited on a consistent standard, and the conflict badges in the root README have exactly one source of truth.

## The default-capability baseline (re-check the latest version before judging)

The baseline comes from official and public sources only — never from memory or impressions. Current baseline (fixed 2026-10-25; sources: entries C1017 and C8013 of the official capability registry `docs/CAPABILITIES.md`, the official global product page, and published hands-on reviews):

1. **Real-time translation** (89 languages): live conversation-translation captions, photo translation of text, menus, and signs; the AI Shortcut Commands already ship a "photo → translate to Chinese" preset.
2. **Real-time captions (Intelligent Captioning)**: same-language conversation captioned on screen as it happens, and the captions persist — history is kept and can be reviewed later.
3. **Meeting transcription + AI summary**: transcription with speaker identification, plus automatically generated smart summaries; voice notes are built in too.
4. **Teleprompter**: the script goes on screen and auto-scrolls, tracking reading speed and pauses.
5. **Smart Vision recognition / AI visual Q&A**: the "Hi Rokid" assistant plus camera — recognize objects, read text and signs, answer questions about the scene.
6. **Visual AR navigation**: direction arrows plus speed / duration / arrival time on screen.
7. **Personal-assistant AI Q&A, notification display, photo/video capture, calls/music.**

On every re-audit, first check whether the baseline has moved (a new model, a new system version, or a new official feature can all extend it). If it has, bump this skill's version per the rules at the end and re-tier whatever is affected.

## How to judge (three tiers, mutually exclusive)

Judge the agent's **core mechanic** — the job it does for the user — not the channels it happens to borrow.

- **Tier 1 · Direct conflict**: the core *is* a default feature with one small twist on top (a different trigger, a small filter, a sliced time window). GO's named example: `chat-catchup` (SO01) — the built-in captions already keep reviewable history, so "shake your head for a summary of the last 15 seconds" is only a twist, and the agent is redundant. Disposition: never regroup it and never submit it (an SOP hard rule); whether it also gets taken down or its draft deleted is GO's call — report it, do not act on it unilaterally.
- **Tier 2 · High overlap**: a default feature covers most of the core in one ask or one tap, and all that remains is one thin closed loop (read text, then one extra register/compare step; answer a question, then one extra guided step). Keep-or-drop is GO's ruling, cluster by cluster; nothing in this tier goes to review before that ruling.
- **Tier 3 · To be tested**: every numbered agent that is neither tier 1 nor tier 2 lands here. The tier means "how this agent relates to the default capabilities gets decided after real-device testing" — it does **not** mean "checked, no conflict". New agents start in this tier by default and move only after an audit.

What does *not* count as a conflict (tier 3, with the reason stated in the report): the default capability is just one step inside a closed loop that the built-ins don't have — register → watch / cover by zone / count step by step / replay afterwards (e.g. the zone-by-zone coverage search in `drop-search`, the target-route watch-and-filter in `my-bus-watch`).

## The audit procedure

1. **Assemble the full set**: enumerate every agent in the repo's category directories and reconcile against the root README list. Agents retired but kept in place are not on the list and do not get tiered.
2. **Read the core**: for each agent, read its PLAN registry line and the mechanism description in its README, and write the core down in one sentence. Where the mechanism can't be read there, verify it in `pages/index/index.ink` and AGENTS.md — never guess from the slug.
3. **Compare with the baseline**: score the core against all seven baseline items and assign a tier by the criteria above. For borderline cases, spell out exactly how far the default feature gets and what the agent's extra layer is, then choose tier 2 or tier 3.
4. **Write the report**: update the workspace report (an item-by-item comparison table: tier 1 in full, tier 2 by cluster, tier 3 as totals) and record the baseline version and the version of this skill the audit relied on.
5. **Sync the badges**: the conflict badges in the root README list follow the report's tiers (tier 1 = Direct Conflict, tier 2 = High Overlap, tier 3 = To Be Tested). Badge definitions are frozen — never add to or alter a badge definition in the name of syncing (GO's ruling, 2026-10-25).
6. **Leave the calls to GO**: tier-1 dispositions and tier-2 keep-or-drop decisions are reported to GO for a ruling, cluster by cluster. Until ruled: no deletions, no submissions, and never write up an undecided item as if it were settled.

## Current tiers (set 2026-10-25, under the v1.0.0 baseline)

- Tier 1 — 14: the DI series `gaze-translate`, `head-nav`, `parking-return`, `baby-care-hands`, `far-ear`, `ambient-captions`, `sign-reader`, `transit-direction`, `speaker-focus`, `teleprompter-gaze`; the attention series `chat-catchup` (SO01), `standup-echo` (SO04), `meeting-filter` (FI04), `talk-replay` (RE02).
- Tier 2 — 40: the image-Q&A cluster / the read-and-register cluster / the notes-and-reminders cluster / the captions-and-transcription cluster / the read-screen-and-numbers cluster (details in the report).
- Tier 3: the remaining numbered agents (68 of the fleet's 122; the root README legend count of 88 includes the 20 active JP/KR agents).
- A pre-screening lesson: CC07 `last-sentence` in the curb-cut series was proposed on the distinction "captions can be replayed" versus Smart Vision. Under the SO01 standard that distinction does not hold. Any new proposal whose distinction rests on some sub-feature of a built-in must pass this skill before work starts.

## Versioning rules

This skill is versioned, and every change must do three things together: bump the version number, add an entry to the Change Log below, and state in the report which version of this skill it relied on.

- **PATCH (x.y.Z)**: wording, examples, process detail — judging criteria and baseline unchanged.
- **MINOR (x.Y.0)**: a baseline item added or removed, a new case added to the judging criteria, a step added to the procedure — any of these can move tiers, so the Change Log entry must name the affected agents.
- **MAJOR (X.0.0)**: a fundamental change to the tier system or the criteria (e.g. GO replaces the judging standard) — the whole fleet is then re-tiered under the new standard and every badge re-synced.

## Change Log

- **v1.0.1 (2026-10-29)**: Wording generalized — pointers to one specific AI assistant removed (the report's origin is now described as the maintainer's workspace) so any AI agent can pick this skill up directly. Judging criteria, baseline, and tiers untouched (PATCH).
- **v1.0.0 (2026-10-28)**: First version. Source material: the first full-fleet audit of 2026-10-25 (122 agents; report at `~/workspace/rokid/audit-builtin-conflicts/REPORT.md`) — the seven-item default-capability baseline, the three-tier judging criteria, the six-step audit procedure, and the current tiers (14 / 40 / 68). Before this version the method lived only in a one-off report and memory entries; from here on it is maintained as a skill.
