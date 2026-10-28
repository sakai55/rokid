# Stop Motion Studio（定格工场）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-stop-motion-studio
```

AV11 · 桌前摆弄小物件/手作时，在眼镜里逐帧拍定格动画并当场合成播放。**v1.1 是极简验证版**：操作砍到只剩两个——**点头开始、说「退出」结束合成**。参数全部写死，没有任何设置页：12 帧/秒、满 120 张（约 10 秒成片）、每秒拍一张、带洋葱皮。本版只验证「拍照 → 合成播放」核心链路，深度功能仍推迟（见文末「后续」）。

## 预览截图

![预览-shoot](../../screenshots/stop-motion-studio/preview-stop-motion-studio-shoot.png)

![预览-play](../../screenshots/stop-motion-studio/preview-stop-motion-studio-play.png)

截图说明（Web 预览实测，如实）：拍摄页取景真出图（截图中为预览宿主的假相机画面），等点头状态完整渲染；合成页验证读数面板完整渲染。但预览宿主的 JPEG 编码不可用（拍帧时宿主回示 `Image encoding is not available on the Web host`），预览里拍不进帧、合成页显示 0 帧与空读数——宿主限制、页面如实回示，不是假数据，与 v1 同口径。帧编码链、ASR「退出」监听、实测帧率读数待真机回填。

## 交互（只有两个操作）

1. **点头开始**：打开就是拍摄页取景（已拍上一帧以半透明洋葱皮叠在取景上，第一帧前无叠加）。点头一次即开始自动拍摄：每 1 秒拍一帧，帧缩至 480×352 JPEG 存入会话内存；大字实时显示「已拍 X / 120 张」与预估成片秒数（张数 ÷ 12）。拍摄中点头不触发任何动作（防说「退出」时头部动作误触，沿用 benchmark 教训）。
2. **说「退出」结束合成**：拍摄中 ASR 持续监听（`SpeechRecognition`，continuous + interim），识别结果里出现「退出」二字（正式或临时结果均可）即停拍、写入作品元数据、自动跳到合成页。合成页进入即按 12 帧/秒自动循环播放；**点头 = 从头重播**，除此外无其他操作。

结束条件共 4 个，停因全部如实记录并显示在合成页：说「退出」/ 满 120 张（拍够了）/ 拍摄满 180 秒（满 3 分钟了，安全上限）/ 双击兜底。ASR 启动失败或报错时，拍摄页小字如实提示「语音退出不可用，请用双击结束」，双击（Backspace）同样走结束合成流程——这是兜底，不是第三个常规操作。

TTS 只在三处说话：开始时「开始拍摄，说退出结束合成」；拍到 60 张时「已拍一半」；结束时随停因一句（如「好的，共 N 张，开始合成」）。

## 参数（全部写死，不是设置）

- 帧率 12 帧/秒；目标张数 120 张（= 12 × 10 秒）；预估成片 = 张数 ÷ 12，满额约 10 秒。
- 拍摄间隔 1 秒/张（自动拍摄）；拍摄真实时长安全上限 180 秒（3 分钟）——指拍摄时长，不是成片时长。
- 拍摄页常驻一行小字明示：「12 帧/秒 · 满 120 张约 10 秒 · 点头开始 · 说退出合成」。

## 结构与功能（核心链路闭环）

- `pages/shoot` 拍摄（入口页）：`getUserMedia({video:true})` → `ImageCapture.grabFrame()` 取景画在页面画布上；**洋葱皮** = 上一帧以 `globalAlpha` 0.45 半透明叠加（真实 drawImage 接线）；点头开始后每秒 `grabFrame` → 画布缩至 480×352 → JPEG 编码（`convertToBlob` q0.6，无画布编码时回退全局 `createImageBlob`）→ data URL + 字节数入**共享内存** `store.js`；结束时把作品元数据写入 `av11_works`（帧率/张数/目标/停因/拍摄耗时/单帧平均 KB/总 KB/成片秒数/实测帧率待合成页回填）并跳合成页。离开页面停流、停定时器、停 ASR。
- `pages/play` 合成：进入即按 12 帧/秒逐帧解码绘制、自动循环播放——这就是「合成播放」；点头从头重播。**验证读数面板**集中显示 GO 真机要看的数据：设定帧率（12）vs **实测帧率**（按真实绘制时间戳算）、已拍张数 / 120、实际成片秒数、单帧平均 KB、帧总大小、拍摄实际耗时、停因；实测帧率回写进 `av11_works` 对应条目。

## 语音交互流

- 语音输入点：只有拍摄中的「退出」监听（`SpeechRecognition` continuous + interim，final/interim 命中「退出」均触发）。全台再无其他 ASR（设置页与语音起名已删）。
- TTS 播报节点：开始一句、60 张一句、结束随停因一句，共三处。
- 语音纠错路径：ASR 不可用时页面明示并提供双击兜底结束；识别未命中时拍摄继续，不误停。

## 手势映射

| 手势 | 键/事件 | 作用 |
|---|---|---|
| 点头 | onHeadGesture nod | 拍摄页开始拍摄；合成页从头重播；拍摄中无动作（防误触） |
| 说「退出」 | SpeechRecognition result | 结束拍摄并合成（主结束方式） |
| 双击 | Backspace | 仅兜底：ASR 不可用时结束拍摄并合成；等待开始时为系统返回 |

## 权限

- CAMERA：grabFrame 取景、洋葱皮、逐帧拍摄。
- RECORD_AUDIO：拍摄中「退出」监听（ASR 开麦）。

## 诚实边界

- **不导出视频文件**：基座没有把静帧编码成视频的文档化能力（无 canvas.captureStream / WebCodecs，Canvas 只出单帧 PNG/JPEG，MediaRecorder 只录实时流，LLM 只出文字）。「合成」就是眼镜内按 12 帧/秒播放，文案从不写「生成视频」。
- **帧只在会话内存**：帧序列存在共享内存模块里，不写任何存储；关掉本 agent 帧即丢失。持久化只有一条：作品元数据 `av11_works`（v1 的设置存储 `av11_cfg` 已随设置页删除，代码零引用）。
- 宿主无相机/ImageCapture/画布/编码/ASR 时如实回示失败，不生成假帧（Web 预览即如此）。

## 后续（核心验证通过后再做，本版未写进代码）

- 编码探针页：逐项检测 canvas.captureStream / VideoEncoder / MediaRecorder 格式，存在才真做帧序列导出视频的编码试验，结论以真机实测为准。
- 作品页与帧持久化：作品列表、<1MB 作品帧存档与回放、跨会话管理。
- LLM/ASR 融合扩展：逐帧 AI 判读等深度融合（本版的 ASR 只做「退出」一词监听，不算融合扩展）。
- 以上全部等「拍照 → 合成播放」核心链路真机验证通过后再立项。

## 设备测试信息

| 项目 | 值 |
|---|---|
| Studio name | 待导入后回填 |
| Version | 1.1.0 |
| App Category | Entertainment |
| Intent Description | Capability check of the stop-motion chain: nod to shoot at 12 fps, say the exit word to composite and loop-play with measured readings |
| Agent ID | 待回填 |
| 状态 | 未导入、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description

Stop Motion Studio is a minimal capability check of one chain: shoot stop-motion frames and composite them in the glasses. No settings: open it and you are on the shoot page, live view plus an onion-skin overlay of your last frame. Nod once and it shoots one frame per second at a fixed 12 fps, up to 120 frames (about 10 s of film). Say the exit word and it stops and loop-plays the composite, with verification readings: set vs measured fps, frame count, average and total KB, shooting time, stop reason.

### Opening Message

Hi, I'm **Stop Motion Studio**. There is nothing to set up: you are already looking through the camera, with an **onion skin** of your last frame over the view. **Nod** and I start shooting one frame per second at **12 fps**, up to 120 frames. When you are done, just say the **exit word** — I stop, composite your frames, and play them back in a loop with the readings that prove the chain works.

### Preview Media

图片 2 张见预览截图节；视频待真机阶段补。

### Change Log

#### Build 1.1.0

**Features added**

- Voice finish: while shooting, continuous speech recognition listens for the exit word; hearing it stops the take and jumps straight to the composite page.
- Double-tap fallback finish, offered on-screen only when speech recognition is unavailable or errors.

**Improvements**

- Interaction cut to two operations (GO 2026-10-28): nod to start, say the exit word to finish and composite. The settings page is gone; frame rate (12 fps), target (120 frames, about 10 s), capture interval (1 s) and the 180 s safety cap are fixed constants, stated in one small line on the shoot page.
- Shooting is fully automatic once started: no per-frame tapping, no menus on either page. The play page now starts looping on entry; nod replays from the first frame.
- TTS reduced to three moments: start, halfway (60 frames), and the finish line with the stop reason.

**Fixes**

- Removed the v1 settings leftovers end to end: speed/length/shoot-mode selectors, voice naming, delete-last-frame and retake, pause/loop switches, and the av11_cfg settings store (zero references in code).

#### Build 1.0.0

**Features added**

- Beginner settings: speed and length word tiers with the frame target computed and shown in plain words; manual or fixed-interval auto shooting; voice naming.
- Frame-by-frame shooting with live viewfinder and onion-skin overlay, spoken frame counts, and spoken stop reasons at the target count or the 3-minute safety cap.
- Composite playback page with a verification panel: set vs measured fps, frame count, average and total KB, actual shooting time and stop reason; work metadata persisted locally.

**Improvements**

- None (initial verification build).

**Fixes**

- None (initial verification build).

## 打包与预览

打包命令 `~/tools/bin/aix pack . -o stop-motion-studio.aix`（仓库副本 aix/stop-motion-studio.aix）；预览走本地截图管线（aix preview + 本地 puppeteer 截图，见 rokid-preview-screenshots skill）。
