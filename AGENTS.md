# Aussie BBQ Watch - Agent Notes

WA09. Australia local scene x attention x directional.

## Design contract

An Australian Christmas barbecue cook with both hands on the tongs looks at a grill slot, nods to start its timer, hears when it is done, and records the finished item.

## Counts

Content set: 6 grill items, 3 timer slots. Finished items are counted by their real number. Cross-session storage key `aussieBbqWatchV1` (picked item, 3 slot timers, finished records array, lastError).

## Storage

Storage key `aussieBbqWatchV1`.

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (the main button on each page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change the selection |
| Nod (head steady) | onHeadGesture nod | Same as main confirm |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- A timer is only done when its minutes have passed; Finish before that speaks the remaining time and records nothing.
- The done alert speaks once per timer; the record is written only by Finish on a done timer.
- Without a sensor the buttons switch slots; the timer itself never depends on the sensor.

## Validation

- Language purity: no CJK characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits.
- Watch wiring: pages/watch _startSensor with a typeof guard, primaryTap starts or finishes, finishTap records under aussieBbqWatchV1.
