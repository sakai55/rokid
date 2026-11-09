# NZ Alps Meet - Agent Notes

DI75. New Zealand local scene x directional (GPS-anchored) x curb-cut (hands-full walker separated from friends).

## Design contract

A Southern Alps walker, separated from friends with both hands full of bags, follows GPS cardinal direction and distance back to the registered meeting point.

## Counts

6 meeting points (Mount Cook Village, Hooker Valley Track, Mueller Hut Track, Tasman Glacier View, Sealy Tarns Track, Aoraki Base Camp).

## Storage

Storage key `nzAlpsMeetV1` (picked point, registered point, arrival records, lastError).

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
