# Canada Winter Games - Agent Notes

GA78. Canada local scene x game x directional x attention. Three gates: scene (a family waiting at the winter carnival, playing together on one pair of glasses); loop (pick a game, play it by head turn and nod, settle with a score, keep the best across sessions); thickness (20 games with distinct mechanics and content + cross-session best records).

## Design contract

A Canadian family waiting at the winter carnival plays winter games on glasses, settling each game with a score.

## Counts

20 tools: 19 games (count 4, quiz 4, direction 4, sequence 4, math 3) + 1 record tool. Counting targets 10/12/8/15; direction 6 rounds each; sequence 5 steps each.

## Storage

Storage key `canadaWinterGamesV1` (picked game, best per game, settled records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Scores come only from real taps and nods; no score is invented.
- Direction games fall back to buttons when the head sensor is off, and sensor failure shows E7001.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: onHeadGesture nod on every game page; _startSensor on direction pages g02, g07, g12, g17.
- Direction hit check: _zone (0/1/2) is compared against ZONES.indexOf(target), not against the target string.
