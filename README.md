# NZ Hangi Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-nz-hangi-watch
```

[nz-hangi-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nz-hangi-watch.aix)

## Features

While a Maori hangi cooks underground, the cook with both hands busy looks at one hangi pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

## Scene

While a Maori hangi cooks underground, the cook with both hands busy looks at one hangi pot, nods to start its timer, and is told when it is ready.

## Direction composition

New Zealand local scene x attention (multi-pot timer watch) x directional (head-turn pot selection).

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands on the hangi, the cook cannot take out a phone; looking at a pot selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial pot.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 hangi dishes with suggested seconds |
| pages/watch | Head-turn pot switch, nod to start timer, ready reminder |
| pages/record | Hangi-out records |

## Content set

6 hangi dishes with suggested seconds: Pork 3600, Lamb 3000, Chicken 2400, Potato 1800, Kumara 1500, Cabbage 1200.

## Cross-session storage

Storage key `nzHangiWatchV1` (timers per pot, hangi-out records, lastError).

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
- Each pot reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the pot; timing itself does not depend on the sensor.

## Preview screenshots

![preview-nz-hangi-watch-index.png](../screenshots/nz-hangi-watch/preview-nz-hangi-watch-index.png)
![preview-nz-hangi-watch-watch.png](../screenshots/nz-hangi-watch/preview-nz-hangi-watch-watch.png)
![preview-nz-hangi-watch-watch-s2.png](../screenshots/nz-hangi-watch/preview-nz-hangi-watch-watch-s2.png)
![preview-nz-hangi-watch-record.png](../screenshots/nz-hangi-watch/preview-nz-hangi-watch-record.png)

## Review Submission

### Feature Description

While a Maori hangi cooks underground, the cook with both hands busy looks at one hangi pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

### Opening Message

While a Maori hangi cooks underground, the cook with both hands busy looks at one hangi pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

### Preview Media

[preview-nz-hangi-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/nz-hangi-watch/preview-nz-hangi-watch-video.mp4)
![preview-nz-hangi-watch-index.png](../screenshots/nz-hangi-watch/preview-nz-hangi-watch-index.png)
![preview-nz-hangi-watch-watch.png](../screenshots/nz-hangi-watch/preview-nz-hangi-watch-watch.png)
![preview-nz-hangi-watch-watch-s2.png](../screenshots/nz-hangi-watch/preview-nz-hangi-watch-watch-s2.png)

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
