# Fiji Lovo Watch - Agent Notes

WA43. Fiji local scene x attention (multi-dish timer watch) x directional (head-turn dish selection). Three gates: scene (a family on lovo day with both hands busy at the earth oven); loop (pick a dish, nod to start its timer, hear the ready reminder, log the dish out); thickness (6 lovo dishes with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn dish selection.

## Design contract

While the Fijian lovo cooks, the family with both hands busy with hot stones and leaves looks at one dish, nods to start its timer, and is told when it is ready.

## Counts

6 lovo dishes with suggested seconds: Palusami 3600, Kokoda 1800, Lovo pork 5400, Lovo chicken 4800, Taro 3600, Cassava 3000.

## Storage

Storage key `fijiLovoWatchV1` (timers per dish, out-of-the-pit records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with the stones and pit size.
- Kokoda marinates rather than cooking in the pit; its timer is a marinating guide.
- Tapping before time only tells the time left; no record is written.
- Each dish reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the dish; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected.
