# Australia Beach Meet - Agent Notes

DI66. Australia local scene x directional (GPS-anchored) x attention.

## Design contract

An Australian beach walker, separated from friends with both hands full of bags, follows GPS cardinal direction and distance back to the registered meeting point.

## Counts

6 meeting points (Bondi Beach South End, Manly Beach Surf Club, Byron Bay Lighthouse Track, Noosa Main Beach, St Kilda Pier, Cottesloe Beach Groyne).

## Storage

Storage key `australiaBeachMeetV1` (picked point, registered point, arrival records, lastError).

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
