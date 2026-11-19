# India Curry Watch - Agent Notes

WA41. India local scene x attention (multi-pot timer watch) x directional (head-turn pot selection). Three gates: scene (a cook on curry day with both hands busy at the stove); loop (pick a curry, nod to start its timer, hear the ready reminder, log the pot off); thickness (6 Indian curries with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn pot selection.

## Design contract

While the Indian curry cooks, the cook with both hands busy looks at one pot, nods to start its timer, and is told when it is ready.

## Counts

6 Indian curries with suggested seconds: Butter Chicken 1500, Palak Paneer 1200, Chana Masala 1800, Rogan Josh 2100, Dal Tadka 900, Biryani 2400.

## Storage

Storage key `indiaCurryWatchV1` (timers per curry, off-the-fire records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with heat and pot size.
- Tapping before time only tells the time left; no record is written.
- Each curry reminds only once when its time is up; the off record is written only by confirming after time.
- Without a sensor, buttons change the curry; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
