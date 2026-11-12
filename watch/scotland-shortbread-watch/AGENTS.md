# Scotland Shortbread Watch - Agent Notes

WA27. Scotland local scene x attention (multi-tray shortbread timer watch) x directional (head-turn tray selection).

## Design contract

While the Scottish shortbread bakes, the baker with both hands busy looks at one tray, nods to start its timer, and is told when it is ready.

## Counts

6 trays with suggested seconds: Classic Shortbread 1500, Petticoat Tails 1200, Fingers 900, Rounds 1080, Millionaire's 1800, Ginger Shortbread 1320.

## Storage

Storage key `scotlandShortbreadWatchV1` (timers per tray, tray-out records, lastError).

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
