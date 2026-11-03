# US Thanksgiving Games - Agent Notes

GA56. United States local scene x game x directional x attention.

## Design contract

A United States Thanksgiving family, waiting together before dinner, plays 20 Thanksgiving games on one pair of glasses, each settled with a score.

## Counts

Content set: 20 games. Counting targets: Turkey 10, Corn 12, Stuffing 8, Apple 9, Gravy 7, Turkey Trot Steps 20. Direction: 6 rounds each. Quiz: 3 or 4 questions each. Sequence: 5 steps each. Rhythm: 8 beats. Record: 6 thanks. Cross-session storage key `usThanksgivingGamesV1` (picked game, best per game, settled records array, lastError).

## Storage

Storage key `usThanksgivingGamesV1`.

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (the main button on each page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change the selection |
| Nod (head steady) | onHeadGesture nod | Same as main confirm |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- Scores are counted only from real taps and nods in the game; no score is invented.
- Direction games fall back to buttons when the head sensor is off, and sensor failure shows E7001.
- The hub shows a 5-game window around the picked game; Open navigates straight to that game page.

## Validation

- Language purity: no CJK characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: onHeadGesture nod to primaryTap on every game page; _startSensor on pages/g02 and pages/g12.
