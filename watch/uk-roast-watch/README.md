# UK Roast Watch

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-uk-roast-watch
```

[uk-roast-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/uk-roast-watch.aix)

## Features

On a British Sunday roast, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none burnt.

## Scene

On a British Sunday roast, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready.

## Direction composition

United Kingdom local scene x attention (multi-tray timer watch) x directional (head-turn tray selection).

## Glasses-only capability

Head-direction coordination + nod to start a timer while hands are busy: with both hands on the roast, the cook cannot take out a phone; looking at a tray selects it and a nod starts its timer. Wiring: pages/watch/index.ink _startSensor + _onYaw + onHeadGesture nod to primaryTap to start the timer. The watch page onLoad reads stored selected to set the initial tray.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 roasts with suggested seconds |
| pages/watch | Head-turn tray switch, nod to start timer, ready reminder |
| pages/record | Roast-out records |

## Content set

6 roasts with suggested seconds: Roast Beef 3600, Roast Lamb 2700, Roast Pork 3000, Roast Chicken 2400, Roast Potatoes 1800, Roast Vegetables 1200.

## Cross-session storage

Storage key `ukRoastWatchV1` (timers per roast, roast-out records, lastError).

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

![preview-uk-roast-watch-index.png](../../screenshots/uk-roast-watch/preview-uk-roast-watch-index.png)
![preview-uk-roast-watch-watch.png](../../screenshots/uk-roast-watch/preview-uk-roast-watch-watch.png)
![preview-uk-roast-watch-watch-s2.png](../../screenshots/uk-roast-watch/preview-uk-roast-watch-watch-s2.png)
![preview-uk-roast-watch-record.png](../../screenshots/uk-roast-watch/preview-uk-roast-watch-record.png)

## Review Submission

### Feature Description

On a British Sunday roast, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none burnt.

### Opening Message

On a British Sunday roast, the cook with both hands busy looks at one tray, nods to start its timer, and is told when it is ready - several trays, none burnt.

### Preview Media

[preview-uk-roast-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/uk-roast-watch/preview-uk-roast-watch-video.mp4)
![preview-uk-roast-watch-index.png](../../screenshots/uk-roast-watch/preview-uk-roast-watch-index.png)
![preview-uk-roast-watch-watch.png](../../screenshots/uk-roast-watch/preview-uk-roast-watch-watch.png)
![preview-uk-roast-watch-watch-s2.png](../../screenshots/uk-roast-watch/preview-uk-roast-watch-watch-s2.png)

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
