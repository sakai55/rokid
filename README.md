# Irish Dance Steps

**Studio import address** (copy into the Import Project box in Global AIUI Studio):

```
https://github.com/sakai55/rokid/tree/agent-ireland-dance-step
```

**Latest AIX download:** [ireland-dance-step.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/ireland-dance-step.aix)

## Overview

GA53 ireland-dance-step — Ireland: Ireland local scene x game x directional. The Irish ceilidh scene is the core, the head-direction step pick is the directional mechanism, and the 10-round settle is the game mechanism.. An Irish ceilidh dance-step game. Turn your head to pick one of four steps, nod to dance it, and settle the score after 10 rounds. Your best score is kept across sessions, and buttons work when no head sensor is present.

AIX size: 11189 B (filled in by the batch closing step).

## Scene

An Irish ceilidh dance-step game. Turn your head to pick one of four steps, nod to dance it, and settle the score after 10 rounds. Your best score is kept across sessions, and buttons work when no head sensor is present.

## Direction mix

Ireland local scene x game x directional. The Irish ceilidh scene is the core, the head-direction step pick is the directional mechanism, and the 10-round settle is the game mechanism.

## Glasses-exclusive capability

Head-direction play with no hands needed: the dancer's head turn picks the step and a nod dances it, so the game runs while the dancer is in ceilidh formation. A phone game would need hands and eyes down at the moment of dancing.

Head wiring evidence: pages/play/index.ink _startSensor reads AbsoluteOrientationSensor with a typeof guard, turns past the 0.35 yaw threshold change the step only after re-centring, and danceTap settles after 10 rounds and persists the best score under irelandDanceStepV1. Buttons change the step when no sensor is present.

## Pages

| Page | Role |
|---|---|
| pages/index | 4 ceilidh steps, best score, go to play or records |
| pages/play | 10 rounds, head-picked step, nod to dance, settle at 10 rounds |
| pages/record | Latest 6 settled games and the total |

## Content set

4 steps: Sidestep Left, Sidestep Right, Forward Step, Turn Step. 10 rounds per game with the fixed target order Left, Right, Forward, Turn, Left, Forward, Right, Turn, Forward, Left. Settled games are counted by their real number.

## Persistence

Cross-session storage key `irelandDanceStepV1`. It stores the selected step, the best score out of 10, the settled-game records array, and lastError.

## Permissions

No permissions. TTS needs no manifest permission and neither camera nor location is used.

## Gestures

Single tap (Enter) or nod dances the step, swipe up/down changes the step, double tap goes back. Buttons cover every action when no sensor is present.

## Error codes

- `E7001` Head sensor unavailable
- `E5001` Storage write failed
- `E5002` Storage read failed
- `E3005` Speech failed
- `E8001` Navigation failed

Failures always show the bare code on screen, and lastError keeps the code plus slug, version, and original text.

## Preview screenshots

Preview screenshots are taken in the batch closing step. Their slots are:

![preview-ireland-dance-step-index.png](../screenshots/ireland-dance-step/preview-ireland-dance-step-index.png)
![preview-ireland-dance-step-play.png](../screenshots/ireland-dance-step/preview-ireland-dance-step-play.png)
![preview-ireland-dance-step-play-s2.png](../screenshots/ireland-dance-step/preview-ireland-dance-step-play-s2.png)
![preview-ireland-dance-step-record.png](../screenshots/ireland-dance-step/preview-ireland-dance-step-record.png)

## Review submission

### Feature Description

An Irish ceilidh dance-step game. Turn your head to pick one of four steps, nod to dance it, and settle the score after 10 rounds. Your best score is kept across sessions, and buttons work when no head sensor is present.

### Opening Message

Pick a step with your head, nod to dance it, and see how many of the 10 rounds you hit.

### Preview Media

1 video ([preview-ireland-dance-step-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ireland-dance-step/preview-ireland-dance-step-video.mp4)) + 3 images: preview-ireland-dance-step-index.png, preview-ireland-dance-step-play-s2.png, preview-ireland-dance-step-record.png.

### Change Log

- 1.0.0: Features added - 4 ceilidh steps, 10-round games with head-direction picking and re-centre rule, settled-game records, best score kept across sessions.

## Device test info

| Item | Value |
|---|---|
| Studio name | Not entered |
| Version | 1.0.0 |
| Category | Not entered |
| Intent description | Not entered |
| Agent ID | Not entered |
| Status | Not imported |
