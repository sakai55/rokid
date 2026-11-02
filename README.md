# Banff Trail Meet

**Studio import address** (copy into the Import Project box in Global AIUI Studio):

```
https://github.com/sakai55/rokid/tree/agent-canada-trail-meet
```

**Latest AIX download:** [canada-trail-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/canada-trail-meet.aix)

## Overview

DI55 canada-trail-meet — Canada: Canada local scene x directional (GPS cardinal guidance). The Banff trail scene is the core and the GPS cardinal guidance is the directional mechanism; both must meet for an arrival record to mean a return.. A Banff hiker separated from companions at a trail junction registers a trailhead meeting point by GPS, then follows a cardinal direction and distance back to it. Hands stay on trekking poles: a nod confirms, and no location is ever invented when GPS is missing.

AIX size: 11848 B (filled in by the batch closing step).

## Scene

A Banff hiker separated from companions at a trail junction registers a trailhead meeting point by GPS, then follows a cardinal direction and distance back to it. Hands stay on trekking poles: a nod confirms, and no location is ever invented when GPS is missing.

## Direction mix

Canada local scene x directional (GPS cardinal guidance). The Banff trail scene is the core and the GPS cardinal guidance is the directional mechanism; both must meet for an arrival record to mean a return.

## Glasses-exclusive capability

GPS-anchored direction for hands on trekking poles: the hiker registers the meeting point without taking the phone out, then reads a cardinal direction and a distance in view and walks back. A phone app would need a free hand and a look down at the wrong moment on the trail.

Direction wiring evidence: pages/index/index.ink saveTap registers the point with navigator.geolocation.getCurrentPosition, and pages/guide/index.ink primaryTap re-measures position and runs _calc (bearing to 8 cardinal points N/NE/E/SE/S/SW/W/NW plus haversine distance rounded to 10 m). The unregistered guide state says Not registered and never invents a location.

## Pages

| Page | Role |
|---|---|
| pages/index | 6 Banff trailheads, register the meeting point by GPS, go to guide or records |
| pages/guide | Cardinal direction and distance back, Arrived writes the record |
| pages/record | Latest 6 arrival records and the total |

## Content set

6 trailheads: Lake Louise Trailhead Bench, Johnston Canyon Trailhead Sign, Moraine Lake Rockpile Meeting Point, Banff Upper Hot Springs Trailhead, Sunshine Village Trailhead, Tunnel Mountain Trailhead. Arrival records are counted by their real number.

## Persistence

Cross-session storage key `canadaTrailMeetV1`. It stores the selected trailhead, the registered point name with latitude and longitude and registration time, the arrival records array, and lastError.

## Permissions

`GEOLOCATION` only. TTS needs no manifest permission and the camera is never used.

## Gestures

Single tap (Enter) or nod confirms the main action, swipe up/down changes the selection, double tap goes back. Buttons cover every action when no sensor is present.

## Error codes

- `E7003` Location permission denied
- `E7002` Location failed or unavailable
- `E5001` Storage write failed
- `E5002` Storage read failed
- `E3005` Speech failed
- `E8001` Navigation failed

Failures always show the bare code on screen, and lastError keeps the code plus slug, version, and original text.

## Preview screenshots

Preview screenshots are taken in the batch closing step. Their slots are:

![preview-canada-trail-meet-index.png](../screenshots/canada-trail-meet/preview-canada-trail-meet-index.png)
![preview-canada-trail-meet-guide.png](../screenshots/canada-trail-meet/preview-canada-trail-meet-guide.png)
![preview-canada-trail-meet-record-s2.png](../screenshots/canada-trail-meet/preview-canada-trail-meet-record-s2.png)

Preview note: the preview has no GPS, so an arrival recorded from the guide page is shown under the generic name "Meeting point" — on device it records the registered point's name.

## Review submission

### Feature Description

A Banff hiker separated from companions at a trail junction registers a trailhead meeting point by GPS, then follows a cardinal direction and distance back to it. Hands stay on trekking poles: a nod confirms, and no location is ever invented when GPS is missing.

### Opening Message

Pick a Banff trailhead, register it as your meeting point, and follow the direction and distance back when you get separated.

### Preview Media

1 video (preview-canada-trail-meet-video.mp4) + 3 images: preview-canada-trail-meet-index.png, preview-canada-trail-meet-guide.png, preview-canada-trail-meet-record-s2.png.

### Change Log

- 1.0.0: Features added - 6 Banff trailheads, GPS meeting-point registration, 8-point cardinal guidance with distance rounded to 10 m, arrival records.

## Device test info

| Item | Value |
|---|---|
| Studio name | Not entered |
| Version | 1.0.0 |
| Category | Not entered |
| Intent description | Not entered |
| Agent ID | Not entered |
| Status | Not imported |
