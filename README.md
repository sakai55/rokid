# NZ Haka Game

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-nz-haka-game
```

[nz-haka-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nz-haka-game.aix)

## Features

At a family gathering in New Zealand, players use only head direction to pick a haka element and nod to perform it, settling the score over 10 rounds and keeping the best across sessions.

## Scene

At a family gathering in New Zealand, players use only head direction to pick a haka element and nod to perform it, settling the score over 10 rounds.

## Direction composition

New Zealand local scene x game x directional (head-turn element picking). Three gates: scene (a New Zealand family gathering, playing a haka game together on one pair of glasses); loop (start, head-pick a haka element, nod to perform it, 10 rounds, settle with a score); thickness (8 real haka elements + fixed 10-round sequence + best records across sessions). Game carries the play loop; directional carries the head-turn element picking.

## Glasses-only capability

Head-direction coordination + nod as the main confirm: turn the head to pick a haka element, nod to perform it, no phone in hand during play. Wiring: pages/play/index.ink _startSensor + _onYaw (re-centre to re-arm, left back one / right next one, one step per turn, never spin) + onHeadGesture nod triggers primaryTap to perform; buttons pick an element when the sensor is off.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 8 haka elements and best score |
| pages/play | 10 rounds of element matching, nod to perform, settle with a score |
| pages/record | Haka records |

## Content set

8 real haka elements, each term web-verified on 2026-11-23 (newzealand.com, Wikipedia Haka, kapa haka references): Pukana wide eyes, Whetero tongue out, Wiri trembling hands, Waewae takahia foot stamp, Kaea leader call, Reo chant words, Peruperu high jump, Tutu ngarahu side jump. 10-round fixed target sequence [3, 6, 1, 7, 0, 4, 2, 5, 3, 6] written in code; it differs from the GA91 and GA93 sequences.

## Cross-session storage

Storage key `nzHakaGameV1` (best score, settled records, lastError).

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
- One head turn changes only one element; re-centre before changing again, never spin.
- The target sequence is fixed in code, not claimed random.
- Without a sensor, buttons pick an element; scoring stays the same. Sensor failure shows E7001.
- Performance judgement is demo judgement only, not physical recognition of the player's body.
- Haka elements are presented as a learning game only, with respect for Maori culture; this is not a claim of authentic haka teaching.

## Preview screenshots

![preview-nz-haka-game-index.png](../screenshots/nz-haka-game/preview-nz-haka-game-index.png)
![preview-nz-haka-game-play.png](../screenshots/nz-haka-game/preview-nz-haka-game-play.png)
![preview-nz-haka-game-play-s2.png](../screenshots/nz-haka-game/preview-nz-haka-game-play-s2.png)
![preview-nz-haka-game-record.png](../screenshots/nz-haka-game/preview-nz-haka-game-record.png)

## Review Submission

### Feature Description

At a family gathering in New Zealand, players use only head direction to pick a haka element and nod to perform it, settling the score over 10 rounds and keeping the best across sessions.

### Opening Message

Haka time! Match the target element, nod to perform it, 10 rounds to settle the winner.

### Preview Media

[preview-nz-haka-game-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/nz-haka-game/preview-nz-haka-game-video.mp4)
![preview-nz-haka-game-index.png](../screenshots/nz-haka-game/preview-nz-haka-game-index.png)
![preview-nz-haka-game-play.png](../screenshots/nz-haka-game/preview-nz-haka-game-play.png)
![preview-nz-haka-game-play-s2.png](../screenshots/nz-haka-game/preview-nz-haka-game-play-s2.png)

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
