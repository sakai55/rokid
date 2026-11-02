# Irish Dance Steps - Agent Notes

GA53. Ireland local scene x game x directional.

## Design contract

An Irish ceilidh dancer picks one of four steps by turning the head and dances it with a nod, for 10 rounds, then settles the score.

## Counts

Content set: 4 steps, 10 rounds per game. Settled games are counted by their real number; the best score is kept across sessions.

## Storage

Storage key `irelandDanceStepV1` (selected step, best score, settled-game records array, lastError).

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (play on the index page, dance on the play page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change step |
| Nod (head steady) | onHeadGesture nod | Same as main confirm: dance the step |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- Head turns past the 0.35 yaw threshold change the step only after re-centring; without a sensor the buttons change the step.
- A miss is counted as a miss and the game settles only after 10 rounds.
- The best score is the real best of settled games, never a claimed score.

## Validation

- Language purity: no CJK characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits.
- Head wiring: pages/play _startSensor with a typeof guard, danceTap settles at 10 rounds, best score persists under irelandDanceStepV1.
