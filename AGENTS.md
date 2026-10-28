# 找不同类 Odd One Out — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA47: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与 JP 系列 gomi-sort（垃圾分类投放辅助）的区别：gomi-sort 是教你把垃圾分对类的生活工具；本作是玩家自己摆局、先下注猜测、再拍照揭晓的对赌式找茬游戏，分类只作裁判口径。

## Design contract

1. 每局给出布置（固定 4 局：水果组混文具、餐具组混玩具、文具组混厨具、鞋组混帽子）。把 4 件实物从左到右摆开。
2. 先猜：滑动选「第几个是不同类」，单击或点头确认——猜测先定死，拍照后不许改口。然后对准 4 件物品拍照。
3. 大模型回 `ODD:`（不同类的位置）+ `ITEMS:`（从左到右 4 件物品名），本地拿 ODD 与你的猜测比对：猜中 +1。判定念出的物品清单会显示出来，它认错了物品一眼可见。

- **Judge chain.** takePhoto(default) → Blob 经 `arrayBuffer()` + 分块 `String.fromCharCode` + `btoa` 转 data: URL（转码失败带 E2005、记判定失败）→ LanguageModel 图片输入，只回 `ODD:` + `ITEMS:` 两行；本地解析位置与猜测比对计分。没给有效位置（0 或格式不对）记判定失败。 A "判定中…" waiting state is
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
- **Gestures.** Tap (Enter) = 开始 / 确认猜测 / 拍照判定 / 下一局 / 再来一局. Swipe (ArrowUp/Down) =
  移动猜测选项. Nod = 猜测阶段 = 确认猜测；判定显示后 = 记录申诉（不改分）. Double-tap (Backspace) is the host's back,
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

- 位置口径是从照片画面左到右数，玩家摆位时若没拉开间距或物品重叠，大模型可能数错位：判定行展示它认出的 4 件物品清单供核对；娱乐判定、以玩家目测为准，申诉（判定后点头）只记录不改分。
- 类别边界（如番茄算水果还是蔬菜）以大模型判定为准并写明，这正是本游戏的争议乐趣来源，但不假装客观。照片只在内存判定，不落盘。
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
- `aix pack` run LAST, after README/AGENTS were final (14.13 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
