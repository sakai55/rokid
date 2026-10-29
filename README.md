# 端水平 Level Keep

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-level-keep
```

**AIX 直接下载**（最新版）：[level-keep.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/level-keep.aix)

头部动作小游戏系列 GA14，C 组（观察 / 控制）的游戏，极简设计：一页、三态（准备 / 进行 / 完成），全程就是头端平。一局 10 秒：先坐稳 / 站稳，点一下开始：摆好、端平，1 秒后开始计时——头端平就是球在正中间，往左歪球就往左跑，往右歪球就往右跑；端平满 10 秒算赢，语音说「端平 10 秒，好平」。屏幕上只有水平球 / 轨道、端平秒数 x / 10 和一行提示；你的头向本身就是游戏动作，由方向传感器对照开局那一刻的端平姿态判定。

与 GA07 的区别：GA07 稳头挑战计的是任何方向都不动（总角偏离 <5 度，上下左右、前后转头都会破功）；本游戏只计滚角——上下点头、前后转头本身不破功，只要头不往左右歪就算端平，球也只随滚角左右跑。与 photo-level 的区别：photo-level 是拿相机拍一张水平的照片；本游戏不用相机，端的是头，不是照片。

## 预览截图

![预览-准备](<../screenshots/level-keep/preview-level-keep-ready.png>)
![预览-进行中](<../screenshots/level-keep/preview-level-keep-playing.png>)
![预览-完成](<../screenshots/level-keep/preview-level-keep-done.png>)

## 系列宪法：颈部安全（GO 的规则）

**转圈是错误的。** 本游戏完全不用转头：全程就是头端平。绝不快速甩动。先坐稳 / 站稳，脚站稳，玩的时候不要走路。出现痛、晕、麻、恶心，立刻停。一局很短：单次 10 秒端平，可重玩。本游戏是日常活动娱乐，**不是医疗诊断、治疗或康复处方**；有颈椎病、眩晕、术后、头颈伤史的人请先问医生。短版印在游戏内的准备屏上；完整版见 AGENTS.md。

## 玩法

1. **准备**：坐稳 / 站稳，头摆正，读一遍安全提示，点「开始」。
2. **摆好（进行中，1 秒）**：语音说「摆好，端平，开始」，屏幕显示「摆好，端平，开始」；1 秒结束时游戏记下你当时的滚角作为端平基准，开始计时。摆好前没有读数时，摆好会等读数到（每 200 毫秒续等），绝不拿空值当基准。
3. **端平（进行中）**：头端平，球在正中间，秒数往上走；语音在开始时说「开始，端平，别歪」。滚角在基准 ±8 度以内才算端平。
4. **歪了**：往左或往右歪出 ±8 度，语音先报一次「往左歪了」或「往右歪了」，屏幕提示「快端平，0.3 秒内回正不算歪」；0.3 秒内回正不算歪、秒数接着走；歪满 0.3 秒，语音说「歪了，从头来」，秒数清零、自动重新摆好（基准重记），不用点。一局里歪了 5 次，语音说「休息一下再来」，回到准备屏。
5. **完成**：端平满 10 秒，屏幕显示「端平 10 秒」，点「再来一局」重新摆好、重新开始。进行中点一下（真机）是放弃本局、回到准备屏。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 进行中放弃 / 完成时再来一局 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮只有一个（主按钮，文案随状态变：开始 / 放弃 / 再来一局）；网页预览无传感器时它显示为演示步进按钮（见下）。本游戏故意不用任何头部手势事件：该 API 官方文档只写了 `'nod'`，而本游戏不用任何手势——端平判定只来自传感器。

## 技术诚实说明

- **无眼动追踪**：平台没有眼动 API；头部方向只来自 `AbsoluteOrientationSensor`。
- **头部手势事件官方文档只写了 `'nod'`**：本游戏不声称任何手势事件，也不装点头事件处理；端平判定全部来自传感器四元数。
- **滚角公式（代码原样，GA03 同款）**：滚角 `roll = atan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))`，单位度；判定用的是相对滚角——当前滚角与摆好时记下的基准滚角之差（包到 −180～180 度），宿主的绝对零点不影响判定。俯仰、偏航不计算、不判定，上下点头或左右转头本身不破功。
- **左右歪的命名是显示约定，不是已验证的宿主符号**：相对滚角 >0 显示并播报为「往右歪了」（球向右），<0 为「往左歪了」（球向左）；该命名待真机确认——真机上真实右倾必须显示「往右歪了」、真实左倾显示「往左歪了」，若宿主滚角轴反了，命名必须对调；命名不影响判定，因为带宽、宽限、胜利只看相对滚角的绝对值。
- **阈值**：端平带 ±8 度（比方向阈值严，因为端平是精细控制）；球每格约 2 度（带边 ±8 度 = 正中间 ±4 格），超出轨道两端时球停在端点；歪出带宽 <0.3 秒不重置（只冻结计时），≥0.3 秒重置并自动重摆；胜利须带内累计满 10 秒；一局 5 次重置即建议休息并回准备屏；计时步进 100 毫秒；摆好 1 秒（无读数时每 200 毫秒续等）。
- **稳定性事件只是辅助信号**：宿主上报稳定性事件时，不稳定只暂停计时、不重置、不单独判赢；宿主不上报时以带内计时为准（已如实说明的回退，不是假装稳定）。
- **传感器缺失 = SKIP / 演示，绝不假装通过**：网页预览没有方向传感器，屏幕明示 SKIP，演示按钮只走标注的演示路径（摆好一步、每点 +1 秒、球全程居中），完成屏写「演示端平 10 秒」；真机有传感器时没有演示路径。
- **零持久化**：不调任何存储 API；端平秒数、基准滚角、重置数与宽限状态只活在页面内存里。
- **与 GA07、photo-level 的区分**：GA07 是任何方向都不动（总角偏离 <5 度）；本游戏只看滚角 ±8 度、带球显示。photo-level 端的是相机照片；本游戏端的是头，不用相机。

## 权限

无。`permissions` 为空数组：传感器与 TTS 不在仅有的三项权限（`GEOLOCATION`、`CAMERA`、`RECORD_AUDIO`）之中，代码也不用这三项对应的任何功能，故一项不声明。空权限打包已验证通过。

## 打包与预览

```bash
cd ~/workspace/rokid/level-keep
~/tools/bin/aix pack . -o ../dist/level-keep.aix
~/tools/bin/aix list ../dist/level-keep.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-level-keep`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开端水平智能体」。
5. 验收点：头摆正点开始，确认出现 1 秒摆好提示「摆好，端平，开始」，摆好后语音说「开始，端平，别歪」，球在正中间、秒数开始走；**重点确认左右命名**：真实右倾确认显示并播报「往右歪了」、球向右跑，真实左倾确认显示并播报「往左歪了」、球向左跑，若反了如实记录并对调命名；**重点确认带宽**：±8 度在真机上是否过严或过松，若不符如实记录并调整；轻微点头、轻微转头确认不破功（秒数接着走），歪出带宽 0.3 秒内回正确认不重置、歪满 0.3 秒确认重置并自动重摆；一局 5 次重置确认回准备屏并提示休息；端平满 10 秒确认完成屏「端平 10 秒」与「再来一局」，再来一局确认重新摆好；进行中点一下确认放弃回准备屏。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 端水平（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Level-hold game for Rokid glasses, voice-guided. Tap start, settle 1 second to capture your level reference, then hold your head level for 10 seconds. Level is head roll within ±8 degrees of the reference, shown as a ball on a track: centered is level, offset with your tilt. Pitch or yaw drift alone does not break level. A tilt beyond the band over 0.3 seconds resets and restarts; 5 resets suggests a rest. No turning; stop at any pain. Entertainment only, not medical advice. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；无自创 API；无任何头部手势处理（该 API 仅文档化 `'nod'`，本游戏不用手势）；权限为空且与实际使用一致（无相机/麦克风/ASR/LLM/存储调用）。
- 逻辑 harness 17 项全过：滚角公式值、相对滚角 ±180 度包回、仅偏航与仅俯仰旋转的滚角均为 0（故俯仰/偏航漂移不破功）、带内 100 步计满 10 秒判赢、200 毫秒歪出不重置、400 毫秒歪出重置一次后仍能赢、带边 8 度、5 次重置即建议休息、球居中/带边 ±4 格/轨道两端钳制。
- `aix pack` 成功（见最终打包验证），`aix list` 确认包内含 README.md 与 AGENTS.md（打包在 README/AGENTS 定稿之后，见打包记录）。
- 预览截图 3 张已生成并逐张目检：准备（不用转头安全提示 + 开始）、进行中（球居中 + 端平 6 / 10 秒 + 演示按钮）、完成（演示端平 10 秒 + 再来一局）各状态均与设计一致，互不重复。

**未验证（如实说明）**
- 宿主 TTS 实际发声、方向传感器在真机上的读数与滚角符号、±8 度端平带与 0.3 秒宽限在真机上的松紧、左右歪命名（相对滚角 >0 称右、<0 称左）是否与真机一致、稳定性事件的真机投递均待真机验证；传感器任一步缺失时游戏如实显示 SKIP / 演示，不假装计分。
- 本游戏是日常活动娱乐，不替代任何医疗或康复判断；颈椎不适者请先问医生，出现痛、晕、麻、恶心立刻停。

## 提审资料 (Review Submission)

### Feature Description

> Level-hold game for Rokid glasses, voice-guided. Tap start, settle 1 second to capture your level reference, then hold your head level for 10 seconds. Level is head roll within ±8 degrees of the reference, shown as a ball on a track: centered is level, offset with your tilt. Pitch or yaw drift alone does not break level. A tilt beyond the band over 0.3 seconds resets and restarts; 5 resets suggests a rest. No turning; stop at any pain. Entertainment only, not medical advice.

### Opening Message

> ## 端水平
>
> 坐稳，点一下开始：摆好，头端平，1 秒后开始计时——**头端平就是球在正中间，往左歪球就往左跑，往右歪球就往右跑**。端平 10 秒算赢，语音说「端平 10 秒，好平」。歪出 ±8 度、超过 0.3 秒就从头来，自动重新摆好再计，不用点；一局里歪了 5 次就休息一下再来。全程不用转头，慢、不甩头，痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗建议。

### Preview Media

- `preview-level-keep-ready.png` — 准备屏（不用转头安全提示 + 开始）
- `preview-level-keep-playing.png` — 进行中（球居中 + 端平 6 / 10 秒）
- `preview-level-keep-done.png` — 完成屏（演示端平 10 秒 + 再来一局）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 端水平一局 10 秒：TTS 全程指导（摆好端平 → 开始端平别歪 → 往左/右歪了 → 歪了从头来 → 休息一下再来 → 端平 10 秒好平），屏幕水平球/轨道显示滚角、计分显示端平 x / 10 秒
- 端平判定：摆好 1 秒记下基准滚角，相对滚角在 ±8 度以内才累计；俯仰、偏航漂移本身不破功（只看滚角）；歪出带宽 <0.3 秒只冻结计时、≥0.3 秒重置并自动重摆（基准重记）；一局 5 次重置即建议休息并回准备屏；球每格约 2 度、带边 ±4 格、轨道两端钳制
- 左右歪命名约定：相对滚角 >0 显示并播报为右倾、<0 为左倾（待真机确认，若宿主轴反了须对调；命名不影响判定）
- 极简三态单页：准备 / 进行 / 完成，摆好作为进行中的前置步骤（非额外状态），单击开始·放弃·再来一局，双击系统返回不拦截
- 传感器缺失诚实 SKIP：网页预览明示 SKIP 并提供标注的演示路径（摆好一步、每点 +1 秒、球全程居中），真机有传感器时无演示路径

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
