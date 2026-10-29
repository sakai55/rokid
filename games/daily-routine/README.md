# 每日一套 Daily Routine

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-daily-routine
```

**AIX 直接下载**（最新版）：[daily-routine.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/daily-routine.aix)

头部动作小游戏系列 **GA20 / 20，收官之作**，D 组（趣味收尾），极简设计：一页、三态（准备 / 进行 / 完成），把 A 组 5 个动作串成一套约 2 分钟的日常流程。坐稳或站稳、头摆正，点一下开始：先校准——Agent 请你低一下头、向左转一下、向左贴一下，记住哪边是下、哪边是左、哪边是左贴（这样真机方向即使反了也不会算错）；然后跟着语音做 5 节，每节做完回正到中间，下一节才报；一节 30 秒没做完就先跳过，不硬撑。

## 系列收官索引

本游戏是 20 个头部动作小游戏的最后一作；前 19 作各一行，名字与导入分支如下：

- GA01 点头操 `nod-count` — `agent-nod-count`
- GA02 转头操 `turn-count` — `agent-turn-count`
- GA03 贴耳操 `ear-tilt` — `agent-ear-tilt`
- GA04 仰低拉伸 `stretch-hold` — `agent-stretch-hold`
- GA05 时钟点位 `neck-clock` — `agent-neck-clock`
- GA06 收下巴 `chin-tuck` — `agent-chin-tuck`
- GA07 稳头挑战 `steady-hold` — `agent-steady-hold`
- GA08 点头接球 `nod-catch` — `agent-nod-catch`
- GA09 左右闪避 `turn-dodge` — `agent-turn-dodge`
- GA10 追光点 `follow-dot` — `agent-follow-dot`
- GA11 节奏点头 `rhythm-nod` — `agent-rhythm-nod`
- GA12 方向记忆 `memory-seq` — `agent-memory-seq`
- GA13 找方向 `find-target` — `agent-find-target`
- GA14 端水平 `level-keep` — `agent-level-keep`
- GA15 慢速扫描 `slow-scan` — `agent-slow-scan`
- GA16 点头问答 `nod-quiz` — `agent-nod-quiz`
- GA17 呼吸转头 `breathe-turn` — `agent-breathe-turn`
- GA18 猜方向 `guess-direction` — `agent-guess-direction`
- GA19 红绿灯 `traffic-light` — `agent-traffic-light`

## 预览截图

![预览-准备](<../../screenshots/daily-routine/preview-daily-routine-ready.png>)
![预览-进行中](<../../screenshots/daily-routine/preview-daily-routine-playing.png>)
![预览-完成](<../../screenshots/daily-routine/preview-daily-routine-done.png>)

## 系列宪法：颈部安全（GO 的规则）

**转圈是错误的。** 本游戏每节只做一个方向，做完回正，下一节才报；绝不从一边直接扫到另一边，绝不快速甩动。慢、小幅度、到微酸即止；上方向只到轻微拉伸，绝不用力往后仰。出现痛、晕、麻、恶心，立刻停。先坐稳 / 站稳。一套约 2 分钟（按各节动作加回正估算约 90–120 秒，不是精确承诺），每节 30 秒没做完就先跳过。本游戏是日常活动娱乐，**不是医疗诊断、治疗或康复处方**；有颈椎病、眩晕、术后、头颈伤史的人请先问医生。短版印在游戏内的准备屏上；完整版见 AGENTS.md。

## 玩法

1. **准备**：坐稳 / 站稳，头摆正，读一遍安全提示，点「开始」。
2. **校准（三句提示）**：按提示慢慢低一下头（记住哪边是下），回正；再慢慢向左转一下（记住哪边是左），回正；再慢慢向左贴一下，耳朵贴向左肩、肩膀别抬（记住哪边是左贴），回正。校准期间不计数。
3. **第 1 节 · 点头 3 次**：慢慢低头，停约 0.8 秒，回正，算 1 次；做满 3 次。点头事件是主判定（官方文档只写了 `'nod'`），俯仰角备用判定兜底。
4. **第 2 节 · 转头左右各 2 次**：左、右、左、右交替，每次转过约 27°、停约 0.8 秒、回正，算 1 次。
5. **第 3 节 · 贴耳左右各 1 次**：耳朵贴向肩膀，稳住 3 秒，回正；左右各 1 次。注意：本节是 3 秒的日常版，比 GA03 的 5 秒短，是有意缩短，不是笔误。语音提醒「肩膀别抬」。
6. **第 4 节 · 仰低拉伸各 1 次**：先仰头稳 3 秒（只到轻微拉伸，不要用力往后仰），回正；再低头稳 3 秒，回正。同样是 3 秒的日常版，比 GA04 的 5 秒短。
7. **第 5 节 · 收下巴 2 次**：下巴水平往后收，像点头的一半还不到，稳住 3 秒，放松；做 2 次。同样是 3 秒的日常版，比 GA06 的 5 秒短。幅度到了 20° 就是低头不是收下巴，判无效并语音纠正；回正要求俯仰角 <8°。
8. **节间回正**：每节结束（最后一节除外）都要回正到中间（偏航角与俯仰角都 <10°），下一节才报；4 秒没回正语音提醒「请回正」，不回正绝不出下一节。
9. **跳过规则**：一节 30 秒没做完，语音说「这一节先跳过」，直接进下一节；跳过不算做完也不算失败，流程一定走完。
10. **完成**：5 节结束，完成屏报出做完几节（「完成 x / 5 节」），点「再来一局」重新校准、再做一套。

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 开始 / 进行中朗读当前指令 / 完成时再来一局 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮只有一个（主按钮，文案随状态变：开始 / 朗读 / 再来一局）；网页预览无传感器时它显示为演示步进按钮（见下）。头部手势事件只在第 1 节用 `'nod'`，且从不单独计数（见技术诚实说明）。

## 技术诚实说明

- **无眼动追踪**：平台没有眼动 API；头部方向只来自 `AbsoluteOrientationSensor`。
- **头部手势事件官方文档只写了 `'nod'`**：不声称转头、摇头、倾斜等手势事件；第 1 节之外的一切判定全部来自传感器四元数。第 1 节里点头事件也从不单独计数：它只完成传感器已经看到低头的那一次（回正时补算），或在低头已过 15° 时把等待推进稳住——俯仰角判定始终在场。
- **阈值**：方向约 27°（25–30° 带）；点头 / 转头稳住约 0.8 秒；贴耳 / 拉伸 / 收下巴稳住 3 秒（日常版）；收下巴带 14–20° 俯仰角，≥20° 算低头判无效、低于 11° 提前松开判无效，回正俯仰角 <8°；其余回正带偏航角与俯仰角都 <10°；每节 30 秒超时跳过；节间回正 4 秒未回正只语音提醒「请回正」绝不提前进下一节；俯仰角 `asin(2*(w*x − y*z))`，偏航角 `atan2(2*(w*z + x*y), 1 − 2*(y*y + z*z))`，侧屈角 `atan2(2*(w*x + y*z), 1 − 2*(x*x + y*y))`，只用相对校准中心的差值。
- **三轴符号都是学习的，不是假设的**：开局三句「请低一下头」「请向左转一下」「请向左贴一下」，玩家实际动过去的方向即被记为下、左、左贴，因此宿主符号即使反了也不会算错方向。剩余注意事项：校准默认玩家按提示真的做对应动作——若反向做，该轴符号会学反；但校准期间不计数，任何重开都会重新校准。真机验收必须确认：三句校准提示出现且真动作能完成校准、之后真低头计为下而非上、真左转计为左而非右、真左贴计为左贴而非右贴、收下巴真低头被纠正且不计数、30 秒未做完一节确实跳过且流程继续、节间回正是硬门（4 秒未回正只提醒不进下一节）。
- **收下巴判定如实说明（GA06 的风险标记，原样带过来）**：真收下巴主要是下巴水平往后收，方向传感器几乎看不到平移；平台也没有平移传感器 API。本游戏因此按小俯仰带 14–20° 判定，提示语特意说「像点头的一半还不到」。真机验收必须确认自然收下巴落在 14–20° 带里；若系统性偏低（纯平移读数接近 0°），修正办法是调低阈值带，而不是假装动作是别的；若没有任何小俯仰带能把收下巴和噪声分开，必须如实上报、不能当作能用的收下巴检测发货。
- **传感器缺失 = SKIP / 演示，绝不假装通过**：网页预览没有方向传感器，屏幕明示 SKIP，演示按钮只走标注的演示路径（校准六步 + 每节一按即完成，共 5 节），完成屏写「演示完成」；真机有传感器时没有演示路径。
- **零持久化**：不调任何存储 API；中心、学到的三轴符号、节次与完成数只活在页面内存里。

## 权限

无。`permissions` 为空数组：传感器与 TTS 不在仅有的三项权限（`GEOLOCATION`、`CAMERA`、`RECORD_AUDIO`）之中，代码也不用这三项对应的任何功能，故一项不声明。空权限打包已验证通过。

## 打包与预览

```bash
cd ~/workspace/rokid/daily-routine
~/tools/bin/aix pack . -o ../dist/daily-routine.aix
~/tools/bin/aix list ../dist/daily-routine.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-daily-routine`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开每日一套智能体」。
5. 验收点：头摆正点开始，确认出现「请低一下头」「请向左转一下」「请向左贴一下」三句校准提示；真动作确认完成校准、回正后进入第 1 节；5 节确认各按阈值计数（点头 3 次、转头左右各 2 次、贴耳左右各稳 3 秒、仰低各稳 3 秒、收下巴 2 次且真低头被纠正）；一节 30 秒未做完确认跳过且流程继续；节间确认必须回正才出下一节、4 秒未回正只提醒「请回正」不进下一节；5 节结束确认完成屏报出完成数且「再来一局」重新校准；**重点确认三轴符号**：真低头必须计为下、真左转必须计为左、真左贴必须计为左贴；**重点确认收下巴带**：自然收下巴落在 14–20° 带里，否则按 AGENTS.md 调阈值或如实上报。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | 每日一套（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Daily routine on Rokid glasses: one guided 2-minute neck routine in 5 fixed segments — 3 gentle nods, alternating turns left/right twice, ear-to-shoulder holds 3 seconds each side, up/down stretch holds 3 seconds each, and 2 chin tucks; return to center between segments, 30-second per-segment skip, no circles. |
| Agent ID | 待导入后回填 |
| 状态 | 未真机验证 |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；无自创 API；头部手势处理只有第 1 节的 `'nod'`；权限为空且与实际使用一致（无相机/麦克风/ASR/LLM/存储调用）。
- 逻辑检查 77 项全部通过（用合成传感器读数直接驱动真实 .ink 代码）：常量取自 .ink 源文件（27°/10°、0.8 秒 / 3 秒稳住、14–20° 收下巴带、8° 收下巴回正、30 秒节超时、4 秒回正宽限、每节次数 3/4/2/2/2、固定顺序）；三句校准；完整 5 节跑到 5/5；转头转错方向不计数；回正门在未回正时拦住；贴耳提前松开不计数；收下巴 ≥20° 判无效不计数；收下巴回正 <8° 走完流程；30 秒超时跳过（不算完成）且流程继续；点头事件路径（低头 15° 进稳住、回正时补算）。
- `aix pack` 成功，`aix list` 确认包内含 README.md 与 AGENTS.md、无 artifacts。
- 预览截图 3 张已生成并逐张目检：准备、进行中（第 1 节点头）、完成（演示完成 5 / 5）各状态均与设计一致，互不重复。

**未验证（如实说明）**
- 宿主 TTS 实际发声、方向传感器在真机上的读数与三轴符号、校准学习的真机表现、各节阈值与稳住手感、30 秒跳过与回正门手感、收下巴带在真机上的落点均待真机验证；传感器任一步缺失时游戏如实显示 SKIP / 演示，不假装计数。
- 本游戏是日常活动娱乐，不替代任何医疗、康复判断；颈椎不适者请先问医生，出现痛、晕、麻、恶心立刻停。

## 提审资料 (Review Submission)

### Feature Description

> Daily routine on Rokid glasses: one guided 2-minute neck routine in 5 fixed segments — 3 gentle nods, alternating turns left/right twice, ear-to-shoulder holds 3 seconds each side, up/down stretch holds 3 seconds each, and 2 chin tucks. Tap start, follow the voice, return to center between segments; any segment unfinished in 30 seconds is skipped, never forced. No circles, no fast jerks. Chin tucks are honestly detected as a small 14–20 degree pitch band.

### Opening Message

> ## 每日一套
>
> 坐稳，头摆正，点一下开始：我先请你低一下头、向左转一下、向左贴一下，记住哪边是下、哪边是左、哪边是左贴，然后带你做 **5 节——点头 3 次、左右转头各 2 次、左右贴耳各稳 3 秒、仰低拉伸各稳 3 秒、收下巴 2 次**。
>
> 每节做完要回正到中间，下一节才报；一节 30 秒没做完就先跳过，不硬撑。绝不转圈，不快速甩动。痛、晕、麻、恶心，立刻停下来。本游戏是日常活动娱乐，不是医疗建议。收下巴如实说明：真收下巴主要是下巴水平往后收，传感器只能看到一点点小俯仰，按 14–20° 小俯仰带判定。

### Preview Media

- `preview-daily-routine-ready.png` — 准备屏（安全提示 + 开始）
- `preview-daily-routine-playing.png` — 进行中（第 1 节点头）
- `preview-daily-routine-done.png` — 完成屏（演示完成 5 / 5 + 再来一局）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 每日一套：5 节固定顺序（点头 3 次、左右转头各 2 次、左右贴耳各稳 3 秒、仰低拉伸各稳 3 秒、收下巴 2 次），语音全程引导，点一下开始、再来一局重开
- 三句校准学三轴符号：开局「请低一下头」「请向左转一下」「请向左贴一下」学习下、左、左贴，宿主符号反了也不算错方向；校准期间不计数，重开重新校准
- 严格节间回正：每节结束（最后一节除外）必须回正到中间（偏航角与俯仰角都 <10°）下一节才报，4 秒未回正只语音提醒「请回正」绝不提前进下一节
- 30 秒节超时跳过：一节 30 秒没做完语音「这一节先跳过」，直接进下一节，跳过不算做完也不算失败，流程一定走完
- 收下巴诚实判定：按 14–20° 小俯仰带判定，≥20° 算低头判无效并语音纠正，提示语「像点头的一半还不到」，并把 GA06 的平移风险标记原样写入验收清单
- 极简三态单页：准备 / 进行 / 完成，校准与回正作为进行中的步骤提示（非额外状态），单击开始·朗读·再来一局，双击系统返回不拦截
- 传感器缺失诚实 SKIP：网页预览明示 SKIP 并提供标注的演示路径（校准六步 + 每节一按即完成，共 5 节），真机有传感器时无演示路径
- 系列收官索引：README 列出前 19 作的名字与导入分支各一行

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
