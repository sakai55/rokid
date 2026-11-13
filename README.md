# UK Pancake Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-uk-pancake-watch
```

[uk-pancake-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/uk-pancake-watch.aix)

## Features

While the Shrove Tuesday pancakes cook, the cook with both hands busy looks at one pan, nods to start its timer, and is told when it is ready - several pans, none burnt.

## Scene

While the Shrove Tuesday pancakes cook, the cook with both hands busy looks at one pan, nods to start its timer, and is told when it is ready.

## Direction composition

United Kingdom local scene x attention (multi-pan pancake timer watch) x directional (head-turn pan selection). Three gates: scene (a cook on Pancake Day with both hands busy at the hob); loop (pick a pan, nod to start its timer, hear the ready reminder, log the pan out); thickness (6 pancake batches with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn pan selection.

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands on the cook, the cook cannot take out a phone; looking at a pan selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial pan.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 pancake batches with suggested seconds |
| pages/watch | Head-turn pan switch, nod to start timer, ready reminder |
| pages/record | Pan-out records |

## Content set

6 pancake batches with suggested seconds: Classic Pancake 180, Lemon & Sugar 150, Banana 240, Blueberry 210, Chocolate Chip 200, Buttermilk 240.

## Cross-session storage

Storage key `ukPancakeWatchV1` (timers per pan, pan-out records, lastError).

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

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with pan heat and batter thickness.
- Tapping before time only tells the time left; no record is written.
- Each pan reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the pan; timing itself does not depend on the sensor.

## Preview screenshots

![preview-uk-pancake-watch-index.png](../screenshots/uk-pancake-watch/preview-uk-pancake-watch-index.png)
![preview-uk-pancake-watch-watch.png](../screenshots/uk-pancake-watch/preview-uk-pancake-watch-watch.png)
![preview-uk-pancake-watch-watch-s2.png](../screenshots/uk-pancake-watch/preview-uk-pancake-watch-watch-s2.png)
![preview-uk-pancake-watch-record.png](../screenshots/uk-pancake-watch/preview-uk-pancake-watch-record.png)

## Review Submission

### Feature Description

While the Shrove Tuesday pancakes cook, the cook with both hands busy looks at one pan, nods to start its timer, and is told when it is ready - several pans, none burnt.

### Opening Message

While the Shrove Tuesday pancakes cook, the cook with both hands busy looks at one pan, nods to start its timer, and is told when it is ready - several pans, none burnt.

### Preview Media

[preview-uk-pancake-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/uk-pancake-watch/preview-uk-pancake-watch-video.mp4)
![preview-uk-pancake-watch-index.png](../screenshots/uk-pancake-watch/preview-uk-pancake-watch-index.png)
![preview-uk-pancake-watch-watch.png](../screenshots/uk-pancake-watch/preview-uk-pancake-watch-watch.png)
![preview-uk-pancake-watch-watch-s2.png](../screenshots/uk-pancake-watch/preview-uk-pancake-watch-watch-s2.png)

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
