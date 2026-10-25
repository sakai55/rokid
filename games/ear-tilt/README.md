# 贴耳操 Ear Tilt

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-ear-tilt
```

头部动作小游戏系列 G03，极简设计：一页、三态（准备 / 进行 / 完成），语音指导做 6 次慢速左右贴耳。坐稳或站稳、头摆正，点一下开始：先校准——Agent 请你向左贴一下，记住哪边是左（这样真机左右方向即使反了也不会算错），然后一句一句带着你做——向左贴，稳住 5 秒（倒数 5、4、3、2、1），回正；向右贴，稳住 5 秒，回正，左右交替各 3 次。屏幕上只有大指令、计数和一行提示（含稳住时的倒数）；你的贴耳本身就是游戏动作，由方向传感器对照校准中心判定。

## 预览截图

![预览-准备](<../../screenshots/ear-tilt/preview-ear-tilt-ready.png>)
![预览-进行中](<../../screenshots/ear-tilt/preview-ear-tilt-playing.png>)
![预览-完成](<../../screenshots/ear-tilt/preview-ear-tilt-done.png>)

## 系列宪法：颈部安全（GO 的规则）

**转圈是错误的。** 只做分段动作：中心 → 一个方向 → 停住 → 回正到中心 → 再换方向。绝不连续转圈，绝不从一个极端直接扫到另一个极端，绝不快速甩动。慢、小幅度、到微酸即止，不到疼痛。**耳朵向肩膀贴，肩膀绝不抬起来迎耳朵——肩膀保持下沉**（语音指导里会反复说这一点）。出现痛、晕、麻、恶心，立刻停。先坐稳 / 站稳。一局 60–180 秒。本游戏是日常活动娱乐，**不是医疗诊断、治疗或康复处方**；有颈椎病、眩晕、术后、头颈伤史的人请先问医生。短版印在游戏内的准备屏上；完整版见 AGENTS.md。

## 玩法

1. **准备**：坐稳 / 站稳，头摆正，读一遍安全提示，点「开始」。
2. **校准（仅一句提示）**：按提示慢慢向左贴一下，Agent 记住哪边是左；再慢慢回正到中间。校准期间不计数。
3. **进行**：每一次 = 贴过去约 27° → 稳住满 5 秒（TTS 倒数 5、4、3、2、1，屏幕同步显示倒数）→ 回正到 10° 以内，TTS 报数（「第 1 次，向右贴，慢一点」……）。没贴够 5 秒就松开不计数；没回正就不算一次，也不能直接开始下一个方向（从一边直接扫到另一边不计数并提示「请先回正」）；贴错方向不计数并提示纠正；一次卡住不动，TTS 只重提示一次，绝不自动计数。
4. **完成**：6/6（左 3 + 右 3），点「再来一局」重新校准中心与左右、再玩一局。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 进行中朗读当前指令 / 完成时再来一局 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮只有一个（主按钮，文案随状态变：开始 / 朗读 / 再来一局）；网页预览无传感器时它显示为演示步进按钮（见下）。本游戏故意不用头部手势事件：该 API 官方文档只写了 `'nod'`，而点头不是本游戏的动作，左右贴耳全部来自传感器四元数。

## 技术诚实说明

- **无眼动追踪**：平台没有眼动 API；头部方向只来自 `AbsoluteOrientationSensor`。
- **头部手势事件官方文档只写了 `'nod'`**：不声称转头、摇头、倾斜等手势事件；左右判定全部来自传感器四元数。
- **阈值**：贴耳到位约 25–30°（代码取 27°），回正 <10°，稳住满 5 秒（有 `onOrientationStabilityChange` 稳定事件时仅在稳定时累计稳住时间，无事件时以计时为准并如实说明）；侧倾角公式为标准四元数转侧倾角（`atan2(2*(w*x + y*z), 1 − 2*(x*x + y*y))`，只用相对校准中心的差值）。
- **左右方向符号是学习的，不是假设的**：开局一句「请向左贴一下」，玩家实际贴过去的方向即被记为左，因此宿主侧倾角符号即使反了也不会把左算成右。剩余注意事项：校准默认玩家按提示真的向左贴——若反向贴，符号会学反；但校准期间不计数、第一局第一贴仍是向左（学反了立刻会觉得不对），且任何重开都会重新校准。真机验收必须确认：校准提示出现、真向左贴能完成校准、之后真向左贴计为左而非右。
- **传感器缺失 = SKIP / 演示，绝不假装通过**：网页预览没有方向传感器，屏幕明示 SKIP，演示按钮只走标注的演示计数（校准两步 + 每点一次算一整贴），完成屏写「演示完成」；真机有传感器时没有演示路径。
- **零持久化**：不调任何存储 API；计数、中心与学到的左右符号只活在页面内存里。

## 权限

无。`permissions` 为空数组：传感器与 TTS 不在仅有的三项权限（`GEOLOCATION`、`CAMERA`、`RECORD_AUDIO`）之中，代码也不用这三项对应的任何功能，故一项不声明。空权限打包已验证通过。

## 打包与预览

```bash
cd ~/workspace/rokid/ear-tilt
~/tools/bin/aix pack . -o ../dist/ear-tilt.aix
~/tools/bin/aix list ../dist/ear-tilt.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-ear-tilt`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开贴耳操智能体」。
5. 验收点：头摆正点开始，确认出现「请向左贴一下」校准提示；真向左贴确认完成校准、回正后第一贴是向左；做一次标准左贴（贴 → 稳住 5 秒听倒数 → 回正）确认计 1 次；故意贴过去不到 5 秒就松开，确认不计数；故意向右贴当轮到向左时，确认不计数且提示纠正；故意从左直接扫到右不回正，确认不计数且提示「请先回正」；一次贴过去后卡住 8 秒以上，确认只重提示一次、不自动计数；做满 6 次确认完成屏与「再来一局」重新校准；**重点确认左右符号**：真向左贴必须计为左、真向右贴计为右（若反了，说明校准时玩家贴反了，重开重新校准）；另确认稳住倒数 5、4、3、2、1 是否逐个报出、肩膀别抬的提示是否出现。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 贴耳操（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Slow side-tilt hold exercise: voice-guided segmented ear-to-shoulder motion, one-prompt left calibration, 5-second spoken-countdown hold, 3 left + 3 right = 6 reps, sensor-tracked against a calibrated center. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；无自创 API；无头部手势处理（该 API 仅文档化 `'nod'`，与本游戏动作无关）；权限为空且与实际使用一致（无相机/麦克风/ASR/LLM/存储调用）。
- `aix pack` 成功（8.45 KB），`aix list` 确认包内为源文件、无 artifacts。
- 预览截图 3 张已生成并逐张目检：准备、进行中、完成各状态均与设计一致，互不重复。

**未验证（如实说明）**
- 宿主 TTS 实际发声、方向传感器在真机上的读数与侧倾角符号、校准学习的真机表现、稳定性事件的真机投递、5 秒稳住倒数的真机报出均待真机验证；传感器任一步缺失时游戏如实显示 SKIP / 演示，不假装计数。
- 本游戏是日常活动娱乐，不替代任何医疗或康复判断；颈椎不适者请先问医生，出现痛、晕、麻、恶心立刻停。

## 提审资料 (Review Submission)

### Feature Description

> Side-tilt hold exercise for Rokid glasses, voice-guided. Sit steady, head straight, tap start: one calibration prompt asks you to tilt left once so the agent learns which way is left, then it talks you through each rep — ear toward shoulder, shoulder stays down, hold five seconds with a countdown, return to center — left and right alternating, three each, six total. Segmented motion only, never circling; a rep counts only as tilt, hold, return. Entertainment only, not medical advice.

### Opening Message

> ## 贴耳操
>
> 坐稳，头摆正，点一下开始：我先请你向左贴一下，记住哪边是左，然后带着你慢慢做 6 次贴耳——**向左贴，稳住 5 秒，回正；向右贴，稳住 5 秒，回正**，左右交替。耳朵向肩膀贴，肩膀别抬起来迎耳朵，幅度小，到微酸就停。
>
> 动作只做分段的，不转圈、不甩头、不从一边直接扫到另一边。痛、晕、麻、恶心，立刻停下来。本游戏是日常活动娱乐，不是医疗建议。

### Preview Media

- `preview-ear-tilt-ready.png` — 准备屏（安全提示 + 开始）
- `preview-ear-tilt-playing.png` — 进行中（大指令 + 计数 3/6）
- `preview-ear-tilt-done.png` — 完成屏（6/6 + 再来一局）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 慢速左右交替贴耳操一局 6 次：开始校准头部中心 + 一句「请向左贴一下」学习左右符号，贴耳 27° → 稳住满 5 秒（TTS 倒数 5、4、3、2、1，屏幕同步倒数）→ 回正 10° 内计 1 次，左 3 + 右 3 交替，TTS 逐步报数
- 防错计数：未稳住满 5 秒松开不计数、未回正不计数且下一方向不接受、从一边直接扫到另一边不计数并提示回正、贴错方向不计数且语音纠正、卡住 8 秒只重提示一次绝不自动计数、校准期间不计数
- 极简三态单页：准备 / 进行 / 完成，校准作为进行中的第一步提示（非额外状态），单击开始·朗读·再来一局，双击系统返回不拦截
- 传感器缺失诚实 SKIP：网页预览明示 SKIP 并提供标注的演示计数路径，真机有传感器时无演示路径

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
