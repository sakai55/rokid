# South Africa Capetown Meet

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-south-africa-capetown-meet
```

[south-africa-capetown-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/south-africa-capetown-meet.aix)

## Features

A visitor in Cape Town with both hands full of shopping bags loses her companions near the V&A Waterfront and returns to the registered meeting point by GPS cardinal direction and distance, and logs arrival.

## Scene

A visitor in Cape Town with both hands full of shopping bags loses her companions near the V&A Waterfront and returns to the registered meeting point by GPS bearing and distance, without taking out her phone.

## Direction composition

South Africa local scene x directional (GPS-anchored) x curb-cut (hands-full visitor separated from her companions). Three gates: scene (a visitor separated in Cape Town, hands full, needs to get back to the meeting point); loop (pick a point, register it by GPS, follow cardinal direction and distance, log arrival); thickness (6 real Cape Town meeting points + multi-step flow + cross-session records). Directional carries the GPS-anchored guidance; curb-cut carries the hands-full, no-phone-in-hand use.

## Glasses-only capability

GPS-anchored direction: cardinal direction plus distance to a registered point, which a phone in a pocket cannot show in view. Wiring: app.json GEOLOCATION, guide page getCurrentPosition with existence guard, _calc bearing to 8 cardinals and haversine distance.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 meeting points |
| pages/guide | GPS register + cardinal + distance |
| pages/record | Arrival records |

## Content set

6 meeting points in Cape Town, all web-verified as real, publicly accessible places on 2026-11-27:

- V&A Waterfront — 123-hectare working harbour precinct with over 450 shops, public walkways and the Victoria Wharf mall.
- Table Mountain Cableway — lower cableway station on Tafelberg Road; the cable car runs to the summit plateau (the agent makes no summit claim beyond the cableway itself).
- Kirstenbosch Garden — National Botanical Garden on the eastern slopes of Table Mountain, open daily, a public garden.
- Camps Bay Beach — free public Blue Flag beach on the Atlantic Seaboard, backed by the Twelve Apostles.
- Bo-Kaap — historic Cape Malay quarter above the city centre; its public streets are free to walk (a lived-in residential neighbourhood — visit respectfully).
- Greenmarket Square — historic public square in the city centre, home to a daily craft and curio market.

No overlap with the south-africa-braai-watch content (cooking watch, different domain).

## Cross-session storage

Storage key `southAfricaCapetownMeetV1` (picked point, registered point, arrival records, lastError).

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

## Honest boundaries

- Distance is an estimate, rounded to 10 metres; indoors or in weak GPS areas the page says so and invents no position.
- No position is given before a point is registered.
- Preview cannot present live GPS: the review video shows only the register-and-measure flow the preview can show, with no position invented. No guide-s2 / record-s2 screenshot is delivered, because preview has no GPS.

## Preview screenshots

![preview-south-africa-capetown-meet-index.png](../screenshots/south-africa-capetown-meet/preview-south-africa-capetown-meet-index.png)
![preview-south-africa-capetown-meet-guide.png](../screenshots/south-africa-capetown-meet/preview-south-africa-capetown-meet-guide.png)
![preview-south-africa-capetown-meet-record.png](../screenshots/south-africa-capetown-meet/preview-south-africa-capetown-meet-record.png)

## Review Submission

### Feature Description

A visitor in Cape Town with both hands full of shopping bags loses her companions near the V&A Waterfront and returns to the registered meeting point by GPS cardinal direction and distance, and logs arrival.

### Opening Message

A visitor in Cape Town with both hands full of shopping bags loses her companions near the V&A Waterfront and returns to the registered meeting point by GPS bearing and distance, without taking out her phone.

### Preview Media

[preview-south-africa-capetown-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/south-africa-capetown-meet/preview-south-africa-capetown-meet-video.mp4)
![preview-south-africa-capetown-meet-index.png](../screenshots/south-africa-capetown-meet/preview-south-africa-capetown-meet-index.png)
![preview-south-africa-capetown-meet-guide.png](../screenshots/south-africa-capetown-meet/preview-south-africa-capetown-meet-guide.png)
![preview-south-africa-capetown-meet-record.png](../screenshots/south-africa-capetown-meet/preview-south-africa-capetown-meet-record.png)

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
