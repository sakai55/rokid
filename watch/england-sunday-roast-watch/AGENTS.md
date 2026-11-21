# England Sunday Roast Watch - Agent Notes

WA45. England local scene x attention (multi-dish timer watch) x directional (head-turn dish selection). Three gates: scene (an English family on Sunday roast day with both hands busy at the oven); loop (pick a dish, nod to start its timer, hear the ready reminder, log the dish out); thickness (6 roast dishes with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn dish selection.

## Design contract

While the English Sunday roast cooks, the family with both hands busy with hot trays looks at one dish, nods to start its timer, and is told when it is ready.

## Counts

6 roast dishes with suggested seconds (presets, see README): Roast Beef 3600, Roast Chicken 4800, Roast Potatoes 2700, Yorkshire Pudding 1200, Carrots 1500, Cauliflower Cheese 1800.

## Storage

Storage key `englandSundayRoastWatchV1` (timers per dish, out-of-the-oven records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are presets and vary with oven heat and dish size.
- Tapping before time only tells the time left; no record is written.
- Each dish reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the dish; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
