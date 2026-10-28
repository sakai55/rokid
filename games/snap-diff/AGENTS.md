# 两拍找不同 Snap Diff — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA50: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与注意力系列 proof-sweep（文字校对找错工具）的区别：proof-sweep 是对着文稿找文字差错的工作工具；本作找的是真实场景两拍之间的实物变化，是先声明后判定的找不同游戏，照片不用于任何校对留档。

## Design contract

1. 一局两拍：先对准一个场景拍第一张；然后动手只改一处（拿走一件 / 放进一件 / 挪动一件）。
2. 先声明：滑动选你改了哪类（少了一件 / 多了一件 / 一件移位），单击或点头确认——声明先定死，再回到原机位拍第二张。
3. 两张照片同送一次大模型判定，大模型回 `TYPE:`（它判的改动类）+ `DIFF:`（一句话说清差异），本地拿 TYPE 与你的声明比对：说中 +1，判定看出的差异原话会显示出来。3 局结算。本作是拍照游戏系列（GA41–GA50）的收官作。

- **Judge chain.** 两张 takePhoto(default) 照片各经 `arrayBuffer()` + 分块 `String.fromCharCode` + `btoa` 转 data: URL（任一转码失败带 E2005、记判定失败），在同一次 LanguageModel prompt 里以两个 image_url part 一起送出（多模态 user 消息支持多图 part）；只回 `TYPE:` + `DIFF:` 两行，本地比对 TYPE 与玩家声明。判定回 NONE（看不出差异）记没说中并写明。 A "判定中…" waiting state is
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
- **Gestures.** Tap (Enter) = 开始 / 拍第一张 / 确认改动 / 拍第二张判定 / 下一局 / 再来一局. Swipe (ArrowUp/Down) =
  声明阶段移动改动类选项. Nod = 声明阶段 = 确认所选；判定显示后 = 记录申诉（不改分）. Double-tap (Backspace) is the host's back,
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

- 双图对比对机位一致性敏感：第二张拍偏了，大模型可能把视角差当成变化，或看不出真变化而回 NONE——判定行会原样展示它的 DIFF 说明，玩家可核对；规则要求「回到原机位」写在 UI 里。
- 两张照片都只存本局内存，不落盘；娱乐判定、以玩家目测为准，申诉（判定后点头）只记录不改分。
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
- `aix pack` run LAST, after README/AGENTS were final (14.04 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
