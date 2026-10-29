# skills/ — Skill Library for the Rokid Project

[中文](README.md) | English | [日本語](README.ja.md)
Translated from the Chinese version (as of 2026-10-29). In case of conflict, the Chinese version prevails.

Skill packages for a Coding Agent (`SKILL.md` + reference material). Install the corresponding skill before developing any Agent,
and do not assume an AIUI API exists based on experience with the Web / mini programs.

| Directory | Contents | Source |
|---|---|---|
| [`aiui-dev/`](aiui-dev/) | Official AIUI development skill: framework, .ink pages, components, WXSS, runtime API contracts, monochrome green design specification, packaging checklist | Vendored copy of the official repository [yodaos-project/AIUI](https://github.com/yodaos-project/AIUI/tree/main/skills/aiui-dev) (synced 2026-10-24); when upstream updates, overwrite and sync here |
| [`rokid-agent-sop/`](rokid-agent-sop/) | This project's production SOP: capability red lines → development → static checks → packaging → preview → README (including review submission material) → GitHub sync (main + aix/ packages + screenshots + `agent-<slug>` branches) → registration; in the same directory, `API-AUDIT.md` is the working draft of the full audit of the official documentation on 2026-10-29 (the evidence for API discipline: usable surface / not-found list / Ink version arrival table / full permission table) | This project's own |
| [`rokid-preview-screenshots/`](rokid-preview-screenshots/) | Local preview screenshot pipeline: `aix preview` exports HTML → local Ink runtime → headless Chrome captures the 480×352 canvas | This project's own |
| [`cc/`](cc/) | Curb-cut effect series design layer (`rokid-curb-cut`): the three founding questions (the ramp itself / channel transformation / spillover map), channel transformation per barrier, the Huiyan exclusion rule, spillover discipline and the no-dilution principle; used together with `rokid-agent-sop`, iterated with version numbers | This project's own |
| [`rokid-conflict-audit/`](rokid-conflict-audit/) | Built-in capability conflict audit: a baseline of the seven built-in features + three-tier judgment (direct conflict / high overlap / to be tested), the sole data source for the conflict badges in the root README; iterated with version numbers (currently v1.0.1) | This project's own |
| [`rokid-boutique-acceptance/`](rokid-boutique-acceptance/) | Boutique line batch acceptance (rokid-boutique-acceptance): check page counts and isomorphism against built files, count content sets item by item, check API wiring for closed loops, check persistence code for cross-session behaviour, placeholders never count, only passing items count; iterated with version numbers | This project's own |
| [`rokid-head-games/`](rokid-head-games/) | Head-movement mini-game design layer (rokid-head-games): the never-turn-in-circles constitution (segmented movements, must return to centre), safety lines, sensor honesty (symbols learned through calibration, nod-only gesture events), a judgment pattern library and GA production lessons; iterated with version numbers (currently v1.0.1) | This project's own |
| [`rokid-directional/`](rokid-directional/) | Directional series design layer (rokid-directional): the three founding questions for glasses vs. chest-worn devices, six design primitives (GAZE — looking is pointing / HEAD — orientation registration and relative direction / dwell confirmation / microphone array honest position / SCAN — turn the head to seek sound / GEO — cardinal directions and positioning), the honest boundaries from the 2026-10-24 audit and a reusable pattern library (orientation registry / look-back confirmation / reading cross-checks / relative heading lock); iterated with version numbers (currently v1.0.1) | This project's own |
| [`jp/`](jp/) | Japan localization skill (rokid-jp-localization): the JP series' locality criteria, Japanese purity rules and machine scan, Chinese copy traps, environment gate; iterated with version numbers | This project's own |
| [`kr/`](kr/) | Korea localization skill (rokid-kr-localization): the KR series' locality criteria, Korean purity rules and machine scan (kana and CJK ideographs = 0), Japanese copy traps, environment gate; iterated with version numbers | This project's own |

## Usage

```bash
# Install a single skill from this repository into the current project
npx skills add https://github.com/sakai55/rokid/tree/main/skills/aiui-dev

# Or copy the directory directly into the project's .agents/skills/
cp -r skills/aiui-dev <agent-project>/.agents/skills/
```

> Note: When packaging an Agent project, `.aixignore` must exclude `.agents/`, otherwise the skill files will get into the .aix package.
