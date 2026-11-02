# NZ Hut Cook Watch - Agent Notes

WA07. New Zealand local scene x attention x directional.

## Design contract

A New Zealand tramping-hut cook with both hands busy looks at a cooker slot, nods to start its timer, hears when it is done, and records the finished dish.

## Counts

Content set: 6 cooker and dish sets, 3 timer slots. Finished dishes are counted by their real number.

## Storage

Storage key `nzHutCookWatchV1` (selected cooker, 3 slot timers with dish name, minutes and start time, finished-dish records array, lastError).

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (watch on the index page, start or finish on the watch page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change cooker or slot |
| Nod (head steady) | onHeadGesture nod | Same as main confirm |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- A timer is only done when its minutes have passed; Finish before that speaks the remaining time and records nothing.
- The done alert speaks once per timer; the record is written only by Finish on a done timer.
- Without a sensor the buttons switch slots; the timer itself never depends on the sensor.

## Validation

- Language purity: no CJK characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits.
- Watch wiring: pages/watch _startSensor with a typeof guard, primaryTap starts or finishes, finishTap records under nzHutCookWatchV1.
