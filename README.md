# 左右闪避 Turn Dodge

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-turn-dodge
```

**AIX 直接下载**（最新版）：[turn-dodge.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/turn-dodge.aix)

头部动作小游戏系列 GA09，B 组（头当控制器）的左右闪避游戏，极简设计：一页、三态（准备 / 进行 / 完成），语音指导 10 回合躲障碍。先坐稳 / 站稳，点一下开始：先校准一次（向左转一下，记下左右），然后每回合障碍只从一边来——障碍在左就向右躲，障碍在右就向左躲，慢慢转过去、停 0.8 秒算躲开，再回正到中间，下一回合才开始。屏幕上只有障碍一边 + 躲闪箭头、躲开数 x / 10 和一行提示；你的转头本身就是游戏动作，由方向传感器对照开局那一刻的头向判定。

回合固定顺序（不是随机，预览与真机行为可复现）：障碍边依次为左、右、右、左、右、左、左、右、左、右；每回合的躲闪方向永远是障碍的反方向。

## 预览截图

![预览-准备](<../screenshots/turn-dodge/preview-turn-dodge-ready.png>)
![预览-进行中](<../screenshots/turn-dodge/preview-turn-dodge-playing.png>)
![预览-完成](<../screenshots/turn-dodge/preview-turn-dodge-done.png>)

## 系列宪法：颈部安全（GO 的规则）

**转圈是错误的。** 只做分段动作：正中 → 向一边转 → 停住 → 回正到中间 → 下一回合。绝不连续转圈，绝不从一边直接扫到另一边，绝不快速甩动——躲闪是沉稳地转，不是猛闪。慢、小幅度、到微酸即止。出现痛、晕、麻、恶心，立刻停。一局很短：10 次躲闪，可重玩。本游戏是日常活动娱乐，**不是医疗诊断、治疗或康复处方**；有颈椎病、眩晕、术后、头颈伤史的人请先问医生。短版印在游戏内的准备屏上；完整版见 AGENTS.md。

## 玩法

1. **准备**：坐稳 / 站稳，头摆正，读一遍安全提示，点「开始」。
2. **校准（进行中，第一步）**：屏幕显示「请向左转一下」，慢慢向左转一次——游戏记下你真实的向左方向（这样宿主左右符号即使反了也不会算反），再「回正到中间」，第 1 回合开始。重开一局会重新校准。
3. **躲闪（进行中，每回合）**：语音报「第 x 回合，左边有障碍，向右躲」（或右边），屏幕大字显示障碍边、提示显示躲闪箭头。慢慢向反方向转，超过约 27 度并停住 0.8 秒，语音说「躲开了」，躲开数 +1。
4. **撞到 / 没躲开**：向着障碍方向转过阈值，语音说「被撞到了」，本回合 0 分；4 秒内没转，语音说「没躲开」，本回合 0 分。躲闪中途没停够就缩回来，不算分，4 秒时钟继续走。
5. **回正**：每回合结束后必须回正到中间（<10 度），下一回合才宣布；4 秒内没回正，下一回合照常宣布并语音提醒「请回正」。最后一回合结束即直接出完成屏（没有下一回合可等）。
6. **完成**：屏幕显示「躲开 x / 10」，点「再来一局」重新校准、重新开始。进行中点一下（真机）是重读当前指令。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 进行中重读指令 / 完成时再来一局 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮只有一个（主按钮，文案随状态变：开始 / 朗读 / 再来一局）；网页预览无传感器时它显示为演示步进按钮（见下）。本游戏故意不用任何头部手势事件：该 API 官方文档只写了 `'nod'`，而本游戏不用任何手势——左右判定只来自传感器。

## 技术诚实说明

- **无眼动追踪**：平台没有眼动 API；头部方向只来自 `AbsoluteOrientationSensor`。
- **头部手势事件官方文档只写了 `'nod'`**：本游戏不声称任何手势事件，也不装点头事件处理；左右判定全部来自传感器四元数。
- **偏航公式（代码原样）**：`yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))`，单位度；只用相对校准中心的差值，宿主的绝对零点不影响判定。
- **左右符号是学来的，不是假设的**：开局一次校准（请向左转一下）记下玩家真实向左的符号，宿主符号反了也不会把左右算反；残留前提是玩家按提示向左转——转反了会学反，重开即重新校准；校准完成前什么都不计分。
- **阈值**：躲闪方向约 27 度（25–30 度档）；回正 <10 度；停稳约 0.8 秒（宿主上报稳定性事件时以稳定为准，不上报时以计时为准，已如实说明的回退，不是假装稳定）；一回合 4 秒无转即判没躲开；回正宽限 4 秒（到期下一回合照常宣布并语音提醒请回正，宽限本身不计分）；校准卡住 8 秒重提示一次，绝不自动计分。
- **回合顺序固定**：障碍边 L, R, R, L, R, L, L, R, L, R，不是随机；躲闪方向永远是障碍的反方向。
- **传感器缺失 = SKIP / 演示，绝不假装通过**：网页预览没有方向传感器，屏幕明示 SKIP，演示按钮只走标注的演示回合（先演示校准，再每点躲开一回合），完成屏写「演示躲开 x / 10」；真机有传感器时没有演示路径。
- **零持久化**：不调任何存储 API；躲开数、回合、中心与左右符号只活在页面内存里。

## 权限

无。`permissions` 为空数组：传感器与 TTS 不在仅有的三项权限（`GEOLOCATION`、`CAMERA`、`RECORD_AUDIO`）之中，代码也不用这三项对应的任何功能，故一项不声明。空权限打包已验证通过。

## 打包与预览

```bash
cd ~/workspace/rokid/turn-dodge
~/tools/bin/aix pack . -o ../dist/turn-dodge.aix
~/tools/bin/aix list ../dist/turn-dodge.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-turn-dodge`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开左右闪避智能体」。
5. 验收点：头摆正点开始，确认出现校准提示「请向左转一下」，真实向左转确认校准完成、回正后第 1 回合宣布「左边有障碍，向右躲」；**重点确认左右符号**：障碍在左时真实向右转确认计躲开（语音「躲开了」），真实向左转确认计撞到（语音「被撞到了」），不是反过来；向反方向转够约 27 度、停 0.8 秒确认计分，停不够就缩回确认不计分；每回合后不回正确认下一回合不宣布，4 秒宽限后确认下一回合宣布并语音提醒「请回正」；4 秒内不动确认判「没躲开」；10 回合后确认完成屏「躲开 x / 10」与「再来一局」，再来一局确认重新校准；**重点确认阈值**：27 度躲闪与 10 度回正在真机上是否过严或过松，若不符如实记录并调整。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 左右闪避（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Left/right dodge game for Rokid glasses, voice-guided. Ten fixed rounds, one obstacle at a time: obstacle left means turn right, obstacle right means turn left. Turn away calmly, hold 0.8 seconds to dodge, then return to center before the next round. A wrong-direction turn is a hit; no turn within 4 seconds is a miss. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；无自创 API；无任何头部手势处理（该 API 仅文档化 `'nod'`，本游戏不用手势）；权限为空且与实际使用一致（无相机/麦克风/ASR/LLM/存储调用）。
- `aix pack` 成功（见最终打包验证），`aix list` 确认包内含 README.md 与 AGENTS.md（打包在 README/AGENTS 定稿之后，见打包记录）。
- 预览截图 3 张已生成并逐张目检：准备（分段躲闪安全提示 + 开始）、进行中（障碍边 + 躲闪箭头 + 躲开数）、完成（演示躲开数 + 再来一局）各状态均与设计一致，互不重复。

**未验证（如实说明）**
- 宿主 TTS 实际发声、方向传感器在真机上的读数与偏航符号、27 度躲闪阈值与 10 度回正阈值在真机上的松紧、0.8 秒停稳的真机表现、4 秒回合时钟与 4 秒回正宽限的真机表现、稳定性事件的真机投递均待真机验证；传感器任一步缺失时游戏如实显示 SKIP / 演示，不假装计分。
- 本游戏是日常活动娱乐，不替代任何医疗或康复判断；颈椎不适者请先问医生，出现痛、晕、麻、恶心立刻停。

## 提审资料 (Review Submission)

### Feature Description

> Left/right dodge game for Rokid glasses, voice-guided. Ten fixed rounds, one obstacle at a time: an obstacle on the left means turn right, on the right means turn left. Turn away calmly, hold 0.8 seconds to dodge, then return to center before the next round. Turning toward the obstacle is a hit; no turn within 4 seconds is a miss. Slow, small range, never circle or jerk; stop at any pain. Entertainment only, not medical advice.

### Opening Message

> ## 左右闪避
>
> 坐稳，点一下开始：先校准一次（向左转一下），然后每回合障碍只从一边来——**障碍在左就向右躲，障碍在右就向左躲**。慢慢向反方向转，停 0.8 秒算躲开，再回正到中间，下一回合才开始。向着障碍转是撞到，4 秒不动是没躲开。10 回合固定顺序，不是随机。慢、小幅度、不甩头、不转圈，痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗建议。

### Preview Media

- `preview-turn-dodge-ready.png` — 准备屏（分段躲闪安全提示 + 开始）
- `preview-turn-dodge-playing.png` — 进行中（障碍边 + 躲闪箭头 + 躲开数）
- `preview-turn-dodge-done.png` — 完成屏（演示躲开数 + 再来一局）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 左右闪避一局 10 回合：TTS 全程指导（坐稳校准 → 每回合报障碍边与躲闪方向 →「躲开了」/「被撞到了」/「没躲开」→ 完成报躲开数），屏幕大字显示障碍边、提示显示躲闪箭头、计分显示躲开 x / 10
- 躲闪判定：向反方向转过约 27 度并停稳 0.8 秒计躲开；向着障碍转过阈值即判撞到；4 秒内无转判没躲开；每回合后须回正 <10 度才宣布下一回合，4 秒回正宽限到期则宣布下一回合并语音提醒请回正；固定障碍顺序 L, R, R, L, R, L, L, R, L, R，非随机
- 开局一次左右校准：请向左转一下，记下真实向左符号，宿主符号反了也不算反左右；校准完成前不计分，重开重新校准
- 极简三态单页：准备 / 进行 / 完成，校准作为进行中的前置步骤（非额外状态），单击开始·重读指令·再来一局，双击系统返回不拦截
- 传感器缺失诚实 SKIP：网页预览明示 SKIP 并提供标注的演示回合路径（演示校准 + 每点躲开一回合），真机有传感器时无演示路径

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
