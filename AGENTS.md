# Ireland Stew Watch - Agent Notes

WA21. Ireland local scene x attention (multi-pot timer watch) x directional (head-turn pot selection).

## Design contract

While an Irish stew cooks, the cook with both hands busy looks at one stew pot, nods to start its timer, and is told when it is ready.

## Counts

6 stews with suggested seconds: Irish Stew 3600, Beef Stew 3000, Lamb Stew 2700, Chicken Stew 2400, Vegetable Soup 1800, Seafood Chowder 1500.

## Storage

Storage key `irelandStewWatchV1` (timers per pot, stew-out records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Tapping before time only tells the time left; no record is written.
- Each pot reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the pot; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer.
