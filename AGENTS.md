# Banff Trail Meet - Agent Notes

DI55. Canada local scene x directional.

## Design contract

A Banff hiker separated from companions at a trail junction registers a trailhead meeting point by GPS and follows a cardinal direction and distance back, without taking the phone out.

## Counts

Content set: 6 trailheads. Arrival records are counted by their real number.

## Storage

Storage key `canadaTrailMeetV1` (selected trailhead, registered point name with latitude and longitude and registration time, arrival records array, lastError).

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (guide page on the index page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change trailhead |
| Nod (head steady) | onHeadGesture nod | Same as main confirm |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- The unregistered guide state says Not registered and never invents a location.
- GPS denied maps to E7003 and other GPS failures to E7002; distance is an estimate rounded to 10 m.
- The meeting point is the hiker's own registered position, not a looked-up place.

## Validation

- Language purity: no CJK characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits.
- GPS wiring: pages/index saveTap registers, pages/guide primaryTap measures and pages/guide _calc converts to cardinal direction and distance.
