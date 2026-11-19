# Wales Coast Meet - Agent Notes

DI105. Wales local scene x directional (GPS-anchored) x curb-cut (hands-full walkers separated from their group). Three gates: scene (walkers separated on a coastal path, hands full of bags or a walking stick, need to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real Wales coast meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Design contract

Walkers on the Wales Coast Path, separated from their group with both hands full, follow GPS cardinal direction and distance back to the registered meeting point without taking out a phone.

## Counts

6 meeting points on the Wales coast (St Davids Head, Rhossili Bay, Three Cliffs Bay, Worm's Head, Barafundle Bay, Tenby North Beach).

## Storage

Storage key `walesCoastMeetV1` (picked point, registered point, arrival records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Distance is an estimate, rounded to 10 metres; indoors or in weak GPS areas the page says so and invents no position.
- No position is given before a point is registered.
- Preview cannot present live GPS: the review video shows only the register-and-measure flow the preview can show, with no position invented.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- GPS wiring: app.json GEOLOCATION + getCurrentPosition with existence guard + _calc cardinal conversion + haversine R=6371000, 10 m rounding.
- GPS error codes: error 1 -> E7003, other errors -> E7002.
