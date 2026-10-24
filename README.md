# outfit-check — 穿搭检查（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-outfit-check
```


50 个「指向性生活问题」Agent 的第 24 个。买衣服时站在
试衣间里拿不准：这件搭不搭？这个颜色配不配？穿去那个
场合行不行？本 Agent 不替你看衣服——它看不见。它做的
是把搭配判断变成规则摆在你眼前：你用选择器描述手里
这件单品、打算搭配什么、去什么场合，内置规则表立刻
给结论（搭 / 勉强 / 不搭）和修改建议，还能把这段文字
描述问一遍大模型要两条贴士，最后站到镜子前复核版型。

## 预览截图

截图统一存放于仓库根目录 `screenshots/outfit-check/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/outfit-check/preview-outfit-check-index.png)

![DEMO 结论态（藏青 + 米色 · 上班 → 搭 6/6）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/outfit-check/preview-outfit-check-verdict.png)

## 解决的问题

搭配翻车大多翻在三个地方：颜色撞了（红配绿）、花纹
打架（条纹配花纹）、场合不对（运动鞋进正式场合）。
这些坑都是规则性的，不需要品味天赋，缺的是试穿那一
刻有人把三件事逐项过一遍。本 Agent 把这三项检查挂在
视线上：你看着衣服描述它，它逐打分、出结论、给改法，
不用腾手翻手机搜「藏青色配什么颜色」。

## 指向性设计（为什么必须用眼镜）

- **凝视即指向（GAZE）+ 手中物拍照（default）**：看着
  衣架上、或镜子里的这件衣服点头，或点 LOOK，用
  `ImageCapture.takePhoto({mode:'default'})` 拍下留档
  ——你看着的那件就是正在检查的那件。照片只作记录，
  不参与任何判断。
- **描述代替识别（诚实边界）**：AIUI 运行时没有
  OCR / 图像分类把照片变成搭配结论的链路。本
  Agent 只送文字描述（产品选择）——平台其实支持
  把照片以 data: URL 图片输入送进大模型，本
  Agent 不用这条路径。所以单品由佩戴者亲眼看后
  用选择器描述
  （类型/颜色/花纹/版型），结论来自规则表对描述的
  打分；ASK AI 收到的是同一段**文字描述**（文本进、
  文本出），永远不发照片。界面全程标注
  「the agent never sees the clothes」。
- **头部稳定 = 凝视确认**：`enableWorldAwareness()`
  后 `onOrientationStabilityChange` 报告头部稳定
  （HEAD STEADY）；点头（`onHeadGesture` 的 `nod`）：
  描述态触发 LOOK 拍照，结论态重读结论——试衣间里
  双手拿着衣服时也能用。
- **镜子复核闭环（PLAN 的「照镜子再评」）**：规则结论
  之后还有第二段：站到镜子前，用 MIRROR 报你镜子里
  看到的整体效果（合身 / 显胖 / 显瘦），它给最后一行
  收尾意见。规则管搭配关系，镜子管上身效果。

## 功能流程

1. 描述单品：FIELD 在 8 个字段间切换（单品 / 颜色 /
   花纹 / 版型 / 搭配 / 搭配色 / 搭配花纹 / 场合），
   VALUE 或方向键轮换取值；颜色是 10 色表（黑 / 白 /
   灰 / 藏青 / 米色 / 红 / 蓝 / 绿 / 黄 / 粉），场合
   5 种（上班 / 约会 / 运动 / 正式场合 / 日常）。
   出厂默认即 DEMO 的一套（藏青上衣 + 米色裤子 +
   上班）
2. LOOK（或稳头点头）拍下这件衣服或镜子里的自己，
   只作记录，显示字节数
3. CHECK 出规则结论（三项打分，满分 6）：
   - 配色：中性色（黑/白/灰/藏青/米色）互搭、或中性
     托亮色 = 2 分；亮色查配对表：蓝+黄 = 2 分，
     红+绿 / 红+粉 撞色 = 0 分，同色一身 = 1 分
   - 花纹：上下都有花纹 = 0 分（打架）；一花一纯
     或全纯 = 2 分
   - 场合：单品类型 × 场合表，如裙子×运动、鞋×
     正式场合 = 0 分
   - 结论：三项全满分 = **搭**（规则故意从严）；
     3–5 分 = **勉强**；场合 0 分或总分 ≤2 =
     **不搭**。结论附三项理由 + 2 条具体建议
     （如「搭配色换成中性色（黑/白/灰/米色），撞色
     立刻解开」「上下只留一个花纹，另一件换纯色」），
     并自动 TTS 朗读；结论后改任何字段，旧结论立即
     作废，提示重新 CHECK
4. ASK AI（可选）：把选择器拼成的文字描述发给
   LanguageModel，要 2 条简短搭配建议，标注来源
   LLM；不可用时如实 SKIP，规则结论独立成立
5. MIRROR 复核：站到镜子前，MIRROR 轮换你看到的
   整体效果（未看 / 合身 / 显胖 / 显瘦），给出收尾
   一行（如「显胖 — 上衣下摆塞一点，或把搭配换成
   深色压一压」）；镜子复核是佩戴者自己的观察，
   不改规则分数
6. SPEAK 重读当前描述或结论 + 建议；结论态按
   Enter / GlobalHook 回到描述态继续改
7. DEMO 按钮：载入藏青纯色合身上衣 + 米色纯色裤子
   + 上班，直接走到「搭」（6/6）结论页

> 安全与边界说明：规则是通用穿搭常识，不是时尚
> 定论——个人风格、品牌调性、面料质感不在覆盖范围
> 内。你描述错了颜色，规则就按错的算；AI 贴士与
> 规则冲突时，先信写明理由的规则项。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | 取流并以 default 模式拍摄正检查的衣服或镜子中的自己（只作影像记录，不参与识别，搭配判断由用户描述 + 内置规则表打分） |

相机只在用户触发时启动：拍完立即停掉全部媒体轨道。
描述、结论与 AI 贴士只在内存里，不落盘、不持久化
任何数据。

## 打包与预览

```bash
cd ~/workspace/rokid/outfit-check
~/tools/bin/aix pack . -o ../dist/outfit-check.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-outfit.js`；结论截图为首页点 DEMO 后截取，
DEMO 按钮坐标见 shot 脚本注释；坐标经视觉定位确认）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-outfit-check`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 outfit-check」，在服装店/家里衣柜前实测：
   拿一件亮色上衣配撞色下装走一遍 CHECK，看结论与建议是否对路；
   再试 ASK AI 在真机大模型下能否返回两条贴士；最后站到镜子前
   用 MIRROR 复核一轮，核对结论页与 TTS 朗读是否正确、及时

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.1（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 20.5 KB（本地打包 `dist/outfit-check.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 规则表逻辑（Node 实测）：把页面对象以 wx 打桩加载进 Node，共
  26 条断言全过——含配色对（黑+白、藏青+米色、红+白 = 2 分安全；
  红+绿、红+粉 = 0 分撞色，且顺序无关；蓝+黄 = 2 分；同色 = 1 分）、
  花纹对（条纹+花纹、格纹+条纹 = 0 分打架；一花一纯、全纯 = 2 分）、
  场合对（鞋×正式场合、裙子×运动 = 0 分；鞋×运动、上衣×上班 = 2 分）、
  完整结论（DEMO 组合 6/6 = 搭且恰有 2 条建议；白鞋×正式场合 = 不搭；
  红绿 + 双花纹的建议里含「换纯色」改法；红+黄 = 勉强）、
  默认选择器与 DEMO 服装逐项一致。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：首页初始态完整渲染（描述行藏青上衣 + 米色裤子
  + 上班、照片行、FIELD/VALUE/LOOK 与 CHECK/ASK AI/SPEAK、
  MIRROR/DEMO 按钮及描述提示框）；点 DEMO 后到达结论态：
  大字「搭 — 可以穿出门」、三项理由行（配色/花纹/场合各 +2）
  与 2 条上班建议均正确渲染。

**未验证**

- 真机相机取流与 default 模式拍衣服/镜中人的记录效果（预览主机无
  相机，LOOK 的 FAIL 路径已如实写明原因，真机待测）。
- 真机头部稳定检测、点头触发 LOOK / 重读结论、结论的自动 TTS
  朗读及时性（服装店环境噪声下待测）。
- 真机 LanguageModel 对文字描述的贴士质量（预览主机无大模型，
  ASK AI 的 SKIP 路径已在代码中如实处理；贴士与规则结论的一致性
  待真机多组描述对比）。
- **判断方式的产品边界**：本 Agent 不看衣服——结论全部来自用户
  用选择器给出的描述 + 内置规则表，照片只作记录；规则是通用
  穿搭常识，个人风格与面料质感不在覆盖范围内。这是已知边界，
  不是待补的验证项。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Outfit Check answers 'does this match, and does it suit the occasion?' while you shop. Describe the piece with selectors - type, colour, pattern, fit - plus what you will pair it with and the occasion. A built-in rule table scores colour pairing, pattern clash and occasion fit, and gives a verdict - matches, so-so or no match - with two concrete fix suggestions, spoken aloud. Optionally, the host AI reads your text description (never a photo) and adds two styling tips.

### Opening Message

Hi, I'm **Outfit Check** - I can't see the clothes, so you describe them and I judge the match.

Use **FIELD** and **VALUE** to describe the piece (type, colour, pattern, fit), what you'll pair it with, and the occasion. **CHECK** gives a rules verdict - matches, so-so or no match - with two fix suggestions, spoken aloud. **ASK AI** adds two tips from your text description only. Then stand at a mirror and tap **MIRROR** for the final fit check.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-outfit-check-index.png`（aix preview 首页：OUTFIT CHECK 初始态，含描述/照片行、FIELD/VALUE/LOOK 与 CHECK/ASK AI/SPEAK、MIRROR/DEMO 按钮及描述提示框，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-outfit-check-verdict.png`（点 DEMO 后到达的规则结论态：大字「搭 — 可以穿出门」+ 三项理由行与 2 条建议 + DEMO 标注，本地文件）
- Video：待真机补 — 真机录制「拿起一件衣服 → 描述选择器 → CHECK 出结论 → ASK AI 贴士 → 镜子前 MIRROR 复核」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None (documentation-accuracy fix only).

**Improvements**

- None.

**Fixes**

- Submission copy corrected (capability-boundary audit 2026-10-24): the optional AI tips were described as coming from an "on-device AI". The host LanguageModel does not expose its provider, model or endpoint, so where inference runs is unknowable from the agent - the copy now says "the host AI" and makes no deployment claim.
- Photo/LLM boundary restated (audit 2026-10-24): earlier copy claimed a photo "cannot be sent to the LLM" as a platform fact. The platform does accept photo input (image_url, including data: URLs); this agent sends the text description only by product choice, and the copy now says so.

#### Build 1.0.0

**Features added**

- Selector-driven outfit description: 8 fields - piece type (top, trousers, skirt, coat, shoes), colour (10-colour palette), pattern (plain, stripes, check, floral), fit (slim, regular, loose), pair type, pair colour, pair pattern, and occasion (work, date, sport, formal, daily). FIELD picks the field, VALUE or the arrow keys cycle it; the full description is always in view.
- Built-in rule verdict, spoken aloud: colour pairing (neutrals pair safely and carry brights; red+green and red+pink clash score 0; blue+yellow scores 2), pattern clash (two non-plain patterns score 0), and occasion fit per piece type (skirt for sport and shoes at a formal event score 0). Verdict is strict by design - all three components at full marks (6/6) means "matches"; any discounted component means "so-so"; a wrong occasion or a total of 2 or less means "no match". Every verdict shows the three scored reasons plus two concrete fix suggestions, and changing any field afterwards voids the old verdict honestly.
- Optional AI tips from text only: ASK AI sends the selector-built text description to the host LanguageModel for two short styling tips, labelled with their source; when the model is unavailable it says SKIP and the rules verdict stands alone. The record photo is never sent anywhere and never judged.
- Mirror re-check: after a verdict, stand at a mirror and cycle what you see (not checked, fits well, looks bulky, looks slimming) for one closing line - the rules judge the combination, the mirror judges how it wears.
- Gaze-directed record photo: head-stability gaze confirmation (HEAD STEADY), nod or LOOK photographs the garment or yourself in the mirror in default mode (record only); DEMO loads a navy top with beige trousers for work and lands on the 6/6 "matches" verdict, no camera needed.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
