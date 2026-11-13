# NZ Milford Meet

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-nz-milford-meet
```

[nz-milford-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nz-milford-meet.aix)

## Features

A Milford Sound tramper separated from friends on the track registers a meeting point by GPS, then follows cardinal direction and distance back to it, and logs arrival.

## Scene

A Milford Sound tramper separated from friends on the track, both hands on walking poles, follows GPS cardinal direction and distance back to the registered trackhead meeting point.

## Direction composition

New Zealand local scene x directional (GPS-anchored) x curb-cut (hands-full tramper separated from friends). Three gates: scene (a tramper separated from friends, hands on poles, needs to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Glasses-only capability

GPS-anchored direction: cardinal direction plus distance to a registered point, which a phone in a pocket cannot show in view. Wiring: app.json GEOLOCATION, guide page getCurrentPosition with existence guard, _calc bearing to 8 cardinals and haversine distance.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 meeting points |
| pages/guide | GPS register + cardinal + distance |
| pages/record | Arrival records |

## Content set

6 meeting points (Milford Track Start, Lake Marian Track, Gertrude Saddle, Key Summit, Homer Tunnel, Milford Sound Wharf).

## Cross-session storage

Storage key `nzMilfordMeetV1` (picked point, registered point, arrival records, lastError).

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

![preview-nz-milford-meet-index.png](../../screenshots/nz-milford-meet/preview-nz-milford-meet-index.png)
![preview-nz-milford-meet-guide.png](../../screenshots/nz-milford-meet/preview-nz-milford-meet-guide.png)
![preview-nz-milford-meet-record.png](../../screenshots/nz-milford-meet/preview-nz-milford-meet-record.png)

## Review Submission

### Feature Description

A Milford Sound tramper separated from friends on the track registers a meeting point by GPS, then follows cardinal direction and distance back to it, and logs arrival.

### Opening Message

A Milford Sound tramper separated from friends on the track registers a meeting point by GPS, then follows cardinal direction and distance back to it, and logs arrival.

### Preview Media

[preview-nz-milford-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/nz-milford-meet/preview-nz-milford-meet-video.mp4)
![preview-nz-milford-meet-index.png](../../screenshots/nz-milford-meet/preview-nz-milford-meet-index.png)
![preview-nz-milford-meet-guide.png](../../screenshots/nz-milford-meet/preview-nz-milford-meet-guide.png)
![preview-nz-milford-meet-record.png](../../screenshots/nz-milford-meet/preview-nz-milford-meet-record.png)

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
