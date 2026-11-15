# Ireland Soda Bread Watch - Agent Notes

WA33. Ireland local scene x attention (multi-loaf soda bread timer watch) x directional (head-turn loaf selection). Three gates: scene (a baker on baking day with both hands covered in flour at the oven); loop (pick a loaf, nod to start its timer, hear the ready reminder, log the loaf out); thickness (6 loaves with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn loaf selection.

## Design contract

While soda bread bakes, the baker with flour on both hands looks at one loaf, nods to start its timer, and is told when it is ready.

## Counts

6 loaves with suggested seconds: Classic Soda Bread 1800, Brown Soda Bread 2100, Spotted Dog 1500, Treacle Bread 2400, Potato Farls 900, Soda Scones 1200.

## Storage

Storage key `irelandSodaBreadWatchV1` (timers per loaf, loaf-out records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with oven heat and loaf size.
- Tapping before time only tells the time left; no record is written.
- Each loaf reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the loaf; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
