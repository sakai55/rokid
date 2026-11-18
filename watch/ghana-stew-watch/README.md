# Ghana Stew Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-ghana-stew-watch
```

[ghana-stew-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ghana-stew-watch.aix)

## Features

While the Ghanaian stew cooks, the cook with both hands busy looks at one dish, nods to start its timer, and is told when it is ready - several dishes, none burnt.

## Scene

While the Ghanaian stew cooks, the cook with both hands busy looks at one dish, nods to start its timer, and is told when it is ready.

## Direction composition

Ghana local scene x attention (multi-dish timer watch) x directional (head-turn dish selection). Three gates: scene (a cook on stew day with both hands busy at the fire); loop (pick a dish, nod to start its timer, hear the ready reminder, log the dish off); thickness (6 Ghanaian dishes with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn dish selection.

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands busy, the cook cannot take out a phone; looking at a dish selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial dish.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 Ghanaian dishes with suggested seconds |
| pages/watch | Head-turn dish switch, nod to start timer, ready reminder |
| pages/record | Off-the-fire records |

## Content set

6 Ghanaian dishes with suggested seconds: Groundnut Stew 1800, Light Soup 1200, Palm Nut Soup 1500, Jollof Rice 1500, Waakye 2400, Banku 900.

## Cross-session storage

Storage key `ghanaStewWatchV1` (timers per dish, off-the-fire records, lastError).

## Permissions

No declared permissions. Speech is host-managed and needs no declaration.

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Error codes

- `E5001` Storage write failed
- `E5002` Storage read failed
- `E3005` Speech failed
- `E8001` Navigation failed
- `E7001` Head sensor unavailable or read failed

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with fire heat and dish size.
- Tapping before time only tells the time left; no record is written.
- Each dish reminds only once when its time is up; the off record is written only by confirming after time.
- Without a sensor, buttons change the dish; timing itself does not depend on the sensor.

## Preview screenshots

![preview-ghana-stew-watch-index.png](../../screenshots/ghana-stew-watch/preview-ghana-stew-watch-index.png)
![preview-ghana-stew-watch-watch.png](../../screenshots/ghana-stew-watch/preview-ghana-stew-watch-watch.png)
![preview-ghana-stew-watch-watch-s2.png](../../screenshots/ghana-stew-watch/preview-ghana-stew-watch-watch-s2.png)
![preview-ghana-stew-watch-record.png](../../screenshots/ghana-stew-watch/preview-ghana-stew-watch-record.png)

## Review Submission

### Feature Description

While the Ghanaian stew cooks, the cook with both hands busy looks at one dish, nods to start its timer, and is told when it is ready - several dishes, none burnt.

### Opening Message

While the Ghanaian stew cooks, the cook with both hands busy looks at one dish, nods to start its timer, and is told when it is ready - several dishes, none burnt.

### Preview Media

[preview-ghana-stew-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ghana-stew-watch/preview-ghana-stew-watch-video.mp4)
![preview-ghana-stew-watch-index.png](../../screenshots/ghana-stew-watch/preview-ghana-stew-watch-index.png)
![preview-ghana-stew-watch-watch.png](../../screenshots/ghana-stew-watch/preview-ghana-stew-watch-watch.png)
![preview-ghana-stew-watch-watch-s2.png](../../screenshots/ghana-stew-watch/preview-ghana-stew-watch-watch-s2.png)

### Change Log

- Features：First release features as above.
- Improvements：None.
- Fixes：None.

## Device test info

| Studio name | To be filled |
|---|---|
| Studio name | To be filled |
| Version / Build | To be filled |
| App Category | To be filled |
| Intent Description | To be filled |
| Agent ID | To be filled |
| Status | To be filled |
