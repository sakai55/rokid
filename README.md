# UK Christmas Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-uk-christmas-games
```

[uk-christmas-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/uk-christmas-games.aix)

## Features

A UK family waiting for Christmas dinner plays 20 Christmas games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

A UK family waiting for Christmas dinner plays Christmas games on glasses, settling each game with a score.

## Direction composition

United Kingdom local scene x game x directional x attention.

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Carol Count |
| pages/g02 | Reindeer Direction |
| pages/g03 | Christmas Quiz |
| pages/g04 | Pudding Steps |
| pages/g05 | Present Math |
| pages/g06 | Ornament Count |
| pages/g07 | Snowman Direction |
| pages/g08 | Carol Quiz |
| pages/g09 | Tree Steps |
| pages/g10 | Gift Math |
| pages/g11 | Snowflake Count |
| pages/g12 | Sleigh Direction |
| pages/g13 | Pudding Quiz |
| pages/g14 | Wreath Steps |
| pages/g15 | Stocking Math |
| pages/g16 | Cracker Count |
| pages/g17 | Star Direction |
| pages/g18 | Market Quiz |
| pages/g19 | Carol Steps |
| pages/g20 | Christmas Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 12/10/15/8; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `ukChristmasGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-uk-christmas-games-index.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-index.png)
![preview-uk-christmas-games-g01.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g01.png)
![preview-uk-christmas-games-g02.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g02.png)
![preview-uk-christmas-games-g03.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g03.png)
![preview-uk-christmas-games-g04.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g04.png)
![preview-uk-christmas-games-g05.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g05.png)
![preview-uk-christmas-games-g06.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g06.png)
![preview-uk-christmas-games-g07.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g07.png)
![preview-uk-christmas-games-g08.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g08.png)
![preview-uk-christmas-games-g09.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g09.png)
![preview-uk-christmas-games-g10.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g10.png)
![preview-uk-christmas-games-g11.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g11.png)
![preview-uk-christmas-games-g12.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g12.png)
![preview-uk-christmas-games-g13.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g13.png)
![preview-uk-christmas-games-g14.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g14.png)
![preview-uk-christmas-games-g15.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g15.png)
![preview-uk-christmas-games-g16.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g16.png)
![preview-uk-christmas-games-g17.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g17.png)
![preview-uk-christmas-games-g18.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g18.png)
![preview-uk-christmas-games-g19.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g19.png)
![preview-uk-christmas-games-g20.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g20.png)
![preview-uk-christmas-games-g01-s2.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g01-s2.png)

## Review Submission

### Feature Description

A UK family waiting for Christmas dinner plays 20 Christmas games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Merry Christmas! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-uk-christmas-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/uk-christmas-games/preview-uk-christmas-games-video.mp4)
![preview-uk-christmas-games-index.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-index.png)
![preview-uk-christmas-games-g01.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g01.png)
![preview-uk-christmas-games-g02.png](../screenshots/uk-christmas-games/preview-uk-christmas-games-g02.png)

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
