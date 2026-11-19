# Trinidad Carnival Game

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-trinidad-carnival-game
```

[trinidad-carnival-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/trinidad-carnival-game.aix)

## Features

At a Trinidad Carnival family gathering, the family plays 10 rounds by head turn alone - turn to pick a carnival event, nod to compete, settle with a score and keep the best across sessions.

## Scene

At a Trinidad Carnival family gathering, the family plays 10 rounds by head turn alone - turn to pick a carnival event, nod to compete.

## Direction composition

Trinidad and Tobago local scene x game x directional (head-turn event picking). Three gates: scene (a Carnival family gathering, playing together on one pair of glasses); loop (start, head-pick an event, nod to compete, 10 rounds, settle with a score); thickness (8 real Carnival events + fixed 10-round sequence + best records across sessions). Game carries the play loop; directional carries the head-turn event picking.

## Glasses-only capability

Head-direction coordination + nod as the main confirm: turn the head to pick a carnival event, nod to compete, no phone in hand during play. Wiring: pages/play/index.ink _startSensor + _onYaw (re-centre to re-arm, left back one / right next one, one step per turn, never spin) + onHeadGesture nod triggers primaryTap to compete; buttons pick an event when the sensor is off.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 8 carnival events and best score |
| pages/play | 10 rounds of event matching, nod to compete, settle with a score |
| pages/record | Carnival records |

## Content set

8 real Trinidad Carnival events: Steelpan, Calypso, Soca, Limbo, J'ouvert, Masquerade, Stick Fighting, Panorama. 10-round fixed target sequence [3, 0, 6, 1, 4, 7, 2, 5, 3, 0] written in code.

## Cross-session storage

Storage key `trinidadCarnivalGameV1` (best score, settled records, lastError).

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
- One head turn changes only one event; re-centre before changing again, never spin.
- The target sequence is fixed in code, not claimed random.
- Without a sensor, buttons pick an event; scoring stays the same. Sensor failure shows E7001.

## Preview screenshots

![preview-trinidad-carnival-game-index.png](../../screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-index.png)
![preview-trinidad-carnival-game-play.png](../../screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-play.png)
![preview-trinidad-carnival-game-play-s2.png](../../screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-play-s2.png)
![preview-trinidad-carnival-game-record.png](../../screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-record.png)

## Review Submission

### Feature Description

At a Trinidad Carnival family gathering, the family plays 10 rounds by head turn alone - turn to pick a carnival event, nod to compete, settle with a score and keep the best across sessions.

### Opening Message

Carnival time! Match the target event, nod to compete, 10 rounds to settle the winner.

### Preview Media

[preview-trinidad-carnival-game-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-video.mp4)
![preview-trinidad-carnival-game-index.png](../../screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-index.png)
![preview-trinidad-carnival-game-play.png](../../screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-play.png)
![preview-trinidad-carnival-game-play-s2.png](../../screenshots/trinidad-carnival-game/preview-trinidad-carnival-game-play-s2.png)

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
