# US July 4th Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-us-july4-games
```

[us-july4-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/us-july4-games.aix)

## Features

A US family waiting for July 4th plays 20 Independence Day games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

A US family waiting for July 4th plays Independence Day games on glasses, settling each game with a score.

## Direction composition

United States local scene x game x directional x attention.

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g04, g10, g16.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Firework Count |
| pages/g02 | Hot Dog Count |
| pages/g03 | Parade Quiz |
| pages/g04 | Flag Direction |
| pages/g05 | BBQ Steps |
| pages/g06 | Sparkler Count |
| pages/g07 | Star Quiz |
| pages/g08 | Picnic Math |
| pages/g09 | Baseball Steps |
| pages/g10 | Firework Direction |
| pages/g11 | Lemonade Count |
| pages/g12 | Parade Order |
| pages/g13 | Corn Count |
| pages/g14 | Flag Quiz |
| pages/g15 | Watermelon Steps |
| pages/g16 | Sparkler Direction |
| pages/g17 | Hot Dog Math |
| pages/g18 | Parade Steps |
| pages/g19 | Star Count |
| pages/g20 | July4 Record |

## Content set

20 tools: 19 games (count 6, quiz 4, direction 3, sequence 4, math 2) + 1 record tool. Counting targets 10/12/8/9/15/7; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `usJuly4GamesV1` (picked game, best per game, settled records, lastError).

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

![preview-us-july4-games-index.png](../screenshots/us-july4-games/preview-us-july4-games-index.png)
![preview-us-july4-games-g01.png](../screenshots/us-july4-games/preview-us-july4-games-g01.png)
![preview-us-july4-games-g02.png](../screenshots/us-july4-games/preview-us-july4-games-g02.png)
![preview-us-july4-games-g03.png](../screenshots/us-july4-games/preview-us-july4-games-g03.png)
![preview-us-july4-games-g04.png](../screenshots/us-july4-games/preview-us-july4-games-g04.png)
![preview-us-july4-games-g05.png](../screenshots/us-july4-games/preview-us-july4-games-g05.png)
![preview-us-july4-games-g06.png](../screenshots/us-july4-games/preview-us-july4-games-g06.png)
![preview-us-july4-games-g07.png](../screenshots/us-july4-games/preview-us-july4-games-g07.png)
![preview-us-july4-games-g08.png](../screenshots/us-july4-games/preview-us-july4-games-g08.png)
![preview-us-july4-games-g09.png](../screenshots/us-july4-games/preview-us-july4-games-g09.png)
![preview-us-july4-games-g10.png](../screenshots/us-july4-games/preview-us-july4-games-g10.png)
![preview-us-july4-games-g11.png](../screenshots/us-july4-games/preview-us-july4-games-g11.png)
![preview-us-july4-games-g12.png](../screenshots/us-july4-games/preview-us-july4-games-g12.png)
![preview-us-july4-games-g13.png](../screenshots/us-july4-games/preview-us-july4-games-g13.png)
![preview-us-july4-games-g14.png](../screenshots/us-july4-games/preview-us-july4-games-g14.png)
![preview-us-july4-games-g15.png](../screenshots/us-july4-games/preview-us-july4-games-g15.png)
![preview-us-july4-games-g16.png](../screenshots/us-july4-games/preview-us-july4-games-g16.png)
![preview-us-july4-games-g17.png](../screenshots/us-july4-games/preview-us-july4-games-g17.png)
![preview-us-july4-games-g18.png](../screenshots/us-july4-games/preview-us-july4-games-g18.png)
![preview-us-july4-games-g19.png](../screenshots/us-july4-games/preview-us-july4-games-g19.png)
![preview-us-july4-games-g20.png](../screenshots/us-july4-games/preview-us-july4-games-g20.png)
![preview-us-july4-games-g01-s2.png](../screenshots/us-july4-games/preview-us-july4-games-g01-s2.png)

## Review Submission

### Feature Description

A US family waiting for July 4th plays 20 Independence Day games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Happy July 4th! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-us-july4-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/us-july4-games/preview-us-july4-games-video.mp4)
![preview-us-july4-games-index.png](../screenshots/us-july4-games/preview-us-july4-games-index.png)
![preview-us-july4-games-g01.png](../screenshots/us-july4-games/preview-us-july4-games-g01.png)
![preview-us-july4-games-g02.png](../screenshots/us-july4-games/preview-us-july4-games-g02.png)

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
