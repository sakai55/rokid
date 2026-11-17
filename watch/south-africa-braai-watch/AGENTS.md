# South Africa Braai Watch - Agent Notes

WA37. South Africa local scene x attention (multi-item timer watch) x directional (head-turn item selection). Three gates: scene (a cook on braai day with both hands busy at the fire); loop (pick an item, nod to start its timer, hear the ready reminder, log the item off); thickness (6 braai items with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn item selection.

## Design contract

While the braai cooks, the cook with both hands busy looks at one braai item, nods to start its timer, and is told when it is ready.

## Counts

6 braai items with suggested seconds: Boerewors 900, Sosaties 720, Lamb Chops 600, Chicken Pieces 1500, Mielies 900, Snoek 600.

## Storage

Storage key `southAfricaBraaiWatchV1` (timers per item, off-the-fire records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with fire heat and item size.
- Tapping before time only tells the time left; no record is written.
- Each item reminds only once when its time is up; the off record is written only by confirming after time.
- Without a sensor, buttons change the item; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
