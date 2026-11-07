# Canada Maple Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-canada-maple-watch
```

[canada-maple-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/canada-maple-watch.aix)

## Features

While Canadian maple syrup boils, the maker with both hands busy looks at one pot, nods to start its timer, and is told when it is ready - several pots, none burnt.

## Scene

While Canadian maple syrup boils, the maker with both hands busy looks at one pot, nods to start its timer, and is told when it is ready.

## Direction composition

Canada local scene x attention (multi-pot timer watch) x directional (head-turn pot selection).

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands on the syrup, the maker cannot take out a phone; looking at a pot selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial pot.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 pots with suggested seconds |
| pages/watch | Head-turn pot switch, nod to start timer, ready reminder |
| pages/record | Syrup-out records |

## Content set

6 pots with suggested seconds: Light Syrup 2400, Medium Syrup 3000, Amber Syrup 3600, Dark Syrup 4200, Golden Syrup 1800, Maple Candy 1500.

## Cross-session storage

Storage key `canadaMapleWatchV1` (timers per pot, syrup-out records, lastError).

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

![preview-canada-maple-watch-index.png](../../screenshots/canada-maple-watch/preview-canada-maple-watch-index.png)
![preview-canada-maple-watch-watch.png](../../screenshots/canada-maple-watch/preview-canada-maple-watch-watch.png)
![preview-canada-maple-watch-watch-s2.png](../../screenshots/canada-maple-watch/preview-canada-maple-watch-watch-s2.png)
![preview-canada-maple-watch-record.png](../../screenshots/canada-maple-watch/preview-canada-maple-watch-record.png)

## Review Submission

### Feature Description

While Canadian maple syrup boils, the maker with both hands busy looks at one pot, nods to start its timer, and is told when it is ready - several pots, none burnt.

### Opening Message

While Canadian maple syrup boils, the maker with both hands busy looks at one pot, nods to start its timer, and is told when it is ready - several pots, none burnt.

### Preview Media

[preview-canada-maple-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/canada-maple-watch/preview-canada-maple-watch-video.mp4)
![preview-canada-maple-watch-index.png](../../screenshots/canada-maple-watch/preview-canada-maple-watch-index.png)
![preview-canada-maple-watch-watch.png](../../screenshots/canada-maple-watch/preview-canada-maple-watch-watch.png)
![preview-canada-maple-watch-watch-s2.png](../../screenshots/canada-maple-watch/preview-canada-maple-watch-watch-s2.png)

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
