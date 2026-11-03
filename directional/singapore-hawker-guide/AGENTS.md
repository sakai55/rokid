# Singapore Hawker Guide - Agent Notes

DI57. Singapore local scene x curb-cut x attention x directional.

## Design contract

A Singapore hawker centre diner with both hands on a tray picks a stall by head direction and nods through queue, order, collect, and tray return, then records one finished visit.

## Counts

Content set: 6 stalls, 4 steps per stall, 2 groups of 3. Finished visits are counted by their real number. Cross-session storage key `singaporeHawkerGuideV1` (picked stall, group, steps per stall, visit records array, lastError).

## Storage

Storage key `singaporeHawkerGuideV1`.

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (the main button on each page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change the selection |
| Nod (head steady) | onHeadGesture nod | Same as main confirm |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- Stall information is a built-in example. Check the stall sign on site for the real queue and price.
- This agent claims no live queue time or price.
- A visit is recorded only when all 4 steps are confirmed; partial steps never count as a visit.
- Direction here is head direction, not GPS location; no location permission is declared.

## Validation

- Language purity: no CJK characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits.
- Guide wiring: pages/guide _startSensor with a typeof guard, primaryTap calls confirmTap, record written only at 4 of 4 under singaporeHawkerGuideV1.
