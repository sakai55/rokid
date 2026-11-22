# USA Liberty Photo - Agent Notes

DI114. USA local scene x directional (gaze photo-check) x attention.

## Design contract

A visitor at the Statue of Liberty with both hands full of guidebook and tickets looks at each viewpoint and nods to photograph-check 12 photo points, and the visit is not complete until every point is checked.

## Counts

6 areas x 12 photo points: Pedestal (Observation Deck / Museum exhibits), Crown (Spiral staircase / Harbour view), Fort Wood (Star walls / Ramparts view), Statue Museum (Original torch / Rooftop deck), Sculpture Garden (Bronze statues / Norwegian copper gift), Island Promenade (Flagpole Plaza / Manhattan skyline view). All web-verified as real, publicly visitable Liberty Island spots on 2026-11-23; wording does not repeat any existing photo agent's points verbatim.

## Storage

Storage key `usaLibertyPhotoV1` (selected area, ticked photo points, photo time and byte count, finish records, lastError). The photo itself is kept only in the session, not persisted.

## Gesture map

| Single tap | Enter | Main confirm |
| Swipe up / down | ArrowUp / ArrowDown | Change selection |
| Nod | onHeadGesture('nod') | Same as main confirm |
| Double tap | Backspace | Back |

## Honest boundaries

- Photos are for the visitor's own checklist only; no face recognition, no claim of automatic landmark recognition.
- No photo, no finish; unticked points only prompt, nothing is recorded.
- When preview has no camera, the photo fails honestly and is never faked as a success.

## Validation

- Language purity: no CJK characters in built files (static check).
- Banned-list grep over code files: 0 hits.
- Photo wiring: pages/photo/index.ink photoTap (getUserMedia + ImageCapture.takePhoto); Blob to data URL via arrayBuffer + chunked btoa, FileReader = 0; confirmTap gated on this._photo.
- Error codes E8004 / E2001 / E2013 verified against repo ERROR-CODES.md.
