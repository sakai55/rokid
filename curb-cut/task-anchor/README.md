# 任务锚（Task Anchor）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-task-anchor
```

CC13 · 路缘坡。ADHD 时间盲与任务切换成本专设：一句话场景是 ADHD/注意力缺陷者开工时声明唯一任务，任务名常驻视线角落，计时分段轻提醒，走神自报后只报已用时与下一步最小动作。

方向构成：路缘坡承担全部一环——特殊人群（ADHD/注意力缺陷者）的时间盲与任务切换成本先行，任务名常驻、25 分钟分段、走神只报时间与最小动作都是为该人群的障碍而设，不为大众收益稀释；大众外溢是任何人开工前先定唯一任务都能少切换，但这不是本 Agent 的设计目标。

## 预览截图

![预览-index](<../../screenshots/task-anchor/preview-task-anchor-index.png>)
![预览-focus](<../../screenshots/task-anchor/preview-task-anchor-focus.png>)
![预览-focus-s2](<../../screenshots/task-anchor/preview-task-anchor-focus-s2.png>)
![预览-log](<../../screenshots/task-anchor/preview-task-anchor-log.png>)
![预览-log-s2](<../../screenshots/task-anchor/preview-task-anchor-log-s2.png>)

## 结构与功能（页清单＋内容集计数）

三页结构（沙漏计时盘形态），共享状态跨会话持久化（wx storage `taskAnchorV1`）：

- **总览（pages/index）**：左侧沙漏计时盘显示今日任务与已专注分钟，右侧子页菜单（▶ 选中标记）＋今日累计；任务模板内容集 8 个（写作业/写报告/做家务/做饭/复习/整理房间/回邮件/运动）。
- **专注（pages/focus）**：选中任务名常驻顶部；25 分钟专注段 `setInterval`（1 秒 tick）计时，满 5 分钟 TTS 轻提醒“还在 XX 上吗”＋已用分钟；下一步最小动作内容集 8 条（每任务一条）；进行中 Enter/点头 = 走神自报（只报已用时与下一步最小动作，计时不停），未开始时 Enter/点头 = 开始；完成确认写入一条日志。
- **记录（pages/log）**：最新 5 条完成日志（任务名＋分钟数＋时间）＋累计专注分钟；Enter/点头播报选中日志。

闭环：进入（总览声明今日任务）→过程（专注页计时＋轻提醒＋走神自报）→结果（完成日志与累计分钟持久化，可反复用）。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 首页打开选中子页／专注页开始或走神自报／记录页播报选中日志 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 首页循环选子页／专注页换任务模板／记录页换选中日志 |
| 点头 | `onHeadGesture('nod')` | 专注页开始或走神自报／记录页播报选中日志 |
| 双击 | Backspace | 系统返回（子页返回键亦可） |

## 权限

无权限。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## 诚实边界

- 计时只计本 Agent 打开后的专注段，不测量真实注意力；走神自报完全由本人触发，Agent 不判定走神、不斥责、不扣分，提醒语气只显示、不斥责。
- 任务模板与下一步动作是固定文案，不是医生或治疗师的建议；注意力困难持续存在请咨询专业人士，本 Agent 不作医疗宣称。

## 设备测试信息

| 项 | 值 |
|---|---|
| Studio name | 任务锚（待导入后回填） |
| Version / Build | 1.0.0 |
| App Category | Life（待导入时确认） |
| Intent Description | 开工声明唯一任务，任务名常驻，25 分钟分段轻提醒，走神自报只报已用时与下一步最小动作 |
| Agent ID | 待导入后回填 |
| 状态 | 本地开发完成；未打包、未推送、未导入 Studio、未真机测试、未提审 |

## 提审资料 (Review Submission)

### Feature Description (≤500 chars)

Task Anchor is for people with ADHD and time blindness: declare one single task before starting, keep its name resident in view, time it in gentle 25-minute focus segments with a soft check-in every 5 minutes, and when attention drifts, self-report to hear only the elapsed time and the next smallest action - never a scolding. Eight task templates, focus progress and completed-task logs persist across sessions.

### Opening Message (≤500, Markdown)

**一次只做一件事。** 先选一个任务，它的名字会一直在视线角落陪着你；25 分钟一段，慢慢来。走神了就自报一声，我只告诉你过去了多久、下一步最小能做什么——不催、不骂。

### Preview Media

图片 5 张（本页预览截图，提审时取 3–5 张）；视频待真机阶段补（提审要求 ≥1 图 ≥1 视频）。

### Change Log

#### Build 1.0.0
- Features added: 三页新作（总览/专注/记录）；任务模板 8 个、下一步最小动作 8 条、25 分钟专注段计时与 5 分钟轻提醒、走神自报、完成日志与累计分钟跨会话持久化。
- Improvements: 无（首版）。
- Fixes: 无（首版）。
