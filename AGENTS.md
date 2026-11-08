# NZ Hangi Watch - Agent Notes

WA19. New Zealand local scene x attention (multi-pot timer watch) x directional (head-turn pot selection).

## Design contract

While a Maori hangi cooks underground, the cook with both hands busy looks at one hangi pot, nods to start its timer, and is told when it is ready.

## Counts

6 hangi dishes with suggested seconds: Pork 3600, Lamb 3000, Chicken 2400, Potato 1800, Kumara 1500, Cabbage 1200.

## Storage

Storage key `nzHangiWatchV1` (timers per pot, hangi-out records, lastError).

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
