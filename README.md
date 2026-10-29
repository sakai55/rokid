# Hotword Forge（热词锻造）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-hotword-forge
```

**AIX 直接下载**（最新版）：[hotword-forge.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/hotword-forge.aix)

AV05 · 仓库盘点手忙时商品名必须被识别准——先把热词与分段参数按宿主真实能力锻好再上岗，顶边界 B5（SpeechRecognitionSession 外部流 ASR）。

## 预览截图

![预览-index](<../screenshots/hotword-forge/preview-hotword-forge-index.png>)
（forge 锻造页截图缺：Web 预览宿主的 SpeechRecognitionSession 能力不可用，能力门按设计拦截进入锻造页；该页待真机导入后补拍。index 页即能力门本体。）
![预览-test](<../screenshots/hotword-forge/preview-hotword-forge-test.png>)
![预览-settle](<../screenshots/hotword-forge/preview-hotword-forge-settle.png>)

## 结构与功能（闭环）

四页，锻造炉形态（厚边块状按钮、词块网格、阈值步进器）：

- **能力门（pages/index）**：中枢菜单页。Enter 在「检测能力」行调用 `await SpeechRecognitionSession.getCapabilities()`，逐项回读显示：audioFormats（mime+采样率）、maxChunkBytes、interimResults、phrases 支持否、contextUpdates 支持否、segmentationModes、vadSilenceDuration{minMs,maxMs}。不支持的项当场标注「宿主不支持 → 锻造页对应开关关闭」；capabilities 不可用时整页如实报错并禁止进锻造。caps 经页间临时键 `av05_caps_tmp` 传给后续页（仅页间传参，非持久化声明项）。
- **锻造（pages/forge）**：内容集 12 个仓库盘点词（纸箱/托盘/货架/叉车/标签/封口/称重/扫码枪/周转箱/防潮垫/捆扎带/出库单，数组可数）。上下移选、Enter 多选勾选热词（boost 固定 +5 并显示）；VAD 静音阈值只在 caps 区间内步进（不支持则显示关闭）；segmentation 只在 caps 所列模式内选；盘点对话 4 句（user/assistant 各 2 句）作为 `updateContext` 注入内容，contextUpdates 不支持则跳过并标注。配置存临时键 `av05_cfg_tmp`。
- **实测（pages/test）**：mime 取 caps.audioFormats 与 `MediaRecorder.isTypeSupported` 的交集；`getUserMedia({audio:true})` → `MediaRecorder.start(250)` 分片 → 串行 Promise 链写入 `session.audio.getWriter()`（`new SpeechRecognitionSession({lang:'zh-CN', interimResults, phrases:选定热词, segmentation:选定})`，启用上下文时先 `updateContext`）；`session.onresult` 的 interim 实时上屏、final 累计；结束时停录 → 等链写完 → `writer.close()` → stop tracks；对每个热词统计 final 文本命中数。
- **结算（pages/settle）**：每词本次命中数 + 弱词清单（命中 0 的词）+ 本次配置摘要；按 Enter 把本次命中合并写入 `av05_hits`（按词累计、跨会话、防重复入账），显示累计榜；可清空累计。

闭环：能力门 → 锻造 → 实测 → 结算入账，可反复用（换词重锻即新一轮）。

## 语音交互流

- 语音输入：实测页本身就是语音作业——佩戴者念出盘点词句（如「三号货架的纸箱和托盘都点完了」），识别 interim/final 实时上屏，命中按 final 文本统计；没有单独的口令识别层，不假装有。
- TTS 播报节点：能力检测完成/失败、锻造存配置（播报已选词数）、实测开始提示、实测结束提示、结算入账确认，均经 `_speak`（宿主 TTS、`immediate`）。
- 纠错路径：识别不准不改数字——回锻造页增减热词、改 VAD/分段后重测一轮，命中以新一轮 final 为准；弱词清单就是下一轮的纠错清单。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 能力门：检测/进入选中行；锻造：勾选热词；实测：开始/结束；结算：入账 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 移动选中（菜单/词块）或切换页面入口 |
| 点头（头稳时） | `onHeadGesture('nod')` | 与各页主确认等价（存配置/开始结束实测/入账） |
| 双击 | Backspace | 系统返回（子页 BACK 钮亦可） |

## 权限

`RECORD_AUDIO`：实测页录制佩戴者语音并分片喂入识别会话。除此之外无相机、无定位。

## 诚实边界

- `SpeechRecognitionSession` / `getCapabilities` / `MediaRecorder` 任一在宿主缺失时，对应页如实报错并停在该步，不生成假能力、假转写、假命中（placeholder 点名：能力门 caps 列表、实测页 interim/final 区在无宿主时只显示不可用说明）。
- caps 未给的字段（maxChunkBytes、VAD 区间、分段列表）显示「宿主未给」，对应开关关闭，不私自补默认值冒充宿主能力。
- 热词 boost 固定 +5 为本 Agent 的接线口径并在界面明示；命中数只按 final 文本逐字计数，不做模糊匹配。
- 页间临时键 `av05_caps_tmp` / `av05_cfg_tmp` / `av05_last_tmp` 只是传参，不是跨会话持久化；真正的持久化只有 `av05_hits`。
- TTS 永不设置 utterance 的 `lang`（官方注明不生效）。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | 待回填 |
| Version / Build | 1.0.0 |
| App Category | Work（待导入时确认） |
| Intent Description | Forge ASR hotwords and segmentation from live host capabilities, test them by voice, and settle per-word hit counts for warehouse stocktaking |
| Agent ID | 待回填 |
| 状态 | 未导入 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

Forge recognition before stocktaking: read the host SpeechRecognitionSession capabilities field by field, pick hotwords from a 12-word warehouse set with VAD and segmentation inside host limits, stream mic chunks into the session, and settle per-word hit counts with a weak-word list that persists across sessions.

### Opening Message (≤500, Markdown)

**欢迎来到热词锻造。** 先过能力门：宿主支持什么就锻什么，不支持的开关当场关闭。选好盘点热词、念一轮实测，弱词清单会告诉你下一轮改哪里。

### Preview Media

图片 3 张（本页预览截图；forge 页待真机补拍，见截图节注）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 四页新作（能力门/锻造/实测/结算）；getCapabilities 全量回读、12 词热词锻造、外部流分片实测、命中结算与跨会话累计榜。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o hotword-forge.aix`（仓库副本入 `aix/hotword-forge.aix`，由批次统一执行）
- 预览：`~/tools/bin/aix preview . --html-out artifacts/preview.html` 后走本地截图管线（自备 Ink 运行时 + 本地服务端口 8902，逐页截图入 `screenshots/hotword-forge/`）
