# Aussie Market Photo - Agent Notes

DI52. Australia local scene x directional (look-to-aim photo check) x attention.

## Design contract

A shopper at an Australian farmers market with both hands full of bags looks at a stall, nods to take a photo as a check, ticks what was bought, and may check out only after the photo and all ticks. Missing items are reminded before checkout.

## Counts

Content set: 6 stalls x 12 goods (each stall carries 2 goods). Checkout records are counted by their real number.

## Storage

Storage key `aussieMarketPhotoV1` (selected stall, tick states, photo timestamp and byte count, checkout records array, lastError). The photo itself is held in memory only during the session; only its timestamp and byte count are persisted.

## Gesture map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Take a photo (main action on the check page) |
| Swipe up / swipe down | ArrowUp / ArrowDown | Change item |
| Nod (head steady) | onHeadGesture nod | Same as main action: take a photo |
| Double tap | Backspace | Back to the previous page |

## Honest boundaries

- The photo is only the shopper's own check evidence. It does not identify goods automatically and it does not recognise any other person's face. Ticking is done by the shopper.
- Checkout is gated: no photo means no checkout, and unticked items mean a reminder, not a checkout record.
- The camera looks where the wearer looks (camera coaxial with view), so looking at the stall aims the photo; nodding fires it.

## Validation

- Language purity: no Chinese, Japanese, or Korean characters in the built files (static machine check).
- Banned-list grep over code files: 0 hits; no old-style file reading call anywhere (Blob to data URL goes through arrayBuffer plus chunked btoa).
- Photo wiring: getUserMedia plus ImageCapture takePhoto in pages/check photoTap; conversion failure, capture failure, and missing camera interface each map to a bare code.
