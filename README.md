# Mic Mode Arena（四麦同台）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-mic-mode-arena
```

**AIX 直接下载**（最新版）：[mic-mode-arena.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/mic-mode-arena.aix)

AV04 · 同一环境里四种麦克风模式同句实测，用实测电平排出「这个环境该用哪种模式」并跨会话记住。顶边界 B4：麦克风四模式（wearer / far-field / near-field / omnidirectional 的 exact→ideal 回退与 getSettings 回读）。

## 预览截图

![预览-index](../screenshots/mic-mode-arena/preview-mic-mode-arena-index.png)

![预览-rounds](../screenshots/mic-mode-arena/preview-mic-mode-arena-rounds.png)

![预览-board](../screenshots/mic-mode-arena/preview-mic-mode-arena-board.png)

![预览-memory](../screenshots/mic-mode-arena/preview-mic-mode-arena-memory.png)

## 结构与功能（闭环）

- `pages/index` 环境选择：内容集 3 环境常驻（街头 / 会议室 / 近耳语），菜单首行切换环境、选中环境写入 `av04_env`；说明文案明示——麦克风模式只对 `getUserMedia` 生效、宿主 ASR 不吃模式、转写仅作参考分。
- `pages/rounds` 四轮录制：测试句内容集 4 句常驻数组，TTS 领读当前句；四模式 `['wearer','far-field','near-field','omnidirectional']` 轮流——每轮真实接 `getUserMedia({audio:{microphoneMode:{exact:mode}}})`，遇 `OverconstrainedError` 回退 `{ideal:mode}` 并在该轮结果标注「exact 不支持，已回退 ideal」；`track.getSettings()` 回读实际 microphoneMode；`MediaRecorder` 录测试句约 3 秒（`audio/ogg;codecs=opus` 若 `isTypeSupported` 否则宿主默认）；录完 Blob 用 `AudioContext.decodeAudioData` 解码，直接对解码后 channel data 计算 RMS/峰值（方法在代码注释与本节写明）；每轮存 `{mode, settings 回读, rms, peak}` 到 `av04_rounds`；`SpeechRecognition` 同步听写一句作参考分（识别字数，仅参考，页面标注，不参与排名）。
- `pages/board` 评分榜：四轮按综合分（RMS + 峰值×0.25）排序成榜 + 结论（当前环境最佳模式），TTS 播报，Enter/点头把结论写入 `av04_best[环境]=模式`。
- `pages/memory` 环境记忆：读 `av04_best` 三环境最佳模式列表（未测显示「未测」），滑动选环境、单击播报，可清空。

## 语音交互流

- TTS 领读：每轮开始先播报「请跟读：<测试句>」，佩戴者跟读同一句，保证四轮输入可比；LEAD 按钮可重听领读——听错/没听清时重读当前句再开录即纠错路径。
- 参考转写：每轮 `SpeechRecognition` 同步听写并显示字数，仅作参考分；纠错口径——转写失败如实标注且不影响电平排名，模式优劣只由实测 RMS/峰值决定。
- TTS 播报节点：环境切换、每轮完成（模式名）、评分榜结论、环境记忆选中项。
- 宿主 ASR 说明：宿主识别不吃麦克风模式（index 页明示），本 Agent 绝不暗示「换模式能让宿主识别更准」。

## 手势映射

| 手势 | 键/事件 | 作用 |
|---|---|---|
| 单击 | Enter | 主动作：切环境 / 开始本轮录制 / 保存最佳模式 / 播报 |
| 上滑/下滑 | ArrowUp / ArrowDown | 移动菜单/记忆选择；rounds 页为重听领读 |
| 点头 | onHeadGesture nod | 主确认（与 Enter 同效：开录、保存结论） |
| 双击 | Backspace | 系统返回（页面不拦截）；子页另有 BACK 按钮 |

## 权限

- RECORD_AUDIO：四模式取流（getUserMedia microphoneMode）、测试句录制（MediaRecorder）、参考转写（SpeechRecognition）与 TTS 领读的音频链路。

## 诚实边界

- 无 placeholder 假数据：取流失败的轮次如实记 0 电平与失败原因并照常进榜尾，不伪造电平。
- exact 回退如实标注：某模式 exact 不支持时回退 ideal 并在该轮与榜单行同时标注，排名用的是回退后的实测电平。
- 参考分边界：SpeechRecognition 字数仅参考、不参与排名；宿主 ASR 不吃麦克风模式，文案明示。
- 电平方法明示：RMS/峰值来自 decodeAudioData 解码后 channel data 的直接计算，非 AnalyserNode 实时估值；解码失败如实标注该轮方法失败。

## 设备测试信息

| 项目 | 值 |
|---|---|
| Studio name | 待导入后回填 |
| Version | 1.0.0 |
| App Category | Work |
| Intent Description | Measure all four microphone modes per environment and remember the best |
| Agent ID | 待回填 |
| 状态 | 未导入、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description

Mic Mode Arena settles which microphone mode fits your environment. In street, meeting-room and near-whisper settings it runs the same test sentence through all four official modes - wearer, far-field, near-field and omnidirectional - falling back from exact to ideal when a mode is unsupported, reading back the actual mode from track settings, and measuring RMS and peak from each decoded recording. Modes are ranked per environment and the winner is remembered.

### Opening Message

Hi, I'm **Mic Mode Arena**. Choose an environment — **street, meeting room or near-whisper** — and I'll lead you through the same test sentence **four times, once per microphone mode**, measure the real levels, and rank them. The best mode for each environment is **remembered** for next time. Note: modes apply to recorded audio only; the host's own speech recognition is just a reference score here.

### Preview Media

图片 4 张见预览截图节；视频待真机阶段补。

### Change Log

#### Build 1.0.0

**Features added**

- Four-mode rounds in three environments with exact-to-ideal fallback and getSettings readback per round.
- RMS/peak measurement from decodeAudioData channel data, ranked board with a spoken best-mode conclusion.
- Cross-session per-environment best-mode memory, with host-ASR reference transcription kept unranked.

**Improvements**

- None (initial build).

**Fixes**

- None (initial build).

## 打包与预览

打包命令 `~/tools/bin/aix pack . -o mic-mode-arena.aix`（仓库副本 aix/mic-mode-arena.aix）；预览命令说明走本地截图管线（aix preview + 本地 puppeteer 截图，见 rokid-preview-screenshots skill）。
