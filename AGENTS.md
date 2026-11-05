# UK Coast Meet - Agent Notes

DI63. United Kingdom local scene x directional (GPS-anchored).

## Design contract

A walker on the Cornwall coast, separated from the group, follows GPS cardinal direction and distance back to the registered meeting point.

## Counts

6 meeting points (St Ives Harbour, Tintagel Castle Gate, Land's End Car Park, Porthleven Beach, Mousehole Village Green, Coast Path Start).

## Storage

Storage key `ukCoastMeetV1` (picked point, registered point, arrival records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Distance is an estimate, rounded to 10 metres; indoors or in weak GPS areas the page says so and invents no position.
- No position is given before a point is registered.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- GPS wiring: app.json GEOLOCATION + getCurrentPosition + _calc cardinal conversion.
