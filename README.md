# US Thanksgiving Games

**Studio import address** (copy into the Import Project box in Global AIUI Studio):

```
https://github.com/sakai55/rokid/tree/agent-us-thanksgiving-games
```

**Latest AIX download:** [us-thanksgiving-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/us-thanksgiving-games.aix)

AIX size: 57,742 bytes.

GA56 us-thanksgiving-games - United States - Game x directional x attention. A United States Thanksgiving family, waiting together before dinner, plays 20 Thanksgiving games on one pair of glasses: count, direction, quiz, order, rhythm, and record games, each settled with a score and kept across sessions.

## Direction mix

Game x directional x attention

## Scene

A United States Thanksgiving family, waiting together before dinner, plays 20 Thanksgiving games on one pair of glasses: count, direction, quiz, order, rhythm, and record games, each settled with a score and kept across sessions.

## Glasses-exclusive capability

Hands-free first-person play with nod as the main confirm on every game page, plus head-direction coordination on the two direction games: the player looks left, centre, or right to pick a direction and nods to confirm it. Take the nod and head direction away and the games cannot be played while hands are busy with family cooking and table work; a phone game needs a hand and a look down.

Wiring evidence: every game page binds onHeadGesture nod to primaryTap, which calls actionTap; direction pages pages/g02/index.ink and pages/g12/index.ink run _startSensor with a typeof guard on AbsoluteOrientationSensor, a yaw threshold of plus or minus 0.35, and a return-to-centre re-arm, and sensor failure maps to E7001. The hub Open button navigates straight to the picked game page, so the hub row selection plus Open is the direct route to a game.

## Pages

| Page | Role |
|---|---|
| pages/index | Hub: 20 games in a 5-game window, best score and settled record count of the picked game |
| pages/g01 | Turkey Count: Count by nod |
| pages/g02 | Pumpkin Direction: Head direction, 6 rounds |
| pages/g03 | Cranberry Quiz: Choice quiz |
| pages/g04 | Corn Count: Count by nod |
| pages/g05 | Pilgrim Steps: Order repeat |
| pages/g06 | Pie Colour: Choice quiz |
| pages/g07 | Harvest Rhythm: Nod rhythm |
| pages/g08 | Thankful Words: Choice quiz |
| pages/g09 | Stuffing Count: Count by nod |
| pages/g10 | Leaf Colour: Choice quiz |
| pages/g11 | Turkey Math: Math choice quiz |
| pages/g12 | Corn Maze Direction: Head direction, 6 rounds |
| pages/g13 | Pumpkin Pie Steps: Order repeat |
| pages/g14 | Football Score Quiz: Choice quiz |
| pages/g15 | Apple Count: Count by nod |
| pages/g16 | Parade Order: Order repeat |
| pages/g17 | Gravy Count: Count by nod |
| pages/g18 | Fall Taste Quiz: Choice quiz |
| pages/g19 | Turkey Trot Steps: Count by nod |
| pages/g20 | Thanksgiving Record: Record by nod, settle at 6 |

## Content set

20 Thanksgiving games: Turkey Count (Count by nod); Pumpkin Direction (Head direction, 6 rounds); Cranberry Quiz (Choice quiz); Corn Count (Count by nod); Pilgrim Steps (Order repeat); Pie Colour (Choice quiz); Harvest Rhythm (Nod rhythm); Thankful Words (Choice quiz); Stuffing Count (Count by nod); Leaf Colour (Choice quiz); Turkey Math (Math choice quiz); Corn Maze Direction (Head direction, 6 rounds); Pumpkin Pie Steps (Order repeat); Football Score Quiz (Choice quiz); Apple Count (Count by nod); Parade Order (Order repeat); Gravy Count (Count by nod); Fall Taste Quiz (Choice quiz); Turkey Trot Steps (Count by nod); Thanksgiving Record (Record by nod, settle at 6). Counting targets: Turkey 10, Corn 12, Stuffing 8, Apple 9, Gravy 7, Turkey Trot Steps 20. Direction games: 6 rounds each. Quiz games: 3 or 4 questions each. Sequence games: 5 steps each. Rhythm: 8 beats. Record game: 6 thanks. Every settled game writes one real record and keeps a best score.

## Persistence

Cross-session storage key `usThanksgivingGamesV1`: picked game, best score per game, settled records array, lastError.

## Permissions

No permissions are declared. Head direction uses the device orientation sensor and spoken feedback uses the host speech path; no location is used.

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (the main button on each page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change the selection |
| Nod (head steady) | onHeadGesture nod | Same as main confirm |
| Double tap | Backspace | Back to the previous page |

## Error codes

- `E5001` Storage write failed
- `E5002` Storage read failed
- `E3005` Spoken feedback failed
- `E8001` Page move failed
- `E7001` Head direction sensor failed

Failures always show the bare code on screen, and lastError keeps the code plus slug, version, and original text.

## Preview screenshots

![preview-us-thanksgiving-games-index.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-index.png)
![preview-us-thanksgiving-games-g01.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g01.png)
![preview-us-thanksgiving-games-g02.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g02.png)
![preview-us-thanksgiving-games-g03.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g03.png)
![preview-us-thanksgiving-games-g04.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g04.png)
![preview-us-thanksgiving-games-g05.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g05.png)
![preview-us-thanksgiving-games-g06.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g06.png)
![preview-us-thanksgiving-games-g07.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g07.png)
![preview-us-thanksgiving-games-g08.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g08.png)
![preview-us-thanksgiving-games-g09.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g09.png)
![preview-us-thanksgiving-games-g10.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g10.png)
![preview-us-thanksgiving-games-g11.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g11.png)
![preview-us-thanksgiving-games-g12.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g12.png)
![preview-us-thanksgiving-games-g13.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g13.png)
![preview-us-thanksgiving-games-g14.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g14.png)
![preview-us-thanksgiving-games-g15.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g15.png)
![preview-us-thanksgiving-games-g16.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g16.png)
![preview-us-thanksgiving-games-g17.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g17.png)
![preview-us-thanksgiving-games-g18.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g18.png)
![preview-us-thanksgiving-games-g19.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g19.png)
![preview-us-thanksgiving-games-g20.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g20.png)
![preview-us-thanksgiving-games-g01-s2.png](../screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-g01-s2.png)

## Review submission

### Feature Description

A United States Thanksgiving family hub with 20 games for family waiting time: counting, head-direction, quiz, order, rhythm, and record games. Each game settles with a score, keeps a best score across sessions, and returns to the hub for the next game.

### Opening Message

Pick a Thanksgiving game and nod to play it. Each game settles with a score and keeps your best for next time.

### Preview Media

- [preview-us-thanksgiving-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/us-thanksgiving-games/preview-us-thanksgiving-games-video.mp4)
- `preview-us-thanksgiving-games-index.png`
- `preview-us-thanksgiving-games-g01.png`
- `preview-us-thanksgiving-games-g01-s2.png`

### Change Log

- Features added: 20 Thanksgiving games in one hub, nod confirm on every game, head-direction play on two games, best scores and settled records kept across sessions.
- Improvements: None in this first build.
- Fixes: None in this first build.

## Device test info

| Item | Value |
|---|---|
| Studio name | Not entered |
| Version | 1.0.0 |
| Category | Not entered |
| Intent description | Not entered |
| Agent ID | Not entered |
| Status | Not imported |
