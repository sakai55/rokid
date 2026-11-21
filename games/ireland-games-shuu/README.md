# Ireland Games Shuu

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-ireland-games-shuu
```

[ireland-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ireland-games-shuu.aix)

## Features

Irish games in one hub: at a family gathering, the whole family plays 20 Irish games on one pair of glasses, settling the score by head movement alone, and the best is kept across sessions.

## Scene

At an Irish family gathering, the whole family plays 20 Irish games on one pair of glasses, settling the score by head movement alone.

## Direction composition

Ireland local scene x game x directional (head-turn direction games) x attention (best-score keeping). Three gates: scene (an Irish family gathering, playing together on one pair of glasses); loop (pick a game from the hub, play by head turn and nod, settle with a score, keep the best across sessions); thickness (20 Irish games with different mechanisms + multi-step flows + cross-session best records). Game carries the play loop; directional carries the head-turn direction games.

## Glasses-only capability

Head-direction coordination + nod as the main confirm: direction games are picked by turning the head, a nod plays, no phone in hand during play. Wiring: every game page onHeadGesture nod triggers primaryTap, direction pages g02/g07/g12/g17 _startSensor + _onYaw with yaw +-0.35 and re-centre to re-arm; hit check uses ZONES.indexOf(target).

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20 games overview |
| pages/g01 | Hurling Count |
| pages/g02 | Gaelic Football Direction |
| pages/g03 | Cliffs of Moher Quiz |
| pages/g04 | Celtic Knot Steps |
| pages/g05 | Clover Math |
| pages/g06 | Camogie Count |
| pages/g07 | Tin Whistle Direction |
| pages/g08 | Aran Sweater Quiz |
| pages/g09 | Irish Dancing Steps |
| pages/g10 | Claddagh Math |
| pages/g11 | Claddagh Count |
| pages/g12 | Uilleann Pipes Direction |
| pages/g13 | Irish Stew Quiz |
| pages/g14 | Bodhran Steps |
| pages/g15 | Blarney Math |
| pages/g16 | Blarney Count |
| pages/g17 | Newgrange Direction |
| pages/g18 | Blarney Stone Quiz |
| pages/g19 | Harp Steps |
| pages/g20 | Ireland Record |

## Content set

20 tools: 19 games (counting 4, quiz 4, direction 4, steps 4, arithmetic 3) + 1 record tool. Counting targets 15/15/3/7, direction games 6 rounds each, steps games 5 steps each, arithmetic 3+4, 2+5, 9-4. Quiz answers are true Irish facts, web-verified 2026-11-22: Cliffs of Moher in County Clare, Aran sweaters from the Aran Islands, traditional Irish stew made with lamb, kissing the Blarney Stone gives the gift of eloquence.

## Cross-session storage

Storage key `irelandGamesShuuV1` (picked game, best per game, settled records, lastError).

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

![preview-ireland-games-shuu-index.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-index.png)
![preview-ireland-games-shuu-g01.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g01.png)
![preview-ireland-games-shuu-g02.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g02.png)
![preview-ireland-games-shuu-g03.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g03.png)
![preview-ireland-games-shuu-g04.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g04.png)
![preview-ireland-games-shuu-g05.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g05.png)
![preview-ireland-games-shuu-g06.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g06.png)
![preview-ireland-games-shuu-g07.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g07.png)
![preview-ireland-games-shuu-g08.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g08.png)
![preview-ireland-games-shuu-g09.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g09.png)
![preview-ireland-games-shuu-g10.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g10.png)
![preview-ireland-games-shuu-g11.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g11.png)
![preview-ireland-games-shuu-g12.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g12.png)
![preview-ireland-games-shuu-g13.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g13.png)
![preview-ireland-games-shuu-g14.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g14.png)
![preview-ireland-games-shuu-g15.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g15.png)
![preview-ireland-games-shuu-g16.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g16.png)
![preview-ireland-games-shuu-g17.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g17.png)
![preview-ireland-games-shuu-g18.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g18.png)
![preview-ireland-games-shuu-g19.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g19.png)
![preview-ireland-games-shuu-g20.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g20.png)
![preview-ireland-games-shuu-g01-s2.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g01-s2.png)

## Review Submission

### Feature Description

Irish games in one hub: at a family gathering, the whole family plays 20 Irish games on one pair of glasses, settling the score by head movement alone, and the best is kept across sessions.

### Opening Message

Irish games are here - pick one, nod to play, and I will keep your score.

### Preview Media

[preview-ireland-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ireland-games-shuu/preview-ireland-games-shuu-video.mp4)
![preview-ireland-games-shuu-index.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-index.png)
![preview-ireland-games-shuu-g01.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g01.png)
![preview-ireland-games-shuu-g02.png](../../screenshots/ireland-games-shuu/preview-ireland-games-shuu-g02.png)

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
