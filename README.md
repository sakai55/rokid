# badge-reader — 名牌识人（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-badge-reader
```


50 个「指向性生活问题」Agent 的第 DI47 个。
社交场合最尴尬的一瞬：对方胸前挂着名牌，字小、挂得低，你
不能凑近盯着看；好不容易寒暄完，转头就把人家名字忘了。本
Agent 让你看向正前方那个人的名牌拍一张长焦照片，眼镜把照
片作为图片发给主机大模型读出姓名 / 公司 / 职位，立刻悄悄
朗读到你一个人耳边；再让你把你自己读到的姓名说出来，两边
逐字比对，不一致以你的为准。然后把这个人登记在他当时所
在的方向上——之后你再转回那个方向停住 2 秒，他的名字卡
片就弹回来，还会再悄悄念给你听。

> **先说清：没有人脸识别。** 本 Agent 永远不认脸——它绑
> 的是你登记那一刻的**头部朝向**。方向对上了就把名字摆出
> 来；站在那个方向上的是不是同一个人，它不知道，也不假
> 装知道。这一点写在界面常驻行、朗读措辞和下面全文里。

## 预览截图

截图统一存放于仓库根目录 `screenshots/badge-reader/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/badge-reader/preview-badge-reader-index.png)

![DEMO 态：名牌机器读数，姓名大字显示（王小明 · 星野科技 · 产品经理），标注 DEMO](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/badge-reader/preview-badge-reader-read.png)

![DICT 核对后：你读到的是王大明，与机器读数不一致，CHECK 显示 DIFF 并明说保存以你的版本为准](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/badge-reader/preview-badge-reader-diff.png)

![再遇卡片：演示朝向转到 90° 停住 2 秒，已登记的李华卡片弹出（按方向匹配，不是按脸）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/badge-reader/preview-badge-reader-remeet.png)

## 解决的问题

读名牌难在三处：距离与礼貌不许你凑近；名字只在当面那几秒
有用，过后就忘；叫错名字比忘了更尴尬。手机拍照放大要举起
来对人拍，动作本身就失礼。本 Agent 把「拍下 → 读出姓名
公司 → 立刻悄悄报你听 → 和你自己的眼睛核对 → 按方向登
记 → 再朝那个方向看时名字自己回来」压成眼镜上的几步：
看向名牌 SNAP，READ 让大模型把照片读成姓名 / 公司 / 职
位并当场念给你听，你瞄一眼大字对不对，再 DICT 把你读到
的姓名说出来比对，SAVE 按当时的朝向登记——全程不用低
头，不用举手机对着人。

## 指向性设计（为什么必须用眼镜）

- **看向即取景（GAZE 长焦）**：名牌小而远，SNAP 用
  `ImageCapture.takePhoto({mode:'telephoto'})` 长焦取
  景——你看向谁的名牌，拍的就是谁的，拍照那一瞬间的头
  朝向同时被冻结下来（`AbsoluteOrientationSensor` 四元
  数算 yaw；无传感器时如实记 `---`）。手机举起来拍，视
  线和手都暴露了意图。
- **读字走官方路径（telephoto + LLM 图片输入）**：运行时
  **没有 OCR API**（档案 §4.3），更没有人脸识别。审计后
  的做法：照片 Blob 经 `FileReader.readAsDataURL` 编码为
  data: URL，作为 user 消息的 `{type:'image_url'}` 内容
  连同文字指令发给主机 `LanguageModel`——这是档案
  §2.9 / §4.3 给出的官方读字路径（同 #39/#41）。提示词
  要求逐项忠实摘录姓名 / 公司 / 职位、看不清标 `[?]`、
  不许发明名牌上没有的内容，按 `NAME:` / `ORG:` /
  `TITLE:` 三行返回。
- **悄悄报你听（视线内的名字 + 只有你听见的朗读）**：读
  到后姓名以页面最大字号显示，并立刻 TTS 朗读姓名 + 公
  司——朗读只进佩戴者的耳朵，这是眼镜相对「把名字亮在
  手机屏上」的根本区别。
- **你的眼睛作交叉验证（核对即产品）**：大模型读名牌会
  读错，姓名错一个字就是叫错人。本 Agent 不让机器读数
  单独作数：DICT 把你自己读到的姓名说出来（原样显示），
  两边做**字面比对**（轻量归一化：去空白、去尾部标
  点），一致显示 `MATCH ✓`，不一致显示 `DIFF ⚠` 并明
  说保存以你的版本为准。比对只是比字面、不理解语义——
  格式差异也会判 DIFF，往安全方向错，界面常驻说明这
  一点。
- **按方向登记、按方向再遇（HEAD 朝向 = 人的位置）**：
  SAVE 把人绑在拍照/口述那一刻的朝向上；之后朝向落入
  某人登记朝向 ±15° 并连续停满 2 秒（tick 累计计时，
  同 #38 纪律），他的卡片弹出、名字再念一次；离开锥形
  区满 5 秒才重新布防。这不是认脸——是「这个方向你登
  记过一个人」，措辞处处如此。

## 手势映射

本 Agent 的主流程（拍名牌 → 读 → 核对 → 登记 → 再遇听名
字）都可以只用眼镜腿触控板手势 + 头部动作完成，不必点屏
幕按钮。手势与键码的对应来自官方文档档案 §3.2.1。

| 手势 | 键码 | 在本 Agent 中的动作 |
|---|---|---|
| 单击触控板 | Enter | 情景主操作：有口述待存 = SAVE 登记这个人；有机器读数待处理 = SPEAK 朗读；再遇卡片已弹出 = SPEAK；其余时候 = SNAP 拍名牌 |
| 滑动触控板 | ArrowUp / ArrowDown | 前后滚动已登记名单的选中项（LIST 按钮等效为向下滚动一位） |
| 双击触控板 | Backspace | 返回 / 关闭（由宿主处理，本 Agent 只记录事件） |
| 长按触控板 | —（系统级） | 唤醒 AI 助手（系统功能，不经过本 Agent） |
| 头部稳定时点头 | onHeadGesture `nod` | 朗读当前名字（与 SPEAK 等效）：有待处理读数念读数、再遇卡片弹出念卡片上的人；点头从不拍照、从不 READ、**从不保存** |
| 屏幕按钮 | — | 只保留 6 个：SNAP（长焦拍名牌）、READ（照片送大模型读姓名/公司/职位）、DICT（口述你读到的姓名作核对/无照片登记）、SAVE（按朝向登记这个人——手势纪律里唯一不许点头代办的动作，留显式按钮与单击两条路）、LIST（滚动名单选中项）、DEMO（无相机时仿真：播入名牌读数 + 一位已登记者，朝向 +45° 步进预览再遇），与手势等效或为手势不代办的动作留明确入口 |

## 功能流程

1. SNAP：看向正前方那个人的名牌拍长焦照片（冻结当时朝
   向 + 时间；照片只在内存，无相机主机如实 FAIL，并提
   示改走 DICT）
2. READ：照片 → data: URL → 主机大模型图片输入，返回
   姓名（大字）/ 公司 / 职位（标注 LLM READ，提示核
   对），并立刻把姓名 + 公司悄悄朗读给你听；模型不可
   用 / 转换不可用 / 模型报错 / wx 回退照片无 Blob，全
   部如实落到对应状态（原因写在 READ 行），照片仍作记
   录，并转入 DICT 兜底
3. DICT（核对/兜底）：wearer 麦克风可用性检查（结果单
   独一行 `MIC CHECK:`）后，用宿主 SpeechRecognition
   （zh-CN）在它自己的麦克风上口述你读到的姓名（可连
   公司一起说，原样保存），与机器姓名做字面比对出
   MATCH / DIFF；没有 SNAP 过也能直接 DICT 完成登记；
   无识别主机走预置姓名轮换并标注 SKIP
4. SAVE / 单击：把确认版姓名（你的版本优先）+ 公司 /
   职位 + 来源 + 登记朝向 + 日期时间存为纯文本（上限
   12 人，超出丢最旧并明说）；没有姓名或没有当时朝向
   如实拒绝；点头永不触发保存
5. 再遇：Agent 打开期间转回某个登记朝向 ±15° 并停满
   2 秒，他的卡片弹出、名字 + 公司再悄悄念一次（同一
   段面对只念一次，离开满 5 秒才重新布防，多人在锥内
   时最近者胜出）
6. DEMO：内存播入一条标注 DEMO 的名牌读数（王小明 ·
   星野科技 · 产品经理，在正前方）外加一位已登记者
   （李华，在 90°）；DEMO 中 DICT 播入的是姓改掉的
   「王大明」，DIFF 状态可完整预览；每点一次 DEMO 朝
   向 +45°，转到 90° 停住即可预览再遇卡片；转满一圈
   退出后恢复真实记录，全程不写存储

> 诚实边界：**没有 OCR、没有人脸识别**，读名牌靠「照
> 片 → 大模型图片输入」这条官方路径，而宿主真机是否真
> 的接受 image_url / data: URL、FileReader 是否可用，
> **都未经真机验证**（见「未验证」第一条）——所以每条
> 失败路径都留了一条能用的路，DICT 口述在任何情况下
> 都能完成登记。再遇提醒按**方向**匹配：登记方向上站
> 的是不是同一个人，眼镜不知道，卡片与朗读的措辞都按
> 「这个方向你登记过」说，你自己核对。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | SNAP 长焦拍名牌（照片只在内存中转、供 READ 转 data: URL，从不落盘保存） |
| RECORD_AUDIO | DICT 的佩戴者模式麦克风可用性检查（getUserMedia，检查流立即停轨）+ 宿主 SpeechRecognition 口述你读到的姓名（zh-CN） |

相机/麦克风只在用户点 SNAP / DICT 时启动，用完立即停掉
全部媒体轨道。不录音；落盘的只有登记的文本（姓名 / 公
司 / 职位 / 来源 / 朝向 / 日期 / 时间）；照片只随 READ 的
那一次请求经宿主通道发给大模型。

## 打包与预览

```bash
cd ~/workspace/rokid/badge-reader
~/tools/bin/aix pack. -o../dist/badge-reader.aix
~/tools/bin/aix preview. --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-badge.js`，独立页面副本 `preview-badge.html`；点击
序列为 canvas 内坐标，坐标经视觉定位确认后写入脚本：首
图为初始态，点 DEMO 到达读数态，再点 DICT 到达核对态，
再点两次 DEMO 把演示朝向转到 90° 并等驻留满 2 秒到达再
遇卡片态）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-badge-reader`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 badge-reader」，在真实社交/会议场合实测：
   **第一优先验证 READ 的图片通路**——SNAP 一张真实名牌，
   READ 是否真的返回姓名 / 公司 / 职位（验证宿主接受
   image_url / data: URL、FileReader 可用）、姓名摘得准不
   准（一字之差就是叫错人）、看不清处是否老实标 `[?]`；
   图片通路若不通，READ 是否如实落到失败状态且 DICT 兜底
   可用；再测长焦在社交距离（1–2 米）拍名牌的清晰度、
   READ 后立刻朗读的音量是否「只有自己听见」、DICT 口述
   的识别率、登记后转回该方向 2 秒再遇卡片与朗读是否触
   发、换人站在同一方向时卡片照常弹出（按方向匹配的预期
   行为，不是 bug）

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 30.7 KB（本地打包 `dist/badge-reader.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 核心逻辑（Node 实测）：把页面对象以 wx / LanguageModel /
  FileReader / SpeechRecognition / speechSynthesis /
  ImageCapture / AbsoluteOrientationSensor 全部打桩加载进
  Node，共 114 条断言全过——含 NAME/ORG/TITLE 解析（标
  准三行、全角冒号、无标签 salvage、仅姓名、空回复返回
  null、`[?]` 原样保留）；字面比对归一化（尾部标点差异
  判 MATCH、姓名不同判 DIFF、DIFF 时你的版本胜出成为
  确认姓名、口述一行拆姓名/公司）；READ 通路（SNAP 以
  telephoto 模式拍照且朝向在拍照瞬间冻结、content 数组
  恰两段且 image_url 段携带 data: 前缀 URL、system 只经
  initialPrompts 首条、prompt 后 session 被 destroy、读
  到后姓名 + 公司立刻朗读一次）；DICT 通路（检查流轨道
  在识别开始前已全部停掉、检查结果独立 `MIC CHECK:`
  行、聆听标注 `(host ASR)`、口述原文 verbatim 入账）；
  失败迁移全覆盖（无大模型 / availability 非 available /
  FileReader 缺失 / 模型抛错 / 模型空回复，全部如实落到
  对应状态且照片保留、DICT 兜底可用；wx 照片无 Blob →
  READ 如实 n/a）；SAVE 纪律（无姓名拒绝且不写存储、
  有姓名无朝向拒绝、**点头永不保存**（只朗读）、SAVE 后
  字段与来源 llm/dict/both 正确、单击在口述待存时等同
  SAVE、口述登记的朝向取口述那一刻）；上限与落盘（12
  人上限丢最旧且有报告、落盘 payload 只有八个文本字段、
  不含 data: URL 与照片字节）；再遇引擎（锥内不满 2 秒
  不触发、满 2 秒只念一次、同段面对不重复、离开不足
  5 秒不重新布防、满 5 秒后再次触发、多人在锥内最近者
  胜出、短暂瞥过不触发也不留卡片）；手势全流程（单击
  无待处理时 SNAP、有读数时 SPEAK，滑动滚动选中项，
  点头须头稳且只朗读，TTS 从不设置 utterance.lang）；
  DEMO（播入读数与已登记者、DICT 播入改姓触发 DIFF、
  步进到 90° 再遇卡片为李华弹出并朗读、转满一圈退出恢
  复真实记录，**整个 DEMO 周期零 wx 存储写入**）。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被.aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图四张（见下方
  Preview Media）：首页初始态完整渲染（名牌框各行、再遇
  卡片框、名单、六个按钮及常驻诚实行）；点 DEMO 到达读
  数态：姓名大字（王小明）与公司 / 职位行正确渲染、标注
  DEMO；再点 DICT 到达核对态：YOU SAID 为王大明（DEMO
  口述），CHECK 显示 DIFF ⚠ 并明说保存以你的版本为
  准；再点两次 DEMO 把演示朝向转到 90° 并驻留满 2 秒
  到达再遇态：已登记的李华卡片弹出并高亮。

**未验证**

- **真机 READ 图片通路**：宿主 `LanguageModel` 是否
  真的接受 user 消息里的 `{type:'image_url'}` content、data:
  URL 是否被接受、Blob → `FileReader.readAsDataURL` 在眼镜运
  行时里是否可用——档案 §2.9 只保证文档层面成立，三者都要真
  机实测。若图片通路在真机不通，READ 会如实落到失败状态，
  本 Agent 靠 DICT 口述仍可完整使用（你的眼睛 + 口述登记 +
  按方向再遇），但「拍照读名牌」这个核心卖点要等真机结论。
- 真机大模型读名牌的质量：姓名 / 公司 / 职位的摘录准确
  率（姓名是高危区）、`[?]` 诚实标注的遵从度、三行格式
  的稳定性；格式跑偏时解析按行 salvage，字段可能分错
  行。名牌版式千差万别（横排/竖排、双语、反光覆膜），真
  机覆盖度待测。
- 真机长焦在社交距离（1–2 米）拍名牌的清晰度与成功率
  （名牌随身体晃动、低头角度、室内弱光）；wx 回退照片
  在真机上的形态（回退照片没有 Blob，READ 对它是如实
  n/a、只能 DICT——真机上回退触发频率待测）。
- 真机 DICT 识别率与字面比对的实际表现：宿主识别器把口
  述姓名转成的文字（同音字、繁简、分隔符）与机器姓名的
  差异会不会频繁误判 DIFF（比对是字面比对，误判方向是
  安全的——多提醒核对且保存以你为准——但频率待真机观
  察）；社交场合噪声下宿主识别器听姓名的准确度（wearer
  检查流不参与识别）。
- 真机再遇的朝向精度：头部朝向读数的漂移与零点参考
  （宿主定义）会不会让 ±15° 锥在真实转身时误触发或漏
  触发；2 秒驻留与 5 秒重新布防的手感；READ 后立刻朗
  读的实际音量是否真的「只有佩戴者听见」（开放式扬声
  器在安静场合的漏音待真机确认）；点头 SPEAK 在社交场
  合的误触率。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Badge Reader reads the name badge of the person in front of you. SNAP takes a telephoto photo; READ sends it to the host AI as an image - the official read-text path; there is no OCR and no face recognition - and quietly speaks the name and company to you alone. DICT the name as YOU read it: the two are compared, MATCH or DIFF, and your version wins. SAVE registers the person against the direction you faced. Turn back to that direction and the name returns.

（461 字符）

### Opening Message

Hi, I'm **Badge Reader** - the badge in front of you, read aloud only to you.

**SNAP** a telephoto photo of the badge (memory only, never saved). **READ** sends it to the host AI as an image and shows **name / company / title** - a machine read that **may misread**. **DICT** the name as YOU read it: **MATCH**, or **DIFF** - your version wins. **SAVE** registers the person against the direction you faced - matched by **direction, never by face**. Face that way and I whisper the name back.

（493 字符）

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-badge-reader-index.png`（aix preview 首页：BADGE READER 初始态，含名牌框各行、再遇卡片框、名单与六个按钮及「photos NOT saved · no face recognition」常驻诚实行，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-badge-reader-read.png`（DEMO 读数态：机器读到的姓名大字「王小明」+ 公司 / 职位行（星野科技 · 产品经理），标注 DEMO，本地文件）
- Image 3：`artifacts/preview-badge-reader-diff.png`（DICT 核对态：YOU SAID 为王大明（DEMO 口述），与机器姓名不一致，CHECK 显示 DIFF ⚠ 并明说保存以你的版本为准，本地文件）
- Image 4：`artifacts/preview-badge-reader-remeet.png`（再遇态：演示朝向转到 90° 驻留满 2 秒，已登记的李华卡片弹出高亮——按方向匹配，不是按脸，本地文件）
- Video：待真机补 — 真机录制「看向对方名牌 SNAP → READ 读出姓名/公司并悄悄朗读 → DICT 说出自己读到的姓名出 MATCH/DIFF → SAVE 登记 → 转开再转回该方向停住，卡片弹出并再念一次」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 4 张图；还需至少 1 个视频，总数保持在 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Telephoto badge capture with the official read-text path: SNAP photographs the badge with ImageCapture in telephoto mode (wx camera-context fallback), freezes the head heading and a single-snapshot timestamp of that instant - the heading is the direction of the person in front of you - and holds the photo Blob in memory only; photos are never written to any storage. READ encodes the Blob to a data: URL and sends it to the host LanguageModel as an image_url part of one user message (multimodal content in the user role only, system prompt via initialPrompts, availability checked first, session destroyed after), asking for the badge's NAME / ORG / TITLE verbatim - unreadable spots marked [?], nothing invented - parsed with a line-salvage fallback. The name is displayed in the page's largest type, labelled a machine read that may misread, and the name + company are spoken to the wearer immediately.
- Your-eyes cross-check: DICT first runs a wearer-mode microphone availability check (stream opened, settings read back, tracks stopped at once - the check does not feed or shape recognition), then the host SpeechRecognition (zh-CN) on its own microphone hears the name as YOU read it (name and company as one line), verbatim. When both exist, the two names are compared literally after light normalisation (whitespace removed, trailing punctuation stripped) and flagged MATCH or DIFF on screen, with the comparison stated to be literal text, not understanding. On a DIFF your version is the one that gets saved. DICT also works with no photo at all (dictation-only registration), and an honest preset cycle covers hosts with no recogniser. Every READ failure state (no model, model unavailable, conversion unavailable, model error, empty reply, wx-fallback photo with no Blob) keeps the photo as a record, states the reason on the READ line, and points at the DICT path.
- Direction registration and re-meet reminders: SAVE (explicit tap or temple-pad single tap only - a nod never saves) registers the confirmed name, company, title, source and the heading of the SNAP/DICT moment as text on this device (key badgePeople, cap 12, oldest dropped with an on-screen note). While the agent is open, holding your heading within ±15 degrees of a registered person's heading for 2 continuous seconds surfaces their card big on screen and whispers the name once per facing episode, re-arming only after 5 s outside the cone; the nearest person in the cone wins. Matching is by direction only - there is no face recognition anywhere in this agent - and reminders exist only while the agent is open.
- DEMO seeds a labelled badge read （王小明 · 星野科技 · 产品经理， dead ahead) plus one already-registered person （李华 · 蓝桥资本， at 90 degrees) entirely in memory; DICT inside DEMO seeds your line with the surname changed （王大明）, so the DIFF cross-check state previews fully; stepping the simulated heading to 90 degrees previews the re-meet card; after a full circle DEMO exits and restores the real session untouched, having written no storage at any point.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
