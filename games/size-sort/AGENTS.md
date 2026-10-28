# 大小排序 Size Sort — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA48: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与指向性系列 shelf-compare（货架商品登记比对工具）的区别：shelf-compare 是把商品信息拍下来比价比参数的购物工具；本作判的是三个同类物的相对大小顺序，是先猜后判的排序游戏，不登记商品信息。

## Design contract

1. 每局指定一类物品（固定 4 局：杯子 → 书 → 瓶子 → 鞋）。找 3 个同类、大小有别的实物，从左到右摆开，位置编号 1、2、3。
2. 先排：滑动在 6 种排列里选你认为的「从大到小」位置序（如 2,1,3 = 中间最大、左边第二、右边最小），单击或点头确认——先定死再拍照。
3. 大模型回 `ORDER:`（它看到的从大到小位置序）+ 一句理由，本地全序比对：完全一致才算猜中 +1，差一位也不算（结果行会同时写出判定顺序与你的顺序）。

- **Judge chain.** takePhoto(default) → Blob 经 `arrayBuffer()` + 分块 `String.fromCharCode` + `btoa` 转 data: URL（转码失败带 E2005、记判定失败）→ LanguageModel 图片输入，只回 `ORDER:`（位置序号的排列）+ `REASON:`；本地校验必须是 1/2/3 的有效排列再与猜测全等比对，无效排列记判定失败。 A "判定中…" waiting state is
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

- 大小口径是「在画面里的视觉大小」（占画面大小/高度），不是实物真实尺寸：摆得离镜头近会显得大——这是写明的规则，玩家摆位时应让三件物品大致在同一排、同一距离，判定结果行写明理由供核对。
- 全序一致才得分，口径严格且写死；娱乐判定、以玩家目测为准，申诉只记录不改分。照片只在内存判定，不落盘。
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
- `aix pack` run LAST, after README/AGENTS were final (14.17 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
