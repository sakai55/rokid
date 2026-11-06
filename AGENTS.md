# UK Roast Watch - Agent Notes

WA15. United Kingdom local scene x attention (multi-tray timer watch) x directional (head-turn tray selection).

## Design contract

On a British Sunday roast, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready.

## Counts

6 roasts with suggested seconds: Roast Beef 3600, Roast Lamb 2700, Roast Pork 3000, Roast Chicken 2400, Roast Potatoes 1800, Roast Vegetables 1200.

## Storage

Storage key `ukRoastWatchV1` (timers per roast, roast-out records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Tapping before time only tells the time left; no record is written.
- Each tray reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the tray; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer.
