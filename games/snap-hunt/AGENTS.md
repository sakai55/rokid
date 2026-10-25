# 拍物寻宝 Snap Hunt — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA41: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与注意力系列 home-find（找物登记工具）的区别：home-find 是把常找物品的位置登记下来日后查询的生活工具；本作是当场出题、当场拍照判定计分的寻宝游戏，不登记、不查询。

## Design contract

1. 屏幕一次给出一个目标物（固定顺序：红色杯子 → 一本书 → 一把钥匙 → 一把椅子 → 一瓶水），语音同步播报。在真实环境里找到它，对准，单击镜腿拍照。
2. 照片经 FileReader 转 data: URL 送宿主大模型图片输入，大模型只回固定格式 `VERDICT: YES/NO` + 一句理由，本地解析计分：命中 +1。判定中会显示「判定中…」等待态。
3. 滑动可先跳到另一个未拍的目标（已判定的不能重拍）；判定后点头 = 记录申诉（只记录次数，永不改分）；大模型不可用或回答格式不对时，该轮如实记「判定失败 · 本轮不计分」。

- **Judge chain.** takePhoto(default) → Blob → FileReader data: URL → LanguageModel 图片输入；提示词要求只回 `VERDICT:` + `REASON:` 两行，本地正则解析 VERDICT 行计分。 A "判定中…" waiting state is
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

- 判定靠大模型图片输入，可能因光线、角度、遮挡判错；UI 与本文件均写明「判定仅供娱乐，有争议以玩家目测为准」，申诉只记录不改分。
- 照片只在内存里转 data: URL 判定，不落盘、不上传自有服务器（大模型为宿主托管通道）。
- 不拍他人正脸作判定对象：五个目标全是物。
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
