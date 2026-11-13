# UK Pancake Watch - Agent Notes

WA29. United Kingdom local scene x attention (multi-pan pancake timer watch) x directional (head-turn pan selection). Three gates: scene (a cook on Pancake Day with both hands busy at the hob); loop (pick a pan, nod to start its timer, hear the ready reminder, log the pan out); thickness (6 pancake batches with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn pan selection.

## Design contract

While the Shrove Tuesday pancakes cook, the cook with both hands busy looks at one pan, nods to start its timer, and is told when it is ready.

## Counts

6 pancake batches with suggested seconds: Classic Pancake 180, Lemon & Sugar 150, Banana 240, Blueberry 210, Chocolate Chip 200, Buttermilk 240.

## Storage

Storage key `ukPancakeWatchV1` (timers per pan, pan-out records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with pan heat and batter thickness.
- Tapping before time only tells the time left; no record is written.
- Each pan reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the pan; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
