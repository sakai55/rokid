# Canada Hockey Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-canada-hockey-games
```

[canada-hockey-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/canada-hockey-games.aix)

## Features

A Canadian family waiting through hockey season plays 20 ice hockey games on one pair of glasses, each settled with a score and kept across sessions.

## Scene

A Canadian family waiting through hockey season plays ice hockey games on glasses, settling each game with a score.

## Direction composition

Canada local scene x game x directional x attention.

## Glasses-only capability

Head-direction coordination + nod as main confirm: games are played by turning the head and nodding, with no phone in hand. Wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on direction pages g02, g07, g12, g17.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 20-game hub list |
| pages/g01 | Puck Count |
| pages/g02 | Slapshot Direction |
| pages/g03 | Hockey Quiz |
| pages/g04 | Skate Steps |
| pages/g05 | Penalty Math |
| pages/g06 | Stick Count |
| pages/g07 | Goalie Direction |
| pages/g08 | Rink Quiz |
| pages/g09 | Zamboni Steps |
| pages/g10 | Score Math |
| pages/g11 | Jersey Count |
| pages/g12 | Faceoff Direction |
| pages/g13 | Team Quiz |
| pages/g14 | Warmup Steps |
| pages/g15 | Ticket Math |
| pages/g16 | Snow Count |
| pages/g17 | Overtime Direction |
| pages/g18 | Trophy Quiz |
| pages/g19 | Fan Steps |
| pages/g20 | Hockey Record |

## Content set

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Cross-session storage

Storage key `canadaHockeyGamesV1` (picked game, best per game, settled records, lastError).

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

![preview-canada-hockey-games-index.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-index.png)
![preview-canada-hockey-games-g01.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g01.png)
![preview-canada-hockey-games-g02.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g02.png)
![preview-canada-hockey-games-g03.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g03.png)
![preview-canada-hockey-games-g04.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g04.png)
![preview-canada-hockey-games-g05.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g05.png)
![preview-canada-hockey-games-g06.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g06.png)
![preview-canada-hockey-games-g07.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g07.png)
![preview-canada-hockey-games-g08.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g08.png)
![preview-canada-hockey-games-g09.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g09.png)
![preview-canada-hockey-games-g10.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g10.png)
![preview-canada-hockey-games-g11.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g11.png)
![preview-canada-hockey-games-g12.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g12.png)
![preview-canada-hockey-games-g13.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g13.png)
![preview-canada-hockey-games-g14.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g14.png)
![preview-canada-hockey-games-g15.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g15.png)
![preview-canada-hockey-games-g16.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g16.png)
![preview-canada-hockey-games-g17.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g17.png)
![preview-canada-hockey-games-g18.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g18.png)
![preview-canada-hockey-games-g19.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g19.png)
![preview-canada-hockey-games-g20.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g20.png)
![preview-canada-hockey-games-g01-s2.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g01-s2.png)

## Review Submission

### Feature Description

A Canadian family waiting through hockey season plays 20 ice hockey games on one pair of glasses, each settled with a score and kept across sessions.

### Opening Message

Game on! Pick a game, nod to play, and I will keep your score.

### Preview Media

[preview-canada-hockey-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/canada-hockey-games/preview-canada-hockey-games-video.mp4)
![preview-canada-hockey-games-index.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-index.png)
![preview-canada-hockey-games-g01.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g01.png)
![preview-canada-hockey-games-g02.png](../../screenshots/canada-hockey-games/preview-canada-hockey-games-g02.png)

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
