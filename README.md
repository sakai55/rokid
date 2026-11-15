# USA Thanksgiving Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-usa-thanksgiving-games
```

[usa-thanksgiving-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/usa-thanksgiving-games.aix)

## Features

An American family waiting for Thanksgiving dinner plays 20 Thanksgiving games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

An American family waiting for Thanksgiving dinner plays Thanksgiving games on glasses, settling each game with a score.

## Direction composition

USA local scene x game x directional x attention. Three gates: scene (a family waiting for Thanksgiving dinner, playing together on one pair of glasses); loop (pick a game, play it by head turn and nod, settle with a score, keep the best across sessions); thickness (20 games with distinct mechanics and content + cross-session best records).

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Turkey Count |
| pages/g02 | Parade Direction |
| pages/g03 | Thanksgiving Quiz |
| pages/g04 | Pumpkin Pie Steps |
| pages/g05 | Cranberry Math |
| pages/g06 | Cornucopia Count |
| pages/g07 | Football Direction |
| pages/g08 | Harvest Quiz |
| pages/g09 | Stuffing Steps |
| pages/g10 | Turkey Math |
| pages/g11 | Acorn Count |
| pages/g12 | Macy Direction |
| pages/g13 | Pilgrim Quiz |
| pages/g14 | Gravy Steps |
| pages/g15 | Pumpkin Math |
| pages/g16 | Leaf Count |
| pages/g17 | Turkey Direction |
| pages/g18 | Autumn Quiz |
| pages/g19 | Pie Steps |
| pages/g20 | Thanksgiving Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `usaThanksgivingGamesV1` (picked game, best per game, settled records, lastError).

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

- Scores come only from real taps and nods; no score is invented.
- Direction games fall back to buttons when the head sensor is off, and sensor failure shows E7001.

## Preview screenshots

![preview-usa-thanksgiving-games-index.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-index.png)
![preview-usa-thanksgiving-games-g01.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g01.png)
![preview-usa-thanksgiving-games-g02.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g02.png)
![preview-usa-thanksgiving-games-g03.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g03.png)
![preview-usa-thanksgiving-games-g04.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g04.png)
![preview-usa-thanksgiving-games-g05.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g05.png)
![preview-usa-thanksgiving-games-g06.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g06.png)
![preview-usa-thanksgiving-games-g07.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g07.png)
![preview-usa-thanksgiving-games-g08.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g08.png)
![preview-usa-thanksgiving-games-g09.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g09.png)
![preview-usa-thanksgiving-games-g10.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g10.png)
![preview-usa-thanksgiving-games-g11.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g11.png)
![preview-usa-thanksgiving-games-g12.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g12.png)
![preview-usa-thanksgiving-games-g13.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g13.png)
![preview-usa-thanksgiving-games-g14.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g14.png)
![preview-usa-thanksgiving-games-g15.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g15.png)
![preview-usa-thanksgiving-games-g16.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g16.png)
![preview-usa-thanksgiving-games-g17.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g17.png)
![preview-usa-thanksgiving-games-g18.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g18.png)
![preview-usa-thanksgiving-games-g19.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g19.png)
![preview-usa-thanksgiving-games-g20.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g20.png)
![preview-usa-thanksgiving-games-g01-s2.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g01-s2.png)

## Review Submission

### Feature Description

An American family waiting for Thanksgiving dinner plays 20 Thanksgiving games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Happy Thanksgiving! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-usa-thanksgiving-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-video.mp4)
![preview-usa-thanksgiving-games-index.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-index.png)
![preview-usa-thanksgiving-games-g01.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g01.png)
![preview-usa-thanksgiving-games-g02.png](../screenshots/usa-thanksgiving-games/preview-usa-thanksgiving-games-g02.png)

### Change Log

- Features：First release features as above.
- Improvements：None.
- Fixes：None.

## Device test info

| Studio name | To be filled |
|---|---|
| Studio name | To be filled |
| Version / Build | To be filled |
| App Category | To be filled |
| Intent Description | To be filled |
| Agent ID | To be filled |
| Status | To be filled |
