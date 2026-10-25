# 对框取景 Frame Align — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA46: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与 games 系列 photo-level（拍照水平校准玩法）的区别：photo-level 判的是画面水平不水平；本作判的是目标物落在九宫格哪一格，是构图对位游戏，不测水平。

## Design contract

1. 每轮给一个构图任务（固定顺序：书→左上、椅子→右上、杯子→正中、水瓶→左下、植物→右下），屏幕九宫格高亮目标格，语音同步播报。
2. 靠挪动物体或转头取景，把目标物主体挪进高亮格，单击拍照。大模型只报告它看到的区域代码（ZONE: TL/TC/TR/ML/C/MR/BL/BC/BR，找不到回 NONE），命中与否由本地拿 ZONE 与目标格比对计分——判定结果里会写明「判定位置 X（目标 Y）」。
3. 滑动可先跳到另一未做构图轮；判定后点头 = 记录申诉（不改分）；大模型不可用/没给 ZONE，该轮如实记判定失败。

- **Judge chain.** takePhoto(default) → FileReader data: URL → LanguageModel 图片输入，只回 `ZONE:` + `REASON:` 两行；本地把 ZONE 与本轮目标格比对计分（大模型只报位置，不直接判输赢）。 A "判定中…" waiting state is
  shown for the whole capture+judge duration; every verdict is
  spoken via TTS.
- **Judge failure is a failed round, honestly.** If the model is
  unavailable, errors, or answers off-format, the round is recorded
  as 判定失败 (no points) - never silently re-judged or faked. A
  capture failure (timeout etc.) does NOT consume the round; the
  player may retry the snap.
- **Appeals never change the score.** Where this game defines a
  nod after a verdict, the nod only increments an in-memory appeal
  counter shown on the done screen.
- **Gestures.** Tap (Enter) = 开始 / 拍照判定 / 下一轮 / 再来一局. Swipe (ArrowUp/Down) =
  切换到上一个 / 下一个未判定目标（已判定的不重拍）. Nod = 判定显示后 = 记录申诉（只记次数，永不改分）；判定前 = 重读本轮目标. Double-tap (Backspace) is the host's back,
  never intercepted.
- **DEMO is a labeled preview path only.** The DEMO key starts a
  demo game whose verdicts come from a fixed preset sequence in the
  code (marked 演示局 on screen and on the done screen). It exists
  because the web preview host has no real camera/LLM judging; on
  a real device the main button runs the true photo path.
- **Zero persistence.** No storage APIs anywhere; score, round
  state and photos live in page memory only. Photos are converted
  to data: URLs in memory for the judge and never saved.

## Technical honesty

- 九宫格是按画面平均三等分的粗格，物体跨格时以「主体所在格」为准，大模型报的格与玩家目测可能差一格：写明娱乐判定、以玩家目测为准，申诉只记录不改分。
- 屏幕上的格是屏幕坐标，不是空间锚定：头一转格就跟着转，对位靠的是拍照那一瞬间的位置。照片只在内存判定，不落盘。
- No continuous video understanding exists on this platform; each
  round is one discrete photo judgement (stream-probe's measured
  conclusion). No OCR API: reading text = photo + LLM image input.
- The judge can be wrong (light, angle, occlusion). The UI and
  README state: judging is for entertainment; the player's own
  eyes win disputes.

## Permissions

`CAMERA` only. The code uses no geolocation and no microphone
capture (TTS needs no RECORD_AUDIO), so nothing else is declared.

## Validation

- Static check: app.json/package.json parse; extracted
  `<script setup>` and app.js pass `node --check`; no legacy
  `Page(`/`App(`/`Widget(`; permissions match features used
  (CAMERA only); CSS green scale only (brightest `#7dff9e`, no
  `#ffffff`, no white rgba).
- Web-preview drive: DEMO path played end-to-end in the local Ink
  runtime; ready / playing / done screenshots read back and
  confirmed distinct and truthful.
- `aix pack` run LAST, after README/AGENTS were final (14.09 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
