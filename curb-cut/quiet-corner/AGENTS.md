# Quiet Corner — Agent Notes

CC14（路缘坡（CC），PLAN CC14 原案：自闭症谱系/感官过载人群）。交互哲学：**罗盘声压环 Compass Ring**，三页结构（过载总览 / 扫描安静方向 / 安静地点记录）。

一句话场景：超市、车站人声灯光一起涌来、过载时立刻知道“往哪边走最安静”，而不是更多信息。

## Design contract

- 总览（index）：中央罗盘圆只显示一个方向词（已标记的最安静方向，未标记为“？”）＋ 8 方向环形标记＋今日安静记录数；首页上下键循环选子页（▶ 选中标记），Enter 打开选中子页。
- 扫描（scan）：环形罗盘，中心只一个方向词。开始扫描以当前朝向为中心；佩戴者慢慢转头一圈，`AbsoluteOrientationSensor` yaw（guarded，try/catch）换算为 8 方向（北/东北/东/东南/南/西南/西/西北）；感觉到最安静方向时点头/Enter 标记，TTS 只报方向与一句话（“往 X 走，那边最安静。”），其余信息全部关掉。
- 地点（spots）：已存地点列表（最新 5 条）＋新增：眼镜无键盘，地点名从常用地点内容集 6 个（超市出口/车站西口/公园长椅/图书馆角落/商场楼梯间/医院走廊尽头）中选，上下键换、Enter/点头保存，保存时连同最近标记方向（未标记记“未定”）。

## 接口与存储

- 传感：`AbsoluteOrientationSensor`（quaternion → yaw，`frequency: 30`，`try/catch` 包裹，缺失时 evt 行如实显示“方向参考不可用，仍可用手动方向标记”，手动上下键仍可标记）；播报：`speechSynthesis` guarded helper（永不设 utterance 的 `lang`）；导航：`wx.navigateTo`/`wx.navigateBack`；点头：`onHeadGesture('nod')`；按键：`onKeyDown`/`onKeyUp`（相关键 preventDefault）。
- 存储键 `quietCornerV1`：`{ quiet: {dir, at}, spots: [{name, dir, at}] }`，`wx.getStorageSync`/`wx.setStorageSync`。

## 诚实边界

- **不用麦克风测声压**：本 Agent 没有声压测量，所谓“最安静方向”是佩戴者本人感觉后点头标记的方向，不是仪器读数；方向词是相对方向（以扫描开始时的朝向为中心），不是指南针绝对方向。
- 标记后 Agent 不追踪、不再追加信息；地点记录只存本人保存的地点与方向。
- 底座七项均不构成其本体（不是翻译/字幕/转写/提词器/慧眼/导航/语音笔记）。

## Permissions

none。TTS 用宿主固定音色，永不设置 utterance 的 `lang`。

## Validation

- 静态校验与打包结果见精品线台账；预览截图在仓库 `screenshots/quiet-corner/`。
