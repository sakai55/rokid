# 质地猎手 Texture Hunt — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA49: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与注意力系列 plant-doctor（看叶片判植物状态的养护工具）的区别：plant-doctor 是对着植物做健康判断的生活工具；本作判的是任意实物表面的质地类别，是找质地计分游戏，不做任何诊断。

## Design contract

1. 每轮出一种质地（固定顺序：木纹 → 金属 → 布料 → 玻璃 → 纸），语音同步播报。找一处该质地的实物表面，凑近让表面占满画面，单击拍照。
2. 判定看的是表面质地本身（纹理与材质），不是物体名称：一张木桌拍远了只看到「桌子」不一定过，凑近拍出木纹才算。照片送大模型，只回 `VERDICT:` + `REASON:`，本地解析，命中 +1。
3. 滑动可先跳到另一未拍质地轮；判定后点头 = 记录申诉（不改分）；大模型不可用/格式不对，该轮如实记判定失败。

- **Judge chain.** takePhoto(default) → FileReader data: URL → LanguageModel 图片输入；提示词写明「判表面质地（纹理与材质），不看物体名称」，只回 `VERDICT:` + `REASON:` 两行，本地解析。 A "判定中…" waiting state is
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

- 质地判定对拍摄距离敏感：太远看不清纹理会被判 NO，判定理由会写明——这属于玩法本身（凑近拍），不是隐藏规则，UI 已明示。仿真材质（如木纹贴纸）按画面质地判，判定可能与真实材质不符，写明娱乐判定、以玩家目测为准。
- 照片只在内存判定，不落盘；不拍他人正脸作判定对象。
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
- `aix pack` run LAST, after README/AGENTS were final (13.96 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
