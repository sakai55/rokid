# Jamaica Games Shuu

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-jamaica-games-shuu
```

[jamaica-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/jamaica-games-shuu.aix)

## Features

Jamaican folk and schoolyard games in one hub: a family waiting together plays 20 Jamaican games on one pair of glasses, each game settles with a score and the best is kept across sessions.

## Scene

Jamaican folk and schoolyard games in one hub: a family waiting together plays 20 Jamaican games on one pair of glasses.

## Direction composition

Jamaica local scene x game x directional (head-turn direction games) x attention (best-score keeping). Three gates: scene (a Jamaican family waiting together, playing on one pair of glasses); loop (pick a game from the hub, play by head turn and nod, settle with a score, keep the best across sessions); thickness (20 Jamaican games with different mechanisms + multi-step flows + cross-session best records). Game carries the play loop; directional carries the head-turn direction games.

## Glasses-only capability

Head-direction coordination + nod as the main confirm: direction games are picked by turning the head, a nod plays, no phone in hand during play. Wiring: every game page onHeadGesture nod triggers primaryTap, direction pages g02/g07/g12/g17 _startSensor + _onYaw; hit check uses ZONES.indexOf(target).

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20 games overview |
| pages/g01 | Dandy Shandy Count |
| pages/g02 | Brown Girl Direction |
| pages/g03 | Ring Game Quiz |
| pages/g04 | Hopscotch Steps |
| pages/g05 | Marble Math |
| pages/g06 | Bull in the Pen Count |
| pages/g07 | River Stone Direction |
| pages/g08 | Anansi Quiz |
| pages/g09 | Kite Steps |
| pages/g10 | Domino Math |
| pages/g11 | Jacks Count |
| pages/g12 | Mango Tree Direction |
| pages/g13 | Duppy Quiz |
| pages/g14 | Bandy Steps |
| pages/g15 | Ludo Math |
| pages/g16 | Cricket Count |
| pages/g17 | Seashell Direction |
| pages/g18 | Bamboo Quiz |
| pages/g19 | Jump Rope Steps |
| pages/g20 | Jamaica Record |

## Content set

20 tools: 19 games (counting 4, quiz 4, direction 4, steps 4, arithmetic 3) + 1 record tool. Counting targets 10/12/8/15, direction games 6 rounds each, steps games 5 steps each, arithmetic 8+6, 7+5, 9+4.

## Cross-session storage

Storage key `jamaicaGamesShuuV1` (picked game, best per game, settled records, lastError).

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

- Scores come only from real nods and taps; no score is invented.
- Without a sensor, direction games use buttons to pick a zone and scoring stays the same; sensor failure shows E7001.
- The 20 game names were checked one by one against all existing hub titles, zero overlap.

## Preview screenshots

![preview-jamaica-games-shuu-index.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-index.png)
![preview-jamaica-games-shuu-g01.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g01.png)
![preview-jamaica-games-shuu-g02.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g02.png)
![preview-jamaica-games-shuu-g03.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g03.png)
![preview-jamaica-games-shuu-g04.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g04.png)
![preview-jamaica-games-shuu-g05.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g05.png)
![preview-jamaica-games-shuu-g06.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g06.png)
![preview-jamaica-games-shuu-g07.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g07.png)
![preview-jamaica-games-shuu-g08.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g08.png)
![preview-jamaica-games-shuu-g09.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g09.png)
![preview-jamaica-games-shuu-g10.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g10.png)
![preview-jamaica-games-shuu-g11.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g11.png)
![preview-jamaica-games-shuu-g12.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g12.png)
![preview-jamaica-games-shuu-g13.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g13.png)
![preview-jamaica-games-shuu-g14.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g14.png)
![preview-jamaica-games-shuu-g15.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g15.png)
![preview-jamaica-games-shuu-g16.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g16.png)
![preview-jamaica-games-shuu-g17.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g17.png)
![preview-jamaica-games-shuu-g18.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g18.png)
![preview-jamaica-games-shuu-g19.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g19.png)
![preview-jamaica-games-shuu-g20.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g20.png)
![preview-jamaica-games-shuu-g01-s2.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g01-s2.png)

## Review Submission

### Feature Description

Jamaican folk and schoolyard games in one hub: a family waiting together plays 20 Jamaican games on one pair of glasses, each game settles with a score and the best is kept across sessions.

### Opening Message

Jamaican games are back - pick one, nod to play, and I will keep your score.

### Preview Media

[preview-jamaica-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-video.mp4)
![preview-jamaica-games-shuu-index.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-index.png)
![preview-jamaica-games-shuu-g01.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g01.png)
![preview-jamaica-games-shuu-g02.png](../screenshots/jamaica-games-shuu/preview-jamaica-games-shuu-g02.png)

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
