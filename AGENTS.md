# Ireland Games Shuu - Agent Notes

GA92. Ireland local scene x game x directional (head-turn direction games) x attention (best-score keeping). Three gates: scene (an Irish family gathering, playing together on one pair of glasses); loop (pick a game from the hub, play by head turn and nod, settle with a score, keep the best across sessions); thickness (20 Irish games with different mechanisms + multi-step flows + cross-session best records). Game carries the play loop; directional carries the head-turn direction games.

## Design contract

At an Irish family gathering, the whole family plays 20 Irish games on one pair of glasses, settling the score by head movement alone.

## Counts

20 tools: 19 games (counting 4, quiz 4, direction 4, steps 4, arithmetic 3) + 1 record tool. Counting targets 15/15/3/7, direction games 6 rounds each, steps games 5 steps each, arithmetic 3+4, 2+5, 9-4. Quiz answers are true Irish facts, web-verified 2026-11-22: Cliffs of Moher in County Clare, Aran sweaters from the Aran Islands, traditional Irish stew made with lamb, kissing the Blarney Stone gives the gift of eloquence.

## Storage

Storage key `irelandGamesShuuV1` (picked game, best per game, settled records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Scores come only from real nods and taps; no score is invented.
- Without a sensor, direction games use buttons to pick a zone and scoring stays the same; sensor failure shows E7001.
- The 20 game names were checked one by one against all existing hub titles, zero overlap.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: every game page nod triggers primaryTap, direction pages _startSensor; hit check uses ZONES.indexOf(target).
- 21 pages, .ink md5 all distinct, direction hit pages 4/4.
