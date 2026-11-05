# US July 4th Games - Agent Notes

GA60. United States local scene x game x directional x attention.

## Design contract

A US family waiting for July 4th plays Independence Day games on glasses, settling each game with a score.

## Counts

20 tools: 19 games (count 6, quiz 4, direction 3, sequence 4, math 2) + 1 record tool. Counting targets 10/12/8/9/15/7; direction 6 rounds each; sequence 5 steps each.

## Storage

Storage key `usJuly4GamesV1` (picked game, best per game, settled records, lastError).

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
- Exclusive wiring: onHeadGesture nod on every game page; _startSensor on direction pages g04, g10, g16.
