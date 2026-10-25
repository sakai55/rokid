# 文字猎手 Word Spot — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA43: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与指向性系列 DI sign-reader（读招牌工具）的区别：sign-reader 是把远处招牌全文读给你的出行工具；本作只判「目标字符在不在画面文字里」并计分，是找字游戏，读出的文字仅作判定凭据展示。

## Design contract

1. 每轮出一个目标字符（固定顺序：数字 7 → 字母 A → 数字 3 → 汉字「门」→ 字母 S），在招牌、门牌、包装、书脊上找到它，对准拍清楚，单击拍照。
2. 大模型判定同时读出画面主要文字（TEXT 行）并显示在判定结果里，玩家可当场核对它到底读到了什么——读错了一眼可见。命中 +1。
3. 滑动可先跳到另一未拍字符轮；判定后点头 = 记录申诉（不改分）；大模型不可用/格式不对，该轮如实记判定失败。

- **Judge chain.** takePhoto(default) → FileReader data: URL → LanguageModel 图片输入（平台无 OCR API，这是官方读字路径）；只回 `VERDICT:` + `TEXT:`（读到的主要文字）+ `REASON:` 三行，本地解析并展示 TEXT 供核对。 A "判定中…" waiting state is
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

- 平台没有 OCR API：所谓读字就是拍照 + 大模型图片输入，可能读错形近字（如 S 与 5、7 与 1）；判定结果展示它读到的文字，玩家可核对，申诉只记录不改分。
- 判定仅供娱乐，有争议以玩家目测为准；照片只在内存判定，不落盘。
- 不拍他人正脸作判定对象：目标是招牌、门牌、包装上的字。
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
- `aix pack` run LAST, after README/AGENTS were final (14.10 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
