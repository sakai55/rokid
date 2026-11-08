# Australia Summer Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-australia-summer-games
```

[australia-summer-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/australia-summer-games.aix)

## Features

An Australian family waiting through summer plays 20 summer games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

An Australian family waiting through summer plays summer games on glasses, settling each game with a score.

## Direction composition

Australia local scene x game x directional x attention.

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Beach Count |
| pages/g02 | Surf Direction |
| pages/g03 | Barbie Quiz |
| pages/g04 | Cricket Steps |
| pages/g05 | Sausage Math |
| pages/g06 | Shell Count |
| pages/g07 | Boomerang Direction |
| pages/g08 | Reef Quiz |
| pages/g09 | Bushwalk Steps |
| pages/g10 | Lamington Math |
| pages/g11 | Koala Count |
| pages/g12 | Wave Direction |
| pages/g13 | Outback Quiz |
| pages/g14 | Sand Steps |
| pages/g15 | Pavlova Math |
| pages/g16 | Kangaroo Count |
| pages/g17 | Surfboard Direction |
| pages/g18 | Wildlife Quiz |
| pages/g19 | BBQ Steps |
| pages/g20 | Summer Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `australiaSummerGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-australia-summer-games-index.png](../../screenshots/australia-summer-games/preview-australia-summer-games-index.png)
![preview-australia-summer-games-g01.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g01.png)
![preview-australia-summer-games-g02.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g02.png)
![preview-australia-summer-games-g03.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g03.png)
![preview-australia-summer-games-g04.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g04.png)
![preview-australia-summer-games-g05.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g05.png)
![preview-australia-summer-games-g06.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g06.png)
![preview-australia-summer-games-g07.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g07.png)
![preview-australia-summer-games-g08.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g08.png)
![preview-australia-summer-games-g09.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g09.png)
![preview-australia-summer-games-g10.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g10.png)
![preview-australia-summer-games-g11.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g11.png)
![preview-australia-summer-games-g12.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g12.png)
![preview-australia-summer-games-g13.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g13.png)
![preview-australia-summer-games-g14.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g14.png)
![preview-australia-summer-games-g15.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g15.png)
![preview-australia-summer-games-g16.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g16.png)
![preview-australia-summer-games-g17.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g17.png)
![preview-australia-summer-games-g18.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g18.png)
![preview-australia-summer-games-g19.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g19.png)
![preview-australia-summer-games-g20.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g20.png)
![preview-australia-summer-games-g01-s2.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g01-s2.png)

## Review Submission

### Feature Description

An Australian family waiting through summer plays 20 summer games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

G'day! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-australia-summer-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/australia-summer-games/preview-australia-summer-games-video.mp4)
![preview-australia-summer-games-index.png](../../screenshots/australia-summer-games/preview-australia-summer-games-index.png)
![preview-australia-summer-games-g01.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g01.png)
![preview-australia-summer-games-g02.png](../../screenshots/australia-summer-games/preview-australia-summer-games-g02.png)

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
