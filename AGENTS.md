# 场景记忆 Scene Memory — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA45: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与注意力系列 day-lookback（日终回看当天登记内容的日记工具）的区别：day-lookback 是回放你一天真实记录的生活工具；本作是当场拍、当场出题、当场转头答题的记忆游戏，照片与题目都只活在本局内存，关掉即没。

## Design contract

1. 先对准一个真实场景（桌面、书架、房间一角）拍一张全景照（wide）。大模型看着这张首图当场出 3 道记忆题并定死正确答案（问题只问画面里确实可见的物品、颜色、数量、位置）。
2. 出题后转过头去、不再看那个场景，凭记忆答题：每题的 3 个选项就是 3 道题的正确答案（按题号轮转排列），考的是「哪个答案配哪道题」。滑动选、单击或点头确认，即时判对错并播报正解。
3. 3 题答完结算。出题失败（大模型不可用或没按格式出题）会如实显示「出题失败 · 可重拍」，绝不编题；可重拍一张重新出题。

- **Judge chain.** takePhoto(wide) → Blob 经 `arrayBuffer()` + 分块 `String.fromCharCode` + `btoa` 转 data: URL（转码失败带 E2005、记判定失败）→ LanguageModel 图片输入，要求只回 3 行 `Qn: 问题 | An: 答案`，本地正则解析并把答案定死；答题阶段全本地比对，不再调大模型。 A "判定中…" waiting state is
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
- **Gestures.** Tap (Enter) = 开始 / 拍场景照出题 / 确认答案 / 再来一局. Swipe (ArrowUp/Down) =
  移动答案选项. Nod = 答题阶段 = 确认所选答案. Double-tap (Backspace) is the host's back,
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

- 题目质量取决于大模型看首图的准确度：它看错了画面，题目与「正解」就会一起错——这是写明的已知边界，判分口径是「以首图判定为准」，不假装客观真理。
- 照片只在内存里出题，不落盘；答题选项就是三题的正解集合，玩家若记住了答案内容却配错题，照样判错——规则在 UI 与本文件写明。
- 判定（出题）仅供娱乐，有争议以玩家目测为准。
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
- `aix pack` run LAST, after README/AGENTS were final (13.89 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
