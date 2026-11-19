# Trinidad Carnival Game - Agent Notes

GA88. Trinidad and Tobago local scene x game x directional (head-turn event picking). Three gates: scene (a Carnival family gathering, playing together on one pair of glasses); loop (start, head-pick an event, nod to compete, 10 rounds, settle with a score); thickness (8 real Carnival events + fixed 10-round sequence + best records across sessions). Game carries the play loop; directional carries the head-turn event picking.

## Design contract

At a Trinidad Carnival family gathering, the family plays 10 rounds by head turn alone - turn to pick a carnival event, nod to compete.

## Counts

8 real Trinidad Carnival events: Steelpan, Calypso, Soca, Limbo, J'ouvert, Masquerade, Stick Fighting, Panorama. 10-round fixed target sequence [3, 0, 6, 1, 4, 7, 2, 5, 3, 0] written in code.

## Storage

Storage key `trinidadCarnivalGameV1` (best score, settled records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Scores come only from real nods and taps; no score is invented.
- One head turn changes only one event; re-centre before changing again, never spin.
- The target sequence is fixed in code, not claimed random.
- Without a sensor, buttons pick an event; scoring stays the same. Sensor failure shows E7001.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/play/index.ink _startSensor + _onYaw (re-centre re-arm) + nod to compete.
- 10-round fixed sequence written in code, settled by real hits.
