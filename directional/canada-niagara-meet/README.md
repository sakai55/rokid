# Canada Niagara Meet

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-canada-niagara-meet
```

[canada-niagara-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/canada-niagara-meet.aix)

## Features

A visitor at Niagara Falls with both hands full loses her companions and returns to the registered meeting point by GPS cardinal direction and distance, and logs arrival.

## Scene

A visitor at Niagara Falls with both hands full loses her companions and returns to the registered meeting point by GPS bearing and distance, without taking out her phone.

## Direction composition

Canada local scene x directional (GPS-anchored) x curb-cut (hands-full visitor separated from her companions). Three gates: scene (a visitor separated at Niagara Falls, hands full, needs to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real Niagara Falls meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Glasses-only capability

GPS-anchored direction: cardinal direction plus distance to a registered point, which a phone in a pocket cannot show in view. Wiring: app.json GEOLOCATION, guide page getCurrentPosition with existence guard, _calc bearing to 8 cardinals and haversine distance.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 meeting points |
| pages/guide | GPS register + cardinal + distance |
| pages/record | Arrival records |

## Content set

6 meeting points at Niagara Falls, Ontario (Table Rock Welcome Centre, Journey Behind the Falls, Clifton Hill, Skylon Tower, Queen Victoria Park, Niagara Parks Butterfly Conservatory). All six web-verified as real, walkable Niagara Falls attractions on 2026-11-22; none duplicates the canada-rockies-meet or canada-trail-meet point lists.

## Cross-session storage

Storage key `canadaNiagaraMeetV1` (picked point, registered point, arrival records, lastError).

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

![preview-canada-niagara-meet-index.png](../../screenshots/canada-niagara-meet/preview-canada-niagara-meet-index.png)
![preview-canada-niagara-meet-guide.png](../../screenshots/canada-niagara-meet/preview-canada-niagara-meet-guide.png)
![preview-canada-niagara-meet-record.png](../../screenshots/canada-niagara-meet/preview-canada-niagara-meet-record.png)

## Review Submission

### Feature Description

A visitor at Niagara Falls with both hands full loses her companions and returns to the registered meeting point by GPS cardinal direction and distance, and logs arrival.

### Opening Message

A visitor at Niagara Falls with both hands full loses her companions and returns to the registered meeting point by GPS cardinal direction and distance, and logs arrival.

### Preview Media

[preview-canada-niagara-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/canada-niagara-meet/preview-canada-niagara-meet-video.mp4)
![preview-canada-niagara-meet-index.png](../../screenshots/canada-niagara-meet/preview-canada-niagara-meet-index.png)
![preview-canada-niagara-meet-guide.png](../../screenshots/canada-niagara-meet/preview-canada-niagara-meet-guide.png)
![preview-canada-niagara-meet-record.png](../../screenshots/canada-niagara-meet/preview-canada-niagara-meet-record.png)

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
