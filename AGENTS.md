# NZ Milford Meet - Agent Notes

DI87. New Zealand local scene x directional (GPS-anchored) x curb-cut (hands-full tramper separated from friends). Three gates: scene (a tramper separated from friends, hands on poles, needs to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Design contract

A Milford Sound tramper separated from friends on the track, both hands on walking poles, follows GPS cardinal direction and distance back to the registered trackhead meeting point.

## Counts

6 meeting points (Milford Track Start, Lake Marian Track, Gertrude Saddle, Key Summit, Homer Tunnel, Milford Sound Wharf).

## Storage

Storage key `nzMilfordMeetV1` (picked point, registered point, arrival records, lastError).

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
