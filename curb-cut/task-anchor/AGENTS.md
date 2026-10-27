# Task Anchor — Agent Notes

CC13（路缘坡（CC），PLAN CC13 原案：ADHD 时间盲与任务切换成本专设）。交互哲学：**沙漏计时盘 Hourglass Dial**，三页结构（任务总览 / 专注计时 / 完成记录）。

一句话场景：ADHD/注意力缺陷者开工时声明唯一任务，任务名常驻视线角落，计时分段轻提醒，走神自报后只报已用时与下一步最小动作。

## Design contract

- 总览（index）：左侧沙漏计时盘（今日任务＋已专注分钟）＋右侧子页菜单（▶ 选中标记）＋任务模板 8 个（写作业/写报告/做家务/做饭/复习/整理房间/回邮件/运动）。首页上下键循环选子页，Enter 打开选中子页。
- 专注（focus）：选中任务名常驻顶部；25 分钟专注段以 `setInterval`（1 秒 tick）计时；每满 5 分钟 TTS 轻提醒“还在 XX 上吗”＋已用分钟，只显示、不斥责。进行中按 Enter/点头 = 走神自报：报已用时与下一步最小动作（每任务一个：先写第一题/先写第一段/先收拾桌面一件/先洗一样菜/先看第一页/先收一个抽屉/先回最短的一封/先热身一分钟），计时不停；未开始时 Enter/点头 = 开始。完成确认把一条日志写入持久化。
- 记录（log）：最新 5 条完成日志（任务名＋分钟数＋时间）＋累计专注分钟；上下键选日志，Enter/点头播报选中日志。

## 接口与存储

- 计时：`setInterval`/`clearInterval`；播报：`speechSynthesis` guarded helper（永不设 utterance 的 `lang`）；导航：`wx.navigateTo`/`wx.navigateBack`；点头：`onHeadGesture('nod')`；按键：`onKeyDown`/`onKeyUp`（相关键 preventDefault）。
- 存储键 `taskAnchorV1`：`{ current: {task, elapsed, done}, logs: [{task, minutes, at}], totalMinutes, drifts }`，`wx.getStorageSync`/`wx.setStorageSync`。专注页离开时保存当前进度，跨会话续看。

## 诚实边界

- 计时只计本 Agent 打开后的专注段，不测量真实注意力；走神自报完全由本人触发，Agent 不判定、不斥责、不扣分。
- 底座七项均不构成其本体（不是翻译/字幕/转写/提词器/慧眼/导航/语音笔记）。

## Permissions

none。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/task-anchor/`。
