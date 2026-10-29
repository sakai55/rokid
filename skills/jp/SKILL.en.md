---
name: "rokid-jp-localization"
description: "Produce Japan-localized Rokid AIUI Agents for the sakai55/rokid fleet (JP numbering, japan/ directory, all-Japanese UI): what counts as genuine Japanese locality, the Japanese language-purity rules and machine scan, known Chinese-copy traps, and the environment gate. Use together with rokid-agent-sop for any JP agent."
version: "1.0.0"
---

# Rokid Japan Localization

[中文](SKILL.md) | English | [日本語](SKILL.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

The locale layer for JP agents. The shared production pipeline (capability red lines, three gates, 9-step SOP, pack/preview/README/GitHub sync) lives in `rokid-agent-sop` — this skill adds only what is specific to Japan. An agent counts as JP only if all three hold: a JP number, a project under `japan/<slug>/`, and a genuinely Japanese scene (below).

## What counts as Japanese locality

The scene must come from real Japanese institutions, etiquette, or services — not a generic agent with Japanese text pasted on. Proven wells (one concrete problem each; a closed loop is required by the SOP gates):

- **Institutions & systems**: tax-free shopping rules (免税・密封袋）, station coin lockers （コインロッカー）, 回覧板 neighborhood circulation boards, 防災 kit checks, ゴミ分別 municipal sorting rules, 回転寿司 conveyor-belt sushi plate pricing.
- **Etiquette as mechanism**: the 神社参拝 shrine-visit sequence （二拝二拍手一拝）, 静粛車両 quiet-car phone-off norms, 飲み会幹事 organizer duties, 山手線 transfer courtesy.
- **Local services & habits**: コンビニ basket discipline, お土産 coverage for workplace gift obligations, bicycle parking/lockout habits.

The test, before designing: name the Japanese rule, institution, or custom the loop depends on. If the loop works unchanged in any country, it is not a JP agent.

## Language rules (the 2026-10-25 purification incident)

- **Every user-visible string is Japanese from the first draft** — status, hero, rows, marks, guide, TTS lines, SCAN prompts, seed/demo data. Only English chrome stays English (page title, button labels, `EVT:` prefix). README documentation stays Chinese (for GO, not UI).
- **Chinese-copy traps** (the generator's defaults leak Chinese; scan for these and their kin): 柜 → ロッカー / 棚, 点头 → うなずき, 守候 → 見守り, 取回 → 受け取り, 越線 → 超過, 寄存 → 預け, plus guide lines and SCAN prompts written as Chinese sentences. Kanji shared with Chinese is fine only when the *phrase* is natural Japanese.
- **Machine scan before packing** (on the built `.ink` files, not just the sources): no Chinese-only phrases anywhere in UI strings; guides and SCAN prompts get a manual read-through, because that is where residue hides best. A JP build that fails the scan does not get packed.
- TTS lines follow the same rule — spoken Japanese, no Chinese residue; the host TTS `lang` attribute is never set (documented as ineffective).

## Environment gate (Japan cases)

Settings must be places where people actually wear glasses. **Out**: 温泉 (onsen) and any bathing/steam/heat setting — JP05 `onsen-gate` was retired in place on exactly this ruling (kept, never deleted; replaced in-slot by `coin-locker`). Commuting, dining, shopping, home, outdoors, and social settings all pass.

## Form & roster

- Each JP agent has its own interaction philosophy and UI form (the series' standing exception to fleet-uniform styling); buttons are styled per form, never a shared default. Green-only palette per the SOP.
- Roster and numbering authority: `~/workspace/goals/20-agent-rokid-aiui-2/files/PLAN-20-JPKR-Agents.md` (JP01–JP10 original line, JP11+ continuations) plus the `japan/` directory. Badge attribution for JP rows: 指向性 only when head orientation is the primary input (jinja-bow), otherwise 注意力 — badge definitions are frozen, see the SOP.

## Versioning of this skill

This skill iterates in place, semver:

- **patch** (1.0.x): new trap words, wording fixes, added examples.
- **minor** (1.x.0): a new locality well, a new scan rule, a new retired case.
- **major** (x.0.0): a gate or language-rule change.

Every change: bump `version:` above, append a Change Log entry below (date, what production run taught it, what changed), update the installed mirror at `~/workspace/custom-skills/rokid-jp-localization/SKILL.md` in the same turn, and push both in one commit. Lessons that apply to all agents (not just JP) go to `rokid-agent-sop` instead — do not duplicate them here.

## Change Log

- **1.0.0 (2026-10-28)** — Landed as a skill on GO's instruction. Distilled from the JP series (JP01–JP13+): the locality wells, the language-purification incident and scan standard (柜/点头/守候 traps), and the onsen-gate environment ruling.
