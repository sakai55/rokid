# 稳头挑战 Steady Hold

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-steady-hold
```

**AIX 直接下载**（最新版）：[steady-hold.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/steady-hold.aix)

头部动作小游戏系列 GA07，B 组（头当控制器）的开场游戏，极简设计：一页、三态（准备 / 进行 / 完成），语音指导稳住头 10 秒。先坐稳 / 站稳、脚站稳，点一下开始：摆好 1 秒，然后头一点也别动，稳满连续 10 秒就赢。屏幕上只有大进度（已稳住 x / 10 秒）和一行提示（「别动，稳住」）；你的不动本身就是游戏动作，由方向传感器对照开局那一刻的头向判定。

与 A 组（GA01–GA06）不同：那些游戏数的是头部动作（点头、转头、侧倾、收下巴），本游戏数的是不动——全程不用转头，没有方向会超标、没有极端可扫到、没有圈可转，不动就是全部玩法。

## 预览截图

![预览-准备](<../../screenshots/steady-hold/preview-steady-hold-ready.png>)
![预览-进行中](<../../screenshots/steady-hold/preview-steady-hold-playing.png>)
![预览-完成](<../../screenshots/steady-hold/preview-steady-hold-done.png>)

## 系列宪法：颈部安全（GO 的规则）

**转圈是错误的。** 本游戏根本不用转头：全程就是稳住不动。绝不快速甩动。先坐稳 / 站稳，脚站稳，玩的时候不要走路。出现痛、晕、麻、恶心，立刻停。一局很短：一次 10 秒稳住，可重玩。本游戏是日常活动娱乐，**不是医疗诊断、治疗或康复处方**；有颈椎病、眩晕、术后、头颈伤史的人请先问医生。短版印在游戏内的准备屏上；完整版见 AGENTS.md。

## 玩法

1. **准备**：坐稳 / 站稳，脚站稳，头摆正，读一遍安全提示，点「开始」。
2. **摆好（进行中，1 秒）**：屏幕显示「摆好，开始稳住」，1 秒结束时把当前头向记为本局的稳住基准。
3. **稳住（进行中，10 秒）**：头一点也别动。屏幕大字显示已稳住秒数（x / 10 秒），提示只有「别动，稳住」。
4. **动了怎么办**：偏出 5 度、持续 0.3 秒以上，计时立刻归零，语音说「动了，从头来」，自动重新摆好 1 秒、重新记基准、再稳 10 秒，不用再点。0.3 秒内的小晃动（抖一下、眨眼级摆动）不算动，计时不停、只暂停那一瞬间。一局里动了 5 次，语音说「休息一下再来」，回到准备屏。
5. **完成**：连续稳满 10 秒，屏幕显示「稳满 10 秒」，点「再来一局」重新开始。进行中点一下（真机）是放弃本局、回到准备屏。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 进行中放弃本局 / 完成时再来一局 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮只有一个（主按钮，文案随状态变：开始 / 放弃 / 再来一局）；网页预览无传感器时它显示为演示步进按钮（见下）。本游戏故意不用任何头部手势事件：该 API 官方文档只写了 `'nod'`，而本游戏不用任何手势——稳住只来自传感器。

## 技术诚实说明

- **无眼动追踪**：平台没有眼动 API；头部方向只来自 `AbsoluteOrientationSensor`。
- **头部手势事件官方文档只写了 `'nod'`**：本游戏不声称任何手势事件，也不装点头事件处理；稳住判定全部来自传感器四元数。
- **稳住度量（代码原样）**：从摆好结束时记下的基准四元数算起的总角变化，`angle = 2*acos(|dot(q, qCenter)|)`，单位度。俯仰 + 偏航 + 滚转合成一个数，任何方向的漂移都会破稳，没有哪个轴可以藏动作；只用相对基准的差值，宿主的绝对零点不影响判定。
- **阈值**：摆好 1 秒（无读数时以 200 毫秒步进等待，绝不记空基准）；稳住限 5 度；宽限 0.3 秒（300 毫秒内回正不重置，只冻结累计，不清零）；持续超 5 度满 300 毫秒即重置归零、自动重开；赢 = 限内累计满 10 秒；一局重开上限 5 次（第 5 次改回准备屏并提示休息）；计时 tick 100 毫秒。
- **稳定性事件只是辅助信号，绝不是唯一信号**：宿主上报 `onOrientationStabilityChange` 时，不稳定只暂停累计，不重置、不单独判赢；宿主不上报时，限内计时本身就是判定依据（已如实说明的回退，不是假装稳定）。
- **传感器缺失 = SKIP / 演示，绝不假装通过**：网页预览没有方向传感器，屏幕明示 SKIP，演示按钮只走标注的演示秒数（先演示摆好，再每点加 1 秒），完成屏写「演示稳满 10 秒」；真机有传感器时没有演示路径。
- **零持久化**：不调任何存储 API；已稳住时间、基准四元数、重开次数与宽限状态只活在页面内存里。

## 权限

无。`permissions` 为空数组：传感器与 TTS 不在仅有的三项权限（`GEOLOCATION`、`CAMERA`、`RECORD_AUDIO`）之中，代码也不用这三项对应的任何功能，故一项不声明。空权限打包已验证通过。

## 打包与预览

```bash
cd ~/workspace/rokid/steady-hold
~/tools/bin/aix pack . -o ../dist/steady-hold.aix
~/tools/bin/aix list ../dist/steady-hold.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-steady-hold`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开稳头挑战智能体」。
5. 验收点：头摆正点开始，确认出现「摆好，开始稳住」1 秒摆好，随后大字开始计稳住秒数；真稳住 10 秒确认完成屏「稳满 10 秒」与「再来一局」；故意明显动头（转头 / 点头 / 抬头任一方向）确认计时归零、语音「动了，从头来」、自动重新摆好；故意抖一下（<0.3 秒小晃动后立刻回正）确认不重置、计时继续；故意连续动头 5 次确认第 5 次后语音「休息一下再来」并回到准备屏；进行中点一下确认放弃回准备屏；**重点确认 5 度阈值与 0.3 秒宽限**：小幅度自然晃动（<5 度）不应重置，明显转头应可靠重置，若 5 度在真机上过严或过松，如实记录并调整阈值；稳定性事件若宿主不上报，确认限内计时本身仍能判赢。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 稳头挑战（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Steady-head challenge: voice-guided 10-second still hold for Rokid glasses. Tap start, settle 1 second, then hold your head completely still — no turning at all. Stay under 5 degrees total angular change from your starting orientation; a wobble under 0.3 seconds is forgiven, sustained movement resets and auto-restarts; 5 resets means rest. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；无自创 API；无任何头部手势处理（该 API 仅文档化 `'nod'`，本游戏不用手势）；权限为空且与实际使用一致（无相机/麦克风/ASR/LLM/存储调用）。
- `aix pack` 成功（见最终打包验证），`aix list` 确认包内含 README.md 与 AGENTS.md（打包在 README/AGENTS 定稿之后，见打包记录）。
- 预览截图 3 张已生成并逐张目检：准备（不用转头的安全提示 + 开始）、进行中（稳住 6 / 10 秒）、完成（演示稳满 10 秒 + 再来一局）各状态均与设计一致，互不重复。

**未验证（如实说明）**
- 宿主 TTS 实际发声、方向传感器在真机上的读数与四元数角变化、5 度阈值在真机上的松紧、0.3 秒宽限的真机表现、稳定性事件的真机投递、5 次重开上限的真机表现均待真机验证；传感器任一步缺失时游戏如实显示 SKIP / 演示，不假装计数。
- 本游戏是日常活动娱乐，不替代任何医疗或康复判断；颈椎不适者请先问医生，出现痛、晕、麻、恶心立刻停。

## 提审资料 (Review Submission)

### Feature Description

> Steady-head challenge for Rokid glasses, voice-guided. Sit steady, tap start, settle for 1 second, then hold your head completely still for 10 continuous seconds — no turning at all. Stillness is measured from your starting orientation: stay under 5 degrees and you win. A wobble under 0.3 seconds is forgiven; sustained movement resets the timer and restarts automatically. After 5 resets, take a rest. Slow, no jerking, stop at any pain. Entertainment only, not medical advice.

### Opening Message

> ## 稳头挑战
>
> 坐稳，脚站稳，点一下开始：摆好，头一点也别动，稳满 10 秒——这个游戏不用转头，全程就是稳住不动。**稳住的标准是 5 度**：从开始那一刻的头向算起，任何方向偏出 5 度、持续 0.3 秒以上，计时归零、自动从头来；0.3 秒内的小晃动不算动。动了 5 次，就休息一下再来。痛、晕、麻、恶心，立刻停下来。本游戏是日常活动娱乐，不是医疗建议。

### Preview Media

- `preview-steady-hold-ready.png` — 准备屏（不用转头的安全提示 + 开始）
- `preview-steady-hold-playing.png` — 进行中（大字稳住 6 秒 + 6 / 10 秒）
- `preview-steady-hold-done.png` — 完成屏（演示稳满 10 秒 + 再来一局）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 稳头一局 10 秒：TTS 全程指导（坐稳摆好 → 1 秒摆好 →「开始，稳住，别动」→ 动了从头来 / 休息一下再来 →「稳满 10 秒，好稳」），屏幕大字显示已稳住秒数 x / 10 秒与一行提示
- 稳住判定：摆好结束时记基准四元数，总角变化 `2*acos(|dot|)` 限 5 度内累计满 10 秒即赢；超限持续满 0.3 秒计时归零并自动重开（重新摆好、重记基准），0.3 秒内小晃动不重置；一局 5 次重开后提示休息并回准备屏
- 极简三态单页：准备 / 进行 / 完成，摆好作为进行中的前置步骤（非额外状态），单击开始·放弃·再来一局，双击系统返回不拦截
- 传感器缺失诚实 SKIP：网页预览明示 SKIP 并提供标注的演示秒数路径（演示摆好 + 每点加 1 秒），真机有传感器时无演示路径

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
