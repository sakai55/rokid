# County Fair Games

**Studio Import Address** (copy into the Global AIUI Studio Import Project input):

```
https://github.com/sakai55/rokid/tree/agent-us-fair-games
```

**Download the latest AIX**: [us-fair-games.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/us-fair-games.aix)

GA51 · United States × Games × Directional. Heavy hub: a family at a US county fair plays 20 fair games on one pair of glasses while waiting.

## Preview Screenshots

![preview-us-fair-games-index.png](../screenshots/us-fair-games/preview-us-fair-games-index.png)
![preview-us-fair-games-g01.png](../screenshots/us-fair-games/preview-us-fair-games-g01.png)
![preview-us-fair-games-g02.png](../screenshots/us-fair-games/preview-us-fair-games-g02.png)
![preview-us-fair-games-g03.png](../screenshots/us-fair-games/preview-us-fair-games-g03.png)
![preview-us-fair-games-g04.png](../screenshots/us-fair-games/preview-us-fair-games-g04.png)
![preview-us-fair-games-g05.png](../screenshots/us-fair-games/preview-us-fair-games-g05.png)
![preview-us-fair-games-g06.png](../screenshots/us-fair-games/preview-us-fair-games-g06.png)
![preview-us-fair-games-g07.png](../screenshots/us-fair-games/preview-us-fair-games-g07.png)
![preview-us-fair-games-g08.png](../screenshots/us-fair-games/preview-us-fair-games-g08.png)
![preview-us-fair-games-g09.png](../screenshots/us-fair-games/preview-us-fair-games-g09.png)
![preview-us-fair-games-g10.png](../screenshots/us-fair-games/preview-us-fair-games-g10.png)
![preview-us-fair-games-g11.png](../screenshots/us-fair-games/preview-us-fair-games-g11.png)
![preview-us-fair-games-g12.png](../screenshots/us-fair-games/preview-us-fair-games-g12.png)
![preview-us-fair-games-g13.png](../screenshots/us-fair-games/preview-us-fair-games-g13.png)
![preview-us-fair-games-g14.png](../screenshots/us-fair-games/preview-us-fair-games-g14.png)
![preview-us-fair-games-g15.png](../screenshots/us-fair-games/preview-us-fair-games-g15.png)
![preview-us-fair-games-g16.png](../screenshots/us-fair-games/preview-us-fair-games-g16.png)
![preview-us-fair-games-g17.png](../screenshots/us-fair-games/preview-us-fair-games-g17.png)
![preview-us-fair-games-g18.png](../screenshots/us-fair-games/preview-us-fair-games-g18.png)
![preview-us-fair-games-g19.png](../screenshots/us-fair-games/preview-us-fair-games-g19.png)
![preview-us-fair-games-g20.png](../screenshots/us-fair-games/preview-us-fair-games-g20.png)
![preview-us-fair-games-g01-s2.png](../screenshots/us-fair-games/preview-us-fair-games-g01-s2.png)

## Direction Composition

- This agent is United States locality × Games × Directional. Each direction carries an irreplaceable role in the scene, not a bundle of features.
- One-sentence scene: at a US county fair, a family waiting between events plays 20 fair games on one pair of glasses.
- Glasses-exclusive capability: head-direction coordination. Every game page is driven by head yaw (left / center / right at the ±0.35 threshold) or by nod to confirm; remove the head input and the loop breaks. A phone app cannot replace it here: hands are busy holding fair food, tickets, and children, and the game is played while looking at the fair itself.

## Structure and Features

21 pages: `pages/index/` hub (20 game names in a 5-game window, best record per game) + 20 game pages, one mechanism each:

| Page | Game | Mechanism | Content count |
|---|---|---|---|
| g01 | Ring Toss | count | target 6 rings |
| g02 | Balloon Pop | direction | 3 rounds, left / center / right targets |
| g03 | Duck Pond Pick | pick | 3 rounds, 3 ducks each |
| g04 | Pie Eating Rhythm | rhythm | 8 steps, bite-chew-bite-swallow twice |
| g05 | Corn Hole Aim | aim | 4 rounds |
| g06 | Milk Bottle Knock | count | target 5 bottles |
| g07 | Horseshoe Toss | direction | 3 rounds |
| g08 | Face Painting Pick | pick | 3 rounds, 3 paints each |
| g09 | Ferris Wheel Order | order | 4 cars ordered tallest first |
| g10 | Livestock Weight Guess | guess | 3 questions, 3 options each |
| g11 | Pie Contest Quiz | quiz | 3 questions, 3 options each |
| g12 | Lemonade Price Calc | calculation | 3 questions, 3 options each |
| g13 | Sack Race Steps | step count | 20 hops, 3 feet each, 60 feet total |
| g14 | Bean Bag Aim | aim | 4 rounds |
| g15 | Fishing Pond Count | count | target 7 fish |
| g16 | Photo Booth Poses | pick | 3 rounds, 3 poses each |
| g17 | Hay Bale Lift | lift count | 3 sets × 4 lifts |
| g18 | Apple Bobbing Timing | timing steps | 8 dip-hold-lift steps |
| g19 | Fireworks Sequence | sequence memory | 4 colors in order |
| g20 | Fair Food Quiz | quiz | 3 questions, 3 options each |

Content totals: 20 games; quiz / guess / calculation pages hold 3 questions each (12 questions); pick pages hold 3 rounds each (9 rounds); direction / aim pages hold 3–4 rounds each (14 rounds). Every finished game writes one record; records are counted as actually stored. Cross-session persistence: storage key `usFairGamesV1` (selected game, records array, `lastError`).

## Gesture Map

| Temple touchpad gesture | Key event | Role in this agent |
|---|---|---|
| Single tap | Enter | Main confirm (open game / count / answer / lock pick) |
| Swipe up / down | ArrowUp / ArrowDown | Move choice or zone (key fallback for head direction) |
| Nod (head steady) | `onHeadGesture('nod')` | Same as main confirm |
| Double tap | Backspace | Back (game pages) |

## Permissions

None. Head-orientation sensing and TTS need no manifest permission, and this agent never calls the camera, the microphone, or GPS. Direction here is head direction at the fair, not a GPS-anchored task, so no `GEOLOCATION` declaration is made.

## Honest Boundaries

- Scores come from the player's own head moves and choices. The agent never judges real-world skill automatically.
- The head sensor only assists: when it is missing, keys move the choice or zone instead, and the game stays playable.
- Game contents (weights, prices, quiz facts) are built-in game data, not live fair information.

## Error Codes

On failure the glasses show the bare code, TTS reads only the code, and the latest error is written to `lastError` in stored data (code, this agent's slug, version, original text). Codes this agent can surface:

- `E5001` record save failed (storage write threw)
- `E5002` record read failed (storage read or parse threw)
- `E3005` speech failed (TTS speak threw)
- `E8001` page switch failed (navigateTo / navigateBack threw)
- `E7001` head sensor unavailable (AbsoluteOrientationSensor creation or start failed, guarded by `typeof`)

## Device Test Information

| Item | Content |
|---|---|
| Studio name | Not filled in |
| Version | 1.0.0 |
| App Category | Not filled in |
| Intent Description | Not filled in |
| Agent ID | Not filled in |
| Status | Not verified on device |

## Review Submission

Feature Description: County Fair Games: 20 county fair games in one glasses agent for family wait time at a US county fair. Ring toss, balloon pop, duck pond, pie eating, corn hole, horseshoes, face painting, Ferris wheel order, livestock guesses, pie quiz, lemonade math, sack race, bean bag aim, fishing, photo booth, hay bale lift, apple bobbing, fireworks sequence, and food quiz. Every game is played by head direction or nod, and scores persist across sessions.

Opening Message: At the county fair with time to spare? Let's play all 20 fair games on your glasses — turn your head to aim, nod to play.

Preview Media:
- `preview-us-fair-games-index.png`
- `preview-us-fair-games-g01.png`
- `preview-us-fair-games-g02.png`
- `preview-us-fair-games-g03.png`
- `preview-us-fair-games-g04.png`
- `preview-us-fair-games-g05.png`
- `preview-us-fair-games-g06.png`
- `preview-us-fair-games-g07.png`
- `preview-us-fair-games-g08.png`
- `preview-us-fair-games-g09.png`
- `preview-us-fair-games-g10.png`
- `preview-us-fair-games-g11.png`
- `preview-us-fair-games-g12.png`
- `preview-us-fair-games-g13.png`
- `preview-us-fair-games-g14.png`
- `preview-us-fair-games-g15.png`
- `preview-us-fair-games-g16.png`
- `preview-us-fair-games-g17.png`
- `preview-us-fair-games-g18.png`
- `preview-us-fair-games-g19.png`
- `preview-us-fair-games-g20.png`

> A formal review submission needs 3–5 media files including at least 1 video (≤60 s). Video is added after GO's device recording.

Change Log — Build 1.0.0:

- Features added: First release. A family at a US county fair plays 20 fair games on one pair of glasses by head direction.
- Improvements: None (first release)
- Fixes: None (first release)
