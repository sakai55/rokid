---
name: "rokid-kr-localization"
description: "Produce Korea-localized Rokid AIUI Agents for the sakai55/rokid fleet (KR numbering, korea/ directory, all-Korean UI): what counts as genuine Korean locality, the Korean language-purity rules and machine scan (kana = 0, CJK ideographs = 0), known Japanese-copy traps, and the environment gate. Use together with rokid-agent-sop for any KR agent."
version: "1.0.0"
---

# Rokid Korea Localization

中文 | [English](SKILL.en.md) | [日本語](SKILL.ja.md)

The locale layer for KR agents. The shared production pipeline (capability red lines, three gates, 9-step SOP, pack/preview/README/GitHub sync) lives in `rokid-agent-sop` — this skill adds only what is specific to Korea. An agent is KR only if all three hold: KR number, project under `korea/<slug>/`, and a genuinely Korean scene (below).

## What counts as Korean locality

The scene must come from real Korean institutions, etiquette, or services — not a generic agent with Korean text pasted on. Proven wells (one concrete problem each, closed loop required by the SOP gates):

- **Institutions & systems**: 종량제 volume-based trash bags and their pricing, 계 rotating savings circles, 층간소음 (inter-floor noise) mediation culture, 한복 rental-and-return shops near palaces, PC방 seat-and-snack billing, 배달 공동현관 (shared entrance) delivery codes.
- **Etiquette as mechanism**: 소주 two-hand receiving and turning away from elders, 노래방 turn rotation, 삼겹살 grill timing.
- **Local services & habits**: 김장 batch counting, 등산 pace and water discipline, 한강 picnic base management, 카페 도장 stamp cards.

Test before designing: name the Korean rule, institution, or custom the loop depends on. If the loop works unchanged in any country, it is not a KR agent.

## Language rules (the 2026-10-25 purification incident)

- **Every user-visible string is Korean (Hangul) from the first draft** — status, hero, rows, marks, guide, TTS lines, SCAN prompts, seed/demo data. Only English chrome stays English (page title, button labels, `EVT:` prefix). README documentation stays Chinese (for GO, not UI).
- **Machine scan before packing** (on the built `.ink` files, not just sources): **kana count = 0 AND CJK ideograph count = 0** in UI strings. This is a hard gate — the incident build shipped whole KR UIs in Japanese (noise-diary, baedal-code), Japanese fragments in others (hangang-base, soju-turn, deungsan-pace), a Japanese body in jongnyang-gauge, and a Chinese SCAN prompt in KR04. (₩, digits, and English chrome are fine; generator doc comments are not UI.)
- **Japanese-copy traps** (caught by the scan, listed so authors avoid them): 向かい → 맞은편, 済み → 완료, 守候-style Chinese status lines, any kana at all. If a string needs a Hanja-derived word, write it in Hangul.
- TTS lines follow the same rule — spoken Korean only; the host TTS `lang` attribute is never set (documented as ineffective).

## Environment gate (Korea cases)

Settings must be places people actually wear glasses. **Out**: 찜질방 / 사우나 and any bathing/steam/heat setting — KR09 `jjimjil-rest` was retired in place on exactly this ruling (kept, never deleted; replaced in-slot by `pcbang-session`). Markets, transit, dining, home, outdoors, social all pass.

## Form & roster

- Each KR agent has its own interaction philosophy and UI form (the series' standing exception to fleet-uniform styling); buttons are styled per form, never a shared default. Green-only palette per the SOP.
- Roster and numbering authority: `~/workspace/goals/20-agent-rokid-aiui-2/files/PLAN-20-JPKR-Agents.md` (KR01–KR10 original line, KR11+ continuations) plus the `korea/` directory. Badge attribution for KR rows: 指向性 only when head orientation is the primary input (soju-turn), otherwise 注意力 — frozen badge definitions, see SOP.

## Versioning of this skill

This skill iterates in place, semver:

- **patch** (1.0.x): new trap words, wording fixes, added examples.
- **minor** (1.x.0): a new locality well, a new scan rule, a new retired case.
- **major** (x.0.0): a gate or language-rule change.

Every change: bump `version:` above, append a Change Log entry below (date, what production run taught it, what changed), update the installed mirror at `~/workspace/custom-skills/rokid-kr-localization/SKILL.md` in the same turn, and push both in one commit. Lessons that apply to all agents (not just KR) go to `rokid-agent-sop` instead — do not duplicate them here.

## Change Log

- **1.0.0 (2026-10-28)** — Landed as a skill at GO's instruction. Distilled from the KR series (KR01–KR13+): locality wells, the language-purification incident and the kana/CJK = 0 scan standard （向かい/済み traps), the jjimjil-rest environment ruling.
