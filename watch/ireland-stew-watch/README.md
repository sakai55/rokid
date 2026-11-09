# Ireland Stew Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-ireland-stew-watch
```

[ireland-stew-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ireland-stew-watch.aix)

## Features

While an Irish stew cooks, the cook with both hands busy looks at one stew pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

## Scene

While an Irish stew cooks, the cook with both hands busy looks at one stew pot, nods to start its timer, and is told when it is ready.

## Direction composition

Ireland local scene x attention (multi-pot timer watch) x directional (head-turn pot selection).

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands on the stew, the cook cannot take out a phone; looking at a pot selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial pot.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 stews with suggested seconds |
| pages/watch | Head-turn pot switch, nod to start timer, ready reminder |
| pages/record | Stew-out records |

## Content set

6 stews with suggested seconds: Irish Stew 3600, Beef Stew 3000, Lamb Stew 2700, Chicken Stew 2400, Vegetable Soup 1800, Seafood Chowder 1500.

## Cross-session storage

Storage key `irelandStewWatchV1` (timers per pot, stew-out records, lastError).

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

![preview-ireland-stew-watch-index.png](../../screenshots/ireland-stew-watch/preview-ireland-stew-watch-index.png)
![preview-ireland-stew-watch-watch.png](../../screenshots/ireland-stew-watch/preview-ireland-stew-watch-watch.png)
![preview-ireland-stew-watch-watch-s2.png](../../screenshots/ireland-stew-watch/preview-ireland-stew-watch-watch-s2.png)
![preview-ireland-stew-watch-record.png](../../screenshots/ireland-stew-watch/preview-ireland-stew-watch-record.png)

## Review Submission

### Feature Description

While an Irish stew cooks, the cook with both hands busy looks at one stew pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

### Opening Message

While an Irish stew cooks, the cook with both hands busy looks at one stew pot, nods to start its timer, and is told when it is ready - several pots, none overcooked.

### Preview Media

[preview-ireland-stew-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ireland-stew-watch/preview-ireland-stew-watch-video.mp4)
![preview-ireland-stew-watch-index.png](../../screenshots/ireland-stew-watch/preview-ireland-stew-watch-index.png)
![preview-ireland-stew-watch-watch.png](../../screenshots/ireland-stew-watch/preview-ireland-stew-watch-watch.png)
![preview-ireland-stew-watch-watch-s2.png](../../screenshots/ireland-stew-watch/preview-ireland-stew-watch-watch-s2.png)

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
