# NZ Ferry Photo

**Studio import address** (copy into the Global AIUI Studio Import Project box):

```
https://github.com/sakai55/rokid/tree/agent-nz-ferry-photo
```

[nz-ferry-photo.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nz-ferry-photo.aix)

## Features

A Wellington ferry visitor with hands full of luggage looks at a photo spot, nods to take a photo, and ticks off 12 photo spots - one missing spot means the walk is not done.

## Scene

A Wellington ferry visitor with hands full of luggage looks at a photo spot, nods to take a photo, and ticks off 12 photo spots.

## Direction composition

New Zealand local scene x directional (look-to-point photo check) x attention.

## Glasses-only capability

Hands-free first-person instant capture: with both hands full of luggage, looking at a spot and nodding takes the photo, and the photo is the gate for finishing. Wiring: pages/photo/index.ink photoTap (getUserMedia + ImageCapture.takePhoto), onHeadGesture nod to primaryTap, confirmTap refuses without a photo.

## Pages

| Pages | Pages |
|---|---|
| pages/index | 6 photo spots |
| pages/photo | Look to lock, nod to take a photo, tick 12 items |
| pages/record | Finished walk records |

## Content set

6 photo spots x 2 photo items = 12 photo items (Ferry Terminal: Ticket gate / Departure board; Te Papa Steps: Front steps / Harbourside sign; Cable Car Top: Cable car / City view; Oriental Bay: Beach / Fountain; Mount Victoria Lookout: City view / Harbour view; Wellington Museum: Front door / Anchor).

## Cross-session storage

Storage key `nzFerryPhotoV1` (picked spot, ticked items, photo time and bytes, finished records, lastError). The photo itself is held only in the session, not persisted.

## Permissions

CAMERA declared. No location or media permission is used.

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
- `E8004` Camera interface missing
- `E2001` Photo capture failed
- `E2013` Photo encoding failed

- Photos are only for the visitor's own check; no other person's face is recognised and no automatic spot recognition is claimed.
- Finishing is gated: no photo means no finish, and unticked spots only warn, no record is written.
- In preview without a camera the photo fails honestly and is never faked as a success.

## Preview screenshots

![preview-nz-ferry-photo-index.png](../screenshots/nz-ferry-photo/preview-nz-ferry-photo-index.png)
![preview-nz-ferry-photo-photo.png](../screenshots/nz-ferry-photo/preview-nz-ferry-photo-photo.png)
![preview-nz-ferry-photo-photo-s2.png](../screenshots/nz-ferry-photo/preview-nz-ferry-photo-photo-s2.png)
![preview-nz-ferry-photo-record.png](../screenshots/nz-ferry-photo/preview-nz-ferry-photo-record.png)

## Review Submission

### Feature Description

A Wellington ferry visitor with hands full of luggage looks at a photo spot, nods to take a photo, and ticks off 12 photo spots - one missing spot means the walk is not done.

### Opening Message

A Wellington ferry visitor with hands full of luggage looks at a photo spot, nods to take a photo, and ticks off 12 photo spots - one missing spot means the walk is not done.

### Preview Media

[preview-nz-ferry-photo-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/nz-ferry-photo/preview-nz-ferry-photo-video.mp4)
![preview-nz-ferry-photo-index.png](../screenshots/nz-ferry-photo/preview-nz-ferry-photo-index.png)
![preview-nz-ferry-photo-photo.png](../screenshots/nz-ferry-photo/preview-nz-ferry-photo-photo.png)
![preview-nz-ferry-photo-photo-s2.png](../screenshots/nz-ferry-photo/preview-nz-ferry-photo-photo-s2.png)

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
