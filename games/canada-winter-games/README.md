# Canada Winter Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-canada-winter-games
```

[canada-winter-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/canada-winter-games.aix)

## Features

A Canadian family waiting out the winter carnival plays 20 winter games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

A Canadian family waiting at the winter carnival plays winter games on glasses, settling each game with a score.

## Direction composition

Canada local scene x game x directional x attention. Three gates: scene (a family waiting at the winter carnival, playing together on one pair of glasses); loop (pick a game, play it by head turn and nod, settle with a score, keep the best across sessions); thickness (20 games with distinct mechanics and content + cross-session best records).

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Snowflake Count |
| pages/g02 | Sled Direction |
| pages/g03 | Winter Quiz |
| pages/g04 | Snowman Steps |
| pages/g05 | Maple Math |
| pages/g06 | Icicle Count |
| pages/g07 | Skate Direction |
| pages/g08 | Carnival Quiz |
| pages/g09 | Hockey Steps |
| pages/g10 | Snow Math |
| pages/g11 | Beaver Count |
| pages/g12 | Toboggan Direction |
| pages/g13 | Canada Quiz |
| pages/g14 | Igloo Steps |
| pages/g15 | Poutine Math |
| pages/g16 | Moose Count |
| pages/g17 | Northern Lights Direction |
| pages/g18 | Snowshoe Quiz |
| pages/g19 | Hot Chocolate Steps |
| pages/g20 | Winter Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `canadaWinterGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-canada-winter-games-index.png](../../screenshots/canada-winter-games/preview-canada-winter-games-index.png)
![preview-canada-winter-games-g01.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g01.png)
![preview-canada-winter-games-g02.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g02.png)
![preview-canada-winter-games-g03.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g03.png)
![preview-canada-winter-games-g04.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g04.png)
![preview-canada-winter-games-g05.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g05.png)
![preview-canada-winter-games-g06.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g06.png)
![preview-canada-winter-games-g07.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g07.png)
![preview-canada-winter-games-g08.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g08.png)
![preview-canada-winter-games-g09.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g09.png)
![preview-canada-winter-games-g10.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g10.png)
![preview-canada-winter-games-g11.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g11.png)
![preview-canada-winter-games-g12.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g12.png)
![preview-canada-winter-games-g13.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g13.png)
![preview-canada-winter-games-g14.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g14.png)
![preview-canada-winter-games-g15.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g15.png)
![preview-canada-winter-games-g16.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g16.png)
![preview-canada-winter-games-g17.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g17.png)
![preview-canada-winter-games-g18.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g18.png)
![preview-canada-winter-games-g19.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g19.png)
![preview-canada-winter-games-g20.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g20.png)
![preview-canada-winter-games-g01-s2.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g01-s2.png)

## Review Submission

### Feature Description

A Canadian family waiting out the winter carnival plays 20 winter games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Happy winter carnival! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-canada-winter-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/canada-winter-games/preview-canada-winter-games-video.mp4)
![preview-canada-winter-games-index.png](../../screenshots/canada-winter-games/preview-canada-winter-games-index.png)
![preview-canada-winter-games-g01.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g01.png)
![preview-canada-winter-games-g02.png](../../screenshots/canada-winter-games/preview-canada-winter-games-g02.png)

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
