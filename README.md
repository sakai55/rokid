# word-look — 看词查词（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-word-look
```


50 个「指向性生活问题」Agent 的第 DI36 个，H 组（学习记忆）第一个。
看书、看路牌、看说明书，遇到一个生词，第一反应是掏手机——
解锁、开词典、打字，一查回来，刚才读到哪儿、那句话什么意思，
全断了。本 Agent 把查词压回视线里：看着生词，把它说出来，
眼镜把听到的词原样摆出来等你核对，对了立刻给中文释义、
简单英文解释和一个例句并朗读，再按场景存进生词本。全程
不读你的书：这个运行时没有 OCR，词是你说出来的，照片
只是留档。

## 预览截图

截图统一存放于仓库根目录 `screenshots/word-look/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/word-look/preview-word-look-index.png)

![DEMO 结果态：itinerary 经离线词典释义并存入旅行场景](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/word-look/preview-word-look-result.png)

## 解决的问题

查词的成本不在查，在「掏手机」这个动作本身：注意力被切走，
阅读的上下文就散了。眼镜的解法是把词的来源换掉——不靠拍
照片识别（做不到），靠你自己的嘴：你正看着那个词，顺口
说出来就行。但语音识别听英文词并不牢靠，听错一个字母，
查出来的就是另一个词的意思，而且它会一本正经地念给你
听。所以本 Agent 的核心设计不是「查」，是「核对」：听到
的词原样大字显示，先让你亲眼确认，再查、再存。

## 指向性设计（为什么必须用眼镜）

- **看向即定位（GAZE 长焦留档）**：LOOK 用长焦
  `ImageCapture.takePhoto({mode:'telephoto'})` 拍下生词
  所在的那一页/那块牌，只作记录——锚定「这个词是在哪儿
  遇到的」，界面只显示字节数。它永远不会被读：AIUI 运行时
  没有 OCR（同 #01 gaze-translate 的结论），任何「看一眼
  就认出词」都不存在。
- **词靠说，核对是产品（MIC4 wearer + 逐字纪律）**：SAY 先做
  佩戴者模式麦克风检查（4 麦优先收你自己的声音），再一次性
  识别。词是英文，先用 `en-US`；主机拒绝该语言时只重试
  一次 `zh-CN` 并把回退警告留在屏幕上；无识别的主机如实
  SKIP 改走离线词条轮换。听到的词**原样**显示（同 #21 的
  纪律），从不悄悄纠正——「refound」听成这样就摆这样，
  你看出来不对，再 SAY 一次。
- **点头只推进，不替答（HEAD 确认）**：头部稳定时点头只
  推进你正在走的流程——核对完的词 DEFINE、查完的结果
  SAVE——它从不替你编词、改词（同 #22/#23 先报后确认）。
- **释义两条来源、全程标注**：DEFINE 只把核对过的词以
  **纯文本**发给主机大模型——这是本 Agent 的产品选择：
  平台支持长焦照片经 data: URL 送入模型读字，本 Agent
  不用这条路径，词必须由你说出并核对。要三行：中文
  释义 / 简单英文解释 / 短例句，标注 LLM；
  大模型不可用就回退内置离线小词典（24 个常见词），标注
  OFFLINE；两边都没有，如实显示 none，绝不编造释义。

## 离线小词典（24 词，大模型不可用时的回退）

itinerary（行程）、boarding（登机）、receipt（收据）、
prescription（处方）、appointment（预约）、deadline（截止
日期）、warranty（保修）、ingredient（成分）、fragile
（易碎）、refund（退款）、detour（绕行）、luggage（行李）、
signature（签名）、discount（折扣）、reservation（预订）、
urgent（紧急）、available（可用）、direction（方向）、
platform（站台）、entrance（入口）、exit（出口）、caution
（小心）、volunteer（志愿者）、schedule（时间表）——每个词
都带中文释义、英文解释和例句，与大模型结果同格式显示。

## 功能流程

1. LOOK（可选）：看着生词所在的页面长焦拍一张留档，只
   显示字节数，拍完即停流
2. SAY：说出生词——先 `en-US` 识别，主机拒绝语言时回退
   `zh-CN` 并警告；无识别主机轮换离线词条（标注 SKIP）
3. 核对：听到的词原样大字显示；不对就再 SAY，绝不自动纠正
4. DEFINE：纯文本送大模型取三段释义（标注 LLM），或离线
   词典命中（标注 OFFLINE），或如实 none；成功后自动朗读
   「词 + 中文释义」一次（合成语音，非真人发音）
5. SCENE 轮换场景（阅读 / 旅行 / 工作 / 日常），SAVE 把
   {词， 释义， 英文解释， 例句， 来源， 场景， 日期} 存入
   `wordBook`（最多 60 条，超了挤掉最旧）
6. BOOK 模式：SCENE 按场景过滤，REVIEW 逐个走词（大字词
   + 释义 + 例句），SPEAK 朗读当前词
7. DEMO：itinerary 走离线通道释义并存入旅行场景，另播
   boarding（今天）与 luggage（昨天）两词——全部来自
   一次 Date 快照，只在内存里，CLEAR 退出后恢复真实生词本

> 诚实边界：**眼镜读不了你看的任何字**。照片是记录，不是
> 输入；词听错了它抓不到，核对环节因此不可省略。大模型
> 释义是文本生成的，个别词义可能不精确；离线词典只有
> 24 个词。朗读是 speechSynthesis 合成音，读错重音、音节
> 都有可能——当「听个大概」，不当发音课。拿不准的释义，
> 回头用正经词典复核。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | LOOK 长焦拍下生词所在的页面留档（只取字节数显示，不保存、不读取） |
| RECORD_AUDIO | SAY 录入生词：佩戴者模式麦克风检查 + 一次性语音识别（en-US 优先，zh-CN 回退）；SPEAK 朗读走系统 TTS 不占麦克风 |

相机/麦克风只在用户点 LOOK / SAY 时启动，用完立即停掉
全部媒体轨道。不录音、不保存照片；生词本只存本机 wx
同步存储，不上传。发给大模型的只有你核对过的那个词
（纯文本）。

## 打包与预览

```bash
cd ~/workspace/rokid/word-look
~/tools/bin/aix pack . -o ../dist/word-look.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-word.js`；结果截图的点击序列为 canvas 内 DEMO (300, 285)，
坐标经视觉定位确认）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-word-look`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 word-look」，拿一本英文书或站在英文
   标识前实测：LOOK 长焦留档是否成功、SAY 对英文词的识别率
   （本 Agent 最大风险点——故意慢慢说、再含糊说，看核对环节
   是否拦得住听错）、大模型释义是否及时且格式正确、断网时
   离线词典是否接得上（查 itinerary 应命中、查生词应如实
   none）、存几条后按场景复习一遍

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 23.9 KB（本地打包 `dist/word-look.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 查词与生词本逻辑（Node 实测）：把页面对象以 wx 打桩加载进
  Node，共 114 条断言全过——含离线词典正好 24 词且任务清单
  逐词齐全、命中大小写不敏感、查不到返回 null；大模型回复
  解析（标准 ZH/EN/EX 三行、全角冒号、单行垃圾回退为 zh、
  三行无前缀按序分配、空回复返回 null）；查词优先级（大模型
  可用优先且词以纯文本送出、forceOffline 跳过大模型、大
  模型不可用回退离线、两边落空如实 none）；DEFINE 全流程
  （成功自动朗读词+释义、无释义时 SAVE 被拒）；上限行为
  （60 条封顶、最新在前、最旧被挤掉）；场景计数与过滤、
  存储加载校验（缺 gloss/非法场景/非数组一律丢弃）；SAY
  三条路径（无识别主机预置轮换且标注 SKIP、en-US 听错的
  「refound」**原样保留不纠正**、主机拒绝 en-US 时只重试
  一次 zh-CN 且界面留回退警告、非语言错误不重试且如实
  FAIL）；BOOK 复习在本场景内循环、空场景如实提示；DEMO
  一快照（三词日期自洽：boarding 与 itinerary 同为快照今天、
  luggage 为昨天、演示从不写真实存储、CLEAR 退出后真实
  生词本原样恢复）；点头推进分发（无词忽略、有词查词、
  有释义存词）。一次真实缺陷在开发中被断言抓出并修复：
  REVIEW 游标曾被渲染路径悄悄推进（打开生词本就跳过第一
  个词），改为只读钳制后复习从第一个词开始。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：首页初始态完整渲染（词框/释义框、场景与
  生词本计数、LOOK/SAY/DEFINE 与 BOOK 操作按钮、常驻诚实
  行）；点 DEMO 后到达结果态：itinerary 大字、释义三段
  （行程；旅行计划 / 英文解释 / 例句）、来源标注 OFFLINE
  (DEMO)、生词本 3/60 且旅行场景 3 条、行首条目日期与
  OFF 标记均正确渲染。BOOK 复习态另在 Node 断言中覆盖
  （场景内循环、空场景提示、朗读内容）。

**未验证**

- 真机 `en-US` 识别对英文生词的准确率——本 Agent 最大的
  真实风险点；主机是否接受 `en-US`、拒绝时的错误码形态、
  回退 `zh-CN` 后对英文词的误听程度，都要真机实测。核对
  环节是为此设的防线，但防线本身（用户是否真的逐字看）
  无法在本地验证。
- 真机大模型（LanguageModel）可用性与三行格式的遵从度：
  格式跑偏时解析会按行序 salvage，释义质量与分段可能
  不如预期，真机待测。
- 真机长焦拍照在书页/标识上的成功率与字节数表现；点头
  推进、定义自动朗读的及时性、TTS 合成音对英文词的读音
  准确度。
- wx 存储在眼镜重启后的持久性（60 条生词本跨重启保留）。
- **输入方式的产品边界**：本 Agent 没有 OCR——词必须由
  用户说出来。不会读、读不准的词，用户连「说」都说不对，
  这类词它帮不上忙；它服务的是「认识字母、就是不知道
  意思」的词，不是生词启蒙工具。这是已知边界，不是待补
  的验证项。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Word Look defines the English word in front of you without reaching for your phone. Look at the page, say the word, and check it on screen as heard - it is never silently corrected, because a misheard word earns a wrong meaning. Define sends the confirmed word as text to the on-device AI for a Chinese meaning, a simple English gloss and an example, or falls back to a labelled offline dictionary of 24 common words. Save files words by scene - reading, travel, work, daily - to review later.

### Opening Message

Hi, I'm **Word Look** - I can't read the page for you, but I can define the word you say.

**LOOK** photographs the page as a record, **SAY** the word and **check it letter by letter** - a wrong word gets a wrong meaning, and I never fix it quietly. **DEFINE** gives the meaning, **SCENE** picks where to file it, **SAVE** keeps it. In **BOOK** mode, **REVIEW** walks your saved words by scene and **SPEAK** reads them aloud.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-word-look-index.png`（aix preview 首页：WORD LOOK 初始态，含词框/释义框、场景与生词本计数、操作按钮及常驻诚实行，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-word-look-result.png`（DEMO 结果态：itinerary 离线释义三段 + 来源标注 OFFLINE (DEMO) + 已存入旅行场景，本地文件）
- Video：待真机补 — 真机录制「看着英文书页说出生词 → 核对大字 → 出释义并朗读 → 按场景存入生词本 → BOOK 模式复习」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None (documentation-accuracy fix only).

**Improvements**

- None.

**Fixes**

- Corrected a false capability premise in the docs (capability-boundary audit 2026-10-24): the README and AGENTS.md previously claimed the captured photo "cannot reach the language model" and that the model is text-only. Per the official capability dossier (§2.9), the host language model accepts image input as `{type:'image_url'}` including data: URLs, and telephoto photo + LLM image input is the platform's official read-text path (§4.3). This agent still sends text only — that is a product choice that keeps the wearer's spoken-and-checked word as the only input; the docs now state it as a choice, not a platform limit.

#### Build 1.0.0

**Features added**

- Look-and-say lookup: LOOK takes a telephoto photo of the page or sign as a record only (byte size shown; the runtime has no OCR and the photo is never read), SAY hears the word itself in one shot - wearer-mode mic check first, English (en-US) recognition first, one honestly-labelled zh-CN retry only when the host rejects the language, and preset cycling over the offline dictionary when no recogniser exists.
- The heard word is shown verbatim, big, for the wearer to check before anything is defined; it is never silently corrected. DEFINE sends the confirmed word as text only to the host language model for a one-line Chinese meaning, a simple English gloss and one example sentence (reply parsed in that three-line format with a line-order salvage fallback), labelled LLM; when the model is unavailable a built-in offline mini-dictionary of 24 common words answers instead, labelled OFFLINE; when neither can help, the agent says so instead of inventing a meaning.
- Results are spoken aloud automatically (word plus Chinese meaning; synthetic TTS speech, stated as such, not a native-speaker recording), and SAVE files {word, meaning, gloss, example, source, scene, date} into an on-device word book (key wordBook, max 60, newest first) under one of four scenes - reading, travel, work, daily. BOOK mode browses by scene filter, REVIEW walks the words of a scene showing word and meaning big, SPEAK reads the current entry.
- DEMO defines "itinerary" through the offline path (forced and labelled), files it under travel, and seeds boarding and luggage from a single date snapshot - all in memory only; leaving DEMO restores the real word book untouched.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
