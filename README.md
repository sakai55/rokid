# 点头接球 Nod Catch

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-nod-catch
```

**AIX 直接下载**（最新版）：[nod-catch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/nod-catch.aix)

头部动作小游戏系列 GA08，B 组（头当控制器）的接球游戏，极简设计：一页、三态（准备 / 进行 / 完成），语音指导轻轻点头接球。10 个球一个一个从上落下，每个球固定落 3 秒，中间有一条接球线：球落到线附近时轻轻点头，就是接住。屏幕上只有下落的球 + 中间的接球线、得分 x / 10 和一行提示；点头本身就是游戏动作。

与 GA07（稳头不动）不同：本游戏考的是点头的时机——点头太早、太晚都算这个球没接住，一个球只能点头一次，没有第二次机会。

## 预览截图

![预览-准备](<../screenshots/nod-catch/preview-nod-catch-ready.png>)
![预览-进行中](<../screenshots/nod-catch/preview-nod-catch-playing.png>)
![预览-完成](<../screenshots/nod-catch/preview-nod-catch-done.png>)

## 系列宪法：颈部安全（GO 的规则）

**转圈是错误的。** 本游戏只用小幅点头：不转圈、不扫动、不快速甩头。接球的点头是轻轻一点，绝不是甩头。慢、小幅度、到微酸即止。出现痛、晕、麻、恶心，立刻停。先坐稳 / 站稳。一局很短：10 个球，可重玩。本游戏是日常活动娱乐，**不是医疗诊断、治疗或康复处方**；有颈椎病、眩晕、术后、头颈伤史的人请先问医生。短版印在游戏内的准备屏上；完整版见 AGENTS.md。

## 玩法

1. **准备**：坐稳 / 站稳，头摆正，读一遍安全提示，点「开始」。
2. **进行中**：球从上落下，固定 3 秒落到底，中间有一条接球线。球心落到线的上下 15% 高度内（即下落进度的 35%–65%，线 crossing 前后约 0.45 秒）时轻轻点头 = 接住（+1，语音「接住了」）。
3. **点头早了 / 晚了**：在窗口之前点头，语音说「早了」；窗口之后点头，语音说「晚了」；这个球都算没接住，球继续落到底，然后才换下一个球——一个球只能点头一次，没有第二次机会。
4. **没点头**：球落到底还没点头，语音说「没接住」，换下一个球。球与球之间停 1 秒，语音说「下一个」。
5. **完成**：10 个球落完，屏幕显示「接住 x / 10」，点「再来一局」重新开始。进行中点一下（真机）只重读提示，绝不会替你接球——接球只能靠点头。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 进行中重读提示 / 完成时再来一局 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |
| 点头（头部手势） | `onHeadGesture('nod')` | 接球——游戏的主动作，窗口内点头 = 接住 |

屏幕按钮只有一个（主按钮，文案随状态变：开始 / 朗读 / 再来一局）；网页预览无传感器时它显示为演示点头按钮（见下）。本游戏故意不用任何其他头部手势事件：该 API 官方文档只写了 `'nod'`，而接球用的正是 `'nod'`。

## 技术诚实说明

- **无眼动追踪**：平台没有眼动 API；接球信号只来自官方文档化的点头事件与方向传感器（备用）。
- **头部手势事件官方文档只写了 `'nod'`**：本游戏不声称任何其他手势事件；点头事件是主接球信号，传感器俯仰是备用信号，两者共用同一个「一球一判」守卫，绝不会把同一个球算两次。
- **下落与窗口（代码原样）**：每球固定 3 秒落到底，无加速；接球线在下落路径中点（50%）；窗口 = 下落进度 35%–65%（球心在接球线上下 15% 屏高内，线 crossing 前后约 0.45 秒）；球间停 1 秒、语音报「下一个」；计时 tick 50 毫秒。
- **一球一判（代码原样）**：点头处理只在球下落中且本球未判过时生效；接住后直接进 1 秒停顿，早了 / 晚了判负后球继续落到底再停顿；停顿中、准备中、完成中的点头一律忽略，绝不会漏进下一个球。
- **备用点头（代码原样）**：方向传感器四元数算俯仰（GA01 同款公式 `pitch = asin(2*(w*x - y*z))`，只用相对开局校准中心的差值），俯仰低过 20 度再回正到 10 度内 = 一次备用点头。注意：轻轻的点头可能不到 20 度——备用路径需要一次明显的点头，这个限制已如实说明；主路径（点头事件）接轻轻的点头。俯仰下方向沿用 GA01 的假设（低头 = 负相对俯仰），若真机符号相反，备用路径只会不触发、绝不会误判，主路径不受影响。
- **轨道显示与判定分离**：9 行轨道只是显示——球的行号是 `floor(进度 × 9)`（最大 8 行），从顶行落到底行、中间经过线行；判定永远用精确的进度窗口 35%–65%，不用行号。
- **传感器缺失 = SKIP / 演示，绝不假装通过**：网页预览没有方向传感器，屏幕明示 SKIP，演示按钮（「演示点头」）按当前球位置走同一套一球一判流程，完成屏写「演示接住 x / 10」；真机有点头事件时没有演示路径。
- **零持久化**：不调任何存储 API；得分、球状态与校准只活在页面内存里。

## 权限

无。`permissions` 为空数组：传感器、点头事件与 TTS 不在仅有的三项权限（`GEOLOCATION`、`CAMERA`、`RECORD_AUDIO`）之中，代码也不用这三项对应的任何功能，故一项不声明。空权限打包已验证通过。

## 打包与预览

```bash
cd ~/workspace/rokid/nod-catch
~/tools/bin/aix pack . -o ../dist/nod-catch.aix
~/tools/bin/aix list ../dist/nod-catch.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-nod-catch`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开点头接球智能体」。
5. 验收点：点开始，确认球从上落下、3 秒落到底、中间有接球线；在球过线时轻轻点头确认接住（+1，语音「接住了」）；故意在球还没到线时点头确认「早了」且该球不再可接；故意在线后点头确认「晚了」且该球不再可接；故意一个球完全不点头确认落底「没接住」；故意在同一个球上连点两次头确认只判一次；球间确认 1 秒停顿与语音「下一个」；10 个球后确认完成屏「接住 x / 10」与「再来一局」；**重点确认点头事件投递与备用路径**：轻轻点头是否可靠投递为点头事件；若宿主不投递点头事件，明显点头（俯仰过 20 度再回正）是否能经备用路径接住；若俯仰符号相反，备用路径不触发是否如实表现为「备用不工作、主路径仍工作」，而非误判；3 秒下落与 ±0.45 秒窗口在真机上是否感觉公平。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 点头接球（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Nod-catch timing game: voice-guided gentle nods catch falling balls on Rokid glasses. Ten balls fall one at a time over a fixed 3 seconds past a center catch line; nod while the ball is within 15% of screen height around the line to catch it. Early or late nods miss that ball, one nod per ball only. Small slow nods, no circling, no jerking. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；无自创 API；唯一头部手势处理是官方文档化的 `onHeadGesture('nod')`；权限为空且与实际使用一致（无相机/麦克风/ASR/LLM/存储调用）。
- `aix pack` 成功（见最终打包验证），`aix list` 确认包内含 README.md 与 AGENTS.md（打包在 README/AGENTS 定稿之后，见打包记录）。
- 预览截图 3 张已生成并逐张目检：准备（只轻轻点头的安全提示 + 开始）、进行中（下落中的球 + 接球线 + 得分）、完成（演示接住 x / 10 + 再来一局）各状态均与设计一致，互不重复。

**未验证（如实说明）**
- 宿主 TTS 实际发声、点头事件在真机上的投递与延迟、备用俯仰路径在真机上的 20 度阈值与符号方向、3 秒下落与 ±0.45 秒窗口的真机手感均待真机验证；传感器任一步缺失时游戏如实显示 SKIP / 演示，不假装计数。
- 本游戏是日常活动娱乐，不替代任何医疗或康复判断；颈椎不适者请先问医生，出现痛、晕、麻、恶心立刻停。

## 提审资料 (Review Submission)

### Feature Description

> Nod-catch timing game for Rokid glasses, voice-guided. Ten balls fall one at a time, each over a fixed 3 seconds, past a visible center catch line. Nod gently exactly as a ball crosses the line to catch it — the catch window is the ball within 15% of screen height around the line. A nod too early or late misses that ball, and one nod per ball only. Score is catches out of 10. Small slow nods only, no circling, no jerking; stop at any pain. Entertainment only, not medical advice.

### Opening Message

> ## 点头接球
>
> 坐稳，点一下开始：10 个球一个一个从上落下，每个球固定落 3 秒。**看准中间的线，轻轻点头接**——球心落到线的上下 15% 高度内点头，就是接住；点头早了说「早了」，晚了说「晚了」，一个球只能点头一次，没有第二次机会；一个球都没点头，落到底就是没接住。球与球之间停 1 秒，语音说「下一个」。最后看你接住几个（满分 10 个），点一下再来一局。只轻轻点头，不转圈、不甩头，痛、晕、麻、恶心立刻停。本游戏是日常活动娱乐，不是医疗建议。

### Preview Media

- `preview-nod-catch-ready.png` — 准备屏（只轻轻点头的安全提示 + 开始）
- `preview-nod-catch-playing.png` — 进行中（下落中的球 + 接球线 + 得分）
- `preview-nod-catch-done.png` — 完成屏（演示接住 x / 10 + 再来一局）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 接球一局 10 个球：TTS 全程指导（开始 → 接住了 / 早了 / 晚了 / 没接住 → 下一个 → 结束报分），屏幕显示下落的球 + 中间接球线、得分 x / 10 与一行提示
- 接球判定：每球固定 3 秒落到底，无加速；窗口 = 下落进度 35%–65%（球心在接球线上下 15% 屏高内，约 ±0.45 秒）；早了 / 晚了判负后球继续落到底，一球只判一次，停顿中与准备 / 完成中的点头一律忽略
- 点头双信号：一球一判守卫下的主信号 `onHeadGesture('nod')`（官方文档化，接轻轻点头）与备用信号（传感器俯仰过 20 度再回正到 10 度内，需明显点头），双路径同球只判一次
- 极简三态单页：准备 / 进行 / 完成，球间 1 秒停顿并语音报「下一个」，单击开始·重读提示·再来一局，双击系统返回不拦截
- 传感器缺失诚实 SKIP：网页预览明示 SKIP 并提供标注的演示点头路径（按当前球位置走同一套判定），真机有点头事件时无演示路径

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
