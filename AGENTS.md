# NZ Roast Watch - Agent Notes

WA35. New Zealand local scene x attention (multi-roast timer watch) x directional (head-turn roast selection). Three gates: scene (a cook on roast day with both hands busy at the oven); loop (pick a roast, nod to start its timer, hear the ready reminder, log the roast out); thickness (6 roasts with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn roast selection.

## Design contract

While roast meat cooks, the cook with both hands busy looks at one roast, nods to start its timer, and is told when it is ready.

## Counts

6 roasts with suggested seconds: Roast Lamb 5400, Roast Beef 4800, Roast Pork 6000, Roast Chicken 5400, Roast Kumara 3600, Roast Pumpkin 2700.

## Storage

Storage key `nzRoastWatchV1` (timers per roast, roast-out records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with oven heat and roast size.
- Tapping before time only tells the time left; no record is written.
- Each roast reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the roast; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
