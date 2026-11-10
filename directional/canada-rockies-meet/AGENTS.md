# Canada Rockies Meet - Agent Notes

DI78. Canada local scene x directional (GPS-anchored) x curb-cut (hands-full hiker separated from friends).

## Design contract

A Rockies hiker separated from friends at a trail junction, both hands on trekking poles, follows GPS cardinal direction and distance back to the registered trailhead meeting point.

## Counts

6 meeting points (Lake Louise, Moraine Lake, Johnston Canyon, Lake Minnewanka, Sunshine Village, Banff Upper Hot Springs).

## Storage

Storage key `canadaRockiesMeetV1` (picked point, registered point, arrival records, lastError).

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
