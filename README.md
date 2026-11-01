# London Bus Meetup

**Studio import address** (copy into the Import Project box in Global AIUI Studio):

```
https://github.com/sakai55/rokid/tree/agent-london-bus-meet
```

**Latest AIX download:** [london-bus-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/london-bus-meet.aix)

## Overview

A visitor in London with both hands full of shopping bags returns to a registered bus stop meeting point by following its GPS compass direction and distance, then records the arrival. Version 1.0.0, 3 pages, country: United Kingdom.

## Scene

A visitor carrying shopping bags near London bus stops opens the agent, registers the stop where the group meets, and walks back to it by compass direction and distance without taking out a phone.

## Direction mix

United Kingdom local scene x directional. The London bus stop scene is the core, and GPS-anchored direction (cardinal bearing plus distance to a registered point) is the mechanism that carries the whole loop.

## Glasses-exclusive capability

- GPS-anchored direction: the registered stop is reached by an 8-point compass bearing plus distance, with the bearing and distance shown in view while the hands stay full. A phone app doing the same job would need a free hand to hold and read.
- The guide step cannot be skipped: without a registered point there is no guide at all, and without a fresh measurement there is no bearing or distance.

GPS triple evidence: permission declared as GEOLOCATION in app.json permissions. Location calls are navigator.geolocation.getCurrentPosition in pages/index/index.ink (saveTap) and pages/guide/index.ink (primaryTap), both through the shared _geo helper. Cardinal conversion is pages/guide/index.ink _calc (Math.atan2 bearing mapped onto the 8-point CARD array, haversine distance rounded to 10 m).

## Pages

| Page | Role |
|---|---|
| pages/index | 6 bus stops, register the current location under the stop name, go to guide or records |
| pages/guide | Measure the current location, show 8-point direction and distance to the registered stop, record arrival |
| pages/record | Latest 6 arrival records and the total |

## Content set

6 London bus stops. Arrival records are counted by their real number.

## Persistence

Cross-session storage key `londonBusMeetV1`. It stores the selected stop, the registered point (latitude, longitude, registered time), the arrival records array, and lastError.

## Permissions

`GEOLOCATION` only. When location use is refused, the agent does not measure and shows the refusal. TTS needs no manifest permission and the camera is never called.

## Gestures

Single tap (Enter) is main confirm, swipe up/down changes selection, nod equals main confirm, double tap goes back.

## Error codes

- `E7002` Location failed (GPS unavailable or measurement error)
- `E7003` Location refused (no permission to use location)
- `E5001` Storage write failed
- `E5002` Storage read failed
- `E3005` Speech failed
- `E8001` Navigation failed

Failures always show the bare code on screen, and lastError keeps the code plus slug, version, and original text.

## Preview screenshots

Preview screenshots are taken in the batch closing step. Their slots are:

![index](../screenshots/london-bus-meet/preview-london-bus-meet-index.png)
![guide](../screenshots/london-bus-meet/preview-london-bus-meet-guide.png)
![record](../screenshots/london-bus-meet/preview-london-bus-meet-record.png)
![preview-london-bus-meet-record-s2.png](../screenshots/london-bus-meet/preview-london-bus-meet-record-s2.png)

## Review submission

### Feature Description

A London visitor's guide back to a bus stop meeting point. Register a stop by GPS, follow its 8-point compass direction and distance, and record the arrival. No place is ever invented: unregistered stops get no guide.

### Opening Message

Let us get back to your bus stop. Register the stop where you meet, then follow its direction and distance.

### Preview Media

3 images (one per page) plus 1 video, backfilled at the device stage.

### Change Log

- 1.0.0: Features added - 6 London bus stops, GPS registration, 8-point compass and distance guide, arrival records.

## Device test info

| Item | Value |
|---|---|
| Studio name | Not entered |
| Version | 1.0.0 |
| Category | Not entered |
| Intent description | Not entered |
| Agent ID | Not entered |
| Status | Not submitted |
