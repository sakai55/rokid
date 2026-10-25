# parcel-sort — 快递分拣（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-parcel-sort
```


50 个「指向性生活问题」Agent 的第 Z29 个。快递一多就堆在门口一地：
这件是谁的？那件是不是生鲜、得先拆？拆错顺序，生鲜在普通堆里
放坏，文件被压在最底下。本 Agent 的分法很眼镜化：一件一件地
看着来——扫一眼面单条码留个记录号，用你自己的眼睛读出收件人、
选好类别和急不急，点 SORT，它就出声指挥你放哪一堆：急件放
左边先拆，普通件放右边。分了几件、每人几件，汇总一直摆在眼前。

> ⚠️ **诚实定位（先读）**：条码只是一个**记录号**，不是查询。
> 运行时没有快递公司的数据库可以查，一个条码字符串变不出
> 收件人姓名和物品内容；眼镜也没有 OCR，**面单是佩戴者亲眼
> 读的**，收件人由佩戴者读完后申报（WHO）。解不出条码时如实
> 走序号标签，绝不编造一个码出来。

## 预览截图

截图统一存放于仓库根目录 `screenshots/parcel-sort/`。

![SORT 初始态：一件未分，当前件待扫码，堆汇总为 0](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/parcel-sort/preview-parcel-sort-index.png)

![DEMO 后落在 LIST：3 件已分（急件优先），堆汇总 急件 2 · 普通 1](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/parcel-sort/preview-parcel-sort-list.png)

## 解决的问题

一堆快递的分拣难点不在搬，在「逐件判断 + 记住结论」：每件都要
读面单、定归属、判急缓，再决定放哪——判断完三件，第一件放哪
又忘了。手机记事本要逐件打字，对着一地箱子根本不现实。眼镜的
串行视角正好对上这个流程：你的视线落在哪件，就处理哪件；
每件的结论（放左还是放右）当场出声、不用记；整批的账
（急件几件、每人几件）一直挂在眼前，拆错、漏拆一眼可见。

## 指向性设计（为什么必须用眼镜）

- **凝视即流水线（核心）**：分拣是天然的串行凝视任务——看向
  哪件就处理哪件。SCAN 对着正看的这件面单广角拍照
  （`ImageCapture.takePhoto({mode:'wide'})`，同 #02 的大视场
  条码路）并尝试 `BarcodeDetector` 解码；头部稳定时点头即
  SORT，手里抱着箱子也不用腾手点屏。
- **结论用耳朵交接**：每件分完立即 TTS 朗读放堆指令
  （「急件：你的文件。放左边急件堆，先拆。」）——你的眼睛
  已经去看下一件了，放哪由耳朵确认，不用回头看屏幕记结论。
- **汇总常驻眼前**：急件/普通件数与每位收件人的件数一直
  显示在视线内；LIST 模式急件优先重排，SPEAK 一口气念完整
  批汇总。分拣是体力活，账要自己长在眼前，不能靠脑子记。

## 功能流程

1. 拿起一件，看着它的面单点 SCAN：广角拍照 + 条码解码，
   解出的字符串原样成为这件的记录号；主机无解码器 / 照片
   里没码 / 相机不可用时如实提示，这件在 SORT 时自动得到
   序号标签（#1、#2……）；照片只在解码瞬间使用、本身不保存，
   落盘的记录只有记录号（或序号标签）与申报的收件人/类别/急常
2. WHO 轮换收件人（我 / 配偶 / 孩子 / 父母 / 全家）——
   你亲眼读面单后的申报；KIND 轮换类别（日用品 / 食品
   生鲜 / 文件 / 衣物 / 电子产品 / 其他），选到食品生鲜时
   急件自动打开（仍可手动翻回）；URG 手动切 急 / 常
3. SORT（或头部稳定点头、Enter）入账并朗读放堆指令：
   急件 → 左堆先拆，普通件 → 右堆。下一件自动保留收件人，
   记录号 / 类别 / 急常重置
4. 随时切 LIST 看整批（急件优先）+ SPEAK 听汇总；
   一批拆完点 CLEAR 清空，开下一批（分拣按批进行，
   一批存本机 wx 同步存储 `parcelSort`，最多 30 件）
5. DEMO 仿真：用一次时钟快照分好 3 件标注 DEMO 的快递
   （我的文件·急 / 孩子的食品生鲜·急 / 配偶的衣物·常），
   直接落在 LIST 视图与堆汇总上；重入 DEMO 先清旧 DEMO 件

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | SCAN 时对面单广角拍照并尝试条码解码（照片只在解码瞬间使用，不保存） |

只声明 CAMERA；世界感知/头部手势在 AIUI 里不需要单独的
权限声明。本 Agent 不用麦克风、不用定位。

## 打包与预览

```bash
cd ~/workspace/rokid/parcel-sort
~/tools/bin/aix pack . -o ../dist/parcel-sort.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-parcel.js`；Shot A = 初始 SORT 态无点击；Shot B = 点
DEMO 一次（canvas 坐标 239,320，经视觉定位确认）落到 LIST 堆汇总态）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-parcel-sort`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 parcel-sort」，攒一批真实快递逐件测：
   带清晰条码的看解码是否成功、无码/小票件看是否如实走序号
   标签；生鲜件验证自动标急；整批听 LIST + SPEAK 汇总是否
   与实际堆数一致

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.1（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 17.2 KB（本地打包 `dist/parcel-sort.aix`，含本 README） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 分拣与汇总逻辑：用 Node 加载页面对象（wx 打桩、speechSynthesis
  记录朗读文本）跑 74 条断言全过——收件人/类别轮换、食品生鲜
  自动标急且可手动翻回、无相机时 SCAN 如实走无码路径并给出
  序号标签、解码条码原样入账、三件分拣的放堆朗读原文逐字
  核对（左急/右常）、分拣后保留收件人且重置类别/急常/记录号、
  堆汇总计数（总数/急/常/每人件数）与汇总朗读原文、LIST
  急件优先且同组稳定、存储往返、上限 30 件丢最旧、CLEAR
  清批并落盘。
- DEMO 确定性：同一套断言验证 DEMO 落点——3 件种子
  （我·文件·急 / 孩子·食品生鲜·急 / 配偶·衣物·常）的
  日期与时间字符串全部来自一次时钟快照、逐字相同，落在
  LIST 且堆汇总为 急件 2 · 普通 1，重入 DEMO 不堆积。
- 打包：`aix pack` 成功（大小见上表）；`aix list` 核对包内含
  AGENTS.md、app.js、app.json、package.json、README.md、
  pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：初始 SORT 态完整渲染（当前件待扫码、
  堆汇总 0/30）；DEMO 态渲染出 LIST 急件优先的三行与堆汇总，
  与 Node 断言的落点一致。预览主机无相机，真实 SCAN 的
  解码/失败路径由 Node 与静态检查覆盖，预览里只走 DEMO 路径
  （与兄弟 Agent 一致）。

**未验证**

- 真机上广角拍照 + `BarcodeDetector` 对真实快递面单条码的
  解码成功率（面单褶皱、反光、小条码都会影响）——这是本
  Agent 第一号真机未知数；解不出时走序号标签是设计内回退，
  不是故障。
- 真机头部稳定与点头 SORT 的触发灵敏度、抱箱子时误触发率。
- TTS 放堆指令与整批汇总在真机上的朗读效果（语速、断句）。
- wx 同步存储在眼镜重启后恢复本批记录的情况——未实测；
  本批若跨重启丢失，按批分拣的设计下损失仅限当前一批。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Parcel Sort turns a doorstep pile of deliveries into two spoken piles. Look at each parcel in turn: scan its label barcode (kept only as a record ID — there is no carrier lookup), declare whose it is and what kind of thing it is, flag it urgent or normal — fresh food flags itself — and the glasses speak the instruction: urgent goes to the left pile, opened first; normal to the right. A running summary always shows urgent count, normal count and parcels per person.

### Opening Message

Hi, I'm **Parcel Sort** — let's clear that pile by the door.

Take the parcels **one at a time**. **Look** at each label and tap **SCAN** — I keep its barcode as a record ID only; I can't read names, so tap **WHO** and **KIND** for what *you* read, and **URG** if it's urgent (fresh food flags itself). Tap **SORT** and I'll tell you the pile: **urgent left, open first — normal right**. **LIST** shows the batch, urgent first; **SPEAK** reads the totals aloud.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-parcel-sort-index.png`（aix preview 初始 SORT 态：当前件待扫码、收件人/类别/急常选择行、堆汇总 0，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-parcel-sort-list.png`（DEMO 后 LIST 态：3 件已分、急件优先排序、堆汇总 急件 2 · 普通 1 与每人件数，本地文件）
- Video：待真机补 — 真机录制「逐件 SCAN 一批真实快递 → SORT 朗读放堆 → LIST + SPEAK 念汇总」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None.

**Improvements**

- None.

**Fixes**

- Documentation accuracy (capability-boundary audit 2026-10-24): corrected wording that called the SCAN photo itself "the record". The photo is used only at the decode moment and is not retained; the durable record is the committed entry — the decoded barcode string (or the sequential batch label when no code decodes) plus the wearer-declared recipient, kind, urgency and timestamp. Docs and code now agree on this everywhere.

#### Build 1.0.0

**Features added**

- Gaze-serial parcel sorting: one parcel at a time, looking at it — SCAN takes a wide-mode photo of its label and tries BarcodeDetector exactly like the shelf-compare agent; a decoded string becomes the parcel's record ID, shown and stored verbatim. Honest fallbacks throughout: no detector, no barcode in frame, or no camera all land on a sequential batch label (#1, #2, ...) with the reason on screen — a decode is never faked.
- Recipient and content declared by the wearer (the agent cannot read the label — no OCR, no carrier database): WHO cycles 我 / 配偶 / 孩子 / 父母 / 全家， KIND cycles 日用品 / 食品生鲜 / 文件 / 衣物 / 电子产品 / 其他， URG flips 急 / 常； landing KIND on fresh food auto-flags urgency (still manually reversible).
- SORT commits {record ID, recipient, kind, urgent, date, time} to on-device wx storage (key parcelSort, cap 30, oldest dropped) and immediately speaks the pile instruction — urgent to the left pile, opened first; normal to the right; the recipient is kept for the next parcel while code/kind/urgency reset. A piles summary (urgent / normal / total plus per-recipient counts) stays on screen; LIST mode regroups the batch urgent-first and SPEAK reads the whole summary aloud; CLEAR empties the batch (sorting is per delivery batch); DEMO seeds three parcels from a single clock snapshot and lands on the LIST summary.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
