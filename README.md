# exit-radar — 出口雷达（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-exit-radar
```


50 个「指向性生活问题」Agent 的第 DI10 个。入住陌生酒店、走进
陌生办公楼时，几乎没人会留意紧急出口在哪——真出事时在烟雾和
慌乱里现找就晚了。本 Agent 让你在到达时就把这件事做掉：慢慢
环视一周，每看到一个出口标志，看着它点一下 MARK，眼镜把
「这个出口的方向 = 你当时的头部朝向」存下来。之后点一下
GUIDE，它按角度差找出离你当前朝向最近的已登记出口，用大
箭头 + 中文朗读告诉你往哪边转。

> ⚠️ **安全定位（先读）**：本 Agent 是**备灾记忆辅助**，不是
> 逃生导航。登记的朝向是你登记时所站位置相对的方向——你换了
> 房间、下了楼层，几何关系就变了。**真实紧急情况下，必须服从
> 建筑自身的出口标志、疏散广播与报警，立刻撤离，不要低头
> 依赖本 Agent。** 平时演练、入住时核对出口位置，才是它的用途。

## 预览截图

截图统一存放于仓库根目录 `screenshots/exit-radar/`。

![MARK 模式：已登记 3 个演示出口（DEMO）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/exit-radar/preview-exit-radar-index.png)

![GUIDE 模式：朝向 45°，最近出口就在正前方（EXIT AHEAD 高亮）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/exit-radar/preview-exit-radar-guide.png)

## 解决的问题

出口信息是「平时无感、出事救命」的那类信息：酒店走廊拐两弯、
办公楼第一次去开会，没人会专门记出口在哪。手机地图帮不上忙
（室内没定位、也不知道出口）。本 Agent 利用眼镜独有的能力：
你看向哪里，你的头朝向就是一个可记录的方向——入住时花十秒
环视登记，出口方位就被「绑」在你的朝向记忆里。

## 指向性设计（为什么必须用眼镜）

- **到达环视 = 把出口标志绑在头部朝向（核心）**：登记那一刻，
  `AbsoluteOrientationSensor` 四元数 yaw 读到的头部朝向，
  就是「从我站的地方看向这个出口」的方向。和标签
  （安全出口 / 楼梯间 / 消防通道 / 大堂方向）、时间一起存进
  一条记录（wx 同步存储 `exitRadar`，最多 6 条）。手机放口袋
  里记不了「我看向哪」。
- **指引 = 相对当前朝向的最近出口**：GUIDE 对每条记录算
  相对角 = 出口朝向 − 当前头部朝向（归一化 −180°…180°），
  取 |相对角| 最小者。显示 8 向箭头与
  「NEAREST EXIT: LEFT-BACK 130° — 楼梯间」，外加登记详情行
  「NEAREST: 楼梯间 · reg 170° · 时间」；|相对角| ≤ 15° 高亮
  **EXIT AHEAD — look for the green sign**。永远不报东南西北，
  只报相对你的左/右/前/后。
- **耳朵收结果**：SPEAK 用中文朗读由实时计算值生成的句子：
  「最近的出口在你左后方 130 度，是楼梯间。转身找绿色标志。」
  或正前方时「最近的出口就在你正前方，是安全出口。往前走，
  找绿色标志。」紧急感之下不用盯屏幕读字。
- **不认标志、不编朝向（诚实边界）**：运行时没有 OCR、没有
  图像分类——出口是你亲眼看着标志登记的，PHOTO 只是用
  `ImageCapture.takePhoto({mode:'telephoto'})` 长焦拍一张标志
  照片当视觉记录（标注 record only）。朝向来源如实标注
  `SENSOR / DEMO / NONE`；无传感器时 MARK 直接拒绝，
  绝不编造一个角度（同 #07 的规则）。

## 功能流程

1. 到达新地方：LABEL 选标签，慢慢转头环视，每看到一个出口
   标志，看着它点 MARK（或头部稳定时点头、按 Enter）→ 登记
   「标签 · 朝向 · 时间」；顺手点 PHOTO 给标志拍一张长焦
   照片留记录
2. 想核对时：点 GUIDE（或 MODE 切过去），转头——箭头实时
   指向角度上最近的出口，正对时亮 EXIT AHEAD；点 SPEAK
   听中文播报
3. 换地方了：CLEAR 清空旧登记，到新地方重新环视登记
   （朝向只对登记时站的位置成立，见文首安全定位）
4. DEMO 仿真：点 DEMO 在 40° / 170° / 300° 登记 3 个标注
   DEMO 的出口（安全出口 / 楼梯间 / 消防通道）并切到 GUIDE；
   之后每点一次 DEMO 当前朝向 +45°，最近出口随之改变；
   朝向 45° 时 40° 的出口相对角 −5°，进入 EXIT AHEAD
   高亮态

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | PHOTO 长焦拍摄出口标志照片作视觉记录（仅用户点击时启动，不做任何识别） |

朝向传感器不需要额外权限声明；本 Agent 不用定位、不开麦克风。

## 打包与预览

```bash
cd ~/workspace/rokid/exit-radar
~/tools/bin/aix pack . -o ../dist/exit-radar.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-exit.js`；SEQ_A = DEMO 一次登记 3 个出口后点 MODE 回到
MARK 态，SEQ_B = 点 GUIDE 后再点 DEMO 把朝向步进到 45° 进入
EXIT AHEAD 态；按钮 canvas 坐标 DEMO (236,292)、MODE (76,259)、
GUIDE (160,322)）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-exit-radar`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 exit-radar」，入住酒店时环视一周逐个
   登记出口，再走回房间点 GUIDE 核对最近出口方向

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 15.91 KB（本地打包 `dist/exit-radar.aix`，含本 README） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 最近出口数学：用 Node 对同一套相对角公式独立核算——演示出口
  40° / 170° / 300° 在朝向 0° 时最近为 40° 出口（相对角 +40°，
  RIGHT-FRONT，箭头 ↗）；朝向 45° 时相对角 −5°，正确进入
  EXIT AHEAD；任务书示例（出口 170°、当前 300°）相对角 −130°，
  LEFT-BACK，与界面文案一致；跨 0° 缠绕（出口 350°、朝向 10°）
  相对角 −20°，正确。
- 打包：`aix pack` 成功（大小见上表）；`aix list` 核对包内含
  AGENTS.md、app.js、app.json、package.json、README.md、
  pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：MARK 态完整渲染（DEMO 登记 3 个出口，
  列表显示标签/朝向/时间，计数 3/6）；GUIDE 态朝向 45° 时
  显示箭头 ↑ 与高亮「EXIT AHEAD — look for the green sign」及
  最近出口详情行。预览主机无可用方向传感器，初始态如实显示
  `SRC: NONE`，传感器错误事件被处理（不崩溃）。开发中调整过
  一次布局：初版页脚 EVT 行被 352px 画布裁掉，已收紧
  padding/边距后完整显示。

**未验证**

- 真机 AbsoluteOrientationSensor 朝向精度/零点、头部稳定与
  点头触发——预览主机都没有，未测。
- 真机上「入住登记 → 走回房间 GUIDE 核对」的全流程，以及
  跨房间后朝向几何失效的实际程度——未实测；本 Agent 的定位
  是同一站位附近的核对与演练，不能替代建筑疏散图。
- PHOTO 长焦拍照在真机上的成像与字节数；**本 Agent 不做
  标志识别/OCR**，照片只是给用户眼睛看的视觉记录。
- TTS 中文播报在真机上的效果。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Exit Radar helps you learn a new place's exits before you ever need them. On arrival, turn around slowly: look at each exit sign, pick a label (emergency exit, stairwell, fire passage, lobby) and tap MARK — the exit is stored bound to your head heading. Later, tap GUIDE and it finds the angularly nearest registered exit relative to where your head faces now, with a big arrow and a spoken sentence. A preparedness and memory aid: in a real emergency, follow the building's signs and alarms.

### Opening Message

Hi, I'm **Exit Radar** — let's learn this place's exits while all is calm.

On arrival, turn around slowly. Look at an **exit sign**, pick a **LABEL** and tap **MARK**: I store that exit *in the direction you are facing*. Later, tap **GUIDE** and turn your head — my **arrow** points to the *nearest registered exit* relative to you, and **SPEAK** reads it aloud. Changed rooms? **CLEAR** and register again. In a real emergency, always follow the building's own signs and alarms first.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-exit-radar-index.png`（aix preview MARK 态：DEMO 登记 3 个出口（40° / 170° / 300°），列表与计数 3/6 完整渲染，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-exit-radar-guide.png`（GUIDE 态：朝向步进到 45°，箭头 ↑ 与高亮「EXIT AHEAD — look for the green sign」，最近出口详情行「NEAREST: 安全出口 · reg 40° · DEMO」，本地文件）
- Video：待真机补 — 真机录制「入住环视登记出口 → GUIDE 转头核对最近出口 + SPEAK 播报」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Arrival scan registration: look at an exit sign, cycle a label (emergency exit / stairwell / fire passage / lobby direction) and MARK it — the exit is stored bound to your current head heading (orientation-sensor yaw, source honestly labeled SENSOR / DEMO / NONE; MARK refuses when no heading exists instead of inventing one), persisted on-device in wx storage (key exitRadar, up to 6 exits).
- GUIDE nearest-exit guidance: for every registered exit the relative angle to your current head heading is computed and the angularly nearest one is shown with an 8-way arrow and a "NEAREST EXIT: LEFT-BACK 130° — stairwell" line plus registration details; within 15 degrees an EXIT AHEAD highlight tells you to look for the green sign; SPEAK reads the nearest-exit sentence in Chinese from live values.
- Telephoto sign photo record (PHOTO) via ImageCapture telephoto mode with wx camera fallback, clearly labeled record-only with no sign-recognition claim; DEMO registers three labeled exits at 40 / 170 / 300 degrees, enters GUIDE, and steps the simulated heading +45 degrees per tap so the nearest-exit choice — including the EXIT AHEAD state — can be previewed end to end.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
