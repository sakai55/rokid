# UK Boxing Day Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-uk-boxing-day-games
```

[uk-boxing-day-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/uk-boxing-day-games.aix)

## Features

A UK family waiting on Boxing Day plays 20 Boxing Day games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

A UK family waiting on Boxing Day plays Boxing Day games on glasses, settling each game with a score.

## Direction composition

United Kingdom local scene x game x directional x attention. Three gates: scene (a family waiting on Boxing Day, playing together on one pair of glasses); loop (pick a game, play it by head turn and nod, settle with a score, keep the best across sessions); thickness (20 games with distinct mechanics and content + cross-session best records).

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Sale Count |
| pages/g02 | Cracker Direction |
| pages/g03 | Boxing Quiz |
| pages/g04 | Leftover Steps |
| pages/g05 | Pudding Math |
| pages/g06 | Walk Count |
| pages/g07 | Darts Direction |
| pages/g08 | Winter Quiz |
| pages/g09 | Board Steps |
| pages/g10 | Sale Math |
| pages/g11 | Robin Count |
| pages/g12 | Sledge Direction |
| pages/g13 | Football Quiz |
| pages/g14 | Roast Steps |
| pages/g15 | Leftover Math |
| pages/g16 | Snow Count |
| pages/g17 | Panto Direction |
| pages/g18 | Panto Quiz |
| pages/g19 | Walk Steps |
| pages/g20 | Boxing Day Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `ukBoxingDayGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-uk-boxing-day-games-index.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-index.png)
![preview-uk-boxing-day-games-g01.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g01.png)
![preview-uk-boxing-day-games-g02.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g02.png)
![preview-uk-boxing-day-games-g03.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g03.png)
![preview-uk-boxing-day-games-g04.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g04.png)
![preview-uk-boxing-day-games-g05.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g05.png)
![preview-uk-boxing-day-games-g06.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g06.png)
![preview-uk-boxing-day-games-g07.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g07.png)
![preview-uk-boxing-day-games-g08.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g08.png)
![preview-uk-boxing-day-games-g09.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g09.png)
![preview-uk-boxing-day-games-g10.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g10.png)
![preview-uk-boxing-day-games-g11.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g11.png)
![preview-uk-boxing-day-games-g12.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g12.png)
![preview-uk-boxing-day-games-g13.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g13.png)
![preview-uk-boxing-day-games-g14.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g14.png)
![preview-uk-boxing-day-games-g15.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g15.png)
![preview-uk-boxing-day-games-g16.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g16.png)
![preview-uk-boxing-day-games-g17.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g17.png)
![preview-uk-boxing-day-games-g18.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g18.png)
![preview-uk-boxing-day-games-g19.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g19.png)
![preview-uk-boxing-day-games-g20.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g20.png)
![preview-uk-boxing-day-games-g01-s2.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g01-s2.png)

## Review Submission

### Feature Description

A UK family waiting on Boxing Day plays 20 Boxing Day games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Happy Boxing Day! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-uk-boxing-day-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-video.mp4)
![preview-uk-boxing-day-games-index.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-index.png)
![preview-uk-boxing-day-games-g01.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g01.png)
![preview-uk-boxing-day-games-g02.png](../screenshots/uk-boxing-day-games/preview-uk-boxing-day-games-g02.png)

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
