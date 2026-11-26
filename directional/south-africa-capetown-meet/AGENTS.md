# South Africa Capetown Meet - Agent Notes

DI117. South Africa local scene x directional (GPS-anchored) x curb-cut (hands-full visitor separated from her companions). Three gates: scene (a visitor separated in Cape Town, hands full, needs to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real Cape Town meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Design contract

A visitor in Cape Town with both hands full of shopping bags loses her companions near the V&A Waterfront and returns to the registered meeting point by GPS bearing and distance, without taking out her phone.

## Counts

6 meeting points in Cape Town: V&A Waterfront, Table Mountain Cableway, Kirstenbosch Garden, Camps Bay Beach, Bo-Kaap, Greenmarket Square. All six web-verified as real, publicly accessible Cape Town places on 2026-11-27; no overlap with the south-africa-braai-watch content (cooking watch, different domain), and no Table Mountain summit-claim wording beyond the cableway.

## Storage

Storage key `southAfricaCapetownMeetV1` (picked point, registered point, arrival records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Distance is an estimate, rounded to 10 metres; indoors or in weak GPS areas the page says so and invents no position.
- No position is given before a point is registered.
- Preview cannot present live GPS: the review video shows only the register-and-measure flow the preview can show, with no position invented. No guide-s2 / record-s2 screenshot is delivered, because preview has no GPS.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- GPS wiring: app.json GEOLOCATION + getCurrentPosition with existence guard + _calc cardinal conversion + haversine R=6371000, 10 m rounding.
- GPS error codes: error 1 -> E7003, other errors -> E7002.
