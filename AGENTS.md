# NZ Haka Game - Agent Notes

GA94. New Zealand local scene x game x directional (head-turn element picking). Three gates: scene (a New Zealand family gathering, playing a haka game together on one pair of glasses); loop (start, head-pick a haka element, nod to perform it, 10 rounds, settle with a score); thickness (8 real haka elements + fixed 10-round sequence + best records across sessions). Game carries the play loop; directional carries the head-turn element picking.

## Design contract

At a family gathering in New Zealand, players use only head direction to pick a haka element and nod to perform it, settling the score over 10 rounds.

## Counts

8 real haka elements: Pukana wide eyes, Whetero tongue out, Wiri trembling hands, Waewae takahia foot stamp, Kaea leader call, Reo chant words, Peruperu high jump, Tutu ngarahu side jump. Each term web-verified as a real haka element on 2026-11-23. 10-round fixed target sequence [3, 6, 1, 7, 0, 4, 2, 5, 3, 6] written in code; it differs from the GA91 and GA93 sequences.

## Storage

Storage key `nzHakaGameV1` (best score, settled records, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Scores come only from real nods and taps; no score is invented.
- One head turn changes only one element; re-centre before changing again, never spin.
- The target sequence is fixed in code, not claimed random.
- Without a sensor, buttons pick an element; scoring stays the same. Sensor failure shows E7001.
- Performance judgement is demo judgement only, not physical recognition of the player's body.
- Haka elements are presented as a learning game only, with respect for Maori culture; this is not a claim of authentic haka teaching.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/play/index.ink _startSensor + _onYaw (re-centre re-arm) + nod to perform.
- 10-round fixed sequence written in code, settled by real hits.
