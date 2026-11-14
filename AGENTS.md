# USA Yellowstone Meet - Agent Notes

DI90. USA local scene x directional (GPS-anchored) x curb-cut (hands-full hikers separated from friends). Three gates: scene (hikers separated on a trail, hands on poles, need to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Design contract

Yellowstone hikers separated on a trail, both hands on trekking poles, follow GPS cardinal direction and distance back to the registered trailhead meeting point.

## Counts

6 meeting points (Old Faithful, Grand Prismatic Spring, Mammoth Hot Springs, Yellowstone Lake, Lamar Valley, Canyon Village).

## Storage

Storage key `usaYellowstoneMeetV1` (picked point, registered point, arrival records, lastError).

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
- GPS wiring: app.json GEOLOCATION + getCurrentPosition with existence guard + _calc cardinal conversion + haversine R=6371000, 10 m rounding.
- GPS error codes: error 1 -> E7003, other errors -> E7002.
