# Ireland Soda Bread Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-ireland-soda-bread-watch
```

[ireland-soda-bread-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ireland-soda-bread-watch.aix)

## Features

While soda bread bakes, the baker with flour on both hands looks at one loaf, nods to start its timer, and is told when it is ready - several loaves, none burnt.

## Scene

While soda bread bakes, the baker with flour on both hands looks at one loaf, nods to start its timer, and is told when it is ready.

## Direction composition

Ireland local scene x attention (multi-loaf soda bread timer watch) x directional (head-turn loaf selection). Three gates: scene (a baker on baking day with both hands covered in flour at the oven); loop (pick a loaf, nod to start its timer, hear the ready reminder, log the loaf out); thickness (6 loaves with suggested seconds + multi-step flow + cross-session records). Attention carries the timing watch; directional carries the head-turn loaf selection.

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands covered in flour, the baker cannot take out a phone; looking at a loaf selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial loaf.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 loaves with suggested seconds |
| pages/watch | Head-turn loaf switch, nod to start timer, ready reminder |
| pages/record | Loaf-out records |

## Content set

6 loaves with suggested seconds: Classic Soda Bread 1800, Brown Soda Bread 2100, Spotted Dog 1500, Treacle Bread 2400, Potato Farls 900, Soda Scones 1200.

## Cross-session storage

Storage key `irelandSodaBreadWatchV1` (timers per loaf, loaf-out records, lastError).

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

- This agent does not measure doneness; it only reminds by time. Seconds are a guide and vary with oven heat and loaf size.
- Tapping before time only tells the time left; no record is written.
- Each loaf reminds only once when its time is up; the out record is written only by confirming after time.
- Without a sensor, buttons change the loaf; timing itself does not depend on the sensor.

## Preview screenshots

![preview-ireland-soda-bread-watch-index.png](../../screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-index.png)
![preview-ireland-soda-bread-watch-watch.png](../../screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-watch.png)
![preview-ireland-soda-bread-watch-watch-s2.png](../../screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-watch-s2.png)
![preview-ireland-soda-bread-watch-record.png](../../screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-record.png)

## Review Submission

### Feature Description

While soda bread bakes, the baker with flour on both hands looks at one loaf, nods to start its timer, and is told when it is ready - several loaves, none burnt.

### Opening Message

While soda bread bakes, the baker with flour on both hands looks at one loaf, nods to start its timer, and is told when it is ready - several loaves, none burnt.

### Preview Media

[preview-ireland-soda-bread-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-video.mp4)
![preview-ireland-soda-bread-watch-index.png](../../screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-index.png)
![preview-ireland-soda-bread-watch-watch.png](../../screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-watch.png)
![preview-ireland-soda-bread-watch-watch-s2.png](../../screenshots/ireland-soda-bread-watch/preview-ireland-soda-bread-watch-watch-s2.png)

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
