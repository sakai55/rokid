# India Curry Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-india-curry-watch
```

[india-curry-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/india-curry-watch.aix)

## Features

While the Indian curry cooks, the cook with both hands busy looks at one pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

## Scene

While the Indian curry cooks, the cook with both hands busy looks at one pot, nods to start its timer, and is told when it is ready.

## Direction composition

India local scene x attention (multi-pot timer watch) x directional (head-turn pot selection). Three gates: scene (a cook on curry day with both hands busy at the stove); loop (pick a curry, nod to start its timer, hear the ready reminder, log the pot off); thickness (6 Indian curries with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn pot selection.

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands busy, the cook cannot take out a phone; looking at a pot selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial pot.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 Indian curries with suggested seconds |
| pages/watch | Head-turn pot switch, nod to start timer, ready reminder |
| pages/record | Off-the-fire records |

## Content set

6 Indian curries with suggested seconds: Butter Chicken 1500, Palak Paneer 1200, Chana Masala 1800, Rogan Josh 2100, Dal Tadka 900, Biryani 2400.

## Cross-session storage

Storage key `indiaCurryWatchV1` (timers per curry, off-the-fire records, lastError).

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

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with heat and pot size.
- Tapping before time only tells the time left; no record is written.
- Each curry reminds only once when its time is up; the off record is written only by confirming after time.
- Without a sensor, buttons change the curry; timing itself does not depend on the sensor.

## Preview screenshots

![preview-india-curry-watch-index.png](../screenshots/india-curry-watch/preview-india-curry-watch-index.png)
![preview-india-curry-watch-watch.png](../screenshots/india-curry-watch/preview-india-curry-watch-watch.png)
![preview-india-curry-watch-watch-s2.png](../screenshots/india-curry-watch/preview-india-curry-watch-watch-s2.png)
![preview-india-curry-watch-record.png](../screenshots/india-curry-watch/preview-india-curry-watch-record.png)

## Review Submission

### Feature Description

While the Indian curry cooks, the cook with both hands busy looks at one pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

### Opening Message

While the Indian curry cooks, the cook with both hands busy looks at one pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

### Preview Media

[preview-india-curry-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/india-curry-watch/preview-india-curry-watch-video.mp4)
![preview-india-curry-watch-index.png](../screenshots/india-curry-watch/preview-india-curry-watch-index.png)
![preview-india-curry-watch-watch.png](../screenshots/india-curry-watch/preview-india-curry-watch-watch.png)
![preview-india-curry-watch-watch-s2.png](../screenshots/india-curry-watch/preview-india-curry-watch-watch-s2.png)

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
