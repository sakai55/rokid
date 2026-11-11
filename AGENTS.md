# US Turkey Watch - Agent Notes

WA25. United States local scene x attention (multi-tray roast timer watch) x directional (head-turn tray selection).

## Design contract

While the Thanksgiving turkey roasts, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready.

## Counts

6 trays with suggested seconds: Whole Turkey 10800, Turkey Breast 5400, Stuffing 1800, Roast Potatoes 2400, Brussels Sprouts 1200, Cranberry Sauce 900.

## Storage

Storage key `usTurkeyWatchV1` (timers per tray, tray-out records, lastError).

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
