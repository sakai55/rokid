# US Turkey Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-us-turkey-watch
```

[us-turkey-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/us-turkey-watch.aix)

## Features

While the Thanksgiving turkey roasts, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none overcooked.

## Scene

While the Thanksgiving turkey roasts, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready.

## Direction composition

United States local scene x attention (multi-tray roast timer watch) x directional (head-turn tray selection).

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands on the roast, the cook cannot take out a phone; looking at a tray selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial tray.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 trays with suggested seconds |
| pages/watch | Head-turn tray switch, nod to start timer, ready reminder |
| pages/record | Tray-out records |

## Content set

6 trays with suggested seconds: Whole Turkey 10800, Turkey Breast 5400, Stuffing 1800, Roast Potatoes 2400, Brussels Sprouts 1200, Cranberry Sauce 900.

## Cross-session storage

Storage key `usTurkeyWatchV1` (timers per tray, tray-out records, lastError).

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

![preview-us-turkey-watch-index.png](../screenshots/us-turkey-watch/preview-us-turkey-watch-index.png)
![preview-us-turkey-watch-watch.png](../screenshots/us-turkey-watch/preview-us-turkey-watch-watch.png)
![preview-us-turkey-watch-watch-s2.png](../screenshots/us-turkey-watch/preview-us-turkey-watch-watch-s2.png)
![preview-us-turkey-watch-record.png](../screenshots/us-turkey-watch/preview-us-turkey-watch-record.png)

## Review Submission

### Feature Description

While the Thanksgiving turkey roasts, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none overcooked.

### Opening Message

While the Thanksgiving turkey roasts, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none overcooked.

### Preview Media

[preview-us-turkey-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/us-turkey-watch/preview-us-turkey-watch-video.mp4)
![preview-us-turkey-watch-index.png](../screenshots/us-turkey-watch/preview-us-turkey-watch-index.png)
![preview-us-turkey-watch-watch.png](../screenshots/us-turkey-watch/preview-us-turkey-watch-watch.png)
![preview-us-turkey-watch-watch-s2.png](../screenshots/us-turkey-watch/preview-us-turkey-watch-watch-s2.png)

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
