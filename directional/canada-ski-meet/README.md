# Canada Ski Meet

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-canada-ski-meet
```

[canada-ski-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/canada-ski-meet.aix)

## Features

Skiers at Whistler Blackcomb separated from companions, both hands holding ski poles, follow GPS cardinal direction and distance back to the registered meeting point, and log arrival.

## Scene

Skiers at Whistler Blackcomb separated from companions, both hands holding ski poles, follow GPS cardinal direction and distance back to the registered meeting point without taking out a phone.

## Direction composition

Canada local scene x directional (GPS-anchored) x curb-cut (hands-full skiers separated from companions). Three gates: scene (skiers separated on the slopes, hands full of poles, need to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Glasses-only capability

GPS-anchored direction: cardinal direction plus distance to a registered point, which a phone in a pocket cannot show in view. Wiring: app.json GEOLOCATION, guide page getCurrentPosition with existence guard, _calc bearing to 8 cardinals and haversine distance.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 meeting points |
| pages/guide | GPS register + cardinal + distance |
| pages/record | Arrival records |

## Content set

6 meeting points at Whistler Blackcomb (Roundhouse Lodge, Glacier Express, Harmony Bowl, Village Gondola, Creekside Gondola, Peak Chair).

## Cross-session storage

Storage key `canadaSkiMeetV1` (picked point, registered point, arrival records, lastError).

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
- Preview cannot present live GPS: the review video shows only the register-and-measure flow the preview can show, with no position invented.

## Preview screenshots

![preview-canada-ski-meet-index.png](../../screenshots/canada-ski-meet/preview-canada-ski-meet-index.png)
![preview-canada-ski-meet-guide.png](../../screenshots/canada-ski-meet/preview-canada-ski-meet-guide.png)
![preview-canada-ski-meet-record.png](../../screenshots/canada-ski-meet/preview-canada-ski-meet-record.png)

## Review Submission

### Feature Description

Skiers at Whistler Blackcomb separated from companions, both hands holding ski poles, follow GPS cardinal direction and distance back to the registered meeting point, and log arrival.

### Opening Message

Skiers at Whistler Blackcomb separated from companions, both hands holding ski poles, follow GPS cardinal direction and distance back to the registered meeting point, and log arrival.

### Preview Media

[preview-canada-ski-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/canada-ski-meet/preview-canada-ski-meet-video.mp4)
![preview-canada-ski-meet-index.png](../../screenshots/canada-ski-meet/preview-canada-ski-meet-index.png)
![preview-canada-ski-meet-guide.png](../../screenshots/canada-ski-meet/preview-canada-ski-meet-guide.png)
![preview-canada-ski-meet-record.png](../../screenshots/canada-ski-meet/preview-canada-ski-meet-record.png)

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
