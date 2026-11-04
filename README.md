# Ireland Coast Guide

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-ireland-coast-guide
```

[ireland-coast-guide.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ireland-coast-guide.aix)

## Features

A walker on the Irish coast registers a meeting point by GPS, then follows cardinal direction and distance back to it, and logs arrival.

## Scene

A walker on the Irish coast, separated from the group, follows GPS cardinal direction and distance back to the registered meeting point.

## Direction composition

Ireland local scene x directional (GPS-anchored) x attention.

## Glasses-only capability

GPS-anchored direction: cardinal direction plus distance to a registered point, which a phone in a pocket cannot show in view. Wiring: app.json GEOLOCATION, guide page getCurrentPosition, _calc bearing to 8 cardinals and haversine distance.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 meeting points |
| pages/guide | GPS register + cardinal + distance |
| pages/record | Arrival records |

## Content set

6 meeting points (Cliffs, Harbour, Lighthouse, Beach Car Park, Village Green, Coast Path Start).

## Cross-session storage

Storage key `irelandCoastGuideV1` (picked point, registered point, arrival records, lastError).

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

![preview-ireland-coast-guide-index.png](../screenshots/ireland-coast-guide/preview-ireland-coast-guide-index.png)
![preview-ireland-coast-guide-guide.png](../screenshots/ireland-coast-guide/preview-ireland-coast-guide-guide.png)
![preview-ireland-coast-guide-record.png](../screenshots/ireland-coast-guide/preview-ireland-coast-guide-record.png)

## Review Submission

### Feature Description

A walker on the Irish coast registers a meeting point by GPS, then follows cardinal direction and distance back to it, and logs arrival.

### Opening Message

A walker on the Irish coast registers a meeting point by GPS, then follows cardinal direction and distance back to it, and logs arrival.

### Preview Media

[preview-ireland-coast-guide-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ireland-coast-guide/preview-ireland-coast-guide-video.mp4)
![preview-ireland-coast-guide-index.png](../screenshots/ireland-coast-guide/preview-ireland-coast-guide-index.png)
![preview-ireland-coast-guide-guide.png](../screenshots/ireland-coast-guide/preview-ireland-coast-guide-guide.png)
![preview-ireland-coast-guide-record.png](../screenshots/ireland-coast-guide/preview-ireland-coast-guide-record.png)

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
