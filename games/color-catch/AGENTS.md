# 颜色捕手 Color Catch — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA42: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与路缘坡系列 CC04 color-order-check（按色序核对物品的辅助工具）的区别：那是给特定人群核对一排物品颜色顺序的工具；本作是出题—找色—拍照判定的计分游戏，判的是主体物主色，不是顺序核对。

## Design contract

1. 每轮出一种颜色（固定顺序：红 → 黄 → 蓝 → 绿 → 橙 → 紫），语音同步播报。找一个以该颜色为主色的真实物体，对准占满画面，单击拍照。
2. 判定看的是主体物的主色：画面角落里有一点该颜色不算命中。照片送大模型图片输入，只回 `VERDICT:` + `REASON:`，本地解析计分，命中 +1。
3. 滑动可先跳到另一未拍颜色轮；判定后点头 = 记录申诉（不改分）；大模型不可用/格式不对，该轮如实记判定失败。

- **Judge chain.** takePhoto(default) → Blob 经 `arrayBuffer()` + 分块 `String.fromCharCode` + `btoa` 转 data: URL（转码失败带 E2005、记判定失败）→ LanguageModel 图片输入；提示词写明「主体物主色」口径，只回 `VERDICT:` + `REASON:` 两行，本地解析。 A "判定中…" waiting state is
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

- 眼镜屏幕是单色绿，但相机照片是真实彩色，判定基于照片而非屏幕所见；颜色口径（主体物主色）在提示词里写死。
- 大模型对相近色（橙/粉、蓝/紫）可能判错；写明娱乐判定、以玩家目测为准，申诉只记录不改分。
- 照片只在内存判定，不落盘。
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
- `aix pack` run LAST, after README/AGENTS were final (13.87 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
