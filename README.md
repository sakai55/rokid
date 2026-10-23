# fall-guard — 跌倒守望（Rokid 眼镜 AIUI Agent）

50 个「指向性生活问题」Agent 的第 33 个。独居的人跌倒了没人知道——本 Agent 在打开期间盯着头部朝向流里的一个动作模式：猛烈翻转之后长时间一动不动。模式命中就出声问「你还好吗？」，有应答就取消；没人应答，就把预设的求助联系人大字显示、反复朗读，让本人或身边的人照着行动。

> ⚠️ **诚实定位（先读）**：它识别的是**动作模式**，不是跌倒；它**不能给任何人打电话或发消息**——AIUI 里没有这种 API，ALERT 只能显示和朗读你预设的联系人。它是尽力而为的出声确认层，不是医疗报警器，不能替代紧急呼叫按钮或个人报警服务；而且**只在 Agent 打开时工作**，没有任何后台监测。

## 预览截图

截图统一存放于仓库根目录 `screenshots/fall-guard/`。

![监测初始态：预览主机无传感器如实显示 SRC: NONE，判据常驻界面](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/fall-guard/preview-fall-guard-index.png)

![DEMO 确认态：模拟剧烈翻转 + 静止后状态机自动走进 CHECK，大字「你还好吗？」并显示应答倒计时](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/fall-guard/preview-fall-guard-check.png)

## 解决的问题

独居跌倒的风险不在摔的那一下，而在摔完之后：躺在地上、喊不出声、够不到手机，一躺几个小时。市面上的解法是胸前挂一个报警按钮——但按钮要记得戴、摔的时候要够得着、按得动。眼镜不一样：它就在头上，而「头」恰好是跌倒时动作最剧烈、跌倒后最静止的部位。把头部朝向流当成信号源，做一层「出声确认」：先问，人答了就没事；没人答，把求助信息喊出来给身边的人听。

## 指向性设计（为什么必须用眼镜）

- **头部运动流（HEAD）**：本 Agent 只用 `AbsoluteOrientationSensor` 四元数流作信号源（运行时另有 Accelerometer/Gyroscope，本 Agent 未使用；AIUI 没有跌倒 API）。相邻四元数夹角 ÷ 时间 = 头部角速度；任意 3 秒窗口内的姿势变化量 = 翻转增益。界面如实标注来源 `SENSOR / DEMO / NONE`。
- **两段判据（防误报的核心）**：正常回头、扭头和摔倒翻转一样快，单看速度必然天天误报——判据在第二段：翻转（3 秒内 ≥ 60°）**之后**连续 15 秒彻底静止（转速 < 15°/s 且不离开停止姿势的 3° 锥形区）。能自己动起来的人，观察立刻取消。两段缺一不可，这是写进状态机的，不是宣传话术。
- **冻流不算静止**：传感器流中断超过 3 秒，静止观察立即取消——冻住的数据和一动不动的头长得一模一样，宁可漏观察，不拿假数据凑数。
- **耳朵确认（MIC + TTS）**：CHECK 期间麦克风听**任意**声音（不设关键词、不做声纹——摔伤的人可能说不出完整的话），点头和点按同样有效；ALERT 的朗读是说给**附近的人**听的，这是眼镜扬声器在这个场景里真正的用途。

## 功能流程

1. 设置联系人（一次性）：REL 轮换关系（子女 / 配偶 / 邻居 / 护工）→ NAME 点后说一遍姓名，识别结果**原样**保存显示（听错了重说，Agent 绝不悄悄改名），存 wx 同步存储 `fallGuardContact`
2. 监测（MONITOR）：打开即守望；快速转头、走动、躺下翻身都不会触发——除非先有 ≥ 60° 的翻转、紧接着 15 秒彻底静止
3. 确认（CHECK）：大字 + 朗读「你还好吗？」每 15 秒重复；出声（任意内容）、点头、点 OK 或按 Enter 任一应答 → 记 `responded-ok` 回到监测；60 秒无应答 → ALERT
4. 求助卡（ALERT）：大字联系人 + 每 20 秒朗读求助句；卡面明示「我不能替你打电话」；手动 HELP 任意状态直达 ALERT；点 BACK 解除并记日志
5. 日志：`fallGuardLog` 只存 {时间，结果}（最多 30 条）：check-pattern / responded-ok / alert-no-response / alert-manual / alert-dismissed；DEMO 事件不入真实日志

## 权限

| 权限 | 用途 |
|---|---|
| RECORD_AUDIO | CHECK 期间的一次性语音应答识别；NAME 设置联系人姓名 |

不用相机、不用定位；头部朝向传感器在 AIUI 里不需要单独的权限声明。

## 打包与预览

```bash
cd ~/workspace/rokid/fall-guard
~/tools/bin/aix pack . -o ../dist/fall-guard.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线（`shot-fall.js`；Shot A = 初始监测态无点击；Shot B = 点 DEMO 一次后等待约 9 秒，状态机自行从 STILL 走进 CHECK，「你还好吗？」确认态入镜）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用分支导入：`https://github.com/sakai55/rokid/tree/agent-fall-guard`（该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging 点 **Repackage and Save**，确认顶部出现绿色 **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版 Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 fall-guard」，先 REL + NAME 设好真实联系人；安全验证法（**不要真摔**）：把眼镜拿在手里快速翻转 90° 后平放在桌上保持不动，应在约 15 秒后听到「你还好吗？」，出声应答验证取消；再放一次不理它，验证 60 秒后亮出联系人卡；另验证快速转头、正常走动、躺下翻身不触发

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 21.2 KB（本地打包 `dist/fall-guard.aix`，含本 README） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON 解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；app.json 权限恰为 `["RECORD_AUDIO"]`，与设计一致。
- 四元数夹角数学：Node 加载页面对象验证——单位四元数自夹角 0、与 rotX(90°) 夹角 90、rotX(30°) 与 rotX(80°) 夹角 50、q 与 −q 夹角 0（同一姿势）；null 与零范数输入返回 null。
- 状态机：Node 加载页面对象（wx 打桩）跑 40 条断言全过——无翻转的 30 秒静止不触发；翻转后持续运动 20 秒不触发；翻转 + 15 秒静止进入 CHECK 并记 `check-pattern`，点按应答回 MONITOR 并记 `responded-ok`；静止观察中途动一下立刻取消且计时清零；传感器流中断使观察取消（冻流不算静止）；45° 转头 + 静止不触发（未达 60° 增益）；CHECK 静默 60 秒升级 ALERT 并记 `alert-no-response`，求助朗读文案含联系人姓名且断言全文不含「已联系 / 已呼叫」；BACK 解除记 `alert-dismissed`；手动 HELP 直达 ALERT 并记 `alert-manual`；日志上限 30 条保最新；联系人存储往返恢复。
- DEMO 确定性：联系人为虚构「子女 · 小明」，落点为 STILL 9.0s / 15s（纯种子，无 Date 依赖）；约 6 秒后状态机自行走进 CHECK；DEMO 期间联系人不落盘、演示事件不入真实日志，CLEAR 退出后真实联系人恢复——均由断言覆盖。
- 打包：`aix pack` 成功，21.18 KB（21,688 B）；`aix list` 核对包内含 AGENTS.md、app.js、app.json、package.json、README.md、pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方 Preview Media）：初始监测态完整渲染（预览主机无可用方向传感器，如实显示 `SRC: NONE`）；DEMO 态渲染出 STILL 种子后状态机自行升级的 CHECK 确认态（大字「你还好吗？」+ 应答倒计时），与 Node 断言行为一致。

**未验证**

- 真机 AbsoluteOrientationSensor 在 5Hz 下对真实跌倒翻转的采样质量：翻转可能快于采样间隔，增益窗口的实际表现要真机（手持模拟、安全垫）才有结论；阈值 60° / 15 秒 / 60 秒届时可能需要按实测调整。
- 真机上摘眼镜放桌、躺下睡觉、乘车颠簸等日常场景的误报率——这是本设计最大的未知数，需长时佩戴记录。
- CHECK 期间 SpeechRecognition 对老人语音、方言、微弱呼救声的识别率（识别不到时仍有 60 秒升级 ALERT 兜底，但应答取消会失效，只能靠点头/点按）与真机 TTS 效果。
- 本 Agent 不能打电话/发消息、只在打开时工作、识别的是模式不是跌倒——这些是能力边界而非缺陷，见文首诚实定位。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Fall Guard keeps watch while it is open on your glasses. It reads the head-orientation stream for one pattern: a violent turn (60 degrees or more in 3 seconds) followed by 15 seconds of complete stillness. A fast turn alone never triggers - only the motionless head after it. On a match it asks aloud, 'Are you OK?' Any reply, nod or OK tap cancels. No answer in 60 seconds and it shows your pre-set emergency contact in big type and reads it aloud on repeat, so you or someone nearby can act.

### Opening Message

Hi, I'm **Fall Guard**. While I'm open I watch your head-orientation stream for one pattern: a **hard jolt** (60° in 3 s) then **15 s still**. A fast turn alone never triggers - only the stillness after it.

On a match I ask aloud: **are you OK?** Say anything, **nod**, or tap **OK**. No reply in **60 s** and I show and read aloud the **emergency contact** you set via **REL + NAME**.

Honest limit: **I cannot call anyone** - only show and speak the contact. I detect a pattern, not falls.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-fall-guard-index.png`（aix preview 初始监测态：SRC: NONE、判据常驻、联系人未设置，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-fall-guard-check.png`（DEMO 确认态：模拟翻转 + 静止后进入 CHECK，大字「你还好吗？」+ 应答倒计时，联系人卡为虚构 DEMO 联系人，本地文件）
- Video：待真机补 — 真机录制「手持眼镜快速翻转后平放桌面 → 约 15 秒后出声询问 → 出声应答取消；再放一次不理 → 60 秒后联系人卡亮起并朗读」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Fixes**

- Corrected the on-screen detection rule to match the implementation: it previously read "JOLT > 240 deg/s", a threshold that does not exist in the code; the screen now states the real rule (a jolt is 60 degrees or more of reorientation within 3 seconds, then 15 s motionless = CHECK). Also removed the incorrect platform claim that the orientation stream is "the only motion basis in the AIUI runtime" - the runtime also documents Accelerometer/Gyroscope, which this agent does not use (capability-boundary audit, 2026-10-24).

#### Build 1.0.0

**Features added**

- Fall-pattern state machine on the documented AbsoluteOrientationSensor quaternion stream (this agent's chosen motion basis - the runtime also documents Accelerometer/Gyroscope, which this agent does not use; there is no fall-detection API): angular speed from successive quaternions, a jolt is 60 degrees or more of reorientation inside any 3-second window, and the CHECK state requires a further 15 continuous seconds of stillness (speed under 15 deg/s, inside a 3-degree cone of the stopped pose). Either half alone - a fast turn, or a motionless head - can never trigger, which is what keeps normal head turns, walking and lying down from raising false checks all day.
- Spoken check with open response: on a match the glasses ask 'are you OK?' immediately and every 15 seconds, listen for ANY recognized speech (deliberately no keyword and no voiceprint - a hurt person may only manage a groan), and accept a head nod, an OK tap or the Enter key as the same answer; a response logs 'responded-ok' and returns to monitoring. Movement during the stillness watch, and any break in the sensor stream (a frozen stream would otherwise fake stillness), cancels the watch outright.
- Pre-set emergency contact card: relation cycled with REL (child / spouse / neighbor / caregiver), the name dictated once with NAME and stored verbatim on-device (wx key fallGuardContact - a name is never silently 'corrected'); 60 seconds without a response, or a manual HELP tap in any state, raises the ALERT card, which shows the contact in big type and reads the help sentence aloud every 20 seconds (with a dial-120 fallback line when no contact is set). An on-device event log (times and outcome categories only, capped at 30, wx key fallGuardLog) supports family review.
- DEMO simulation, memory only: a synthetic 95-degree jolt followed by stillness lands in the STILL watch at 9.0 of 15 seconds and escalates into CHECK on its own seconds later; the demo contact is fictional and labeled DEMO, is never persisted, and demo events never enter the real log.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
