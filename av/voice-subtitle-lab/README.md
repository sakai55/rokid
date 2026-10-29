# Voice Subtitle Lab（声字工场）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-voice-subtitle-lab
```

**AIX 直接下载**（最新版）：[voice-subtitle-lab.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/voice-subtitle-lab.aix)

AV06 · 给店里/家里做语音播报前，挑出读得清、跟得上词级字幕的音色与语速组合，顶边界 B6（TTS synthesize 词级字幕）。

## 预览截图

![预览-index](<../../screenshots/voice-subtitle-lab/preview-voice-subtitle-lab-index.png>)
![预览-synth](<../../screenshots/voice-subtitle-lab/preview-voice-subtitle-lab-synth.png>)
![预览-ab](<../../screenshots/voice-subtitle-lab/preview-voice-subtitle-lab-ab.png>)
![预览-favs](<../../screenshots/voice-subtitle-lab/preview-voice-subtitle-lab-favs.png>)

## 结构与功能（闭环）

四页，字幕舞台形态（大字当前词区、词条逐个点亮、音色横向选择、细框舞台钮）：

- **脚本库（pages/index）**：中枢菜单页。内容集 8 条播报稿（开店迎客/取餐提醒/关门提示/活动播报/寻物启事/天气提醒/会议开始/生日祝福，数组可数）；末行可口述自加一条——宿主 `SpeechRecognition` 听写（interimResults 开、取 `results[resultIndex][0].transcript`，final 后入列尾）。Enter 选稿（存页间临时键 `av06_script_tmp`）跳合成页。
- **选声合成（pages/synth）**：11 个官方音色全列（female-tianmei / English_radiant_girl / English_expressive_narrator / male-qn-qingse / male-qn-jingying / female-yujie / Chinese (Mandarin)_News_Anchor / Chinese (Mandarin)_Radio_Host / clever_boy / lovely_girl / English_Trustworthy_Man），上下键选；rate（0.8/1.0/1.2）、pitch（0.9/1.0/1.1）步进选，preferredFormat（mp3/ogg_opus/pcm）与 sampleRate 选项显示。Enter 合成：`utterance.voice` 赋选定音色 id 字符串、`rate/pitch` 赋值，`await speechSynthesis.synthesize(utt,{subtitles:'word',audio:{preferredFormat,sampleRate}})`；`task.onchunk` 收 cues 逐词上屏点亮、大字区显示当前词；`new SpeechAudioPlayer(task)` 播放，合成后 Enter 播放/暂停切换；ABORT 小钮调 `task.abort()`；合成耗时与 `task.finished` 的 duration 显示。本页可把当前组合连同耗时存为 A 组或 B 组。
- **A/B 对照（pages/ab）**：A/B 两组并排（音色/rate/pitch/合成耗时/duration/字幕词数）；各自 PLAY 会重新 synthesize 后播放（活 task 对象不能跨页，见诚实边界）；上下切换指向、Enter 定胜出组（存临时键供收藏页入藏）。
- **收藏（pages/favs）**：胜出组合（脚本索引+音色+rate+pitch，附格式/采样率）按 Enter 写入 `av06_favs` 跨会话留用；可删单条、可清空。

闭环：选稿/口述 → 合成试听 → A/B 定胜出 → 收藏复用，可反复用。

## 语音交互流

- 口令/语音输入：脚本库末行「口述自加」——说出一条播报稿，听写 interim 实时上屏，final 入列；A/B 与收藏不另设口令，靠手势定胜出/入藏。
- ASR 节点：仅脚本库听写一处，用宿主 SpeechRecognition；听错纠错 = 再口述一次（新稿追加）或改选内置稿，界面明示。
- TTS 节点：选稿确认、A/B 定胜出、收藏入藏成功均经 `_speak` 简短播报；合成试听本身走 synthesize + SpeechAudioPlayer（不是 speak 队列）。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 脚本库：选稿/口述；合成：合成→播放/暂停；A/B：定胜出；收藏：入藏 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 移动选中（稿件/音色/指向/收藏条目） |
| 点头（头稳时） | `onHeadGesture('nod')` | 与各页主确认等价 |
| 双击 | Backspace | 系统返回（子页 BACK 钮亦可，合成页另有 ABORT 小钮中止任务） |

## 权限

`RECORD_AUDIO`：脚本库口述自加稿件需要听写。除此之外无相机、无定位。

## 诚实边界

- 为什么走 synthesize：`speak` 队列无 pause/cancel，故播放控制只能走 `synthesize` + `SpeechAudioPlayer`，界面与文案明示；宿主无 synthesize/player 时如实报错，不拿 speak 代替冒充可暂停（placeholder 点名：合成页字幕区与大字区在无宿主时只显示不可用说明）。
- `utterance.voice` 按档案赋字符串音色 id；宿主拒绝赋值时如实报错并停止合成，不静默换音色。
- utterance 的 `lang` 不生效、不设置，全文案明示。
- cues 的高亮按 chunk 到达顺序逐词点亮，是字幕到达顺序的呈现；不承诺与播放头的毫秒级对齐（宿主未给播放进度回调）。
- A/B 跨页重放必须重新 synthesize（活 task 不能跨页保存），按钮文案写明「重合成」，耗时以合成页实测为准。
- 页间临时键 `av06_script_tmp` / `av06_combo_tmp` / `av06_ab_tmp` / `av06_winner_tmp` 只是传参；真正的持久化只有 `av06_favs`。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | 待回填 |
| Version / Build | 1.0.0 |
| App Category | Life（待导入时确认） |
| Intent Description | Pick a broadcast voice by synthesizing scripts with word-level subtitles, compare A/B combos, and keep winning voice settings across sessions |
| Agent ID | 待回填 |
| 状态 | 未导入 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

Choose the voice before you broadcast: eight ready scripts plus dictation, all eleven official voices with rate and pitch steps, synthesis with word-level subtitle cues that light up as they arrive, A/B comparison of two combos, and favourites that keep the winning voice settings across sessions.

### Opening Message (≤500, Markdown)

**欢迎来到声字工场。** 先选一条播报稿，再挑音色合成试听——字幕会逐词点亮。两组对照选出胜出组合，收藏起来下次直接用。

### Preview Media

图片 4 张（本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 四页新作（脚本库/选声合成/A/B 对照/收藏）；8 条播报稿+口述自加、11 音色 synthesize 词级字幕、SpeechAudioPlayer 播放暂停、胜出组合跨会话收藏。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o voice-subtitle-lab.aix`（仓库副本入 `aix/voice-subtitle-lab.aix`，由批次统一执行）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（自备 Ink 运行时 + 本地服务端口 8902，逐页截图入 `screenshots/voice-subtitle-lab/`）
