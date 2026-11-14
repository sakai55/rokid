# USA Yellowstone Meet

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-usa-yellowstone-meet
```

[usa-yellowstone-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/usa-yellowstone-meet.aix)

## Features

Yellowstone hikers separated on a trail register a meeting point by GPS, then follow cardinal direction and distance back to it, and log arrival.

## Scene

Yellowstone hikers separated on a trail, both hands on trekking poles, follow GPS cardinal direction and distance back to the registered trailhead meeting point.

## Direction composition

USA local scene x directional (GPS-anchored) x curb-cut (hands-full hikers separated from friends). Three gates: scene (hikers separated on a trail, hands on poles, need to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Glasses-only capability

GPS-anchored direction: cardinal direction plus distance to a registered point, which a phone in a pocket cannot show in view. Wiring: app.json GEOLOCATION, guide page getCurrentPosition with existence guard, _calc bearing to 8 cardinals and haversine distance.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 meeting points |
| pages/guide | GPS register + cardinal + distance |
| pages/record | Arrival records |

## Content set

6 meeting points (Old Faithful, Grand Prismatic Spring, Mammoth Hot Springs, Yellowstone Lake, Lamar Valley, Canyon Village).

## Cross-session storage

Storage key `usaYellowstoneMeetV1` (picked point, registered point, arrival records, lastError).

## Permissions

GEOLOCATION declared. No camera or media permission is used.

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
- `E7002` Location unavailable
- `E7003` Location permission denied

- Distance is an estimate, rounded to 10 metres; indoors or in weak GPS areas the page says so and invents no position.
- No position is given before a point is registered.

## Preview screenshots

![preview-usa-yellowstone-meet-index.png](../screenshots/usa-yellowstone-meet/preview-usa-yellowstone-meet-index.png)
![preview-usa-yellowstone-meet-guide.png](../screenshots/usa-yellowstone-meet/preview-usa-yellowstone-meet-guide.png)
![preview-usa-yellowstone-meet-record.png](../screenshots/usa-yellowstone-meet/preview-usa-yellowstone-meet-record.png)

## Review Submission

### Feature Description

Yellowstone hikers separated on a trail register a meeting point by GPS, then follow cardinal direction and distance back to it, and log arrival.

### Opening Message

Yellowstone hikers separated on a trail register a meeting point by GPS, then follow cardinal direction and distance back to it, and log arrival.

### Preview Media

[preview-usa-yellowstone-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/usa-yellowstone-meet/preview-usa-yellowstone-meet-video.mp4)
![preview-usa-yellowstone-meet-index.png](../screenshots/usa-yellowstone-meet/preview-usa-yellowstone-meet-index.png)
![preview-usa-yellowstone-meet-guide.png](../screenshots/usa-yellowstone-meet/preview-usa-yellowstone-meet-guide.png)
![preview-usa-yellowstone-meet-record.png](../screenshots/usa-yellowstone-meet/preview-usa-yellowstone-meet-record.png)

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
