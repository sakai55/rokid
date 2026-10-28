# Dual Shot Verify（双拍核验）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-dual-shot-verify
```

AV08 · 贵重物品交接时，同一件物品拍全景与细节两张照片、由同一模型会话分三轮交叉核对，一致才落账，顶边界 B8 双图 LLM 三轮。

## 预览截图

![预览-index](../screenshots/dual-shot-verify/preview-dual-shot-verify-index.png)
![预览-detail](../screenshots/dual-shot-verify/preview-dual-shot-verify-detail.png)
![预览-verify](../screenshots/dual-shot-verify/preview-dual-shot-verify-verify.png)
![预览-ledger](../screenshots/dual-shot-verify/preview-dual-shot-verify-ledger.png)

## 结构与功能（闭环）

四页闭环：全景登记 → 细节拍 → 交叉核验 → 落账。

- **全景登记（pages/index）**：中枢菜单（上下选、Enter 执行）。Enter 选「拍全景」时走真实相机链：`getUserMedia({video:true})` → `ImageCapture(track).takePhoto({mode:'wide'})` → canvas 缩图宽 480（`createImageBitmap` + `convertToBlob` jpeg 0.7，失败回退原图并标注）→ dataURL 存临时键 `av08_tmp`（页间传参，非持久化声明项，见下）。显示已登记状态与原图字节数。语音命名：`SpeechRecognition`（`interimResults=true`）听写登记名，听错重说即纠错。
- **细节拍（pages/detail）**：头稳引导页。`onOrientationStabilityChange` 实时显示稳/未稳；未稳时 Enter 只提示「先稳住头部」且不拍，稳后 Enter 拍 `takePhoto({mode:'telephoto'})`，同样缩图后存入 `av08_tmp.detail`，页面显示两拍齐备状态。
- **交叉核验（pages/verify）**：缺任一图禁止开始并提示回前页补拍。齐备后 Enter 在同一 `LanguageModel` session 内串行三轮：轮1 只发 wide 图、轮2 只发 detail 图，均要求回 `ITEM:`/`VALUE:` 固定格式；轮3 用 `promptStreaming`（轮询 `stream.read()` 流式上屏）发两图加前两轮文本，要求回 `AGREE: YES/NO` + `DIFF:`。本地再比对轮1/轮2 的 ITEM/VALUE 字段：不一致时结论区整块标注「两拍不一致」并 TTS 喊「两拍不一致，请复核」；一致且轮3 AGREE=YES 才给「可落账」。任一轮失败如实标失败、结论为「核验未完成」。
- **落账（pages/ledger）**：仅结论为「可落账」时 Enter 才把 {登记名, 轮1, 轮2, 结论, 时间} 写入持久化 `av08_records`；未完成/不一致置灰说明不可落账。列表回看存档；语音说「重跑核验」跳回 verify 页重跑。

页间传参说明：照片 dataURL 与核验中间结果走 wx storage 临时键 `av08_tmp`，这是页间传参通道，不是持久化存档；持久化只有 `av08_records` 一项。

与慧眼的区别（UI 小字同文）：慧眼是单拍即时辨识、单拍给结论；本台单拍不给任何结论，必须双拍配对、分轮隔离判读、再做分歧结算，分歧未清零不得落账。

## 语音交互流

- 登记命名：index 选「语音命名」→ 开口说物品名 → 中间结果实时上屏 → 定稿写入登记名；听错了再选一次重说覆盖，即纠错。
- 核验播报：结论为不一致时 TTS 主动喊「两拍不一致，请复核」；一致时播报「核验一致，可落账」。
- 语音纠正：在 verify 或 ledger 页说「重跑核验」，识别到关键词即（在 ledger）跳回 verify 页 /（在 verify 页）直接重跑三轮。
- 细节拍提示：未稳时按 Enter，TTS 提示「先稳住头部」。
- ASR 不可用时如实显示失败，不假装听见；TTS 用宿主固定音色，不设 `lang`。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 作用 |
|---|---|---|
| 单击 | Enter | 执行选中/焦点动作（拍全景、开始核验、落账等主动作） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 移动菜单选中态 / 切换子页焦点动作 |
| 点头（头稳时） | `onHeadGesture('nod')` | 与主确认等价（细节拍页点头即在头稳时拍细节） |
| 双击 | Backspace | 系统返回（子页另有 BACK 钮 `wx.navigateBack`） |

## 权限

- `CAMERA`：拍 wide 全景与 telephoto 细节两张照片。
- `RECORD_AUDIO`：语音命名与「重跑核验」语音指令的宿主 ASR 输入。

## 诚实边界

- LLM 判读只转写照片中可见内容，格式外内容不采信；任一轮失败、答复不明确或轮3未给 AGREE 时结论一律为「核验未完成」，绝不编造核验结果、绝不落账。
- 缩图失败时回退原图 dataURL 并在页面标注；Web 预览无相机/无 LLM 时各步如实失败，页面照常渲染。
- 本地字段比对只比对 ITEM/VALUE 两项的文本一致性，不做图像相似度计算；「一致」指判读文本一致，不等于实物鉴定结论，本台不是鉴定工具。
- placeholder 点名：无假数据、无 DEMO 种子；唯一未在 Web 预览验证的是真机 `ImageCapture` 的 wide/telephoto 模式与宿主 LLM 看图链路，需真机回填。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | Dual Shot Verify（待回填） |
| Version / Build | 1.0.1 |
| App Category | 待回填（导入时确认） |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未导入 |

## 提审资料 (Review Submission)

### Feature Description

Two photos or it did not happen: register an item with a wide shot, capture its detail with a steady-head telephoto shot, then one model session judges each photo alone and both together in three serial rounds. Only an agreeing pair can be filed; any mismatch is announced aloud and blocks filing.

### Opening Message

**Dual Shot Verify.** Photograph the whole item first, then its detail with a steady head. I will judge each photo separately, cross-check them, and only file the pair when they agree.

### Preview Media

图片 4 张（见本页预览截图）；视频待真机阶段补（提审要求 3–5 个文件、≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 四页新作（全景登记/头稳细节拍/三轮交叉核验/门检落账）；双图隔离判读与本地分歧结算。
- Improvements: 无（首版）。
- Fixes: 无（首版）。

#### Build 1.0.1
- Features added: 无。
- Improvements: 无。
- Fixes: 删除 FileReader（Ink 运行时不存在，真机必死）：照片 Blob→dataURL 改走官方文档路径 `blob.arrayBuffer()` + 分块 `btoa`，失败路径接全局错误码 E2005 并在状态行显示。

## 打包与预览

- 打包：`~/tools/bin/aix pack . -o dual-shot-verify.aix`（仓库副本按规矩放 `aix/dual-shot-verify.aix`）
- 预览：`~/tools/bin/aix preview .` 后走本地截图管线生成 4 页预览图，存入仓库 `screenshots/dual-shot-verify/`。
