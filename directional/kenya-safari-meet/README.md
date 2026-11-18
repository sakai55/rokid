# Kenya Safari Meet

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-kenya-safari-meet
```

[kenya-safari-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/kenya-safari-meet.aix)

## Features

Safari-goers in Kenya, separated from their group with both hands full of bags or binoculars, follow GPS cardinal direction and distance back to the registered meeting point, and log arrival.

## Scene

Safari-goers in Kenya, separated from their group with both hands full, follow GPS cardinal direction and distance back to the registered meeting point without taking out a phone.

## Direction composition

Kenya local scene x directional (GPS-anchored) x curb-cut (hands-full safari-goers separated from their group). Three gates: scene (safari-goers separated on a safari, hands full of bags or binoculars, need to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real safari meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Glasses-only capability

GPS-anchored direction: cardinal direction plus distance to a registered point, which a phone in a pocket cannot show in view. Wiring: app.json GEOLOCATION, guide page getCurrentPosition with existence guard, _calc bearing to 8 cardinals and haversine distance.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 meeting points |
| pages/guide | GPS register + cardinal + distance |
| pages/record | Arrival records |

## Content set

6 meeting points on a Kenya safari (Amboseli Observation Hill, Maasai Mara Keekorok Lodge, Lake Nakuru Flamingo Point, Tsavo East Aruba Dam, Diani Beach South End, Nairobi National Park Gate).

## Cross-session storage

Storage key `kenyaSafariMeetV1` (picked point, registered point, arrival records, lastError).

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

![preview-kenya-safari-meet-index.png](../../screenshots/kenya-safari-meet/preview-kenya-safari-meet-index.png)
![preview-kenya-safari-meet-guide.png](../../screenshots/kenya-safari-meet/preview-kenya-safari-meet-guide.png)
![preview-kenya-safari-meet-record.png](../../screenshots/kenya-safari-meet/preview-kenya-safari-meet-record.png)

## Review Submission

### Feature Description

Safari-goers in Kenya, separated from their group with both hands full of bags or binoculars, follow GPS cardinal direction and distance back to the registered meeting point, and log arrival.

### Opening Message

Safari-goers in Kenya, separated from their group with both hands full of bags or binoculars, follow GPS cardinal direction and distance back to the registered meeting point, and log arrival.

### Preview Media

[preview-kenya-safari-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/kenya-safari-meet/preview-kenya-safari-meet-video.mp4)
![preview-kenya-safari-meet-index.png](../../screenshots/kenya-safari-meet/preview-kenya-safari-meet-index.png)
![preview-kenya-safari-meet-guide.png](../../screenshots/kenya-safari-meet/preview-kenya-safari-meet-guide.png)
![preview-kenya-safari-meet-record.png](../../screenshots/kenya-safari-meet/preview-kenya-safari-meet-record.png)

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
