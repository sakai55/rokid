# Scotland Shortbread Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-scotland-shortbread-watch
```

[scotland-shortbread-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/scotland-shortbread-watch.aix)

## Features

While the Scottish shortbread bakes, the baker with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none overbaked.

## Scene

While the Scottish shortbread bakes, the baker with both hands busy looks at one tray, nods to start its timer, and is told when it is ready.

## Direction composition

Scotland local scene x attention (multi-tray shortbread timer watch) x directional (head-turn tray selection).

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands on the bake, the baker cannot take out a phone; looking at a tray selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial tray.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 trays with suggested seconds |
| pages/watch | Head-turn tray switch, nod to start timer, ready reminder |
| pages/record | Tray-out records |

## Content set

6 trays with suggested seconds: Classic Shortbread 1500, Petticoat Tails 1200, Fingers 900, Rounds 1080, Millionaire's 1800, Ginger Shortbread 1320.

## Cross-session storage

Storage key `scotlandShortbreadWatchV1` (timers per tray, tray-out records, lastError).

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

- Tapping before time only tells the time left; no record is written.
- Each tray reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the tray; timing itself does not depend on the sensor.

## Preview screenshots

![preview-scotland-shortbread-watch-index.png](../screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-index.png)
![preview-scotland-shortbread-watch-watch.png](../screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-watch.png)
![preview-scotland-shortbread-watch-watch-s2.png](../screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-watch-s2.png)
![preview-scotland-shortbread-watch-record.png](../screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-record.png)

## Review Submission

### Feature Description

While the Scottish shortbread bakes, the baker with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none overbaked.

### Opening Message

While the Scottish shortbread bakes, the baker with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none overbaked.

### Preview Media

[preview-scotland-shortbread-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-video.mp4)
![preview-scotland-shortbread-watch-index.png](../screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-index.png)
![preview-scotland-shortbread-watch-watch.png](../screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-watch.png)
![preview-scotland-shortbread-watch-watch-s2.png](../screenshots/scotland-shortbread-watch/preview-scotland-shortbread-watch-watch-s2.png)

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
