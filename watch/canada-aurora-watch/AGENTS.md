# Canada Aurora Watch - Agent Notes

WA11. Canada local scene x attention (watching) x directional (head-turn point selection).

## Design contract

A Canada aurora viewer in gloves, hands too cold for a phone, picks a viewing point by head turn and logs sightings by nodding.

## Counts

6 viewing points (Yellowknife Lake, Whitehorse Hill, Churchill Bay, Jasper Field, Dawson Ridge, Iqaluit Shore). Sighting records counted by real number.

## Storage

Storage key `canadaAuroraWatchV1` (picked point, sighting records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not forecast the aurora; sightings are only what the viewer logs.
- Without a sensor, buttons pick the viewing point.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod.
