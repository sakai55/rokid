# Stop Motion Studio（定格工场）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-stop-motion-studio
```

AV11 · 桌前摆弄小物件/手作时，免手持、免手机剪辑，在眼镜里把定格动画逐帧拍完并当场合成播放。**v1 是验证版**：只跑通「拍照 → 合成播放」这一条核心链路，并把验证读数摆在明处，等真机验证通过后再加深度功能（见文末「后续」）。

## 预览截图

![预览-index](../screenshots/stop-motion-studio/preview-stop-motion-studio-index.png)

![预览-shoot](../screenshots/stop-motion-studio/preview-stop-motion-studio-shoot.png)

![预览-play](../screenshots/stop-motion-studio/preview-stop-motion-studio-play.png)

截图说明（Web 预览实测，如实）：设置页与合成页完整渲染；拍摄页取景真出图（截图中为预览宿主的假相机画面）。但预览宿主的 JPEG 编码不可用（拍帧时宿主回示 `Image encoding is not available on the Web host`）且取景绘制间歇失败，故预览里拍不进帧、合成页显示 0 帧与空读数——这是宿主限制、页面如实回示，不是假数据。帧编码链、帧的跨页传递与实测帧率读数待真机回填。已实测跨页可见的是共享内存里的目标张数与拍摄耗时（合成页读数面板的目标 80、拍摄耗时来自拍摄页）。

## 参数（初学者版：只选两个词）

- **速度**三档：慢速 5 帧/秒 / 中速 8 帧/秒 / 快速 12 帧/秒（词为主，数字为辅）。
- **长度**三档：短 / 中 / 长，名义成片 5 / 10 / 15 秒。
- **张数不单独设**：目标张数 = min(帧率 × 名义秒数， 120)，实际成片秒数 = 目标张数 ÷ 帧率；设置页大字实时显示人话结果，如「中速 · 中 — 拍 80 张，成片约 10 秒」「快速 · 长 — 拍 120 张，成片约 10 秒」（12×15=180 被 120 封顶）。
- **拍法**二选一：手动（点一下拍一张，默认）/ 自动（固定每 2 秒一张，无间隔档位）。自动模式在设置页显示估算耗时；超过 3 分钟的组合会显示被上限截断的约拍张数（约 90 张）。
- **安全上限（不是设置）**：拍摄真实时长满 3 分钟自动停、张数到目标自动停；停时 TTS 说清停因——「拍够了」或「满 3 分钟了」（手动结束则说「拍摄结束」），停因同时记入作品元数据。
- 「最长 3 分钟」指**拍摄时长**上限，不是成片时长；成片是 5–15 秒量级。

## 结构与功能（核心链路闭环）

- `pages/index` 设置：作品名语音起名（`SpeechRecognition`，说错重说纠错，说「开始」直达拍摄页）；速度/长度/拍法三行单击切换；设置存 `av11_cfg`。
- `pages/shoot` 拍摄：`getUserMedia({video:true})` → `ImageCapture.grabFrame()` 取景画在页面画布上；**洋葱皮** = 上一帧以 `globalAlpha` 0.45 半透明叠加在当前取景上（真实 drawImage 接线）；拍一帧 = `grabFrame` → 画布缩至 480×352 → JPEG 编码（`convertToBlob` q0.6，无画布编码时回退全局 `createImageBlob` 不缩放）→ data URL + 字节数入**共享内存** `store.js`；TTS 每帧轻报张数、每 10 帧报进度；到目标张数或满 3 分钟自动停并播报停因，随后写入作品元数据 `av11_works` 并跳合成页。离开页面停流停定时器；返回时重启相机并可续拍/补拍。
- `pages/play` 合成：按设定帧率定时逐帧解码绘制播放——这就是「合成播放」；暂停/重播/循环、删最后一帧、回拍摄页补拍（同序列续拍）。**验证读数面板**集中显示 GO 真机要看的数据：设定帧率 vs **实测帧率**（按真实绘制时间戳算）、已拍张数/目标、单帧平均 KB、帧总大小、拍摄实际耗时、停因、推算成片秒数；实测帧率会回写进 `av11_works` 对应条目。

## 语音交互流

- 语音输入点：只有设置页的语音起名（v1 唯一的 ASR，成本低、是主交互）；拍摄页无 ASR 口令（已按验证版范围砍掉）。
- TTS 播报节点：参数切换（速度/长度/拍法）、起名成功、每帧报数、每 10 帧进度、自动开始、停因播报（拍够了/满 3 分钟了/拍摄结束）、播放结束。
- 语音纠错路径：起名说错直接重说覆盖；参数说错无此问题（全是单击切换）。

## 手势映射

| 手势 | 键/事件 | 作用 |
|---|---|---|
| 单击 | Enter | 主动作：切换参数 / 起名 / 拍一帧 / 启停自动 / 播放暂停 / 删帧 |
| 上滑/下滑 | ArrowUp / ArrowDown | 移动行选择 |
| 点头 | onHeadGesture nod | 拍摄页拍一帧；合成页播放/暂停；设置页同单击 |
| 双击 | Backspace | 系统返回（页面不拦截） |

## 权限

- CAMERA：grabFrame 取景、洋葱皮、逐帧拍摄。
- RECORD_AUDIO：设置页语音起名（ASR 开麦）。

## 诚实边界

- **不导出视频文件**：基座没有把静帧编码成视频的文档化能力（无 canvas.captureStream / WebCodecs，Canvas 只出单帧 PNG/JPEG，MediaRecorder 只录实时流，LLM 只出文字）。v1 的「合成」就是眼镜内按帧率播放，文案从不写「生成视频」。
- **帧只在会话内存**：帧序列存在共享内存模块里，不写任何存储；关掉本 agent 帧即丢失。持久化只有两条：设置 `av11_cfg` 与作品元数据 `av11_works`（名/帧率/张数/目标/停因/拍摄耗时/单帧平均 KB/总 KB/成片秒数/实测帧率）。
- 宿主无相机/ImageCapture/画布/编码时如实回示失败，不生成假帧（Web 预览即如此）。

## 后续（核心验证通过后再做，本版未写进代码）

- 编码探针页：逐项检测 canvas.captureStream / VideoEncoder / MediaRecorder 格式，存在才真做帧序列导出视频的编码试验，结论以真机实测为准。
- 作品页与帧持久化：作品列表、<1MB 作品帧存档与回放、跨会话管理。
- LLM/ASR 融合扩展：拍摄页语音口令、逐帧 AI 判读等深度融合。
- 以上全部等「拍照 → 合成播放」核心链路真机验证通过后再立项。

## 设备测试信息

| 项目 | 值 |
|---|---|
| Studio name | 待导入后回填 |
| Version | 1.0.0 |
| App Category | Entertainment |
| Intent Description | Shoot a stop-motion sequence frame by frame and play it back in the glasses with verification readings |
| Agent ID | 待回填 |
| 状态 | 未导入、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description

Stop Motion Studio is a verification build of one core chain: shoot a stop-motion sequence frame by frame and play it back in the glasses. Pick just two words, a speed (slow 5, mid 8, fast 12 fps) and a length (short, mid, long), and the frame target is computed for you. The shoot page shows a live view with an onion-skin overlay of the previous frame; shooting stops by itself at the target or at three minutes and says why. The play page is the composite: it plays the frames at the chosen rate and shows verification readings, set vs measured fps, frame count, average KB per frame and total size.

### Opening Message

Hi, I'm **Stop Motion Studio**. Pick a **speed** and a **length** — I work out the frames myself. On the shoot page you'll see an **onion skin** of your last frame over the live view; tap or nod for each frame, or switch to auto. I stop on my own when the frames are done or three minutes are up, and the play page **composites your clip** and shows the readings that prove it worked.

### Preview Media

图片 3 张见预览截图节；视频待真机阶段补。

### Change Log

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
