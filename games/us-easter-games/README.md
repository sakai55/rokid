# US Easter Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-us-easter-games
```

[us-easter-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/us-easter-games.aix)

## Features

A US family waiting through Easter plays 20 Easter games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

A US family waiting through Easter plays Easter games on glasses, settling each game with a score.

## Direction composition

United States local scene x game x directional x attention.

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Egg Count |
| pages/g02 | Bunny Direction |
| pages/g03 | Easter Quiz |
| pages/g04 | Basket Steps |
| pages/g05 | Egg Math |
| pages/g06 | Chick Count |
| pages/g07 | Tulip Direction |
| pages/g08 | Spring Quiz |
| pages/g09 | Parade Steps |
| pages/g10 | Bunny Math |
| pages/g11 | Flower Count |
| pages/g12 | Egg Hunt Direction |
| pages/g13 | Garden Quiz |
| pages/g14 | Bonnet Steps |
| pages/g15 | Candy Math |
| pages/g16 | Lamb Count |
| pages/g17 | Rainbow Direction |
| pages/g18 | Spring Song Quiz |
| pages/g19 | Picnic Steps |
| pages/g20 | Easter Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `usEasterGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-us-easter-games-index.png](../../screenshots/us-easter-games/preview-us-easter-games-index.png)
![preview-us-easter-games-g01.png](../../screenshots/us-easter-games/preview-us-easter-games-g01.png)
![preview-us-easter-games-g02.png](../../screenshots/us-easter-games/preview-us-easter-games-g02.png)
![preview-us-easter-games-g03.png](../../screenshots/us-easter-games/preview-us-easter-games-g03.png)
![preview-us-easter-games-g04.png](../../screenshots/us-easter-games/preview-us-easter-games-g04.png)
![preview-us-easter-games-g05.png](../../screenshots/us-easter-games/preview-us-easter-games-g05.png)
![preview-us-easter-games-g06.png](../../screenshots/us-easter-games/preview-us-easter-games-g06.png)
![preview-us-easter-games-g07.png](../../screenshots/us-easter-games/preview-us-easter-games-g07.png)
![preview-us-easter-games-g08.png](../../screenshots/us-easter-games/preview-us-easter-games-g08.png)
![preview-us-easter-games-g09.png](../../screenshots/us-easter-games/preview-us-easter-games-g09.png)
![preview-us-easter-games-g10.png](../../screenshots/us-easter-games/preview-us-easter-games-g10.png)
![preview-us-easter-games-g11.png](../../screenshots/us-easter-games/preview-us-easter-games-g11.png)
![preview-us-easter-games-g12.png](../../screenshots/us-easter-games/preview-us-easter-games-g12.png)
![preview-us-easter-games-g13.png](../../screenshots/us-easter-games/preview-us-easter-games-g13.png)
![preview-us-easter-games-g14.png](../../screenshots/us-easter-games/preview-us-easter-games-g14.png)
![preview-us-easter-games-g15.png](../../screenshots/us-easter-games/preview-us-easter-games-g15.png)
![preview-us-easter-games-g16.png](../../screenshots/us-easter-games/preview-us-easter-games-g16.png)
![preview-us-easter-games-g17.png](../../screenshots/us-easter-games/preview-us-easter-games-g17.png)
![preview-us-easter-games-g18.png](../../screenshots/us-easter-games/preview-us-easter-games-g18.png)
![preview-us-easter-games-g19.png](../../screenshots/us-easter-games/preview-us-easter-games-g19.png)
![preview-us-easter-games-g20.png](../../screenshots/us-easter-games/preview-us-easter-games-g20.png)
![preview-us-easter-games-g01-s2.png](../../screenshots/us-easter-games/preview-us-easter-games-g01-s2.png)

## Review Submission

### Feature Description

A US family waiting through Easter plays 20 Easter games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Happy Easter! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-us-easter-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/us-easter-games/preview-us-easter-games-video.mp4)
![preview-us-easter-games-index.png](../../screenshots/us-easter-games/preview-us-easter-games-index.png)
![preview-us-easter-games-g01.png](../../screenshots/us-easter-games/preview-us-easter-games-g01.png)
![preview-us-easter-games-g02.png](../../screenshots/us-easter-games/preview-us-easter-games-g02.png)

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
