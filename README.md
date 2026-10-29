# System Audio Capture（内录转写台）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-system-audio-capture
```

**AIX 直接下载**（最新版）：[system-audio-capture.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/system-audio-capture.aix)

AV10 · 把设备自己正在播放的声音（视频课、播客、语音播报）内录下来、分片喂进识别会话转成文字稿并归档，顶边界 B10 内录→外部流转写链 + B4 内录纪律。

## 预览截图

![预览-index](../screenshots/system-audio-capture/preview-system-audio-capture-index.png)
![预览-capture](../screenshots/system-audio-capture/preview-system-audio-capture-capture.png)
![预览-transcribe](../screenshots/system-audio-capture/preview-system-audio-capture-transcribe.png)
![预览-archive](../screenshots/system-audio-capture/preview-system-audio-capture-archive.png)

## 结构与功能（闭环）

四页闭环：来源门 → 内录 → 转写 → 归档。

- **来源门（pages/index）**：中枢菜单。Enter 选「探测来源」只发一个请求：`getUserMedia({audio:{captureSource:'system-audio'}})`。纪律（代码注释与 UI 同文）：绝不带麦克风模式参数、绝不带回声消除约束、失败永不回退麦克风。成功后回读 `track.getSettings()` 显示 `captureSource` 实际值；再用 Analyser 读 1 秒 RMS，≈0 时提示「当前无播放声（静音）」。探测完自动关流。
- **内录（pages/capture）**：沿用来源门纪律独立开流（每页独立开流，不跨页传流）。`MediaRecorder` 先查 `isTypeSupported('audio/ogg;codecs=opus')`，支持用之、不支持回退默认并上屏标注；`start(250)` 分片，计数与字节累计实时上屏；Analyser 电平块列实时显示，证明来源是播放声。Enter 停录后汇总 Blob——Blob 不能直接进 wx storage，转 dataURL 存临时键 `av10_tmp`（页间传参，非持久化声明项）。大小上限风险如实标注：录音超 500KB 时明示「过长，dataURL 可能存不下」，写入失败如实报错；超长仅保留前段转写路径为 placeholder（见诚实边界）。
- **转写（pages/transcribe）**：会话不开麦（页面明示）。从临时键 dataURL 用 `atob` 解 base64 自行组回 Blob（不依赖 `fetch(dataURL)`）；新建 `SpeechRecognitionSession({lang:'zh-CN', interimResults: 查 getCapabilities 后定})`；录音按 `maxChunkBytes=16384` 切片，串行 `writer.write(每片)` 后 `writer.close()`；`onresult` 的 interim/final 实时上屏成文字稿，定稿存回临时键。整链分环节命名（还原录音/建会话取 writer/分片写入），任一步失败如实标环节名，不编造文字稿。
- **归档（pages/archive）**：Enter 把 {时间, 时长估算, 转写全文, 字节} 写入持久化 `av10_archive`；时长估算优先走解码实测，失败如实写未知。列表回看。回放原录：dataURL → atob 还原 Blob → `arrayBuffer` → `AudioContext.decodeAudioData` → `createBufferSource` 播放（可 stop），页面标注此为 Web Audio 解码播放路径。

与会议转写的区别（来源门明示）：录的是设备自身播放声、非环境会议声；来源不对，整台不开工，也永不偷偷改用麦克风冒充内录。

## 语音交互流

- 来源确认：来源门探测成功后 TTS 播报「内录来源已确认」。
- 录制反馈：开录/停录完成时 TTS 播报「内录开始 / 内录完成」。
- 转写反馈：转写出定稿后 TTS 播报「转写完成」；无定稿时不播报成功、页面如实说明。
- 归档反馈：归档成功 TTS 播报「已归档」。
- 本台的「语音」本体是被录的播放声与转写稿，不设 ASR 口令输入；TTS 用宿主固定音色，不设 `lang`（转写会话的 `lang:'zh-CN'` 是识别会话参数，与 TTS 无关）。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 作用 |
|---|---|---|
| 单击 | Enter | 执行选中/焦点动作（探测来源、开录/停录、开始转写、归档等主动作） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 移动菜单选中态 / 切换子页焦点动作 |
| 点头 | `onHeadGesture('nod')` | 与主确认等价 |
| 双击 | Backspace | 系统返回（子页另有 BACK 钮） |

## 权限

- `RECORD_AUDIO`：内录来源流（`captureSource:'system-audio'`）的开启与录制。无 `CAMERA`、无 `GEOLOCATION`。

## 诚实边界

- 来源纪律是硬约束：请求失败（例如 `OverconstrainedError`）只如实显示错误并停工，永不回退麦克风；`getSettings()` 未回报字段时如实写「未回报」，不假装已确认。
- 录音经 dataURL 过临时键是页间传参方案，有大小上限：超 500KB 已上屏警告，wx 存储写入失败时如实报错；超长录音「仅保留前段转写」目前是 placeholder——转写页对已存入的录音全量分片，不做截断承诺。
- placeholder 点名：`SpeechRecognitionSession` 的 writer 获取按 `session.writer` / `createWriter()` / `writable.getWriter()` 三种形态依次尝试，宿主实际形态与 `onresult` 事件形状需真机回填验证；任一形态不合时转写在「建会话/取 writer」环节如实失败。Web 预览无内录来源时各步如实失败。
- 转写质量取决于宿主识别会话对喂入音频的支持，本台只保证分片链路与失败可见，不保证识别准确率。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | System Audio Capture（待回填） |
| Version / Build | 1.0.1 |
| App Category | 待回填（导入时确认） |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未导入 |

## 提审资料 (Review Submission)

### Feature Description

Record what the device itself is playing, never the room: a source gate that requests only the system-audio capture source and refuses any microphone fallback, chunked recording with a live level meter, a recognition session fed chunk by chunk with your recording, and an archive with decode playback.

### Opening Message

**System Audio Capture.** Play something on the device, prove the source at the gate, record it in chunks, and I will transcribe the recording and file it with its playback.

### Preview Media

图片 4 张（见本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 四页新作（来源门纪律探测/分片内录/会话分片转写/归档回放）；内录来源硬纪律与 Web Audio 解码回放。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

#### Build 1.0.1
- Features added: 无。
- Improvements: 无。
- Fixes: 删除 FileReader（Ink 运行时不存在，真机必死）：录音 Blob→dataURL 改走官方文档路径 `blob.arrayBuffer()` + 分块 `btoa`，失败路径接全局错误码 E2005 并在状态行显示。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o system-audio-capture.aix`（仓库副本按规矩放 `aix/system-audio-capture.aix`）
- 预览：`~/tools/bin/aix preview .` 后走本地截图管线生成 4 页预览图，存入仓库 `screenshots/system-audio-capture/`。
