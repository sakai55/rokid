# 条码宾果 Barcode Bingo — Agent Notes

AIUI Agent for Rokid glasses (single page, `pages/index/index`).
Photo-interaction game series GA44: a real-world photo game -
winning each round is judged from a photo of the player's actual
surroundings, never from on-screen pretend play.

与指向性系列 parcel-sort（扫码分拣包裹的登记工具）的区别：parcel-sort 是把包裹码登记归类的活儿；本作不登记任何内容，只认码制填格凑线，是宾果游戏。检测到的码内容只在判定行里短暂显示前 18 字，不保存。

## Design contract

1. 3×3 宾果盘固定 9 个码制格：二维码、商品码13、条码128、商品码8、条码39、UPC-A、数据矩阵、库德巴、PDF417。在身边实物（包装、书、票据、设备标签）上找条码，对准单击扫码。
2. 拍照（wide）后用原生 BarcodeDetector 检测码制：命中未填格就填格 ✓；重复码制或盘上没有的码制，本次计次但不填格；没扫到码不计次可重扫。最多扫 12 次，填满 9 格提前结束。
3. 计分 = 填格数 + 连线数 × 3（行/列/对角共 8 条线）。点头播报当前盘面（已填几格、几线、已扫几次）。

- **Judge chain.** takePhoto(wide) → Blob → createImageBitmap → 原生 BarcodeDetector.detect() 读 format；不用大模型判定（本系列唯一例外，PLAN 指定）。扫不到码不计次，格式以检测返回的 format 名为准。 A "判定中…" waiting state is
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
- **Gestures.** Tap (Enter) = 开始 / 扫码 / 再来一局. Swipe (ArrowUp/Down) =
  不用滑动. Nod = 播报盘面（已填格数 / 连线数 / 已扫次数）. Double-tap (Backspace) is the host's back,
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

- 码制名以 BarcodeDetector 返回的 format 为准；宿主支持的码制以 getSupportedFormats 为上限，盘上某种码制若宿主不支持检测，就永远填不上——真机首测要先核对 9 种码制的支持情况，如实记录。
- 同一实物上的码只能提供它自身的码制，凑满盘需要真的找齐不同码制的实物；照片不保存，码内容不落盘。
- 本机无 BarcodeDetector 时明示不可用，只提供标注的演示局，绝不假装扫到码。
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
- `aix pack` run LAST, after README/AGENTS were final (13.52 KB);
  `aix list` verified the pack contains README.md and AGENTS.md.
- Not yet verified on a real device: camera quality, real LLM
  judging latency/accuracy, TTS delivery. Device testing and
  review submission are GO-gated.
