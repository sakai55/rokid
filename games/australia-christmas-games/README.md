# Australia Christmas Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-australia-christmas-games
```

[australia-christmas-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/australia-christmas-games.aix)

## Features

An Australian family waiting for Christmas lunch plays 20 Christmas games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

An Australian family waiting for Christmas lunch plays Christmas games on glasses, settling each game with a score.

## Direction composition

Australia local scene x game x directional x attention.

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Prawn Count |
| pages/g02 | Surf Direction |
| pages/g03 | Christmas Quiz |
| pages/g04 | Cricket Steps |
| pages/g05 | Pavlova Math |
| pages/g06 | Koala Count |
| pages/g07 | Boomerang Direction |
| pages/g08 | Barbie Quiz |
| pages/g09 | Sand Steps |
| pages/g10 | Lamington Math |
| pages/g11 | Kangaroo Count |
| pages/g12 | Wave Direction |
| pages/g13 | Outback Quiz |
| pages/g14 | Beach Steps |
| pages/g15 | Seafood Math |
| pages/g16 | Platypus Count |
| pages/g17 | Santa Direction |
| pages/g18 | Summer Quiz |
| pages/g19 | BBQ Steps |
| pages/g20 | Christmas Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `australiaChristmasGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-australia-christmas-games-index.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-index.png)
![preview-australia-christmas-games-g01.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g01.png)
![preview-australia-christmas-games-g02.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g02.png)
![preview-australia-christmas-games-g03.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g03.png)
![preview-australia-christmas-games-g04.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g04.png)
![preview-australia-christmas-games-g05.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g05.png)
![preview-australia-christmas-games-g06.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g06.png)
![preview-australia-christmas-games-g07.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g07.png)
![preview-australia-christmas-games-g08.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g08.png)
![preview-australia-christmas-games-g09.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g09.png)
![preview-australia-christmas-games-g10.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g10.png)
![preview-australia-christmas-games-g11.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g11.png)
![preview-australia-christmas-games-g12.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g12.png)
![preview-australia-christmas-games-g13.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g13.png)
![preview-australia-christmas-games-g14.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g14.png)
![preview-australia-christmas-games-g15.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g15.png)
![preview-australia-christmas-games-g16.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g16.png)
![preview-australia-christmas-games-g17.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g17.png)
![preview-australia-christmas-games-g18.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g18.png)
![preview-australia-christmas-games-g19.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g19.png)
![preview-australia-christmas-games-g20.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g20.png)
![preview-australia-christmas-games-g01-s2.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g01-s2.png)

## Review Submission

### Feature Description

An Australian family waiting for Christmas lunch plays 20 Christmas games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Merry Christmas! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-australia-christmas-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/australia-christmas-games/preview-australia-christmas-games-video.mp4)
![preview-australia-christmas-games-index.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-index.png)
![preview-australia-christmas-games-g01.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g01.png)
![preview-australia-christmas-games-g02.png](../../screenshots/australia-christmas-games/preview-australia-christmas-games-g02.png)

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
