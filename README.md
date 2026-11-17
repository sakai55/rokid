# Scotland Highland Games

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-scotland-highland-games
```

[scotland-highland-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/scotland-highland-games.aix)

## Features

At a Highland Games family gathering, family members pick a real Highland event by head direction and nod to compete, settling 10 rounds with a best score kept across sessions.

## Scene

At a Highland Games family gathering, family members pick a real Highland event by head direction and nod to compete, settling 10 rounds.

## Direction composition

Scotland local scene x game x directional (head-turn event selection). Three gates: scene (a family at a Highland Games gathering, playing together on one pair of glasses); loop (pick the target event by head turn, nod to compete, settle 10 rounds with a score, keep the best across sessions); thickness (8 real Highland events + 10 fixed rounds + cross-session best records). Game carries the play loop; directional carries the head-turn event selection.

## Glasses-only capability

Head-direction coordination: eyes and head direction are the selection, a nod is the compete action, no phone in hand during play. Wiring: pages/play/index.ink _startSensor (AbsoluteOrientationSensor existence guard) + _onYaw (re-centre arming gate: |yaw|<0.15 re-arms, turning left or right changes one event) + onHeadGesture nod to primaryTap to compete; buttons change the event when no sensor is present.

## Pages

| Pages | Pages |
|---|---|
| pages/index | Rules, 8 Highland events and best score |
| pages/play | 10 rounds of event matching, hits counted, settle writes a record |
| pages/record | Recent games and best score |

## Content set

8 real Highland Games events: Caber Toss, Hammer Throw, Tug of War, Stone Put, Weight for Distance, Weight for Height, Sheaf Toss, Highland Dancing. 10 rounds over a fixed target sequence [0, 3, 1, 6, 4, 2, 7, 5, 0, 3] written in code.

## Cross-session storage

Storage key `scotlandHighlandGamesV1` (best score, settled records, lastError).

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

- Segmented motion: one head turn changes one event only, and re-centring is required before changing again; never spin in a circle.
- Without a sensor, buttons change the event and scoring stays the same.
- The target sequence is fixed in code; no random draw is claimed.

## Preview screenshots

![preview-scotland-highland-games-index.png](../screenshots/scotland-highland-games/preview-scotland-highland-games-index.png)
![preview-scotland-highland-games-play.png](../screenshots/scotland-highland-games/preview-scotland-highland-games-play.png)
![preview-scotland-highland-games-play-s2.png](../screenshots/scotland-highland-games/preview-scotland-highland-games-play-s2.png)
![preview-scotland-highland-games-record.png](../screenshots/scotland-highland-games/preview-scotland-highland-games-record.png)

## Review Submission

### Feature Description

At a Highland Games family gathering, family members pick a real Highland event by head direction and nod to compete, settling 10 rounds with a best score kept across sessions.

### Opening Message

Welcome to the Highland Games! Match the target event, nod to compete, 10 rounds decide the winner.

### Preview Media

[preview-scotland-highland-games-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/scotland-highland-games/preview-scotland-highland-games-video.mp4)
![preview-scotland-highland-games-index.png](../screenshots/scotland-highland-games/preview-scotland-highland-games-index.png)
![preview-scotland-highland-games-play.png](../screenshots/scotland-highland-games/preview-scotland-highland-games-play.png)
![preview-scotland-highland-games-play-s2.png](../screenshots/scotland-highland-games/preview-scotland-highland-games-play-s2.png)

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
