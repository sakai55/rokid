# NZ Roast Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-nz-roast-watch
```

[nz-roast-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nz-roast-watch.aix)

## Features

While roast meat cooks, the cook with both hands busy looks at one roast, nods to start its timer, and is told when it is ready - several roasts, none burnt.

## Scene

While roast meat cooks, the cook with both hands busy looks at one roast, nods to start its timer, and is told when it is ready.

## Direction composition

New Zealand local scene x attention (multi-roast timer watch) x directional (head-turn roast selection). Three gates: scene (a cook on roast day with both hands busy at the oven); loop (pick a roast, nod to start its timer, hear the ready reminder, log the roast out); thickness (6 roasts with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn roast selection.

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands busy, the cook cannot take out a phone; looking at a roast selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial roast.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 roasts with suggested seconds |
| pages/watch | Head-turn roast switch, nod to start timer, ready reminder |
| pages/record | Roast-out records |

## Content set

6 roasts with suggested seconds: Roast Lamb 5400, Roast Beef 4800, Roast Pork 6000, Roast Chicken 5400, Roast Kumara 3600, Roast Pumpkin 2700.

## Cross-session storage

Storage key `nzRoastWatchV1` (timers per roast, roast-out records, lastError).

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

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with oven heat and roast size.
- Tapping before time only tells the time left; no record is written.
- Each roast reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the roast; timing itself does not depend on the sensor.

## Preview screenshots

![preview-nz-roast-watch-index.png](../screenshots/nz-roast-watch/preview-nz-roast-watch-index.png)
![preview-nz-roast-watch-watch.png](../screenshots/nz-roast-watch/preview-nz-roast-watch-watch.png)
![preview-nz-roast-watch-watch-s2.png](../screenshots/nz-roast-watch/preview-nz-roast-watch-watch-s2.png)
![preview-nz-roast-watch-record.png](../screenshots/nz-roast-watch/preview-nz-roast-watch-record.png)

## Review Submission

### Feature Description

While roast meat cooks, the cook with both hands busy looks at one roast, nods to start its timer, and is told when it is ready - several roasts, none burnt.

### Opening Message

While roast meat cooks, the cook with both hands busy looks at one roast, nods to start its timer, and is told when it is ready - several roasts, none burnt.

### Preview Media

[preview-nz-roast-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/nz-roast-watch/preview-nz-roast-watch-video.mp4)
![preview-nz-roast-watch-index.png](../screenshots/nz-roast-watch/preview-nz-roast-watch-index.png)
![preview-nz-roast-watch-watch.png](../screenshots/nz-roast-watch/preview-nz-roast-watch-watch.png)
![preview-nz-roast-watch-watch-s2.png](../screenshots/nz-roast-watch/preview-nz-roast-watch-watch-s2.png)

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
