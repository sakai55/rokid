# London Bus Meetup - Agent Notes

DI51. United Kingdom local scene x directional GPS.

## Design contract

A visitor in London with both hands full of shopping bags returns to a registered bus stop meeting point by following its GPS compass direction and distance, then records the arrival.

## Counts

Content set: 6 London bus stops (Victoria Station, Waterloo Station, King's Cross, Oxford Circus, London Bridge, Piccadilly Circus). Arrival records are counted by their real number.

## Storage

Storage key `londonBusMeetV1` (selected stop, registered point latitude/longitude/registered time, arrival records array, lastError).

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (main button on each page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change selection |
| Nod (head steady) | onHeadGesture nod | Same as main confirm |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- Distance is an estimate including GPS error, not an exact walking distance. GPS is weak indoors and may fail.
- An unregistered place gets no guide. The agent never invents a place.
- The meeting point is the shopper's own registration; official stop information stays authoritative.

## Validation

- Language purity: no Chinese, Japanese, or Korean characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits.
- GPS triple: GEOLOCATION declared in app.json, getCurrentPosition calls in pages/index (saveTap) and pages/guide (primaryTap), cardinal conversion in pages/guide _calc.
