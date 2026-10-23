# cook-along — 做饭跟做（Rokid 眼镜 AIUI Agent）

50 个「指向性生活问题」Agent 的第 11 个。做饭时手上全是油和水，
翻不了手机菜谱，步骤还总做到一半就忘：菜谱就悬在你的视线里，
你看着锅做，点头或喊一声「下一步」就翻页，定时步骤在眼前倒计时、
到点出声提醒——全程不用腾手碰任何屏幕。

## 预览截图

截图统一存放于仓库根目录 `screenshots/cook-along/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/cook-along/preview-cook-along-index.png)

![DEMO 跳到番茄炒蛋第 3 步、倒计时运行中的步骤视图](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/cook-along/preview-cook-along-step.png)

## 解决的问题

手机菜谱在厨房里根本用不了：手脏手湿不能划屏，手机放远了看不清，
放近了溅上油；做到一半去洗手翻页，回来已经忘了刚才到哪一步。
本 Agent 把菜谱搬进视线：步骤大字就显示在你看锅的余光里，
翻页靠点头和声音，计时靠眼前的倒计时和到点朗读，做饭的手
从头到尾不用离开锅和案板。

## 指向性设计（为什么必须用眼镜）

- **菜谱在视线内（GAZE）**：当前步骤大字显示在视线里，你看着
  锅就等于看着菜谱，不用在锅和手机之间来回低头找步骤；
  LOOK 也是看着锅拍——视线指到哪，记录的就是哪口锅。
- **头部稳定 = 凝视确认**：`enableWorldAwareness()` 开启世界
  感知后，`onOrientationStabilityChange` 报告头部稳定时才
  响应点头（`onHeadGesture` 的 `nod`）：未开火时点头 = START，
  进行中点头 = NEXT。炒菜时身体晃动不会误触发，稳住头的一点
  才是确认。
- **4 麦 wearer 模式可用性检查（MIC4）**：LISTEN 先按文档方式
  用 `getUserMedia({audio:{captureSource:'microphone',
  microphoneMode:'wearer', echoCancellation:true}})` 打开
  佩戴者模式麦克风流——这只是一次**可用性检查**：读
  `track.getSettings()` 确认实际模式后，检查完立即停轨道。
  **口令识别由宿主 `SpeechRecognition`（zh-CN）在它自己的
  麦克风通路上完成**；wearer 模式只作用于那条随即停掉的
  检查流，对宿主识别没有任何影响。听到「下一步」或
  「好了」自动翻页，其它话如实显示「听到了，但不是口令」。
- **倒计时在眼前**：带分钟的步骤（腌肉 10 分钟、烧水 5 分钟、
  炒番茄 2 分钟等）点 TIMER 启动倒计时，剩余 mm:ss 就显示在
  步骤框里，余光扫一眼就知道还剩多久；归零变「TIME UP」并用
  TTS 朗读「时间到」+ 当前步骤，推进下一步自动清掉旧计时。
- **看锅判断在你（诚实边界）**：LOOK 用
  `ImageCapture.takePhoto({mode:'default'})` 给眼前的锅拍一张
  只作记录（显示字节数）；火候由你亲眼判断——PAN 轮换你看到
  的状态（还生 / 刚好 / 有点糊），每个状态配一句调整建议
  （有点糊 → 关小火，加两勺水快翻匀）。照片不判断熟度，
  界面全程标注「record only; YOU judge doneness」。

## 功能流程

1. RECIPE 选菜：番茄炒蛋（6 步）/ 青椒肉丝（7 步）/
   清水煮面（6 步），选中即回到第 0 步备料清单；
   ArrowUp / ArrowDown 在未开火时同样换菜
2. START（或稳住头点头 / Enter）开始第 1 步，步骤大字显示
3. NEXT / 点头 / 语音「下一步」「好了」逐步推进；做菜进行中
   RECIPE 锁定防误触；最后一步后再 NEXT 进入
   「DONE - 上菜」状态
4. 当前步带分钟数时点 TIMER 启动倒计时（再点停止），
   剩余时间显示在步骤框；归零 TTS 喊「时间到」
5. LISTEN 语音翻页：wearer 模式麦克风可用性检查（读回设置
   后即停流）+ 宿主 SpeechRecognition（zh-CN，走其自有
   麦克风通路）识别，两步相互独立；识别结果如实显示；
   不可用时显示 SKIP，回退点头/按钮
6. LOOK 看着锅拍照留档（只作记录）；PAN 轮换锅况
   （还生 / 刚好 / 有点糊）显示对应调整建议
7. SPEAK 朗读当前步骤（备料步朗读备料清单）
8. DEMO 按钮：载入番茄炒蛋并跳到第 3 步（炒番茄 2 分钟）
   且启动倒计时，预览即可看到步骤视图 + 实时计时行

> 诚实说明：菜谱是内置 3 道家常菜，不支持导入外部菜谱；
> 照片只作记录、熟度靠佩戴者亲眼判断；语音翻页是点 LISTEN
> 后的一次性识别，不是常驻唤醒词。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | 取流并以 default 模式拍摄眼前的锅（只作影像记录，不参与火候判断） |
| RECORD_AUDIO | LISTEN 语音翻页：wearer 模式麦克风可用性检查 + 宿主 SpeechRecognition（自有麦克风通路）识别「下一步 / 好了」口令 |

相机/麦克风只在用户点 LOOK / LISTEN 时启动：麦克风检查完
立即停轨道，相机拍完立即停掉全部媒体轨道；计时器、识别器
在页面隐藏/卸载时一律清除/abort。

## 打包与预览

```bash
cd ~/workspace/rokid/cook-along
~/tools/bin/aix pack . -o ../dist/cook-along.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-cook.js`；步骤截图的点击序列为 canvas 内 DEMO (395, 242) 一次点击，
DEMO 自带跳步 + 启动倒计时）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-cook-along`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 cook-along」，站在灶台前选好菜点 START，
   看着锅做：点头/喊「下一步」翻页，定时步开 TIMER，
   看锅况点 PAN

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.1（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 16.2 KB（本地打包 `dist/cook-along.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；
  模板里 9 个 bindtap 处理函数在逻辑对象中均有定义。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：首页初始态完整渲染（番茄炒蛋备料步、
  TIMER/PAN/ASR 三行状态、RECIPE/START/NEXT、TIMER/LISTEN/SPEAK、
  LOOK/PAN/DEMO 三排按钮）；点 DEMO 后跳到番茄炒蛋第 3 步，
  步骤大字（炒番茄出红汁）与倒计时运行行（TIMER 1:5x left）
  正确显示。

**未验证**

- 真机头部稳定检测与点头翻页在炒菜动作中的实际灵敏度。
- **宿主 ASR 口令识别在真实厨房噪音**（抽油烟机、沸水声）
  下能否稳定听到「下一步」（wearer 模式检查只验证模式可
  打开、读得到设置，不参与识别；预览主机无
  SpeechRecognition，LISTEN 的 SKIP 路径已如实显示，真机待测）。
- 真机相机取流与 default 模式拍锅的效果（预览主机无相机，
  LOOK 的 FAIL 路径已如实写明原因，真机待测）。
- 真机 TTS 朗读当前步与计时归零「时间到」提醒的效果。
- **已知产品边界**：菜谱为内置 3 道，不支持导入；照片只作
  记录、不判断熟度——这是设计边界，不是待补验证项。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Cook Along is a hands-free cooking companion for Rokid Glasses. Pick one of three built-in recipes; steps stay in your line of sight while you watch the pan: nod or say "next" to advance, timed steps get an in-view countdown and a spoken alert at zero. The host speech recognizer hears voice commands on its own microphone (after a wearer-mode mic availability check), and PAN logs what you see — still raw, just right, or starting to burn — with a one-line fix for each.

### Opening Message

Hi, I'm **Cook Along** — your recipe, right where you're already looking.

Tap **RECIPE** to pick a dish (tomato eggs, pepper pork, or plain noodles), then **START**. I'll show one big step at a time: nod or tap **NEXT**, or tap **LISTEN** and say "下一步" to move on with oily hands. Steps with minutes get a **TIMER** countdown in view and a spoken "时间到" alert. Tap **LOOK** to photograph the pan (record only — you judge doneness) and **PAN** to log what you see.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-cook-along-index.png`（aix preview 首页：COOK ALONG 初始态，番茄炒蛋备料步 + TIMER/PAN/ASR 状态行 + 三排按钮，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-cook-along-step.png`（DEMO 跳到番茄炒蛋第 3 步的运行态：步骤大字 + 倒计时运行行 TIMER 1:5x left，本地文件）
- Video：待真机补 — 真机录制「选菜 → 开火做第 1 步 → 点头/语音翻页 → 定时步倒计时到点提醒 → 看锅 PAN」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None.

**Improvements**

- None.

**Fixes**

- Mic-mode copy corrected (capability-boundary audit 2026-10-24): wearer mode is an availability check only — the getUserMedia stream is opened in wearer mode, its settings are read back, and it is stopped at once. Voice commands are recognized by the host SpeechRecognition on its own microphone, which the checked mode does not affect. The UI listening line, this README and AGENTS.md now say exactly that, instead of implying recognition runs through the wearer-mode array.

#### Build 1.0.0

**Features added**

- Line-of-sight recipes: 3 built-in dishes （番茄炒蛋 6 steps, 青椒肉丝 7 steps, 清水煮面 6 steps), each opening on an ingredients step 0; RECIPE cycles dishes and resets, START begins step 1, NEXT / nod (head steady) / voice command advances, with a DONE — 上菜 finish state.
- In-view step timer: timed steps show a ready countdown, TIMER starts/stops a 1-second mm:ss countdown inside the step box, advancing clears it, and at zero the line shows TIME UP with a spoken "时间到" alert.
- Voice step control: LISTEN runs a documented wearer-mode microphone availability check (getUserMedia captureSource microphone, microphoneMode wearer; settings read back, stream stopped at once) and then the host SpeechRecognition (zh-CN, on its own microphone — the checked wearer mode does not affect recognition); hearing 下一步 or 好了 advances the step, anything else is shown honestly as heard-but-not-a-command; ASR unavailable shows SKIP.
- Gaze-anchored pan check: LOOK photographs the pan you are looking at (default mode, record only, byte size shown, wx camera fallback); PAN cycles what YOU see （还生 / 刚好 / 有点糊） with a one-line adjustment tip per state. The photo never judges doneness.
- SPEAK reads the current step aloud; DEMO jumps mid-recipe into step 3 with the timer running so the step view and live countdown are visible without camera or microphone.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
