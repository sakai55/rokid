# USA Turkey Watch - Agent Notes

WA31. United States local scene x attention (multi-dish Thanksgiving timer watch) x directional (head-turn dish selection). Three gates: scene (a cook on Thanksgiving with both hands busy at the stove); loop (pick a dish, nod to start its timer, hear the ready reminder, log the dish out); thickness (6 dishes with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn dish selection.

## Design contract

While the Thanksgiving turkey roasts, the cook with both hands busy looks at one dish, nods to start its timer, and is told when it is ready.

## Counts

6 dishes with suggested seconds: Roast Turkey 10800, Honey Ham 7200, Roast Chicken 5400, Sweet Potato Casserole 1800, Green Bean Casserole 1500, Pumpkin Pie 2400.

## Storage

Storage key `usaTurkeyWatchV1` (timers per dish, dish-out records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with oven heat and dish size.
- Tapping before time only tells the time left; no record is written.
- Each dish reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the dish; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
