# Singapore Hawker Watch - Agent Notes

WA48. Singapore local scene x attention (multi-dish hawker timer watch) x directional (head-turn dish selection).

## Design contract

While hawker dishes cook at home in Singapore, the cook with both hands busy on hot woks looks at one dish, nods to start its timer, and is told when it is ready.

## Counts

6 hawker dishes with family timer presets (seconds): Roti Prata 240, Oyster Omelette 300, Hokkien Mee 420, Bak Chor Mee 360, Carrot Cake 300, Nasi Lemak 900. All six verified as real Singapore hawker dishes by web search on 2026-11-27; none repeats a stall name from directional/singapore-hawker-guide (Chicken Rice, Laksa, Char Kway Teow, Hainanese Curry, Satay, Sugar Cane Juice) or from singapore-laksa-watch (Laksa).

## Storage

Storage key `singaporeHawkerWatchV1` (timers per dish, dish-out records, selected dish, lastError).

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Seconds are family timer presets, not measured doneness: the agent reminds by time only.
- Tapping before time only tells the time left; no record is written.
- Each dish reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the dish; timing itself does not depend on the sensor.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Exclusive wiring: pages/watch/index.ink _startSensor + _onYaw + nod to start the timer; watch onLoad reads stored selected dish as the initial position.
