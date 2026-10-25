# market-radar — 菜场雷达（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-market-radar
```


50 个「指向性生活问题」Agent 的第 DI21 个。菜市场里几十个摊位
绕成迷宫：你一路走一路问价，转头就忘了哪家报的什么价；等
想起东头那家西红柿便宜，想回去找，又不记得它在哪儿了。
手机备忘录能记价格，记不了方向。本 Agent 把摊位「钉」在
你的头部朝向上：站在摊位前看着它，说出价格登记下来；之后
在市场里慢慢转头，正对某个已登记摊位时它就带着当时的报价
亮出来——转一圈，最便宜的那家自己跳出来。

## 预览截图

截图统一存放于仓库根目录 `screenshots/market-radar/`。

![REG 模式：DEMO 登记 3 个摊位后的列表（蔬菜 60° / 水果 180° / 海鲜 300°）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/market-radar/preview-market-radar-index.png)

![RADAR 模式：朝向 45°，正对蔬菜摊（FACING 高亮，西红柿3块一斤）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/market-radar/preview-market-radar-radar.png)

## 解决的问题

菜市场比价的难点不是记性，是「价」和「位」分家：价格记在
脑子里（或手机里），位置全靠感觉，回头找人海茫茫。本 Agent
利用眼镜独有的能力：你看向哪里，你的头部朝向就是一个可
记录的方向——问价的那一刻顺手登记，「哪家、卖什么、多少钱、
在哪个方向」一次存全。找回去时不用问路，转头扫一圈，
FACING 亮起来的就是它。

## 指向性设计（为什么必须用眼镜）

- **问价即登记 = 把摊位绑在头部朝向（核心）**：登记那一刻，
  `AbsoluteOrientationSensor` 四元数 yaw 读到的头部朝向，
  就是「从我站的地方看向这个摊位」的方向。和品类
  （蔬菜 / 水果 / 肉类 / 海鲜 / 干货调料）、价格备注、时间
  一起存进一条记录（wx 同步存储 `marketStalls`，最多 8 条）。
  手机放口袋里记不了「我看向哪」。
- **找回 = 相对当前朝向的正对检测**：RADAR 对每条记录算
  相对角 = 摊位朝向 − 当前头部朝向（归一化 −180°…180°），
  取 |相对角| 最小者；|相对角| ≤ 60°（正前方锥形范围）时
  大字高亮「FACING: 水果 · 苹果5块一斤 · 10:02」，外加登记
  详情「reg 180° · rel +15° · RIGHT-FRONT」与 8 向箭头。
  慢慢转头扫一圈，哪家亮起来就是正对着它了。
- **比价 = 同品类留两条 + 列表朗读**：同一个品类可以登记
  两次，两家的报价都在列表里逐行显示（品类 · 备注 · 朝向 ·
  时间）；LIST 模式点 SPEAK 逐条朗读所有备注，先听完再
  决定回哪家。
- **备注靠嘴、核对靠眼（诚实设计）**：NOTE 用一次性
  SpeechRecognition（zh-CN）记价格——动手前先按文档方式做
  佩戴者模式（`microphoneMode:'wearer'`）麦克风可用性检查：
  那条检查流只读回设置、验证模式可用，随即停掉；识别由
  宿主 SpeechRecognition 用它自己的麦克风完成，检查用的
  佩戴者模式不会给识别降噪。识别结果**原样**显示在
  NOTE 行：价格数字正是 ASR 最容易听错的东西，所以必须
  你亲眼核对后才按 REG 存入，眼镜不偷偷「纠正」。
  主机没有识别能力时 NOTE 如实显示 SKIP，改走三个预置
  标签（便宜 / 一般 / 贵），不假装在听。

## 功能流程

1. 走到摊位前站定，脸对着摊位：CAT 选品类，点 NOTE 说
   「西红柿三块一斤」，看一眼 NOTE 行核对无误，点 REG
   （或头部稳定时点头、按 Enter）→ 登记成功，自动切到
   RADAR
2. 继续逛：每个问过价的摊位都这样登记一家；同一品类问了
   两家就登记两次，两条都留着比价
3. 想找回某家：回到当初登记的那片区域（朝向只对登记时
   站的位置成立），在 RADAR 里慢慢转头，正对时 FACING
   带着价格亮起来；点 SPEAK 听它朗读正对摊位的备注
4. 收摊前点 LIST 看全部摊位逐行比价，或 SPEAK 逐条朗读
   所有备注；CLEAR 清空全部登记（下次来市场价格全变了，
   重新登记）
5. DEMO 仿真：点 DEMO 在 60° / 180° / 300° 登记 3 个标注
   DEMO 的摊位（蔬菜 西红柿3块一斤 / 水果 苹果5块一斤 /
   海鲜 虾25块一斤）并切到 RADAR；之后每点一次 DEMO 当前
   朝向 +45°，朝向 45° 时 60° 的蔬菜摊相对角 +15°，进入
   FACING 高亮态

## 权限

| 权限 | 用途 |
|---|---|
| RECORD_AUDIO | NOTE 一次性语音记价格：先做佩戴者模式（wearer）麦克风可用性检查（检查流读回设置后立即停掉），识别由宿主 SpeechRecognition 以其自有麦克风完成；只保存你确认过的备注文本，不录音、不保存音频 |

朝向传感器不需要额外权限声明；本 Agent 不用相机、不用定位。

## 打包与预览

```bash
cd ~/workspace/rokid/market-radar
~/tools/bin/aix pack . -o ../dist/market-radar.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-market.js`；SEQ_A = DEMO 一次登记 3 个摊位后点 MODE 两次
（RADAR → LIST → REG）回到 REG 态看列表，SEQ_B = 点 MODE 回到
RADAR 后再点 DEMO 把朝向步进到 45° 进入 FACING 态；按钮 canvas
坐标经视觉定位确认：DEMO (390,280)、MODE (90,251)）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-market-radar`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 market-radar」，去菜市场逐摊位登记：
   重点核对 ① NOTE 在市场噪声里听价格数字的准确率（登记前
   核对环节是否够用）② 回到登记区域转头时 FACING 亮起的
   角度是否对得上真实摊位 ③ 同一品类两家登记后 LIST 比价
   与 SPEAK 逐条朗读是否顺手

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.1（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 18.6 KB（本地打包 `dist/market-radar.aix`，含本 README；打包时间戳使字节数有 ±0.01 KB 抖动） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 最近摊位数学：用 Node 对同一套相对角公式独立核算 10 个用例——
  演示摊位 60° / 180° / 300° 在朝向 45° 时最近为 60° 蔬菜摊
  （相对角 +15°，FACING 亮起，与预览渲染一致）；朝向 0° 时
  相对角 +60° 恰在锥形边界内；朝向 350° 时最近为 300° 海鲜摊
  （相对角 −50°，跨 0° 缠绕正确）；单摊位正后方（相对角 180°）
  正确判为不在 FACING 范围。相对角符号沿用兄弟 Agent 的约定
  （相对角 = 摊位朝向 − 当前朝向，正值 = 在你右边），故 DEMO
  朝向 45° 时 60° 摊位显示 +15°。
- 打包：`aix pack` 成功（大小见上表）；`aix list` 核对包内含
  AGENTS.md、app.js、app.json、package.json、README.md、
  pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：REG 态完整渲染（DEMO 登记 3 个摊位，
  列表显示品类/备注/朝向/时间，计数 3/8）；RADAR 态朝向 45°
  时显示箭头 ↑ 与高亮「FACING: 蔬菜 · 西红柿3块一斤」及登记
  详情行「reg 60° · rel +15° · FRONT · DEMO」。预览主机无
  可用方向传感器，初始态如实显示 `SRC: NONE`，传感器错误
  事件被处理（不崩溃）；预览主机无 SpeechRecognition，
  NOTE 的 SKIP 预置标签路径已在代码中实现并通过静态检查。

**未验证**

- 真机 AbsoluteOrientationSensor 朝向精度/零点、头部稳定与
  点头触发——预览主机都没有，未测。菜市场多为钢结构棚顶，
  磁环境可能让朝向漂移，实际可用程度以真机为准。
- 真机上「逐摊登记 → 回到登记区域转头找回」的全流程，
  以及登记位置偏移几米后朝向几何的实际误差——未实测；
  本 Agent 的定位是同一片区域内的找回辅助，不能替代
  市场平面图。
- NOTE 在真实市场噪声（吆喝、喇叭、剁肉声）里对价格数字
  的识别准确率——这是本 Agent 真机测试的第一号未知数；
  「登记前亲眼核对 NOTE 行」就是为此设计的兜底。
- 佩戴者模式（wearer）麦克风检查在真机上是否被接受、
  TTS 中文播报在真机上的效果。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Market Radar pins market stalls to the direction you are facing. At a stall, pick a category, say the price out loud — 'tomatoes, 3 yuan a jin' — check the note on screen, then tap REG: the stall is stored with your head heading and the time. Later, turn your head slowly in RADAR mode: when you face a registered stall again it lights up with its price note, and SPEAK reads it aloud. Register the same item at two stalls and compare quotes before you buy.

### Opening Message

Hi, I'm **Market Radar** — I remember which stall quoted what, and where it was.

Face a stall, pick its **CAT**, tap **NOTE** and say the item and price — then *check the note*: numbers are easy to mishear, so I show exactly what I heard. Tap **REG** to pin that stall to the direction you are facing. Later, turn slowly in **RADAR** mode: a saved stall in front of you lights up **FACING** with its price, and **SPEAK** reads it. Two stalls, same tomatoes? Keep both — comparing is the point.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-market-radar-index.png`（aix preview REG 态：DEMO 登记 3 个摊位（60° / 180° / 300°），列表与计数 3/8 完整渲染，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-market-radar-radar.png`（RADAR 态：朝向步进到 45°，箭头 ↑ 与高亮「FACING: 蔬菜 · 西红柿3块一斤 · 01:16」，登记详情行「reg 60° · rel +15° · FRONT · DEMO」，本地文件）
- Video：待真机补 — 真机录制「摊位前 CAT + NOTE 说价 + REG 登记 → 回到登记区域转头 FACING 亮起 + SPEAK 朗读」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.1

**Features added**

- None.

**Improvements**

- None.

**Fixes**

- NOTE microphone copy corrected (capability-boundary audit 2026-10-24): the wearer-mode getUserMedia step is an availability check only — its stream reads back settings and stops at once; price notes are then dictated by the host SpeechRecognition on its own microphone. Earlier copy wrongly implied the wearer mode suppressed market noise during recognition; the NOTE listening status now reads "NOTE listening (host ASR)" and the check result is shown separately as "MIC CHECK: wearer OK".

#### Build 1.0.0

**Features added**

- Stall registration bound to head heading: face a stall, cycle a category (vegetables / fruit / meat / seafood / dry goods), speak a price note and REG it — category, note, orientation-sensor heading and time are stored together on-device in wx storage (key marketStalls, up to 8 stalls; the heading source is honestly labeled SENSOR / DEMO / NONE and REG refuses when no heading exists instead of inventing one). The same category can be registered twice on purpose, so two quotes for the same item can be compared.
- Spoken price notes with a verify-before-save step: NOTE runs a one-shot zh-CN SpeechRecognition after a documented wearer-mode microphone check, and the heard text is shown verbatim on screen for the wearer to eyeball — prices and numbers are what ASR gets wrong most — before REG saves it; on hosts without recognition, NOTE honestly reports SKIP and cycles three preset tags (cheap / fair / pricey) instead.
- RADAR re-finding and comparison: in RADAR mode the angularly nearest registered stall within ±60 degrees of the current head heading lights up big as FACING with its price note, registration details and an 8-way arrow, and SPEAK reads the faced stall (or, in LIST mode, every note in order); DEMO registers three labeled stalls at 60 / 180 / 300 degrees, enters RADAR, and steps the simulated heading +45 degrees per tap so the FACING state can be previewed end to end.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
