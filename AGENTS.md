# Canada Maple Watch - Agent Notes

WA17. Canada local scene x attention (multi-pot timer watch) x directional (head-turn pot selection).

## Design contract

While Canadian maple syrup boils, the maker with both hands busy looks at one pot, nods to start its timer, and is told when it is ready.

## Counts

6 pots with suggested seconds: Light Syrup 2400, Medium Syrup 3000, Amber Syrup 3600, Dark Syrup 4200, Golden Syrup 1800, Maple Candy 1500.

## Storage

Storage key `canadaMapleWatchV1` (timers per pot, syrup-out records, lastError).

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
