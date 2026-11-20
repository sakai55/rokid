# Barbados Crop Over Game - Agent Notes

GA91. Barbados local scene x game x directional (head-turn event picking). Three gates: scene (a Crop Over family gathering, playing together on one pair of glasses); loop (start, head-pick an event, nod to join in, 10 rounds, settle with a score); thickness (8 real Crop Over events + fixed 10-round sequence + best records across sessions). Game carries the play loop; directional carries the head-turn event picking.

## Design contract

At a family gathering during Crop Over, family members use only head direction to pick a festival event and nod to join in, settling the score over 10 rounds.

## Counts

8 real Crop Over events: Kadooment Day parade, Foreday Morning, Calypso tent, Soca competition, Craft market, Food fair, Grand Kadooment costumes, Pic-O-De-Crop finals. 10-round fixed target sequence [5, 2, 7, 0, 4, 1, 6, 3, 5, 2] written in code.

## Storage

Storage key `barbadosCropOverGameV1` (best score, settled records, lastError).

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
- Exclusive wiring: pages/play/index.ink _startSensor + _onYaw (re-centre re-arm) + nod to join in.
- 10-round fixed sequence written in code, settled by real hits.
