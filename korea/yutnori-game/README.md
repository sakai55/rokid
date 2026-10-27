# Yutnori Game

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：
```
https://github.com/sakai55/rokid/tree/agent-yutnori-game
```

一句话场景：家人在春节或中秋聚会时，不用手、只用头部动作玩 윷놀이，先到 20 格者胜。

方向构成：韩国在地 × 游戏 × 注意力。在地性落在 설날·추석 家族 윷놀이；游戏承担玩法闭环一环（开始／掷棒移子／输赢计分）；注意力承担棋子位置、比分与成绩记录的守候一环。

## 预览截图

![总览](<../../screenshots/yutnori-game/preview-yutnori-game-index.png>)
![掷棒](<../../screenshots/yutnori-game/preview-yutnori-game-throw.png>)
![掷棒二](<../../screenshots/yutnori-game/preview-yutnori-game-throw-s2.png>)
![记录](<../../screenshots/yutnori-game/preview-yutnori-game-record.png>)
![记录二](<../../screenshots/yutnori-game/preview-yutnori-game-record-s2.png>)

## 结构与功能

- 页清单（3 页）：总览 index（20 格棋盘＋双方棋子位置＋比分）／掷棒 throw（点头/Enter 掷棒、按结果移子、到终点结算）／记录 record（胜负・掷棒次数・最佳记录）。
- 内容集计数：윷棒结果 5 种（도・개・걸・윷・모，每种含步数与说明）＋棋盘 20 格；윷/모 另奖励再掷一次。
- 闭环：进入总览 → 掷棒页点头掷棒（TTS 报结果与步数）→ 移子、到 20 格结算胜负 → 记录页查看并朗读成绩；胜负・掷棒次数・最佳记录跨会话持久化（存储键 `yutnoriV1`），可反复开局。

## 手势映射

| 操作 | 效果 |
|---|---|
| 首页 ArrowUp/ArrowDown | 循环选子页（▶ 标记） |
| 首页 Enter | 打开选中子页 |
| 掷棒页 Enter／点头 | 掷棒（主动作） |
| 掷棒页 ArrowUp/ArrowDown | 上／下一条结果说明 |
| 记录页 ArrowUp/ArrowDown | 上／下一行记录 |
| 记录页 Enter／点头 | 朗读记录 |

## 权限

无。TTS 用宿主固定音色，不设置 utterance 的 `lang`。

## 诚实边界

- 掷棒是演示随机数（在 5 种结果中随机选一），不是物理 윷 识别；棒面显示是结果的可视化，不是传感器读数。
- 头部动作宜缓慢、小幅；疼痛或眩晕时立即停止，不主张任何医疗效果。

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名 | 待回填 |
| Version | 1.0.0 |
| App Category | 待回填 |
| Intent Description | 待回填 |
| Agent ID | 待回填 |
| 状态 | 未导入／未真机验证 |

## 提审资料 (Review Submission)

- Feature Description：家族 윷놀이：只用头部动作掷棒、走 20 格棋盘，先到终点者胜，胜负与掷棒记录跨会话保存。
- Opening Message：설날·추석 가족 윷놀이를 머리 움직임만으로 즐기세요. 고개를 끄덕이면 윷이 던져지고, 20칸에 먼저 도착하면 승리합니다.
- Preview Media：预览截图见上（截图由开发流程后补，至少 1 图＋1 视频，视频 ≤60 秒）。
- Change Log（Build 1.0.0）：
  - Features added：20 格棋盘总览、5 种结果掷棒页、胜负结算、胜负与掷棒记录持久化。
  - Improvements：无（首版）。
  - Fixes：无（首版）。
