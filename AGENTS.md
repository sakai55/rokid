# NZ Ferry Photo - Agent Notes

WA13. New Zealand local scene x directional (look-to-point photo check) x attention.

## Design contract

A Wellington ferry visitor with hands full of luggage looks at a photo spot, nods to take a photo, and ticks off 12 photo spots.

## Counts

6 photo spots x 2 photo items = 12 photo items (Ferry Terminal: Ticket gate / Departure board; Te Papa Steps: Front steps / Harbourside sign; Cable Car Top: Cable car / City view; Oriental Bay: Beach / Fountain; Mount Victoria Lookout: City view / Harbour view; Wellington Museum: Front door / Anchor).

## Storage

Storage key `nzFerryPhotoV1` (picked spot, ticked items, photo time and bytes, finished records, lastError). The photo itself is held only in the session, not persisted.

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Photos are only for the visitor's own check; no other person's face is recognised and no automatic spot recognition is claimed.
- Finishing is gated: no photo means no finish, and unticked spots only warn, no record is written.
- In preview without a camera the photo fails honestly and is never faked as a success.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Photo wiring: pages/photo/index.ink photoTap (getUserMedia + ImageCapture.takePhoto); Blob to data URL via arrayBuffer + chunked btoa, FileReader = 0.
