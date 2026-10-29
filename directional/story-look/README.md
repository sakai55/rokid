# story-look — 绘本共读（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-story-look
```

**AIX 直接下载**（最新版）：[story-look.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/story-look.aix)


50 个「指向性生活问题」Agent 的第 DI37 个，H 组（学习记忆）第二个。
给孩子讲绘本，最容易变成家长一个人的独白：照着书一页一页念，
孩子听两页就开始抠沙发。本 Agent 把共读变成对话：绘本在你
手里、孩子在你身边，你看着这一页说一句话，眼镜把这句话变成
一段适合读给 3–6 岁孩子的讲解词，再递给你一个问孩子的问题
——你问一句、孩子答一句，这一页就讲活了。它从头到尾看不见
绘本：这一页是什么，全靠你说。

## 预览截图

截图统一存放于仓库根目录 `screenshots/story-look/`。

![首页初始状态](../../screenshots/story-look/preview-story-look-index.png)

![DEMO 问题态：第 2 页已讲好，问题大字停在眼前等你问孩子](../../screenshots/story-look/preview-story-look-question.png)

## 解决的问题

绘本共读的质量不在「念得对不对」，在互动：停下来问一句
「你猜接下来会怎样」，孩子就从听众变成了参与者。但临时想
问题并不容易——故事讲到一半，脑子跟着情节走，往往想不出
合适的问法，或者问得像考试。本 Agent 替家长盯住的正是这件
事：你只需要把这一页「说了什么」讲出来，讲解词的润色和
提问的准备交给它，而且顺序卡死：**生成文本先出现在你眼前，
你看过、点了 READ，才会出声给孩子听。**

## 指向性设计（为什么必须用眼镜）

- **看向即定位（GAZE 页记录）**：LOOK 用
  `ImageCapture.takePhoto({mode:'default'})` 拍下绘本这一
  页，只作记录——锚定「讲到哪一页」，界面只显示字节数。
  它不会被读：运行时没有 OCR；而把照片发给大模型是本
  Agent 刻意不走的路——平台其实支持照片经 data: URL 作为
  图片输入送入大模型（档案 §2.9 的官方读字路径），本
  Agent 只把文字发给模型，这是产品选择，不是平台限制。
  所以这一页的内容 100% 来自你说的话。
- **你说一页，它记一页（MIC4 wearer 检查 + 逐字纪律）**：SAY
  先做佩戴者模式麦克风可用性检查（开 wearer 模式流、读
  回 settings 后立即停流），再用宿主 SpeechRecognition 在
  它自己的麦克风上一次性识别。说明白：wearer 模式只作
  用于那条检查流，管不到宿主识别器（档案 §2.4 / §2.8）——
  本 Agent 不承诺「优先收家长、孩子插话不会被当成描
  述」；孩子在旁边说话可能被听进来，防线是你核对屏幕上
  原样显示的那句话。你说的话**原样**保存显示——整个故事
  建立在这些话上，提示词送出去的就是你看到的这句话，
  一字不改。
- **上下文是故事的记忆（HEAD 页序）**：TELL 时，前面所有
  页的描述按顺序一并以纯文本发给大模型，所以第 5 页的
  讲解记得第 1 页的小兔子为什么哭——连贯性来自页序，
  不是来自它「看过这本书」（它没看过）。
- **点头只存档（HEAD 确认）**：头部稳定时点头只做 NEXT
  ——把你已经讲过、预览过的这一页存档。它不生成、不
  朗读：对孩子出声的每一次，都必须先经过你的眼睛和一次
  明确的点按（同 DI22 / DI23 先报后确认的纪律）。

## 功能流程

1. LOOK（可选）：看着绘本这一页拍一张留档，只显示字节
   数，拍完即停流
2. SAY：用一句话描述这一页（wearer 麦克风检查 + zh-CN
   一次性识别，原样显示核对；无识别主机轮换内置样例描述，
   标注 SKIP）
3. TELL：描述 + 前文描述（纯文本）送大模型，返回 2–3 句
   讲解 + 一个问题（标注 LLM）；大模型不可用回退
   OFFLINE ECHO——讲解就是你的描述原样，问题从内置题库
   按页轮换（标注 OFFLINE ECHO）
4. 预览：讲解词和问题先摆在屏幕上，**不自动朗读**；你
   看完点 READ，合成语音以 0.85 倍速（主机是否采纳未验
   证）读出讲解词，问题由你亲口问孩子
5. NEXT / 点头：把 {页码， 描述， 讲解词， 问题， 来源}
   存入 `storyLook`（只保留最近一个故事，最多 20 页）
6. READ ALL：按顺序把存好的讲解词整篇重播——睡前再听
   一遍今晚的故事
7. DEMO：内存里播入《小兔子》两页（第 1 页已存档、第 2
   页已讲好停在问题视图），全部 OFFLINE ECHO，不写真实
   存储；CLEAR 退出后恢复你真实的故事

> 诚实边界：**眼镜看不见绘本**。照片是记录，不是输入；
> 你没说到的情节，它不应该有——提示词里要求只围绕你的
> 描述展开、不发明新角色新情节，但生成文本仍可能有出入，
> 这正是朗读前必须由你预览的原因。大模型的讲解是机器生成
> 文本，适不适合你的孩子只有你能判断；OFFLINE ECHO 读的
> 是你自己的原话，两种来源在界面上标注分明。问题都是开放
> 式闲聊引导，没有标准答案，不评价孩子的回答。

## 内置题库（离线回退，10 问）

你猜，接下来会发生什么？／ 如果你是它，你会怎么做？／
它现在的心情是什么样的？／ 这一页里，你听到了什么声音？／
你最喜欢这一页的哪个地方？／ 它接下来会去哪里呢？／ 谁会
来帮助它呢？／ 你想对它说什么？／ 这一页里，你发现了什么
小秘密？／ 猜猜看，这个故事会怎么结束？——按页轮换，离线
时讲解词为家长描述原样（OFFLINE ECHO）。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | LOOK 拍下绘本这一页留档（只取字节数显示，不保存、不读取——运行时没有 OCR；照片经 data: URL 送大模型平台是支持的，本 Agent 选择不送，只发文字） |
| RECORD_AUDIO | SAY 录入这一页的描述：佩戴者模式麦克风检查 + 一次性语音识别（zh-CN）；READ / READ ALL 朗读走系统 TTS 不占麦克风 |

相机/麦克风只在用户点 LOOK / SAY 时启动，用完立即停掉
全部媒体轨道。不录音、不保存照片；故事只存本机 wx 同步
存储，不上传。发给大模型的只有描述文字（你说过的话）。

## 打包与预览

```bash
cd ~/workspace/rokid/story-look
~/tools/bin/aix pack . -o ../dist/story-look.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-story.js`；问题态截图的点击序列为 canvas 内 DEMO (122, 317)，
坐标经视觉定位确认）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-story-look`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 story-look」，拿一本孩子最喜欢的绘本
   实测：LOOK 拍页是否成功、SAY 对家长描述的识别率（孩子在
   旁边插话时宿主识别器会不会把孩子的话听成描述）、大模型讲解是否只用
   你描述过的内容（故意漏说一个角色，看它会不会自己发明）、
   断网时 OFFLINE ECHO 是否接得上（讲解应等于你的原话）、
   READ 的语速孩子是否跟得上、讲满几页后 READ ALL 整篇重播

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.1（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 22.3 KB（本地打包 `dist/story-look.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 共读逻辑（Node 实测）：把页面对象以 wx 打桩加载进 Node，共 69 条
  断言全过——含题库恰好 10 问；OFFLINE ECHO 的讲解与家长描述逐字
  相同、问题按页轮换并在第 11 页回绕；提示词组装（前文描述按故事
  顺序在前、本页描述在后、无前文时省略上下文段、两段式格式要求
  齐全）；大模型回复解析（标准 NARRATION/QUESTION 两段、全角冒号、
  单行垃圾回退、缺问题时补题库第一问、空回复返回 null）；TELL 优先
  级（大模型可用时优先且提示词确实带上前文、不可用时回退 ECHO）；
  **TELL 之后自动朗读次数为 0**（先预览后朗读在断言里卡死）、READ
  只读讲解词本身；NEXT 存档字段完整（页码/描述/讲解/问题/来源全
  保留）且未讲先存被拒；20 页封顶后 TELL 被拒；存储加载校验（缺
  描述/缺讲解/垃圾条目一律丢弃、页码重排）；READ ALL 按页序拼接
  讲解、空故事不发声；SAY 无识别主机走预置轮换并标注 SKIP；DEMO
  两页播种（第 1 页小兔子迷路已存档、第 2 页遇猫头鹰已讲好并落在
  问题视图、来源标注 OFFLINE ECHO、演示全程不写真实存储、DEMO 内
  NEXT 仍不落盘、CLEAR 退出后真实故事原样恢复）。
- 1.0.1 文档订正后复验（2026-10-24，能力边界审计）：静态检查重跑
  全过；页面逻辑 Node 打桩抽查——LLM 与 OFFLINE ECHO 两条路径下
  TELL 之后自动朗读次数均为 0、READ 点按后恰好朗读 1 次且内容为
  讲解词本身、ECHO 讲解与家长描述逐字相同（先预览后朗读未被破坏）。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：首页初始态完整渲染（描述框/讲解问题框、页码与
  故事计数、LOOK/SAY/TELL 与 READ/NEXT/READ ALL 按钮、常驻诚实
  行）；点 DEMO 后到达第 2 页问题态：第 1 页已存档行（ECHO 标记）
  与第 2 页描述、讲解（回声原文）、大字问题均正确渲染。

**未验证**

- 真机大模型（LanguageModel）讲故事的实际质量：是否真能忍住
  不发明家长没说过的角色情节、两段格式的遵从度、2–3 句讲解对
  3–6 岁孩子的适配度，都要拿真绘本实测；格式跑偏时解析按行
  salvage，讲解与问题可能分错段。
- 真机 SAY 在亲子场景的识别率：孩子在旁边说话、电视开着时，
  宿主识别器把谁的话听成描述（wearer 检查流不参与识别，
  无从「优先」家长）；描述被听错时家长是否真会
  核对（逐字显示是防线，防线本身无法本地验证）。
- READ 的 0.85 倍速在真机 TTS 上是否生效（部分主机忽略 rate）、
  合成语音读中文故事的自然度；点头存档在抱着孩子/拿着书时的
  误触率。
- 拍页照片在真机上的成功率与字节数表现（只作记录，不影响
  主流程）；wx 存储在眼镜重启后 20 页故事的持久性。
- **产品边界**：本 Agent 不认书、不读字——家长完全不描述、
  只想让眼镜「自己看图讲故事」的用法不存在，也不应被暗示
  存在。它放大的是家长的讲述，不是替代家长讲。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Story Look makes picture-book reading a conversation. The glasses never see your book: no OCR, and the page photo is a record only, never sent (text-only input is this agent's choice). Describe each page in a sentence; your words and earlier pages go as text to the on-device AI, which drafts a warm 2-3 sentence telling for a 3-6 year old, plus one question for your child. No AI? A labelled offline echo reads them back with a built-in question. Nothing is spoken until you preview and tap READ.

### Opening Message

Hi, I'm **Story Look** - I can't see your picture book, so you describe each page and I'll help you tell it.

**LOOK** records the page as a photo. **SAY** one sentence about what it shows - kept exactly as heard. **TELL** drafts a short telling plus a question for your child: **preview it first**, then **READ** speaks it aloud. **NEXT** files the page (a story holds 20), and **READ ALL** replays the whole tale. No AI around? The offline echo reads your own words back, labelled as such.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-story-look-index.png`（aix preview 首页：STORY LOOK 初始态，含描述框/讲解问题框、页码与故事计数、操作按钮及常驻诚实行，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-story-look-question.png`（DEMO 问题态：第 1 页已存档、第 2 页讲解与大字问题停在眼前，来源标注 OFFLINE ECHO，本地文件）
- Video：待真机补 — 真机录制「看着绘本说出这一页 → 预览讲解词 → 点 READ 读给孩子 → 问出大字问题 → 点头存档翻页 → READ ALL 整篇重播」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None (documentation-accuracy fix only; no behaviour change).

**Improvements**

- Wording aligned with the capability dossier: the 0.85 TTS rate is now described as "whether the host honours the rate is unverified" everywhere it appears, matching the unverified list.

**Fixes**

- Corrected a false platform claim (capability-boundary audit 2026-10-24): earlier copy said "the language model takes text only" and that a freshly captured photo cannot be sent to the model. Per dossier section 2.9, the host language model does accept image input, including photos encoded as data: URLs - the official read-text path. Story Look's text-only design is a product choice: this agent deliberately sends text only and does not use the photo-input path; the docs now say exactly that instead of claiming a platform limit.
- Corrected the wearer-mode mic claim (same audit): earlier copy said the 4-mic array "prioritises the storytelling parent over the child beside them". The wearer-mode getUserMedia stream is an availability check only - opened, settings read back, stopped - and the page description is recognised by the host SpeechRecognition on its own microphone (dossier sections 2.4 / 2.8), which the wearer mode cannot shape. The docs no longer promise that a child's interjections are filtered out; the verbatim on-screen description remains the check.

#### Build 1.0.0

**Features added**

- Page-by-page co-reading: LOOK photographs the picture-book page in default mode as a record only (byte size shown; the runtime has no OCR, and this agent sends text only to the language model by design - the platform does accept photos as data: URL image input, a path this agent chooses not to use - so the photo is never read and the glasses never see the page), SAY hears the parent describe the page in one sentence - wearer-mode mic availability check first (the wearer-mode stream is opened, its settings read back and stopped; recognition itself runs on the host recogniser's own microphone, so no claim is made that a child beside you is filtered out), the heard sentence kept verbatim and shown for checking, with an honest SKIP preset cycle when no recogniser exists.
- TELL sends the current description plus every previous page's description, in story order, as text only to the host language model, which returns a warm 2-3 sentence narration suitable for reading aloud to a 3-6 year old and one question to ask the child (reply parsed in that two-part format with a line salvage fallback), labelled LLM; the prompt instructs the model to stay with what the parent described and invent no new characters or events. When the model is unavailable, an OFFLINE ECHO fallback answers instead: the narration is the parent's own description read back unchanged - never dressed up as a generated story - and the question rotates through a built-in bank of 10 gentle open questions by page, labelled OFFLINE ECHO.
- Preview-before-voice is a hard rule, not a setting: generated text appears on screen first and is never auto-spoken; READ speaks the narration (synthetic TTS at 0.85 rate - whether the host honours the rate is unverified) only on the parent's explicit tap, and the question is shown big for the parent to ask in their own voice. NEXT (or a steady-head nod) files {page number, parent description, narration, question, source} into the last story on device (key storyLook, max 20 pages), and READ ALL replays the saved narrations in order as one bedtime re-listen.
- DEMO seeds a two-page bunny story through the offline echo path - page 1 filed, page 2 told and waiting on its question view - entirely in memory; leaving DEMO restores the real story untouched.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
