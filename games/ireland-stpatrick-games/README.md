# Ireland St Patrick Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-ireland-stpatrick-games
```

[ireland-stpatrick-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ireland-stpatrick-games.aix)

## Features

An Irish family waiting for the St Patrick's Day parade plays 20 St Patrick's games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

An Irish family waiting for the St Patrick's Day parade plays St Patrick's games on glasses, settling each game with a score.

## Direction composition

Ireland local scene x game x directional x attention. Three gates: scene (a family waiting for the parade, playing together on one pair of glasses); loop (pick a game, play it by head turn and nod, settle with a score, keep the best across sessions); thickness (20 games with distinct mechanics and content + cross-session best records).

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Shamrock Count |
| pages/g02 | Ceilidh Direction |
| pages/g03 | St Patrick Quiz |
| pages/g04 | Soda Bread Steps |
| pages/g05 | Shamrock Math |
| pages/g06 | Leprechaun Count |
| pages/g07 | Riverdance Direction |
| pages/g08 | Dublin Quiz |
| pages/g09 | Parade Steps |
| pages/g10 | Harp Math |
| pages/g11 | Harp Count |
| pages/g12 | Parade Direction |
| pages/g13 | Irish Quiz |
| pages/g14 | Ceilidh Steps |
| pages/g15 | Rainbow Math |
| pages/g16 | Rainbow Count |
| pages/g17 | Shamrock Direction |
| pages/g18 | Parade Quiz |
| pages/g19 | Pot Steps |
| pages/g20 | St Patrick Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `irelandStpatrickGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-ireland-stpatrick-games-index.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-index.png)
![preview-ireland-stpatrick-games-g01.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g01.png)
![preview-ireland-stpatrick-games-g02.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g02.png)
![preview-ireland-stpatrick-games-g03.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g03.png)
![preview-ireland-stpatrick-games-g04.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g04.png)
![preview-ireland-stpatrick-games-g05.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g05.png)
![preview-ireland-stpatrick-games-g06.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g06.png)
![preview-ireland-stpatrick-games-g07.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g07.png)
![preview-ireland-stpatrick-games-g08.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g08.png)
![preview-ireland-stpatrick-games-g09.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g09.png)
![preview-ireland-stpatrick-games-g10.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g10.png)
![preview-ireland-stpatrick-games-g11.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g11.png)
![preview-ireland-stpatrick-games-g12.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g12.png)
![preview-ireland-stpatrick-games-g13.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g13.png)
![preview-ireland-stpatrick-games-g14.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g14.png)
![preview-ireland-stpatrick-games-g15.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g15.png)
![preview-ireland-stpatrick-games-g16.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g16.png)
![preview-ireland-stpatrick-games-g17.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g17.png)
![preview-ireland-stpatrick-games-g18.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g18.png)
![preview-ireland-stpatrick-games-g19.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g19.png)
![preview-ireland-stpatrick-games-g20.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g20.png)
![preview-ireland-stpatrick-games-g01-s2.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g01-s2.png)

## Review Submission

### Feature Description

An Irish family waiting for the St Patrick's Day parade plays 20 St Patrick's games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Happy St Patrick's Day! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-ireland-stpatrick-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-video.mp4)
![preview-ireland-stpatrick-games-index.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-index.png)
![preview-ireland-stpatrick-games-g01.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g01.png)
![preview-ireland-stpatrick-games-g02.png](../../screenshots/ireland-stpatrick-games/preview-ireland-stpatrick-games-g02.png)

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
