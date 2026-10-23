# ambient-captions — 环境字幕（Rokid 眼镜 AIUI Agent）

50 个「指向性生活问题」Agent 的第 20 个。听力不佳时，
面对面聊天是一场猜谜：每句话听一半漏一半，人名、数字
最容易丢。字幕早就有了 — 但只在电视和视频里有，坐在
你对面的人说话没有字幕。眼镜能把字幕放到它该在的
地方：说话人的脸下方，你不用低头、不用掏手机，对话
进行的同时，字就出现在你看着他的那个位置。

## 预览截图

截图统一存放于仓库根目录 `screenshots/ambient-captions/`。

![首页待机态（对准说话人引导行、MIC 待机、字幕栈为空、「ASR aid, not a transcript」诚实说明常驻）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ambient-captions/preview-ambient-captions-index.png)

![DEMO 字幕态（三句合成文本走同一套字幕栈路径：最新一句大字、前两句带时间小字、LATEST 行标注 DEMO 与仅存内存）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/ambient-captions/preview-ambient-captions-captions.png)

## 解决的问题

「你再说一遍？」一顿饭说上十次，双方都累。助听场景
里最难的不是音量，而是分辨：声音都听到了，词却糊在
一起。逐句字幕把「听」变成「看」— 最新一句大字、
前两句小字带时间留在上方，漏看一句还能往回瞥一眼，
闪太快就让它在耳边再说一遍。眼镜是唯一合适的载体：
字幕必须出现在你正看着的位置（对方的脸下方），
手机举在手里做不到，电视字幕更管不到真人。

## 指向性设计（为什么必须用眼镜）

- **字幕长在对方脸上（HEAD + 显示）**：你正对说话人
  时，字幕就出现在他的脸下方、你的视线正中央 — 界面
  常驻引导行「Face the speaker - captions sit under
  their face」。这是手机平放在桌上永远做不到的：
  它不知道谁在你对面。诚实边界：识别由宿主
  SpeechRecognition 在它自己的麦克风通路上完成，
  字幕准不准由宿主识别管线决定，本 Agent 不声称
  头部朝向能改变识别输入或字幕质量（朝向对质量的
  影响未验证，见「未验证」）。
- **为什么检查 near-field（MIC4 近场模式）**：START
  先按文档方式用 `getUserMedia` 的 `captureSource:
  'microphone'` + `microphoneMode: 'near-field'` 做
  一次可用性检查（读回 `track.getSettings()`，查完
  立即停轨道）。按媒体文档定义：交谈对象坐在对面
  1–2 米，是「附近的声音」= near-field — 检查这个
  模式就是确认这台设备上存在与面对面交谈距离对应
  的近距离拾音模式（近距离交谈路径可用）。如实
  说明：这次检查只验证模式存在，检查流随即停掉、
  不是识别的输入；真正的字幕识别由宿主
  SpeechRecognition 在它自己的麦克风通路上完成，
  检查选哪个模式不会改变识别听到的声音。模式被
  设备拒绝（OverconstrainedError）时回退默认麦克
  风并如实提示。
- **字幕在视线正中（HANDS-FREE 显示）**：单色绿滚动
  字幕栈 — 最新一句 16px 大字，前两句小字各带时间
  （HH:MM）。不用腾手、不用低头看表看手机，眼睛
  不离开对方就能读完。
- **点头重读**：头部稳定时点头 = REPEAT，把最新一句
  用 TTS 在你耳边再说一遍 — 看漏了不用开口打断对方
  说「再说一遍」。

## 功能流程

1. 待机：显示对准引导行、MIC 状态、空字幕栈与诚实
   说明行
2. START（或 Enter）：查 `SpeechRecognition`，不可用
   FAIL 写明 → 近场模式检查 → 一轮接一轮识别，
   轮次号常驻界面
3. 出字幕：每识别出一句 → 追加字幕栈（最新大字、
   前两句带时间小字，最多 30 句，只存内存）
4. REPEAT（或头部稳定时点头）：TTS 朗读最新一句；
   没有字幕时朗读操作提示
5. STOP 立即结束循环并 abort 识别器；CLEAR 清空
   字幕栈；页面隐藏/卸载同样停机清理
6. DEMO：按节奏喂三句合成文本（你好，今天过得怎么样 /
   我刚从超市回来 / 晚上我们吃火锅吧），走同一套
   `_addCaption` 字幕栈路径，条目标注 DEMO — 无
   麦克风也能完整演示

> 诚实说明：本 Agent 是 **ASR 对话辅助，不是记录稿**。
> 字幕一定会出错 — 人名、数字、地址这类最关键的信息
> 恰恰最容易错；一次只能跟一个人说话，两人同时开口
> 字幕就乱了。它给你的是「大概在说什么」的参考，
> 绝不能当作对方说过的话的证据或记录，不能用于对质、
> 签约或医疗/法律场合；重要内容请当面复述确认。另外
> 字幕**只存内存、永不落盘**：一场对话不是一份录音，
> 关掉页面字幕就消失 — 这是有意的。

## 权限

| 权限 | 用途 |
|---|---|
| RECORD_AUDIO | START 后：`getUserMedia` 近场模式可用性检查（仅验证模式存在，检查流随即停掉）+ 宿主 `SpeechRecognition`（自有麦克风通路）逐轮识别生成字幕；不录音、不保存音频、不上传。字幕只存内存（最多 30 句），无任何持久化 |

## 打包与预览

```bash
cd ~/workspace/rokid/ambient-captions
~/tools/bin/aix pack . -o ../dist/ambient-captions.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-captions.js`；字幕截图的点击序列为 canvas 内 DEMO (127, 231)
点 1 次后等约 5 秒待三句合成文本走完：注意 artifacts/preview.html
需先把 importmap 的 jspm 地址换成本地 `/ink/index.js` 再复制到
preview-tools/www/）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-ambient-captions`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 ambient-captions」：请家人坐在对面
   1–2 米处正常聊天，点 START 后正对对方，逐句核对字幕
   与原话的出入（重点记人名、数字的错误率）；然后侧过头
   45° 再聊几句，记录字幕质量是否有可观察的变化（识别
   走宿主管线，本 Agent 不预设朝向会影响质量 — 这是
   观察项，不是验证项）；试一次两人同时说话看字幕是否如实地
   乱；最后点 REPEAT 与点头重读各试一次 — 这几项就是
   本 Agent 真机可用性的真实边界

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.1（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 16.3 KB（本地打包 `dist/ambient-captions.aix`，分次打包有 ±0.01 KB 级抖动） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；
  5 个 bindtap 处理函数（startTap / stopTap / repeatTap /
  demoTap / clearTap）全部有定义。
- 字幕栈与轮次状态机验算：把页面对象以 wx 打桩 + 假
  `SpeechRecognition` 加载进 Node，共 44 项断言全过 —
  字幕追加与渲染顺序（最新大字、前两句带 HH:MM 时间）；
  空字幕拒绝；栈上限 30 句丢最旧；CLEAR 清空；START
  近场检查读回 `near-field`、第 1 轮启动、识别结果经
  同一路径成字幕、onend 衔接下一轮；STOP abort 识别器
  且不再续轮；no-speech 安静计数且循环继续；连续 5 轮
  network 错误停机且原因上屏；not-allowed 立即停机
  说明；DEMO 三句走同一字幕路径、顺序与标注正确；
  REPEAT 朗读最新一句、无字幕时朗读提示；头部不稳的
  点头被忽略、稳定点头 = REPEAT；无 `SpeechRecognition`
  的主机上 START 如实 FAIL、不假装在出字幕。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见
  Preview Media）：首页待机态完整渲染（对准引导行、MIC
  待机、空字幕栈与诚实说明行常驻）；点 DEMO 后三句合成
  文本走完，最新一句「晚上我们吃火锅吧」大字显示、
  前两句带时间小字、LATEST 行标注 DEMO 与字幕计数。
  预览主机无 `SpeechRecognition`，START 的 FAIL/SKIP
  路径为代码完备、已由 Node 打桩测试覆盖，未在此环境
  触发截图。
- 1.0.1 审计修复复验（2026-10-24，能力边界审计）：静态
  检查重跑通过（app.json / package.json / `<script def>`
  JSON 解析、`<script setup>` 与 app.js `node --check`、
  grep 无残留）；页面对象 Node 打桩复验 21 项断言全过 —
  重点核对新界面行：待机行 `MIC: idle · rounds 0 ·
  near-field check on START`、识别中行 `MIC CHECK:
  near-field · round N · listening (host ASR)`（模式只
  出现在 MIC CHECK 检查结果段、识别明确标注宿主
  ASR）、检查流读回 settings 后立即停轨、无识别器时
  START 如实 FAIL、字幕栈 30 句上限与 CLEAR 清空
  不变；预览截图两张已按新文案重拍。

**未验证**

- 真机 `near-field` 模式检查是否被接受、宿主识别在
  1–2 米面对面距离的实际质量；近场检查的回退路径
  未在真机触发过。
- 真实对话里的字幕错误率 — 本 Agent 最大的未知数：
  人名/数字/地址的错误率、口音与语速的影响、多人同时
  说话时的混乱程度、侧头 45° 时字幕质量是否有可观察
  变化（本 Agent 不预设结论），只能真机多场景实测。
- 真机头部稳定/点头触发 REPEAT 的灵敏度；TTS 重读
  在嘈杂环境里能否听清；字幕刷新延迟（每轮识别的
  间隔）是否跟得上正常语速。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Ambient Captions puts live subtitles under the face of the person talking to you. Tap START and the glasses check the near-field mic mode (your partner sits 1-2 m away, a nearby source), then run speech-recognition rounds back to back: each sentence lands in a rolling stack, the latest in big type, the last two above it with their times. REPEAT re-speaks the newest line. Captions live in memory only and carry ASR errors - an aid, not a transcript.

### Opening Message

Hi, I'm **Ambient Captions** - I subtitle the person across from you, live, under their face.

Tap **START** and face the speaker: I first check the near-field mic mode (partner 1-2 m away), then caption sentence by sentence with the host recognizer - newest line big, last two above with times. Missed one? **REPEAT** (or a steady head nod) repeats it at your ear. Captions WILL have errors, especially names and numbers - an aid, never a record. **DEMO** shows the flow.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-ambient-captions-index.png`（aix preview 首页待机态：对准引导行、MIC 待机、空字幕栈、诚实说明行，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-ambient-captions-captions.png`（DEMO 字幕态：三句字幕入栈、最新一句大字、前两句带时间、DEMO 标注，本地文件）
- Video：待真机补 — 真机录制「点 START → 家人坐在对面聊天 → 字幕逐句上屏 → 点 REPEAT 重读最新一句」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None.

**Improvements**

- None.

**Fixes**

- Corrected a mode/recognition conflation (capability-boundary audit 2026-10-24): the UI listening line and the design notes presented the near-field mic mode as if it shaped the recognition input, and claimed facing the speaker makes captions more accurate. The near-field getUserMedia stream is an availability check only - it is stopped before recognition, and captions are produced by the host SpeechRecognition on its own microphone. The listening line now reads "MIC CHECK: <mode> · round N · listening (host ASR)", the separate mic-check result is shown as history, and the head-orientation caption-quality claim was removed (orientation effect unverified).

#### Build 1.0.0

**Features added**

- Rolling conversation captions: START first runs the documented near-field microphone availability check (a partner 1-2 m away is a nearby source per the media docs - near-field is the mode documented for that distance; the check only verifies the mode is available and its stream is stopped at once, with a labeled fallback to the default microphone when the device rejects that mode), then runs back-to-back zh-CN speech-recognition rounds with a live round counter.
- A caption stack under the speaker's face: each recognised sentence is appended - the latest line in large type, the previous two lines above it in smaller type with their HH:MM times - capped at 30 lines, held in memory only, never persisted or uploaded, wiped by CLEAR.
- REPEAT by button or by a head-steady nod, re-speaking the latest caption at your ear through TTS (or the how-to hint when there is no caption yet).
- A stated error policy: no-speech rounds are counted quietly; persistent recognition errors (not-allowed, service-not-allowed, audio-capture) or five errors in a row stop the captions with the reason on screen instead of spinning forever.
- DEMO synthetic lines: three sample sentences fed through the same caption-stack path as real recognition and tagged DEMO, so the full flow runs with no microphone.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
