# 安静角（Quiet Corner）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-quiet-corner
```

**AIX 直接下载**（最新版）：[quiet-corner.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/quiet-corner.aix)

CC14 · 路缘坡。自闭症谱系/感官过载人群专设：一句话场景是超市、车站人声灯光一起涌来、过载时立刻知道“往哪边走最安静”，而不是更多信息。

方向构成：路缘坡承担全部一环——特殊人群（自闭症谱系/感官过载者）先行：过载时信息越少越好，所以本 Agent 只给一个方向词加一句话行动指令，其余信息全部关掉；安静地点可存为记录，下次过载直接翻旧记录。安静地点记录集与多步流程（总览→扫描标记→存地点）构成厚度。

## 预览截图

![预览-index](<../../screenshots/quiet-corner/preview-quiet-corner-index.png>)
![预览-scan](<../../screenshots/quiet-corner/preview-quiet-corner-scan.png>)
![预览-scan-s2](<../../screenshots/quiet-corner/preview-quiet-corner-scan-s2.png>)
![预览-spots](<../../screenshots/quiet-corner/preview-quiet-corner-spots.png>)
![预览-spots-s2](<../../screenshots/quiet-corner/preview-quiet-corner-spots-s2.png>)

## 结构与功能（页清单＋内容集计数）

三页结构（罗盘声压环形态），共享状态跨会话持久化（wx storage `quietCornerV1`）：

- **总览（pages/index）**：中央罗盘圆只显示一个方向词（已标记的最安静方向，未标记为“？”）＋ 8 方向环形标记（北/东北/东/东南/南/西南/西/西北）＋今日安静记录数；首页上下键循环选子页（▶ 选中标记），Enter 打开选中子页。
- **扫描（pages/scan）**：环形罗盘，中心只一个方向词，上下两排方向标记。开始扫描以当前朝向为中心；佩戴者慢慢转头一圈，`AbsoluteOrientationSensor` yaw 换算为相对方向；感觉到最安静方向时点头/Enter 标记，TTS 只报方向与一句话（“往 X 走，那边最安静。”）。
- **地点（pages/spots）**：已存地点列表（最新 5 条）＋新增：地点名从常用地点内容集 6 个（超市出口/车站西口/公园长椅/图书馆角落/商场楼梯间/医院走廊尽头）中选，上下键换、Enter/点头保存，保存时连同最近标记方向（未标记记“未定”）。

闭环：进入（总览确认状态）→过程（扫描：转头→感觉→点头标记，只报方向与一句话）→结果（最安静方向与安静地点记录持久化，可反复用）。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 首页打开选中子页／扫描页开始扫描或标记最安静／地点页保存选中地点 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 首页循环选子页／扫描页手动换方向／地点页换待存地点名 |
| 点头 | `onHeadGesture('nod')` | 扫描页标记最安静方向／地点页保存选中地点 |
| 双击 | Backspace | 系统返回（子页返回键亦可） |

## 权限

无权限。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## 诚实边界

- **不用麦克风测声压**：本 Agent 没有声压测量，“最安静方向”是佩戴者本人感觉后点头标记的方向，不是仪器读数；方向词是相对方向（以扫描开始时的朝向为中心），不是指南针绝对方向。
- 传感器缺失时如实显示“方向参考不可用，仍可用手动方向标记”，手动上下键仍可标记，不假装有传感器读数。
- 本 Agent 不诊断、不治疗感官过载；过载严重时请离开现场或寻求身边人帮助。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | 安静角（待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | Life（待导入时确认） |
| Intent Description | 过载时慢慢转头一圈，感觉到最安静方向时点头标记，只显示方向与一句话，安静地点可存为记录 |
| Agent ID | 待导入后回填 |
| 状态 | 本地开发完成；未打包、未推送、未导入 Studio、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

Quiet Corner is for autistic people and anyone facing sensory overload in supermarkets and stations: turn slowly in a circle, nod when a direction feels quietest, and the agent shows only that direction plus one action sentence - nothing more. No microphone sound measurement, no extra information. Saved quiet spots persist across sessions.

### Opening Message (≤500, Markdown)

**人声灯光一起涌来的时候，只问一件事：往哪边走最安静。** 慢慢转一圈，感觉到最安静的方向就点头——我只告诉你那个方向和一句话，别的什么都不给你看。

### Preview Media

图片 5 张（本页预览截图，提审时取 3–5 张）；视频待真机阶段补（提审要求 ≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 三页新作（总览/扫描/地点）；8 方向相对方向扫描与点头标记、只报方向与一句话的 TTS、常用地点 6 个、安静地点记录跨会话持久化。
- Improvements: 无（首版）。
- Fixes: 无（首版）。
