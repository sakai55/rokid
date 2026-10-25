# teleprompter-gaze — 凝视提词（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-teleprompter-gaze
```


50 个「指向性生活问题」Agent 的第 Z48 个。演讲、录视频、上台发言
最怕的不是讲错，是**忘词后低头找稿**：眼神一离开听众，气势就散
了。本 Agent 把稿子放在你的视线正中央——当前段大字、下一段小字
预览，你抬着头讲，点头就翻段；可选的自动跟随听着你讲，听到你的
话和后面的段落字面对上了，就替你翻过去。

> 诚实改造（PLAN 原案与实现的两处出入，先说清）：一、**没有文件
> 导入**——运行时没有把外部稿件读进来的通道，稿子只有两个来源：
> 内置的一篇示例演讲（标注 SAMPLE）和你亲口口述的段落（原样存
> 本机）。二、**「语速自动跟随」是尽力而为的字面匹配**——它把宿
> 主识别到的话归一化后，在当前段与后面两段里找逐字对得上的尾巴，
> 对上了才翻段；不是语义理解，不保证跟得上，跟丢了手动翻段永远
> 有效。下面各节同口径。

## 预览截图

截图统一存放于仓库根目录 `screenshots/teleprompter-gaze/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/teleprompter-gaze/preview-teleprompter-gaze-index.png)

![DEMO 态：种子句经真实匹配路径跟随到第 3 段](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/teleprompter-gaze/preview-teleprompter-gaze-demo.png)

![讲完终态：THE END，用时冻结标 (final)](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/teleprompter-gaze/preview-teleprompter-gaze-done.png)

## 解决的问题

提词器早就有了，但都长在别处：纸在讲台上、手机在手里、提词屏在
镜头后——看哪一个都得把视线从人身上移开。眼镜的提词不一样：稿
子就浮在你正看着的方向，你看着听众，就等于看着稿子。翻段靠头部
动作和镜腿触控，不用腾手、不用低头。忘词的那两秒，你只需要停
顿一下，眼前就是下一句。

## 指向性设计（为什么必须用眼镜）

- **视线即提词板（GAZE）**：段落显示在视场正中央，当前段大字、
  下一段小字预览——你的注视点就是提词位置，讲到哪里，眼神都不
  离开前方的人。
- **点头翻段（HEAD）**：头部稳定时点头 = 前进一段，这是演讲中
  最不打断仪态的翻页方式；头没稳住的点头会被忽略并如实提示，
  免得你正常点头致意就把稿子翻飞了。
- **听着你讲（MIC4/宿主 ASR）**：AUTO 跟随每一轮先做佩戴者模式
  麦克风可用性检查（wearer 流只查可用性、停轨后宿主识别才开
  始），再用宿主 SpeechRecognition 听你这一轮说了什么——4 麦
  的佩戴者拾音路径在设备上存在，是检查确认的事；识别本身走
  宿主自己的麦克风，模式不塑造识别（审计口径）。
- **手势优先（档案 §3.2.1）**：全部主流程只用触控板手势 + 头稳
  + 点头就能走完（见下方「手势映射」）；屏幕只保留 NEXT /
  BACK / AUTO / DICT / SPEAK / DEMO 六个与手势等效或手势不代
  办的按钮。

## 手势映射

本 Agent 的全部主流程（读稿 → 翻段 → AUTO 跟随 → 讲完听总结）
都可以只用眼镜腿触控板手势 + 头部动作完成，不必点屏幕按钮。
手势与键码的对应来自官方文档档案 §3.2.1。

| 手势 | 键码 | 在本 Agent 中的动作 |
|---|---|---|
| 单击触控板 | Enter | 情景主操作：AUTO 开着但无轮次在跑 = 开一轮聆听；已讲完 = 朗读总结；其余时候 = 前进一段 |
| 下滑动触控板 | ArrowDown | 前进一段（与 NEXT 等效） |
| 上滑动触控板 | ArrowUp | 回上一段（与 BACK 等效；讲完时 = 回最后一段复习） |
| 双击触控板 | Backspace | 返回 / 关闭（由宿主处理，本 Agent 只记录事件） |
| 长按触控板 | —（系统级） | 唤醒 AI 助手（系统功能，不经过本 Agent） |
| 头部稳定时点头 | onHeadGesture `nod` | 前进一段；点头从不开 AUTO、从不口述、从不朗读 |
| 屏幕按钮 | — | 只保留 6 个：NEXT（前进一段）、BACK（回一段）、AUTO（自动跟随开关——手势不代办「开关聆听」这件事，留明确入口）、DICT（口述录入一段——要开麦，必须显式点）、SPEAK（朗读当前段练习 / 讲完时朗读总结）、DEMO（示例稿 + 一次种子跟随演示），其余动作与手势一一等效 |

## 功能流程

1. 打开就是内置 SAMPLE 稿第 1 段，先试手感：点头 / 单击 / 下滑
   动翻段，上滑动回退，当前段大字、下一段小字预览，进度「段
   1/4」随时可见
2. 录自己的稿：点 DICT，一次口述一段（先做 wearer 麦克风检查，
   界面单独一行 `MIC CHECK:`），听到的话原样进稿——第一段口述
   会开启「你的稿子」并存到本机（key `prompterScript`，最多 12
   段），以后打开自动载入；SAMPLE 不会被当成你的稿子存下
3. 开讲：点 AUTO 打开自动跟随（或全程手动翻段）——你讲的话被
   宿主识别后，与当前段及后面两段逐字比对，尾巴对上就跳到那一
   段，事件行写明「AUTO matched → 段 N (literal match)」；对不
   上原地不动并写明原因，你点头随时接管
4. 讲的时候界面给你两个读数：ELAPSED 本场用时（tick 计时）、
   PACE 约 X 字/分（由 AUTO 命中算出，标明样本数，只是读数）
5. 最后一段翻过去进入「讲完了」：SPEAK 朗读总结（一共几段、
   用时几分几秒），用时冻结不再走字；BACK 可回最后一段复习
6. DEMO 按钮：载入 SAMPLE 并用一句原样摘自第 3 段的种子文本走
   一遍真实匹配路径，当场跟随到第 3 段；再点一次退出，你的稿
   子与进度原样恢复，演示不写任何存储

> 诚实说明：AUTO 是**逐字匹配**，不是听懂——你改词、跳段超过
> 两段、现场太吵、识别听错，都会跟丢；跟丢不报错装懂，只如实
> 停在原地。宿主识别报致命错误时 AUTO 会自己关掉并写明原因。
> 稿子没有导入通道：要么用示例，要么口述录入（原样保存，讲之
> 前请在屏幕上核对一遍——识别听错的字会原样进稿）。

## 权限

| 权限 | 用途 |
|---|---|
| RECORD_AUDIO | 佩戴者模式麦克风可用性检查（DICT / AUTO 每轮前）+ 段落口述与 AUTO 跟随的宿主语音识别 |

只申请录音一个权限：没有拍照、没有定位；朗读走宿主 TTS。麦克
风检查流查完即停轨、不参与识别；本 Agent 不录音、不保存音频，
稿子只以文本存本机 wx 同步存储，不上传。

## 打包与预览

```bash
cd ~/workspace/rokid/teleprompter-gaze
~/tools/bin/aix pack . -o ../dist/teleprompter-gaze.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-prompt.js`，独立页面副本 `preview-prompt.html`；DEMO / NEXT
按钮点击坐标在 shot 脚本运行日志中按 canvas 坐标记录）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-teleprompter-gaze`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 teleprompter-gaze」：先用 SAMPLE 稿点头
   翻完 4 段，确认讲完总结的用时；再 DICT 口述两段自己的稿（核
   对屏幕上的字是否原样），关掉重开确认稿子还在；开 AUTO 照着
   SAMPLE 念，故意把一句念错说法，验证它如实不跟（事件行 no
   literal match）、点头能接管；再正常念一句第 3 段的话，验证
   跳段跟随与 PACE 读数出现

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 22.8 KB（本地打包 `dist/teleprompter-gaze.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；
  屏幕按钮为 NEXT / BACK / AUTO / DICT / SPEAK / DEMO 六个 bindtap。
- 状态机测试：Node 里以 wx / SpeechRecognition / getUserMedia /
  speechSynthesis 存根加载页面对象、页面计时器由手动 tick 驱动，跑
  **99 条断言全过**——覆盖：SAMPLE 默认载入且从不落盘（显式调用
  保存也零写入）、DICT 原样追加（只去首尾空白、标点保留）并开启
  自己的稿子、存储里只有口述文本无一字 SAMPLE、12 段上限与拒绝
  提示、重载恢复自己的稿子、无识别器时 DICT 如实 FAIL 且不加段、
  前进/回退边界（末段 → 讲完 → 再前进不动 → BACK 回末段 → 回到
  首段停住）、点头纪律（头不稳不翻段、头稳才翻、非 nod 手势忽
  略）、纯手势全程走完（Enter/下滑/上滑/点头到终点、终点 Enter
  朗读含段数的总结、Backspace 无副作用）、tick 用时（150 tick =
  75 秒，总结念「1 分 15 秒」，讲完冻结不走字、(final) 后缀同秒
  内也切换、BACK 离开终态恢复 ticking）、SPEAK 练习朗读当前段原
  文、匹配引擎（当前段子串 → 不动、下一段 → 进 1、下下段 → 进
  2、乱码 → 不匹配、<4 字尾巴 → 永不匹配、标点归一化后不足 4 字
  → 不匹配、中间位置往后两段可达、已讲过的段落永不回搜）、命中
  EVT 原文案、语速数学（两次命中推进 18 + 29 字、间隔 30 秒 →
  94 字/分，样本数入界面）、AUTO 集成（照稿念 → 跟随到第 2 段、
  每轮 mic-stop 必在 asr-start 之前、无关话不挪稿且 EVT 如实、
  致命 ASR 错误 → AUTO 自关且原因上屏、自关后不再开轮、手动翻
  段不受影响、AUTO 与 DICT 互斥）、DEMO（种子句跟随到第 3 段且
  EVT 标注 DEMO、零存储写入、退出恢复真实稿子与自有标记）、
  TTS 从不设置 lang。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图三张（见
  Preview Media）：首页初始态完整渲染（SAMPLE 第 1 段大字 + 下
  一段预览 + 全部诚实行）；DEMO 态经真实匹配路径停在第 3 段；
  讲完终态 THE END 且 ELAPSED 标 (final) 冻结。

**未验证**

- **宿主 SpeechRecognition 的轮次行为（第一优先核对）**：AUTO 靠
  「一轮识别结束 → 自动开下一轮」续接；若宿主只支持单次识别且
  轮次间隙长，跟随会有可感知的断档；若宿主识别对中文长句的断
  句与返回时机不同，尾巴匹配的命中率也会变。真机需实测：照稿
  念、跳段念、改词念三种情况的跟随表现。
- **wearer 模式在真机上的检查结果**：`microphoneMode: 'wearer'`
  是否被真机接受、getSettings 读回的模式名是什么，未验证（被
  拒时回退默认麦克风并如实标注，识别不受影响——识别本来就不
  靠检查流）。
- 真机头部稳定检测与点头手势的触发手感（演讲时自然点头致意会
  不会被判成翻页 nod——本 Agent 只认「头稳 + nod」组合，自然
  点头多半伴随头动，理论上安全，真机需验）；触控板单击/滑动
  在本 Agent 键位映射下的实际触发情况。
- 宿主 TTS 朗读总结与练习朗读的实际效果；SPEAK 的语速语调未
  做任何设置（lang 从不设置，rate 用宿主默认）。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Teleprompter Gaze keeps your script in your line of sight. Paragraphs show big on the glasses display with the next one previewed below; nod, tap or swipe to advance - no looking down at paper. Dictate your own paragraphs by voice (a built-in sample is included; there is no file import, and your words are kept verbatim on the device). An optional AUTO follow listens and advances when your spoken words literally match a coming paragraph - best-effort only, and manual advance always works.

（492 字符）

### Opening Message

Hi, I'm **Teleprompter Gaze** — your script, right in your line of sight.

I open with a short built-in **sample** speech. **Nod**, tap, or swipe down to advance a paragraph; swipe up goes back. Tap **DICT** and speak to build your own script — saved verbatim on this device (no file import). **AUTO** listens and tries to follow you by matching your words against the coming paragraphs — best-effort only; manual advance always works. **SPEAK** reads the current paragraph aloud for practice.

（493 字符）

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-teleprompter-gaze-index.png`（aix preview 首页：TELEPROMPTER 初始态，SAMPLE 第 1 段大字 + 下一段预览、五项状态行与六个按钮齐全，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-teleprompter-gaze-demo.png`（DEMO 态：种子句经真实字面匹配路径跟随到第 3 段，EVT 行标注 literal match，PACE 进入 measuring，本地文件）
- Image 3：`artifacts/preview-teleprompter-gaze-done.png`（讲完终态：THE END 大字、ELAPSED 冻结标 (final)、EVT 行给出段数与用时，本地文件）
- Video：待真机补 — 真机录制「点头翻完 SAMPLE 四段 → DICT 口述一段自己的稿并核对 → 开 AUTO 照稿念并跳段跟随 → 故意改词验证不跟、点头接管」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 3 张图；还需至少 1 个视频，总数保持在 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- In-view prompter: the current paragraph renders big in the centre of the glasses display with the next paragraph previewed below it and an always-visible 段 N/M progress line. Advance by steady-head nod, temple-touchpad single tap (Enter) or swipe down; swipe up goes back. Reaching the end lands on a finished state whose SPEAK summary reports the paragraph count and the total time, with the elapsed clock frozen from that moment.
- Your own script by dictation: DICT records one paragraph at a time through the host recogniser after a wearer-mode microphone availability check (check stream stopped before recognition starts; the result is shown on its own MIC CHECK line). Dictated words are stored verbatim - trimmed only, never rewritten - up to 12 paragraphs, persisted as text in on-device storage and reloaded on the next open. The built-in 4-paragraph sample speech is clearly labelled SAMPLE and is never persisted as the wearer's own. There is deliberately no file import: the script sources are the sample and your dictation, stated on screen.
- AUTO follow (best-effort, literal): while AUTO is on, each recognition round is matched literally - after stripping whitespace and punctuation - against the current and next two paragraphs. If the tail of what you said (at least 4 normalised characters) appears verbatim in a later paragraph, the prompter advances there and the event line says so; if nothing matches it stays put and says that instead. Fatal recogniser errors turn AUTO off by themselves with the reason shown. A pace readout (characters per minute, with its match count) is computed from matched advances and labelled readout-only - it controls nothing.
- Tick-based timing: the talk clock accumulates 500 ms timer ticks instead of sampling the wall clock, so elapsed time and pace stay consistent; the finished state freezes the total.
- Gesture-first operation (temple touchpad, dossier §3.2.1): single tap = contextual primary action (start an AUTO round when idle / speak the summary when finished / advance otherwise), swipe down = next, swipe up = back, double-tap = host back, steady-head nod = advance. Six on-screen buttons (NEXT / BACK / AUTO / DICT / SPEAK / DEMO) mirror the gestures or cover actions gestures must not trigger implicitly (opening the microphone, toggling listening).
- DEMO: loads the sample script in memory and feeds a verbatim line from paragraph 3 through the real matching path, so the follow to paragraph 3 previews end-to-end; leaving DEMO restores the wearer's real script and position, and DEMO never writes storage.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
