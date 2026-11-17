# Scotland Highland Games - Agent Notes

GA84. Scotland local scene x game x directional (head-turn event selection). Three gates: scene (a family at a Highland Games gathering, playing together on one pair of glasses); loop (pick the target event by head turn, nod to compete, settle 10 rounds with a score, keep the best across sessions); thickness (8 real Highland events + 10 fixed rounds + cross-session best records). Game carries the play loop; directional carries the head-turn event selection.

## Design contract

At a Highland Games family gathering, family members pick a real Highland event by head direction and nod to compete, settling 10 rounds.

## Counts

8 real Highland Games events: Caber Toss, Hammer Throw, Tug of War, Stone Put, Weight for Distance, Weight for Height, Sheaf Toss, Highland Dancing. 10 rounds over a fixed target sequence [0, 3, 1, 6, 4, 2, 7, 5, 0, 3] written in code.

## Storage

Storage key `scotlandHighlandGamesV1` (best score, settled records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Segmented motion: one head turn changes one event only, and re-centring is required before changing again; never spin in a circle.
- Without a sensor, buttons change the event and scoring stays the same.
- The target sequence is fixed in code; no random draw is claimed.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Sensor wiring: pages/play/index.ink _startSensor (existence guard) + _onYaw (re-centre gate) + onHeadGesture nod to compete.
- 10-round fixed sequence written in code, settled on real counts.
