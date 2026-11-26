# Australia Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-australia-games-shuu
```

**Latest AIX package:** [australia-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/australia-games-shuu.aix)

## Features

An Australian family at a gathering plays 20 Australian games on one pair of glasses — counting, direction, quiz, steps and arithmetic — each settled with a score and kept across sessions.

## Scene

At a family gathering in Australia, the whole family plays 20 Australian games on one pair of glasses, settling the score by head movement alone.

## Direction composition

Australia local scene x game x directional x attention. Three gates: scene (an Australian family at a gathering, playing together on one pair of glasses); loop (pick a game, play it by head turn and nod, settle with a score, keep the best across sessions); thickness (20 games with distinct mechanics and content + cross-session best records).

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture('nod') to primaryTap on every game page; _startSensor with AbsoluteOrientationSensor on direction pages g02, g07, g12, g17 (yaw beyond ±0.35 selects Left/Right, returning to centre re-arms; sensor failure shows E7001). Removing head play breaks the loop: direction games cannot be played by buttons alone in any meaningful way, and every game settles by nod.

## Pages

| Page | Game |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Boomerang Count |
| pages/g02 | AFL Direction |
| pages/g03 | Cricket Quiz |
| pages/g04 | Bush Dance Steps |
| pages/g05 | Wallaby Count |
| pages/g06 | Surf Colour Match |
| pages/g07 | Didgeridoo Direction |
| pages/g08 | Barbie Cook Steps |
| pages/g09 | Wombat Count |
| pages/g10 | Opal Colour Match |
| pages/g11 | Billabong Steps |
| pages/g12 | Stockman Direction |
| pages/g13 | Emu Count |
| pages/g14 | Koala Quiz |
| pages/g15 | Lamington Steps |
| pages/g16 | Cricket Arithmetic |
| pages/g17 | Swell Direction |
| pages/g18 | Boomerang Arithmetic |
| pages/g19 | Outback Arithmetic |
| pages/g20 | Australia Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, steps 4, arithmetic 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each with a fixed target sequence per game; steps 5 steps each. Direction sequences: g02 AFL [Right, Left, Centre, Right, Centre, Left]; g07 Didgeridoo [Centre, Right, Left, Centre, Left, Right]; g12 Stockman [Left, Centre, Right, Centre, Right, Left]; g17 Swell [Right, Centre, Left, Left, Right, Centre]. Quiz answers are real Australian facts, verified against public sources: a cricket team fields 11 players; the sea at Bondi Beach is blue on a clear day; a black opal has a dark (black) base stone; koalas mainly eat eucalyptus leaves.

## Cross-session storage

Storage key `australiaGamesShuuV1` (picked game, best per game, settled records, lastError).

## Permissions

No declared permissions. Speech is host-managed and needs no declaration.

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Error codes

- `E5001` Storage write failed
- `E5002` Storage read failed
- `E3005` Speech failed
- `E8001` Navigation failed
- `E7001` Head sensor unavailable or read failed

## Honest boundaries

- Scores come only from real taps and nods; no score is invented.
- Direction games fall back to buttons when the head sensor is off, and sensor failure shows E7001.
- Counting targets are play targets, not claims about real animal numbers.
- "Barbie Cook Steps" is barbecue cooking steps ("barbie" is Australian slang for barbecue), not a doll.
- Quiz facts are single verified facts, not a claim of comprehensive knowledge about each subject.

## Preview screenshots

![preview-australia-games-shuu-index.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-index.png)
![preview-australia-games-shuu-g01.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g01.png)
![preview-australia-games-shuu-g02.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g02.png)
![preview-australia-games-shuu-g03.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g03.png)
![preview-australia-games-shuu-g04.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g04.png)
![preview-australia-games-shuu-g05.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g05.png)
![preview-australia-games-shuu-g06.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g06.png)
![preview-australia-games-shuu-g07.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g07.png)
![preview-australia-games-shuu-g08.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g08.png)
![preview-australia-games-shuu-g09.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g09.png)
![preview-australia-games-shuu-g10.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g10.png)
![preview-australia-games-shuu-g11.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g11.png)
![preview-australia-games-shuu-g12.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g12.png)
![preview-australia-games-shuu-g13.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g13.png)
![preview-australia-games-shuu-g14.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g14.png)
![preview-australia-games-shuu-g15.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g15.png)
![preview-australia-games-shuu-g16.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g16.png)
![preview-australia-games-shuu-g17.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g17.png)
![preview-australia-games-shuu-g18.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g18.png)
![preview-australia-games-shuu-g19.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g19.png)
![preview-australia-games-shuu-g20.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g20.png)
![preview-australia-games-shuu-g01-s2.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g01-s2.png)

## Review Submission

### Feature Description

An Australian family at a gathering plays 20 Australian games on one pair of glasses — counting, direction, quiz, steps and arithmetic — each settled with a score and kept across sessions.

### Opening Message

G'day! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-australia-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/australia-games-shuu/preview-australia-games-shuu-video.mp4)
![preview-australia-games-shuu-index.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-index.png)
![preview-australia-games-shuu-g01.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g01.png)
![preview-australia-games-shuu-g02.png](../screenshots/australia-games-shuu/preview-australia-games-shuu-g02.png)

### Change Log

- Features: First release features as above.
- Improvements: None.
- Fixes: None.

## Device test info

| Field | Value |
|---|---|
| Studio name | To be filled |
| Version / Build | To be filled |
| App Category | To be filled |
| Intent Description | To be filled |
| Agent ID | To be filled |
| Status | To be filled |
