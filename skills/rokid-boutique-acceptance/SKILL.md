---
name: "rokid-boutique-acceptance"
description: "Acceptance check for Rokid boutique-line batches in the sakai55/rokid repo: verify a batch from the built files, not from ledger prose — page counts, skeleton isomorphism, counted content sets, API wiring per claimed loop step, persistence code for cross-session claims, placeholders never counted, and only passing agents counted toward the batch. Use after building and before packing, pushing, or registering any boutique batch."
version: "1.1.0"
---

# Rokid Boutique Batch Acceptance

The acceptance layer for the boutique line （精品线）. Production (three gates, 9-step SOP, pack/preview/README/GitHub sync) lives in `rokid-agent-sop` — this skill adds only how a finished batch is *verified*. A batch is accepted from its **built files**, never from its ledger, its PLAN notes, or its own report: a claim counts only when the built project shows the same fact.

Run it after building, **before** packing counts as done, before pushing, and before registering the batch (root README list, PLAN tables, goal timelines). The boutique daily cron (`rokid-boutique-daily-10`) carries a condensed copy of these checks in its body; this skill is the authority when the two disagree.

## Check structure from the built files

- Count pages from the built project files (`app.json` page list + `pages/` tree) for each agent, and record the count beside the agent name.
- Fail any non-game agent that has only one page, because a single page cannot carry entry → process → result. (Games follow the SOP loop-gate relaxation, but a boutique game still needs its thickness: levels/progress/content set must be in the files.)
- Compare page lists and built file sizes across the whole batch, and flag agents that share the same skeleton with only labels changed as **isomorphic — fail**. Ten near-identical `.ink` sizes are evidence, not coincidence.
- Treat every ledger claim and design note as unproven until the built files show the same fact.
- **Heavy agents — count distinct pages.** An agent designated heavy (the daily batch carries 2) must show **20 or more distinct pages** in the built files: reconcile the `app.json` page list against the `pages/` tree, one entry each, every page functionally different in content and wiring. States of one page, demo steps, and screenshot variants never count as pages. Spot-check 5 pages for genuine difference; merge look-alike pages in the count and recheck the total. Under 20 after merging — fail, do not count.

## Verify each claimed gate in code

- **Content set — count it.** For each claimed set, count the items in the built files and record the count (stations, songs, questions, stalls, steps…). A set that cannot be counted does not exist.
- **Loop — find the call.** For each claimed loop step, search the built files for the API call that step needs (head orientation / `onHeadGesture`, ASR, TTS, camera…). A step with no call is unwired and fails that claim. Permissions in `app.json`/`package.json` must match the features actually wired — never zero-permission claims for a camera/sensor feature.
- **Cross-session memory — find the persistence code.** When cross-session memory is claimed, search for the storage/write code (key name recorded). No persistence code, no claim.
- **Placeholders stay labelled.** Any placeholder or sample feature is labelled as a placeholder in the interface and in the notes, and is never counted as wired.

## Count only what passes and report the rest

- Count an agent toward the batch only when every claim it makes passes the checks above.
- Report each failed agent with its failed check and the built-file evidence, and put the batch shortfall at the **top** of the report. Never fill the count with a thin replacement, never lower a gate to reach the daily number, and never recount an agent that failed the same check after a cosmetic relabel.
- Remedies that keep the standard: merge thin agents that belong to one scenario into one scenario agent (originals stay archived, never deleted), or thicken a failed concept with a real content set / multi-step flow and rerun every check from the built files.

## Versioning of this skill

This skill iterates in place, semver:

- **patch** (1.0.x): wording fixes, added evidence examples, a new isomorphism tell.
- **minor** (1.x.0): a new check, a new counted-claim type, a new failure case.
- **major** (x.0.0): a gate-level change (what counts as passing changes meaning).

Every change: bump `version:` above, append a Change Log entry below (date, what production run taught it, what changed), update the installed mirror at `~/workspace/custom-skills/rokid_boutique_acceptance/SKILL.md` in the same turn, and push both in one commit. Lessons that apply to all production (not just acceptance) go to `rokid-agent-sop` instead — do not duplicate them here.

## Change Log

- **1.1.0 (2026-10-28)** — Minor: new check. GO added a heavy quota to the daily batch （每日 2 个重度 Agent, each 20+ distinct pages); acceptance now reconciles the built `app.json` page list against the `pages/` tree for heavy-designated agents, states/demo steps never count as pages, and look-alike pages are merged before recounting.
- **1.0.0 (2026-10-28)** — Landed as a skill at GO's instruction. Distilled from the boutique line's first week: the 2026-10-27 first batch passed its three gates in ledger prose but was, in built files, 10/10 single-page with near-identical 8.35–8.57 KB `.ink` files — GO's verdict 「还是老问题」; the same-day merge-redo (JP20/JP21/JP22/KR15 + CC10 v2, three to four pages each, counted sets, visible persistence keys) supplied the passing shape; the checks were then patched into the daily cron and the 2026-10-28 batch (10 agents, 3 pages each) was the first run accepted under them.
