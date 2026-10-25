# cross-street — 过街确认（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-cross-street
```


50 个「指向性生活问题」Agent 的第 Z34 个。过马路出事，往往不是不会看，而是走神——低头看手机、想着心事，一侧根本没看就迈了步。本 Agent 在你起步之前管住你的头：先左转头停稳、再右转头停稳（顺序可反），两侧都确认了才播报「左右都看过了」。

> ⚠️ **诚实定位（先读）**：它确认的是**你的头转过去并停稳了**，不是「路上没车」。它没有相机参与、看不见车辆、电动车和信号灯——PLAN 里这项写的「可通行参考」，在本 Agent 里只落实为对**看的动作**的完成记录，判定行逐字是「双向确认完成（仅供参考）— 眼镜看不见车辆，过街全程请继续观察」。界面与朗读文案里不存在任何「可以通行 / 安全通过」式的说法。它消灭的只有一种失败：忘了看、只看了一边。

## 预览截图

截图统一存放于仓库根目录 `screenshots/cross-street/`。

![初始态：站在路边面朝马路点 START；预览主机无传感器如实显示 SRC: NONE，规则与进度条常驻界面](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/cross-street/preview-cross-street-index.png)

![DEMO 进行态：基准 100°，左侧已确认，头在 +40°，指引「向右还差 20° 到确认区」；DEMO 不写日志（LOG 仍为 0）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/cross-street/preview-cross-street-ritual.png)

## 解决的问题

「左右看」是每个人都学过的动作，失败模式不在知识而在执行：赶时间、低头看手机、和同伴说话、只朝来车方向瞥一眼就走。特别是安静又快的电动车，常常就从没看的那一侧过来。手机做不了这件事——它不知道你的头朝哪；眼镜可以：它就长在头上，头部朝向就是现成的信号。把过街拆成一个不可跳步的仪式：基准、一侧确认、另一侧确认，每一步都要用真实的转头 + 停稳来完成，过完这个仪式，「没看」这件事就没有藏身之处了。

## 指向性设计（为什么必须用眼镜）

- **基准朝向（HEAD）**：`AbsoluteOrientationSensor` 四元数算 yaw。START 时你面朝马路的朝向被存为基准——眼镜不知道马路在哪，基准就是你点开始时脸朝的方向，这是明说的约定而不是假装的定位。
- **相对转头角（HEAD）**：rel = 当前朝向 − 基准（−180..180，+ = 右转，与全系列一致的符号约定）。左右各 ≥60° 才进确认区；界面上的进度条把 rel 实时画出来：`◆` 是你的头，`+` 是两侧 ±60° 确认区，`|` 是基准方向，还差多少度一目了然。
- **停稳判定（HEAD 稳定性）**：进了确认区还要连续停稳 1 秒——头部朝向 250ms 内没有 ≥2° 变化、样本流活着、且宿主 `onOrientationStabilityChange` 没有报告移动中。样本流超过 750ms 没有新样本即视为已断（5Hz 下正常间隔约 200ms）：冻住的流和停稳的头长得一样，绝不拿它凑数；且 250ms 沉降 + 1000ms 保持放不进 750ms 的死亡窗口，流一断，保持永远攒不满。点头只朗读进度——点头是俯仰，永远冒充不了转头。
- **耳朵收尾（TTS）**：每侧确认即出声播报，免得你低头看界面；双确认后朗读判定，全程不用手、不用看屏幕细节。

## 功能流程

1. 站到路边，面朝你要过的马路，点 START（或按 Enter）：当前朝向存为基准，界面显示 `REF: xxx°`
2. 向左转头超过 60°，停稳 1 秒 → 左侧 ✓ + 朗读「左边看过了。」（先右后左完全一样，顺序不限）
3. 向另一侧转头超过 60°，停稳 1 秒 → 右侧 ✓；两侧齐了进入完成态：大字「左右都看过了 — LOOKED BOTH WAYS」+ 逐字判定行 + 朗读「左右都看过了。过街时请继续左右观察，注意车辆。」
4. 完成时间记入本机日志 `crossStreetLog`（只存时间，最多 30 条）；LOG 朗读累计次数与最近一次；RESET 回到路边重来（日志保留）；CLEAR 清日志（DEMO 中点 CLEAR 是退出演示）

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限 |

不用相机、不用麦克风、不用定位；头部朝向传感器在 AIUI 里不需要单独的权限声明，故 app.json 无 `permissions` 字段（同 #07 / #15 / #28 / #30）。

## 打包与预览

```bash
cd ~/workspace/rokid/cross-street
~/tools/bin/aix pack . -o ../dist/cross-street.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线（`shot-cross.js`；Shot A = 初始路边态无点击；Shot B = 点 DEMO 一次（canvas 坐标 233,308，视觉定位），落在进行态 1/2：左侧已确认、头在 +40°、向右还差 20°）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用分支导入：`https://github.com/sakai55/rokid/tree/agent-cross-street`（该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging 点 **Repackage and Save**，确认顶部出现绿色 **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版 Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 cross-street」；**先在安全的人行道/空地验证、不要站在车行道上调参数**：面朝一个方向点 START，依次左转 60° 以上停稳、右转 60° 以上停稳，应听到两侧播报与双确认判定；再验证只转一侧、转够但不停稳、快速甩头扫过都不确认；**重点验证左右符号**：左转时界面 REL 应为负、指引应指向左（与兄弟 Agent 共用同一套符号约定，真机首次必须实测一次）；最后再到真实路口完整走一遍——并照常边过街边左右观察

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 19.3 KB（本地打包 `dist/cross-street.aix`，含本 README） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON 解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；app.json **确实没有** `permissions` 字段，与零权限设计一致（断言覆盖）。
- 文案纪律：断言页面源码包含逐字判定行「双向确认完成（仅供参考）— 眼镜看不见车辆，过街全程请继续观察」，且不含「安全通过 / 可以安全过街 / 可以通行 / 安全过街 / 可以过街 / 放心通过 / 通行许可 / 可以过了」中任何一串——判定只记录「看过」，从不宣称路是空的。
- 相对角数学：Node 加载页面对象验证——`_rel` 跨 0°/360° 环绕正确（基准 350°、头转到 50° = +60；基准 10°、头转到 310° = −60），进度条 21 格、基准位与 ◆ 位置正确（含 +40 → 第 14 格、−70 → 第 2 格、钳制在两端）。
- 状态机：Node 加载页面对象（wx 打桩）跑 **84 条断言全过**——无朝向时 START 拒绝且不编造基准；快速甩头扫过 −70° 不确认（转头未停稳）；在 +30° 完美停稳 3 秒不确认（停稳未转够）；停稳满 1 秒确认该侧并朗读对应侧文案；**先右后左**的顺序同样完成并进入 DONE、判定行逐字显示、判定朗读发出、日志记 1 条且只存时间、持久化到 wx 存储、DONE 中多余 tick 不重复记账、RESET 回 IDLE 且保留日志、日志可从存储往返恢复；环绕基准下恰好 ±60° 确认、−59° 差 1° 不确认（边界是 60°）；确认中途转回阈值内、宿主报告「移动中」、样本流冻死三种打断都使保持计时清零且无法凑满（750ms 新鲜度窗口）；点头只朗读进度、永远不确认任何一侧。
- DEMO 确定性：基准 100°、左侧已确认、头在 +40°、指引恰为「还差 20°」，全部为纯常量种子（无 Date 依赖）；再点一次 DEMO 后由真实状态机确认右侧并走完判定；DEMO 期间不写日志、不落盘，CLEAR 退出后回到真实 IDLE——均由断言覆盖。
- 打包：`aix pack` 成功，19.26 KB（19,721 B）；`aix list` 核对包内含 AGENTS.md、app.js、app.json、package.json、README.md、pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方 Preview Media）：初始路边态完整渲染（预览主机无可用方向传感器，如实显示 `SRC: NONE`，传感器 error 被页脚接住、无崩溃）；DEMO 态渲染出进行态 1/2（左侧 ✓、REL +40、进度条 ◆ 在位、向右指引 20°），与 Node 断言行为一致。

**未验证**

- 真机 AbsoluteOrientationSensor 的 yaw 零点漂移与左右符号：rel 的正负约定与兄弟 Agent 共用同一套（+ = 右），但「左转时 rel 变负」必须在真机上实测确认一次——这是本 Agent 真机首测的第一项，README 的真机步骤里已列明。若真机符号相反，翻转的只是符号映射一处，不影响状态机。
- 真机上头部朝向的抖动幅度：停稳门限（2° / 250ms）是按经验设的，眼镜佩戴松动、步行中的自然摆动会不会让 1 秒保持难以攒满，要真机在路边实测；阈值（60° / 1 秒 / 2°）届时可能需要按实测调整。
- 真机 TTS 播报在街道噪声环境下的可听性，以及行人实际过街节奏里这个仪式是否顺手（会不会因为赶时间被跳过）——只能靠真实路口试用回答。
- 本 Agent 看不见车辆与信号灯、基准取决于你点 START 时的朝向——这些是能力边界而非缺陷，见文首诚实定位。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Cross Street makes sure you actually look both ways before crossing. At the curb, face the road and tap START: that heading becomes the reference. Turn your head 60 degrees or more to one side and hold it steady for one second and that side is confirmed; then do the other side, in either order. When both sides are confirmed it announces that you looked both ways - a record of the looking ritual only. It cannot see cars, bikes or lights, and it never declares a crossing safe.

### Opening Message

Hi, I'm **Cross Street**. At the curb, face the road and tap **START** - that heading is your reference. Turn your head **60 degrees or more left** and **hold steady 1 second**; then the same to the **right**. Either order works. When both sides check in, I announce that you **looked both ways** and log the time. Honest limit: I only verify your head turned and paused. **I cannot see vehicles or traffic lights**, and I never call a crossing safe - keep looking all the way across.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-cross-street-index.png`（aix preview 初始路边态：SRC: NONE、规则与 ±60° 进度条常驻、无基准提示，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-cross-street-ritual.png`（DEMO 进行态 1/2：基准 100°、左侧已确认、头在 +40°、指引「向右还差 20°」，DEMO 不写日志，本地文件）
- Video：待真机补 — 真机在安全人行道录制「面朝一方点 START → 左转停稳确认 → 右转停稳确认 → 双确认判定行与朗读」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Look-both-ways ritual state machine on the documented AbsoluteOrientationSensor quaternion stream (yaw), the same heading basis as the sibling agents: START at the curb captures the heading you face as the reference (with no heading the capture is refused - a reference is never invented, and the agent honestly does not know where the road is). Each side then confirms independently, in either order, when the head has turned 60 degrees or more that way from the reference AND held steady for one continuous second; mid-hold movement, turning back inside the threshold, a host 'moving' stability event, or a dead sample stream all reset the hold, so a fast head sweep can never fake a side.
- Live relative-angle guidance: the current heading, the signed relative angle, and a 21-step progress bar (marker = your head, '+' = the +-60 degree hold zones, '|' = the reference) plus a plain next-step line ('20 degrees more to the hold zone', 'holding 0.6s / 1.0s'), so the wearer always knows what the ritual still needs. Each confirmed side is spoken aloud ('left side looked'), and a head nod only ever reads progress aloud - a nod is a pitch motion and can never stand in for a turn.
- Two-sided verdict with strict wording discipline: when both sides are confirmed the glasses show and say that you looked both ways, with the on-screen verdict stating it is a reference only and that the glasses cannot see vehicles - no page or speech copy anywhere claims a crossing is safe or permitted. Completed rituals are logged on-device with their time only (wx key crossStreetLog, capped at 30), and a DEMO mode plays a half-finished ritual in memory (reference 100 degrees, left side done, head at +40 degrees) that the real state machine then completes, without ever writing the log.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
