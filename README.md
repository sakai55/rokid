# NZ Hut Cook Watch

**Studio import address** (copy into the Import Project box in Global AIUI Studio):

```
https://github.com/sakai55/rokid/tree/agent-nz-hut-cook-watch
```

**Latest AIX download:** [nz-hut-cook-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nz-hut-cook-watch.aix)

## Overview

WA07 nz-hut-cook-watch — New Zealand: New Zealand local scene x attention x directional. The tramping-hut cooking scene is the core, the look-to-pick slot watch is the attention mechanism, and head direction switching slots is the directional mechanism.. A New Zealand tramping-hut cook with both hands busy looks at one cooker, nods to start its timer, hears a spoken alert when it is done, and records the finished dish. Buttons switch slots when no head sensor is present.

AIX size: 11630 B (filled in by the batch closing step).

## Scene

A New Zealand tramping-hut cook with both hands busy looks at one cooker, nods to start its timer, hears a spoken alert when it is done, and records the finished dish. Buttons switch slots when no head sensor is present.

## Direction mix

New Zealand local scene x attention x directional. The tramping-hut cooking scene is the core, the look-to-pick slot watch is the attention mechanism, and head direction switching slots is the directional mechanism.

## Glasses-exclusive capability

Hands-busy hut cooking: the cook looks at a slot and nods to start the timer while both hands hold pots, and the spoken done alert arrives without a look at a phone. Taking a phone out with wet hands over a stove would miss the moment.

Watch wiring evidence: pages/watch/index.ink _startSensor reads AbsoluteOrientationSensor with a typeof guard and maps head yaw to 3 slots, primaryTap starts the timer for the index-selected cooker, the done state speaks once per timer and finishTap records the dish under nzHutCookWatchV1. Buttons switch slots when no sensor is present.

## Pages

| Page | Role |
|---|---|
| pages/index | 6 hut cooker and dish sets, go to watch or records |
| pages/watch | 3 timer slots, look to switch slots, nod to start, Finish records a done dish |
| pages/record | Latest 6 finished dishes and the total |

## Content set

6 cooker and dish sets: Hut Stove - Soup Pot (30 min), Hut Stove - Rice Pot (25 min), Camp Burner - Kettle (5 min), Camp Burner - Pasta Pot (12 min), Fireplace Pot - Stew (40 min), Solar Cooker - Porridge (20 min). Finished dishes are counted by their real number.

## Persistence

Cross-session storage key `nzHutCookWatchV1`. It stores the selected cooker, the 3 slot timers (dish name, minutes, start time), the finished-dish records array, and lastError.

## Permissions

No permissions. TTS needs no manifest permission and neither camera nor location is used.

## Gestures

Single tap (Enter) or nod confirms the main action, swipe up/down changes the selection, double tap goes back. Buttons cover every action when no sensor is present.

## Error codes

- `E7001` Head sensor unavailable
- `E5001` Storage write failed
- `E5002` Storage read failed
- `E3005` Speech failed
- `E8001` Navigation failed

Failures always show the bare code on screen, and lastError keeps the code plus slug, version, and original text.

## Preview screenshots

Preview screenshots are taken in the batch closing step. Their slots are:

![preview-nz-hut-cook-watch-index.png](../screenshots/nz-hut-cook-watch/preview-nz-hut-cook-watch-index.png)
![preview-nz-hut-cook-watch-watch.png](../screenshots/nz-hut-cook-watch/preview-nz-hut-cook-watch-watch.png)
![preview-nz-hut-cook-watch-watch-s2.png](../screenshots/nz-hut-cook-watch/preview-nz-hut-cook-watch-watch-s2.png)
![preview-nz-hut-cook-watch-record.png](../screenshots/nz-hut-cook-watch/preview-nz-hut-cook-watch-record.png)

## Review submission

### Feature Description

A New Zealand tramping-hut cook watch. With both hands busy, look at a cooker slot, nod to start its timer, hear a spoken alert when it is done, and record the finished dish. Buttons switch slots when no head sensor is present.

### Opening Message

Pick a hut cooker, look at a slot, nod to start its timer, and let it tell you when dinner is done.

### Preview Media

1 video ([preview-nz-hut-cook-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/nz-hut-cook-watch/preview-nz-hut-cook-watch-video.mp4)) + 3 images: preview-nz-hut-cook-watch-index.png, preview-nz-hut-cook-watch-watch-s2.png, preview-nz-hut-cook-watch-record.png.

### Change Log

- 1.0.0: Features added - 6 hut cooker and dish sets, 3-slot look-to-switch timer watch, spoken done alert, finished-dish records.

## Device test info

| Item | Value |
|---|---|
| Studio name | Not entered |
| Version | 1.0.0 |
| Category | Not entered |
| Intent description | Not entered |
| Agent ID | Not entered |
| Status | Not imported |
