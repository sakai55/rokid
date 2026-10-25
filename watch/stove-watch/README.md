# 灶台守望 stove-watch

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-stove-watch
```


注意力外挂系列 **W01**（守望型 WATCH）· Rokid 眼镜 AIUI Agent

开火时逐个看向锅登记并设时，之后三口锅的倒计时在你视线里
并行走着；哪口到点，它按「相对你的方向」叫你一次，并把提
醒留在眼前，直到你真的转头看回那口锅——回看本身就是确
认。你只管做菜，时钟归它。

## 预览截图

![初始界面：还没登记任何锅，提示看着一口锅点 SET](<../../screenshots/stove-watch/preview-stove-watch-index.png>)

![DEMO：两口锅并行计时，汤锅还剩 4 秒，指南给出回看方向](<../../screenshots/stove-watch/preview-stove-watch-demo.png>)

![汤锅到点后转头看回它，回看确认（face）闭环，蒸锅继续计时](<../../screenshots/stove-watch/preview-stove-watch-acked.png>)

## 解决的问题

做饭时最耗神的不是手艺，是轮流盯表：汤在炖、菜在炒、水在
烧，三个倒计时全靠脑子轮着转——切着菜想着汤，备着料忘了
锅，注意力一切过去，必糊一个。问题不在记性，在于人的注意
力只有一个焦点，而灶台要三个。

本 Agent 外包的正是这份「轮流盯表」的注意力：登记之后，
三个倒计时由它同时数着；到点的提醒不靠你想起来，而是它
按方向叫你；确认不靠你按键，而是你真的回头看了一眼——
注意力闭环就此合上。

## 注意力外包设计

- 外包哪种注意力：**守望型（WATCH）**——持续低强度的时
  间监视。它不需要你的眼睛，只需要一个不走神的时钟和一
  个知道「哪口锅在哪个方向」的登记簿。
- 为什么必须是眼镜（胸前设备做不了）：登记与确认都长在
  视线轴上。登记 = 你看着一口锅点 SET，头部朝向
  （`AbsoluteOrientationSensor`）就是这口锅的地址；提
  醒 = 按相对方向喊「左边的汤锅到时间了」，你不用读屏
  就知道往哪看；确认 = 你转头看回那口锅、停满 1 秒，
  回看动作本身完成确认。胸前挂的设备看不见你看向哪
  里，也没法把「你刚才真的回头看了一眼」变成信号——
  它的提醒只能靠你掏出手机按键确认，注意力闭环断在
  最后一公里。
- 三个并行时钟、一个确认语义：250ms 一拍的引擎同时数
  三口锅（一律拍数累计，不反复读时钟）；到点只喊一
  次，横幅留下等回看；多口同时到点时逐个处理，确认一
  口、下一口顶上来。
- 响度守听只是加层，不是主菜：厨房持续变响（电平口
  径，见下）时它多提醒一次；没有这层，倒计时闭环也完
  整成立。

## 功能流程

1. 登记（SET）：站在平常做饭的位置，看着一口锅，单击
   触控板（或点 SET）打开登记；下滑换名字（汤锅 / 炒
   锅 / 蒸锅 / 饭锅），上滑换时长（5 / 10 / 15 / 20 /
   30 分钟），再单击开始。这口锅从此绑定当前朝向。最
   多 3 口；计时中的锅点 TIME 可加 5 分钟。
2. 守望：清单里每口锅显示剩余时间与相对你当前脸朝向
   的方向（「左边的汤锅 还剩 03:00」）。方向永远是相
   对量，不报东南西北。
3. 到点：TTS 按当时的相对方向朗读一次，如「正后方的
   汤锅到时间了」；横幅留在眼前，不重复喊。
4. 回看确认：转头看向那口锅——头稳住、朝向落入登记
   朝向 ±15° 内连续满 1 秒——即确认（记 `face`）；也
   可点 ACK（记 `tap`）。快速扫过不算，换一口重新计
   时。
5. 守听（LISTEN，可选）：开启后全向麦克风流只喂一个
   电平表；电平持续高于 0.55 满 10 秒，提醒一次
   「厨房声音持续很大，看一眼你正前方的锅」；同一段
   响声只提醒一次，电平回落才重新布防。关页面或再点
   一次 LISTEN 立即停麦。
6. DEMO：播入两口演示锅（汤锅在 350°、还剩约 6 秒；
   蒸锅在 90°、还剩 5 分钟），演示头先停在 180° 背对
   汤锅；每点一次 DEMO 朝向 +45°，转到正对汤锅停满
   1 秒触发回看确认；转满一圈退出并恢复你真实的锅，
   全程不写任何存储。

## 手势映射

档案 §3.2.1 触控板手势。登记、计时、到点、回看确认全
流程可仅用手势与转头完成；按钮只作兜底与发现入口。

| 手势 | 系统键 | 本 Agent 行为 |
|---|---|---|
| 单击 | Enter | 情景主操作：登记中 = 开始计时；选中的锅等回看 = 确认（tap）；空槽 = 打开登记；计时中 = 朗读状态 |
| 上滑 | ArrowUp | 换选中槽（向上）；登记中 = 换时长档（5→10→15→20→30 循环） |
| 下滑 | ArrowDown | 换选中槽（向下）；登记中 = 换名字（汤锅→炒锅→蒸锅→饭锅循环） |
| 双击 | Backspace | 返回（宿主处理，本页不拦截） |
| 头部稳定时点头 | `onHeadGesture('nod')` | 只朗读状态——点头永不登记、永不确认（防误触；确认只认回看或单击） |
| 转头看回锅并停稳 1 秒 | 朝向传感器 + 稳定事件 | 回看确认（face）：该锅朝向 ±15° 内、头稳住、连续 1 秒 |

保留的 6 个按钮及理由：SET 是登记入口（手势的单击与之等
价，但新用户需要可见入口）；TIME 是计时中加 5 分钟的唯
一入口；ACK 是转头不便时（如手持重物侧身）的确认兜底；
LISTEN 涉及麦克风开启，必须有明确可见的开关，绝不自动
开麦；SPEAK 与点头等价，留给不方便点头的场景；DEMO 是
无灶台环境下预览完整闭环的唯一入口。

## 权限

| 权限 | 用途 | 说明 |
|---|---|---|
| RECORD_AUDIO | 只在点 LISTEN 后开启全向 getUserMedia 流，喂 AnalyserNode 电平表做响度守听 | 音频从不录制/保存/上传；关页面立即停轨 |

倒计时、朝向登记、回看确认、TTS 都不需要任何权限。本
Agent **不写任何 wx 存储**——登记、剩余时间、电平都只在
本次会话内存里，页面关掉一切消失。

## 打包与预览

在本目录执行：

```bash
~/tools/bin/aix pack . -o ../dist/stove-watch.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

包文件 `stove-watch.aix`（约 22.1 KB），预览截图见上（本
地预览管线生成，artifacts/ 不入包）。

## 真机测试（Path 1）

1. 在 Global AIUI Studio 用 GitHub 子目录导入本分支：
   `https://github.com/sakai55/rokid/tree/agent-stove-watch`
2. Studio 里构建并保存新版本（Device Debug →
   Repackage and Save），等到云端打包完成提示。
3. 手机端打开海外版 Hi Rokid App：设置 → 开发者选项
   → AIUI → 更新眼镜资源包，等「智能体资源包下载成
   功」。
4. 对眼镜说「乐奇，打开灶台守望智能体」，或在智能体列
   表里打开，然后按下面的清单验收。

真机验收清单（建议）：

- [ ] 站在灶台前登记 3 口锅（不同朝向），方向词与实际
      位置一致（左/右/正前各一口）
- [ ] 三口 5 分钟计时并行走完，到点各喊一次、方向正确
- [ ] 到点后不转头：横幅一直在、不重复喊；转头看回并
      停满 1 秒：确认并显示 face；单击 ACK 路径同样成
      立
- [ ] 快速转头扫过到点的锅：不被确认
- [ ] LISTEN 开启后放一段持续响声（如开油烟机高档 +
      水龙头）满 10 秒：收到一次响度提醒且措辞只有
      「声音持续很大」；响声不断时不重复提醒；安静后
      再响可再次提醒
- [ ] LISTEN 状态下关页面重开：麦克风已释放（重开后是
      关闭状态）
- [ ] 登记时换站位：方向关系随之改变——确认 README
      的诚实说明与实际一致

## 真机测试信息

| 字段 | 内容 |
|---|---|
| Studio 名称 | 待导入后回填 |
| Version / Build | 1.0.0（首版，待导入后回填 Build 号） |
| App Category | 待导入后回填（提审时按内容填写） |
| Intent Description | Stove Watch: look-to-register pot timers with look-back acknowledgement |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成（静态校验 + Node harness 102/102 + 预览截图），未导入 Studio、未真机测试 |

## 验证情况

### 已验证

- 静态校验通过：app.json / package.json / `<script def>`
  JSON 解析；`<script setup>` 与 app.js 的 `node
  --check`；无 `Page(` / `App(` / `Widget(` /
  `workers:` 残留。
- Node harness 102 条断言全过（wx / 朝向传感器 /
  getUserMedia / AnalyserNode / TTS 桩 + 手动 tick 驱
  动）：三口锅并行倒计时与拍数数学；到点按相对方向朗
  读且仅一次、横幅留存；回看确认的锥形（±15°）与 1
  秒停留语义（不足不确认、换锅重新计时）；ACK 与
  Enter 两条确认路径；两个到点项的排队呈现；登记上
  限与无朝向拒绝；响度守听的持续 10 秒触发、单段只
  提醒一次、回落重新布防、短时尖峰不触发；
  OverconstrainedError 回退默认麦克风并如实标注；
  onHide 停麦停表；纯手势全流程（Enter/上滑/下滑完成
  登记与确认）；点头永不登记/确认（只朗读状态）；
  DEMO 播种、到点、回看确认、退出后真实锅原样恢复；
  **全程 wx 存储写入次数 = 0**；任何 utterance 的
  `lang` 从未被设置。
- aix pack 成功，包内含 README.md 且不含 artifacts/；
  预览截图 3 张为当前构建实拍：初始态、DEMO 双锅计时
  态、回看确认闭环态（方向词与头部朝向的几何关系在
  截图中可核对：汤锅 reg 350°，头在 180° 时显示「正
  后方 170°」，转到 0° 后确认）。

### 未验证

- **LISTEN 是响度守听，不是沸腾识别（最重要的边界）**：
  AIUI 运行时没有声音分类器，本 Agent 只测 RMS 电平。
  它不能分辨沸腾、溢锅、油爆、电视声；小火慢炖可能根
  本过不了 0.55 阈值，大油烟机可能一开就过。0.55 这
  个阈值与 10 秒持续时长的「手感」只能在真实厨房里校
  准，本地预览无麦克风、无真实声场，未验证。
- 宿主真机上 getUserMedia + AnalyserNode 的持续电平行
  为（采样稳定性、增益、与系统降噪的相互作用）未验
  证；`microphoneMode: 'omnidirectional'` 只作用于这
  条电平流，模式的真机可用性靠 getSettings 回读标
  注，未验证。
- 真机朝向传感器在厨房环境（转身、俯身看锅、蒸汽）的
  yaw 漂移与稳定事件表现未验证；±15° 锥形 + 1 秒停
  留的体感需真机调。
- TTS 在真机的播报音量与厨房噪声下的可懂度未验证
  （本 Agent 无「喊第二遍」机制——如真机证明听不清，
  需重新设计，而不是偷偷重复播报）。
- 守望只在 Agent 打开时存在：息屏/退出后的行为以宿
  主为准，本 Agent 不做任何后台承诺。

## 提审资料 (Review Submission)

> Global Studio「提审」页逐项对应，导入后可直接抄录。

### Feature Description（488 字符，上限 500）

Stove Watch outsources the pot-watching loop while you cook. Register up to three pots by looking: each binds to that head heading with its own countdown, and all timers run side by side in your view, hands free to chop. When a pot runs out, it calls you once by direction - the soup pot on your left is done - and waits until you actually look back at it. An optional loudness watch nudges you once if the kitchen stays loud for a while. Loudness only; it never claims to detect boiling.

### Opening Message（492 字符，上限 500，支持 Markdown）

Hi, I am **Stove Watch** - I keep the pot timers, you keep cooking.

Look at a pot and tap **SET**: swipe down for its name, swipe up for the minutes, tap again to start. Up to three pots count down together, each labelled with its direction from you. When one runs out I call it once - then I wait until you **look back at it** for a second; that glance is the acknowledgement. Turn on **LISTEN** and I nudge you once if the kitchen stays loud a while - loudness only; I cannot hear boiling.

### Preview Media

提审要求 3–5 个文件，且至少 1 张图 + 1 个视频（视频
≤60 秒）。本地已生成 3 张预览图（见上方「预览截图」，
中央存于仓库 `screenshots/stove-watch/`）：

1. `preview-stove-watch-index.png` — 初始界面：空登记簿
   与诚实常驻行
2. `preview-stove-watch-demo.png` — DEMO：两口锅并行计
   时与回看方向指南
3. `preview-stove-watch-acked.png` — 回看确认（face）
   闭环后的状态

视频（1 个，≤60 秒，真机拍摄「登记 → 到点 → 回看确
认」完整闭环）：**待真机测试时补拍**，补齐后再提审。

### Change Log

**Build 1.0.0（首版）**

Features added:

- 看向锅登记：头部朝向绑定 + 名字/时长两维滑动选择，
  最多 3 口锅并行倒计时
- 到点单次方向播报 + 横幅留存，确认语义为「回看」
  （±15° / 1 秒）或单击 ACK
- LISTEN 响度守听：全向电平流、持续 10 秒大响度单次
  提醒、回落重新布防
- DEMO 双锅播种，完整预览到点与回看确认闭环

Improvements:

- （首版，无）

Fixes:

- （首版，无）
