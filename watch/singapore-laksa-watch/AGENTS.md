# Singapore Laksa Watch - Agent Notes

WA23. Singapore local scene x attention (multi-pot noodle timer watch) x directional (head-turn noodle selection).

## Design contract

While noodles cook at a Singapore hawker centre, the cook with both hands busy looks at one noodle, nods to start its timer, and is told when it is ready.

## Counts

6 noodles with suggested seconds: Laksa 600, Char Kway Teow 300, Hokkien Mee 420, Bak Chor Mee 360, Fish Head Curry 1800, Chicken Rice 1500.

## Storage

Storage key `singaporeLaksaWatchV1` (timers per noodle, noodle-out records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Tapping before time only tells the time left; no record is written.
- Each noodle reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the noodle; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer.
