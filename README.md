# clean-check — 清洁复查（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-clean-check
```

**AIX 直接下载**（最新版）：[clean-check.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/clean-check.aix)


50 个「指向性生活问题」Agent 的第 DI30 个。打扫最气人的不是累，
是漏：窗台、柜顶、墙角、桌下，每次漏的总是这几个边角，复查
还得弯腰低头逐个凑近看。本 Agent 把房间的六个易漏区域绑在
你的头部朝向上，打扫完慢慢环视一周——你的视线在哪个区域
稳稳停满 2 秒，哪个区域才算「看过」被打勾；没看向的角落，
它用相对方向把你领过去，一个都不漏。

> ⚠️ **诚实定位（先读）**：覆盖的含义是**「你的视线在那里
> 停留满 2 秒」**，不是「那里擦干净了」。眼镜无法判断洁净，
> 打扫是你的手做的事——正确用法是边看边擦，那 2 秒正好
> 用来动手。本 Agent 只解决「漏看」，不解决「没擦净」。

## 预览截图

截图统一存放于仓库根目录 `screenshots/clean-check/`。

![SWEEP 初始态：六个区域均无登记朝向，预览主机无传感器如实显示 SRC: NONE](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/clean-check/preview-clean-check-index.png)

![DEMO 环视中：1/6 已覆盖（窗边 ✓ gaze），头部停在 90° 正对门口、驻留 1.2s，指引指向下一个床边](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/clean-check/preview-clean-check-sweep.png)

## 解决的问题

打扫漏边角，漏的从来不是「中间的大面」，而是注意力没到过的
地方：柜顶看不见、桌下懒得蹲、墙角扫一眼就过。事后复查没有
凭据，全凭感觉，感觉恰恰就是漏扫的原因本身。手机清单记不了
你看过哪儿——眼镜可以：你的头部朝向就是覆盖记录的坐标系。
环视一周，驻留打勾，没看向的它点名，复查从此是走完的流程，
不是一种感觉。

## 指向性设计（为什么必须用眼镜）

- **区域 = 绑在头部朝向上的覆盖格（核心）**：SETUP 模式站在
  你平时打扫会站的位置，看着区域点 REG，`AbsoluteOrientationSensor`
  的 yaw 朝向就和这个区域绑在一起存下来（wx 同步存储
  `cleanCheckZones`）。六个区域（窗边 / 门口 / 床边 / 柜顶 /
  墙角 / 桌下）各带一句亲眼核对的线索。
- **凝视覆盖 = 朝向锥 + 头部稳定 + 2 秒驻留**：SWEEP 时朝向
  落在某区域登记朝向 ±25° 内且头部稳定，驻留计时开始；
  连续停满 2 秒才记 `✓ gaze`（带时间）。离开锥形区、换区、
  头部不稳，计时立即清零——快速摇一圈头拿不到一个 gaze 勾，
  这条规则就是为防「假看过」而设。
- **指引 = 相对当前朝向，永不报东南西北**：未在驻留时，指引
  给出角度上最近的未覆盖区域与 8 向箭头、「TURN: RIGHT-BACK
  130° — reg 270°」式提示（PLAN 里「柜顶在你右后方 130°」
  的场景）；驻留进行中，指引越过当前区域指向下一个最近的
  未覆盖区域，你永远知道看完这里去哪。
- **打勾方式如实入账**：驻留之外 MARK / Enter / 头部稳定
  点头可手动打勾（优先打你正对着的区域），记 `✓ tap`；
  点头永远只记 tap——2 秒驻留是拿到 gaze 勾的唯一途径，
  列表逐行可查，不做假账。
- **耳朵收尾**：6/6 大字 **SWEEP DONE — 每个角落都看过了**
  并自动 TTS 朗读收尾，朗读里同样说清「记录的是你看过」；
  SPEAK 随时朗读还差哪几处、最近的一处在哪个方向。
- **不编朝向（诚实边界）**：朝向来源如实标注
  `SENSOR / DEMO / NONE`；无传感器时 SETUP 登记直接拒绝
  （同 DI07 的规则）。朝向只对你登记时站的位置成立——复查
  时站回登记位置附近，锥形区才有意义。

## 功能流程

1. （可选，一次性）SETUP 登记：MODE 切到 SETUP，ZONE 选区域，
   站到打扫站位、看着它点 REG（或头部稳定时点头、Enter）→
   绑定朝向；六个区域逐个登记（重新登记会覆盖旧朝向）。
   没登记的区域也能复查，只是没有凝视覆盖与转向指引
2. 环视复查：SWEEP 模式站在登记站位附近慢慢转头——指引
   先把你领到最近的未覆盖区域，正对它、头部放稳，驻留
   条从 0 走到 2s，该区域自动记 ✓ gaze 并跳向下一个；
   实在不想驻留的区域，亲眼看好后 MARK 打勾（记 ✓ tap）
3. 全覆盖：6/6 后大字 SWEEP DONE + 自动朗读收尾；
   RESET 开新一轮（清覆盖、保留登记）
4. DEMO 仿真：点 DEMO 在内存里给 6 个区域绑上演示朝向
   30° / 90° / 150° / 210° / 270° / 330°（不写存储、不覆盖
   真实登记）。演示设定为环视已开始：窗边（30°）已用完整
   2 秒驻留覆盖（覆盖时间由一次 Date 快照生成），头部现在
   停在 90° 正对门口、保持稳定，门口驻留定格在 1.2s 供
   预览看清（真机上按真实时间推进），落在 1/6，指引指向
   床边（TURN: RIGHT-FRONT 60°）；之后每点一次 DEMO 朝向
   +45°，定格驻留换到新锥形区内的区域。DEMO 中点 CLEAR
   退出演示并恢复真实登记

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不声明任何权限：不用相机、不用麦克风、不用定位 |

app.json 无 `permissions` 字段（同 DI07 / DI15 / DI28）；头部朝向
传感器在 AIUI 里不需要单独的权限声明。

## 打包与预览

```bash
cd ~/workspace/rokid/clean-check
~/tools/bin/aix pack . -o ../dist/clean-check.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-clean.js`；Shot A = 初始 SWEEP 态无点击；Shot B = 点
DEMO 一次（canvas 坐标 125,305）落到 DEMO 环视 1/6 态）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-clean-check`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 clean-check」，先在 SETUP 里逐个登记
   六个区域的朝向，再故意快速转一圈头验证拿不到 gaze 勾，
   然后慢速环视逐区驻留到 6/6，听收尾播报

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 19.3 KB（本地打包 `dist/clean-check.aix`，含本 README） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；
  app.json 无 `permissions` 字段（零权限，与设计一致）。
- 驻留/覆盖状态机：用 Node 加载页面对象（wx 打桩）跑 68 条断言
  全过——驻留连续 2000ms 才覆盖（1999ms 不覆盖）、离开锥形区
  计时清零后从零重来、头部不稳计时清零、锥形区边界（相对角
  恰好 25° 在区内、26° 在区外）、每区 300ms 的快速摇头扫一圈
  覆盖数为零、朝向登记与重新登记覆盖、存储往返、MARK 记 tap
  且优先打正对着的区域、6/6 进入 SWEEP DONE、RESET 清覆盖
  且保留登记。
- DEMO 确定性：同一套断言验证 DEMO 落点——演示朝向
  30/90/150/210/270/330、窗边已由 gaze 预覆盖、进度 1/6、
  头部停在 90°、门口驻留定格 1.2s、指引文案恰为
  「NEXT: 床边 — TURN: RIGHT-FRONT 60°」、再点 DEMO 步进到
  135° 时驻留换到床边；且演示朝向从不写入 wx 存储（落盘被
  DEMO 守卫拦住），CLEAR 退出演示后恢复真实登记。
- 打包：`aix pack` 成功（大小见上表）；`aix list` 核对包内含
  AGENTS.md、app.js、app.json、package.json、README.md、
  pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：初始 SWEEP 态完整渲染（六区未登记、当前
  指引 NO HEADING；预览主机无可用方向传感器，初始态如实
  显示 `SRC: NONE`，传感器错误事件被处理、不崩溃）；DEMO 态
  渲染出 1/6 进度、窗边 `✓ gaze` 行、门口 `◎ dwell 1.2s`
  行与床边的 NEXT 指引，与 Node 断言的落点一致。

**未验证**

- 真机 AbsoluteOrientationSensor 朝向精度/零点、头部稳定
  判定与 5Hz 读数下驻留计时的实际手感——预览主机都没有，
  未测；尤其复查站位与登记站位不一致时锥形区的实际可用
  范围，要在真机上走一轮才知道。
- 真机上「SETUP 逐区登记 → 完整环视 6/6 → 收尾播报」的
  全流程，以及登记在眼镜重启后经 wx 存储恢复的情况——
  未实测。
- TTS 中文播报（剩余朗读与收尾播报）在真机上的效果。
- 本 Agent 不判断任何区域的真实洁净程度，这是设计定位
  而非缺陷：擦没擦净永远由佩戴者的眼睛和手确认。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Clean Check is a gaze-coverage re-check for the corners cleaning always misses: window side, doorway, bedside, cabinet top, wall corner, under the desk. Bind each zone to a head heading once in SETUP. Then sweep the room slowly: a zone is ticked off only after your gaze dwells on it, head steady, for a full 2 seconds. Missed zones get turn-by-turn guidance until all six are covered. It honestly tracks where you looked - it never claims the spot is actually clean.

### Opening Message

Hi, I'm **Clean Check** — let's make sure no corner got skipped.

Bind the **six zones** to head headings once in **SETUP**. Then just **turn slowly**: when your gaze rests on a zone for **2 steady seconds**, it is ticked as **covered**. Missed a corner? My **arrow** points you to the nearest one still missing. Tap **MARK** only for spots you cleaned without dwelling — I record those honestly as *by tap*. **Covered means looked at** — your hands still do the cleaning.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-clean-check-index.png`（aix preview 初始 SWEEP 态：六区未登记、指引 NO HEADING、SRC: NONE，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-clean-check-sweep.png`（DEMO 环视态：进度 1/6，窗边 ✓ gaze，门口 ◎ dwell 1.2s，指引 NEXT: 床边 TURN: RIGHT-FRONT 60°，本地文件）
- Video：待真机补 — 真机录制「SETUP 逐区登记朝向 → 快速摇头验证无覆盖 → 慢速环视驻留到 6/6」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Six-zone gaze-coverage cleaning check (window side, doorway, bedside, cabinet top, wall corner, under the desk), each zone with a concrete look-and-wipe cue; SWEEP mode tracks coverage live with progress x/6 and speaks what is still missed via SPEAK.
- Heading binding per zone (SETUP mode): stand at your cleaning spot, look at the zone and REG — the head heading (orientation-sensor yaw, source honestly labeled SENSOR / DEMO / NONE; REG refuses when no heading exists instead of inventing one) is persisted on-device in wx storage (key cleanCheckZones); re-registering a zone replaces its heading.
- Real gaze coverage rule: a zone is covered "by gaze" only when the current heading stays within 25 degrees of its registered heading with the head steady for a continuous 2 seconds (leaving the cone or moving the head resets the timer, so a fast head sweep earns nothing); manual MARK ticks are recorded honestly as "by tap" per row, and a head nod can only ever produce a tap tick, never a gaze tick.
- Turn guidance to the angularly nearest missed zone with an 8-way arrow (relative directions only, never compass points), pointing past the zone being dwelled on to the next one; at 6/6 the page shows SWEEP DONE and auto-speaks the wrap-up in Chinese; RESET starts a new sweep keeping registrations, CLEAR removes them; DEMO binds six simulated headings in memory only (never overwriting real registrations), pre-covers the window side by a full gaze dwell from a single Date snapshot, and holds a 1.2s primed dwell on the doorway for preview.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
