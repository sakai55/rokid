# County Fair Games — Agent Notes

GA51. United States locality × Games × Directional (head direction). Heavy hub: hub + 20 game pages.

## Design contract

One-sentence scene: at a US county fair, a family waiting between events plays 20 fair games on one pair of glasses.

## Counts

Content set: 20 games (mechanisms interleaved: count 3, direction / aim 4, pick 3, rhythm 1, step count 1, lift count 1, timing 1, order 2, quiz / guess / calculation 4); quiz pages hold 3 questions each, pick pages 3 rounds each, direction pages 3–4 rounds each, order page 4 items and 4 steps. Cross-session persistence key `usFairGamesV1` (selected game, per-game records array `records`, lastError).

## Storage

Storage key `usFairGamesV1`.

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (open game / count / answer / lock pick) |
| Swipe up / down | ArrowUp / ArrowDown | Move choice or zone (key fallback for head direction) |
| Nod (head steady) | `onHeadGesture('nod')` | Same as main confirm |
| Double tap | Backspace | Back (game pages); hub top speaks its name |

## Head-direction rules

- Direct-zone pages: head yaw below -0.35 = left, above 0.35 = right, else center; after each confirm the player must return the head to center before the next confirm counts (recenter gate).
- Edge-step pages: each head turn from center moves the choice by exactly one step; the head must return to center before the next step (segmented moves, never spinning).
- Sensor missing or erroring falls back to keys and reports bare code E7001.
