# Ghana Stew Watch - Agent Notes

WA39. Ghana local scene x attention (multi-dish timer watch) x directional (head-turn dish selection). Three gates: scene (a cook on stew day with both hands busy at the fire); loop (pick a dish, nod to start its timer, hear the ready reminder, log the dish off); thickness (6 Ghanaian dishes with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn dish selection.

## Design contract

While the Ghanaian stew cooks, the cook with both hands busy looks at one dish, nods to start its timer, and is told when it is ready.

## Counts

6 Ghanaian dishes with suggested seconds: Groundnut Stew 1800, Light Soup 1200, Palm Nut Soup 1500, Jollof Rice 1500, Waakye 2400, Banku 900.

## Storage

Storage key `ghanaStewWatchV1` (timers per dish, off-the-fire records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with fire heat and dish size.
- Tapping before time only tells the time left; no record is written.
- Each dish reminds only once when its time is up; the off record is written only by confirming after time.
- Without a sensor, buttons change the dish; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
