# elder-day — 老人全天（Rokid 眼镜 AIUI Agent）

50 个「指向性生活问题」Agent 的第 50 个。独居老人一天的难处不是
哪一件大事，是**一串小事全靠记性**：早晨的药吃没吃、上午水喝
没喝、傍晚门窗关没关——漏一件，家人不放心，老人自己也不踏实。
本 Agent 把一天拆成固定的六件事，绑在家中实物的方向上：做完
一件，看着那件实物停满 2 秒就确认；到了点还没确认，它用家人
预设的原话轻轻播报一次。

## 预览截图

截图统一存放于仓库根目录 `screenshots/elder-day/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/elder-day/preview-elder-day-index.png)

![DEMO 演示日 16:10：3/6 已确认，下午吃药到期播报一次](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/elder-day/preview-elder-day-demo.png)

![DEMO 中把剩余三件逐项确认完：DAY DONE 全天完成态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/elder-day/preview-elder-day-done.png)

## 解决的问题

提醒类工具对独居老人有两道坎：一是提醒响的时候人不在手机旁
边，二是提醒完了没人知道到底做没做。本 Agent 的清单不在手机
里、**在视线里**：六件事连同它们对应的实物（药瓶、水杯、餐桌、
大门）一起摆在眼前，确认动作就是「看向那件东西」本身——看
过了、说做完了，才记下。家人预先把时间和留言设好，老人一天
里要做的只有三件事：滑动选事项、看向实物确认、想听进度时点
一下朗读。

## 指向性设计（为什么必须用眼镜）

- **凝视即确认（GAZE/HEAD）**：每件事项绑在它对应实物的头部
  朝向上，「看向它 + 头稳住连续 2 秒」就是一次确认（±25° 锥
  形区、250ms 一拍累计计时）——快速转头扫一圈每个方向都
  「路过」却哪件都没确认，驻留规则让假确认拿不到 gaze 勾。
  确认的意义正是「你真的走到那件东西跟前、看着它」。
- **同物一个方向（GEO-H 的室内版）**：两件吃药看的是同一个
  药瓶、两件门窗看的是同一扇大门——登记朝向时，同物还没有
  自己朝向的事项自动继承，家人只登记四个方向就够。漏确认
  的事项按登记朝向给出 8 向箭头与「TURN: RIGHT 90°」把人领
  回去，永远不报东南西北。
- **提醒跟着未完成状态走（HEAD + 时间）**：不是到点无条件响，
  而是「时间到了 **且** 还没确认」才播报一次；提前确认过的
  事项到点一声不响。全天开着的眼镜才配谈「全天清单」——
  提醒只在页面打开时存在（见诚实说明），这条不含糊。
- **手势优先（档案 §3.2.1）**：日常主流程只用触控板手势 +
  头稳 + 点头就能走完（见下方「手势映射」）；登记朝向与改
  时间是家人一次性设置，按设计留在按钮上。

## 手势映射

本 Agent 的**日常**主流程（选事项 → 看向实物确认 → 听今日
状态）都可以只用眼镜腿触控板手势 + 头部动作完成。手势与键码
的对应来自官方文档档案 §3.2.1。

| 手势 | 键码 | 在本 Agent 中的动作 |
|---|---|---|
| 单击触控板 | Enter | 情景主操作：选中事项未确认 = 点按确认（记为 tap）；选中事项已确认 = 跳到下一件未确认；六件全确认完 = 朗读全天汇总 |
| 滑动触控板 | ArrowUp / ArrowDown | 在 6 件事项之间前后移动选中项 |
| 双击触控板 | Backspace | 返回 / 关闭（由宿主处理，本 Agent 只记录事件） |
| 长按触控板 | —（系统级） | 唤醒 AI 助手（系统功能，不经过本 Agent） |
| 头部稳定时点头 | onHeadGesture `nod` | 仅当你正对着选中事项的实物（登记朝向在 ±25° 内）且头稳时 = 确认它（记为 nod）；点头从不登记朝向、从不修改时间 |
| 屏幕按钮 | — | DONE（点按确认：给不想等 2 秒驻留的确认留一条如实入账的路，与单击等效）、MARK（登记朝向：家人一次性设置——坐在平常位置看着实物绑方向，没有它就没有凝视确认与转向指引）、TIME（调整预设时间：家人一次性设置，30 分钟一档步进，没有自由输入就不会输错）、LIST（跳到下一件未确认：滑动是逐个移，LIST 是直达）、SPEAK（朗读今日状态：确认了几件、哪几件到期未确认）、DEMO（无传感器时演示：播入 16:10 的演示日，点按步进朝向，转满一圈再点退出） |

## 功能流程

1. **家人一次性设置**：老人坐在平常的位置，家人（或老人自己）
   逐件选中事项、看着对应实物点 MARK 登记方向（药瓶 / 水杯 /
   餐桌 / 大门四个方向，同物自动共享）；时间不对的事项点 TIME
   按 30 分钟一档调好。计划存本机，下次打开自动恢复
2. **日常确认**：做完一件事，转头看向它的实物、头稳住停满
   2 秒（记 `gaze`）；或滑动选中后点 DONE / 单击（记 `tap`）；
   正对着实物点头也行（记 `nod`）——三种方式在清单里分得清
   清楚楚，重复确认会被拒绝
3. **到期播报**：页面开着时每 30 秒核对一次：某件的时间到了
   还没确认 → 标 DUE 并朗读家人预设留言**一次**（原文照念），
   之后只留视觉 DUE 状态、不再重复喊；想再听，点 SPEAK 听
   今日状态
4. **全天收尾**：六件全确认 → DAY DONE，朗读汇总一次；确认
   记录按日期存本机（最多 7 天），跨天自动开新的一天，昨天
   的记录原样保留，家人可以翻看老人哪天哪件是几点、怎么确
   认的

> 诚实说明：**确认 ≠ 核实**。本 Agent 记录的是老人「看向了
> 那件实物、并说做完了」，它没有能力判断药是否真的吃下去、
> 门是否真的锁好——家人请按这个口径理解记录。**它绝不给医
> 疗建议**：吃药事项逾期，它只说「还没确认」并念家人预设的
> 原话，没有任何剂量逻辑、不判断漏服、更不建议补服或加倍；
> 吃不吃、补不补，问医生或药师（同 #31 med-look 的克制）。
> **提醒只在本页打开时存在**：没有后台、没有推送——老人没
> 打开本 Agent 时，到期播报不会响，它不是全天候监护。事项
> 名称与播报留言是本版固定预设（家人能调的只有时间与朝
> 向）；设备时钟不对，到期判断就跟着不对。

## 权限

**本 Agent 不申请任何权限**——这是刻意的设计：

| 权限 | 本 Agent 的取舍 |
|---|---|
| CAMERA | 不申请：不拍照核对（确认靠凝视与本人声明，不靠图像判断） |
| RECORD_AUDIO | 不申请：没有口述入口（时间用 TIME 按键 30 分钟步进，留言为固定预设） |
| GEOLOCATION | 不申请：全天清单是室内事务，用不到定位 |

朝向传感器在 AIUI 里不需要单独的权限声明。一个要整天开着的
老人用 Agent，能少要的权限一件都不要。

## 打包与预览

```bash
cd ~/workspace/rokid/elder-day
~/tools/bin/aix pack . -o ../dist/elder-day.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-elder.js`，独立页面副本 `preview-elder.html`；按钮点击坐标在
shot 脚本运行日志中按 canvas 坐标记录）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-elder-day`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 elder-day」，在真实家里：坐在平常的位
   置逐件 MARK 四个实物方向，验证同物共享（下午吃药自动继承
   药瓶方向）；把一件吃药事项的 TIME 调到当前时间之后 30 分
   钟内，到点验证 DUE 只播报一次、关掉重开不再播报；逐件凝视
   确认，验证快速转头扫一圈骗不到勾；全确认后验证 DAY DONE
   只念一次；第二天打开验证新的一天是空清单、昨天的记录还在

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 24.7 KB（本地打包 `dist/elder-day.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；
  app.json **不含 permissions 键**（零权限，与设计一致）。
- 状态机测试：Node 里以 wx/传感器存根 + 可控假时钟加载页面对象跑
  **92 条断言全过**——覆盖：到期逻辑（时间未到不到期、整点到
  期、提前确认过的事项永不到期）、到期播报（家人预设留言**逐
  字**播报、只播一次、30 秒周期不重喊、播报标志落盘、重开不
  再播报）、MARK（无朝向拒绝、同物朝向共享继承、异物不串、
  计划落盘与恢复）、凝视覆盖规则（锥形区 + 头稳连续 2 秒按
  250ms 拍累计、1.75 秒不算数、快速扫视骗不到勾、头不稳不
  计时、离开锥形区清零）、点头纪律（头不稳/没对上/无登记都
  忽略、对上且头稳记为 nod、点头从不登记朝向）、TIME 编辑
  （+30 分钟步进、跨零点回绕、落盘与恢复、把到期事项步进到
  未来后 DUE 消除）、TURN 指引相对角与左右措辞、重复确认拒
  绝、日期跨天（页面开着跨零点自动开新日、昨天记录保留、记
  录最多 7 天且最旧被丢）、DAY DONE（汇总只念一次、完成后不
  重念）、纯手势全流程（Enter 逐件确认、滑动选事项、双击无
  副作用）、SPEAK 状态文案构成、DEMO（16:10 种子 3 件已确认
  gaze/tap/gaze、下午吃药到期只播一次且在事件行留痕、头部停
  在水杯方向、演示全程零落盘、转满一圈退出恢复真实记录）、
  **全部朗读文本扫描无剂量/建议类词**（补服/加倍/片/粒/剂量/
  饭前饭后/空腹/漏服等）、TTS 从不设置 lang。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图三张（见
  Preview Media）：首页初始态、DEMO 演示日到期态、全确认
  DAY DONE 态均完整渲染。

**未验证**

- **提醒的真实边界（第一优先向家人说明）**：到期播报只在本
  Agent 页面打开期间发生（30 秒核对一次）；关掉页面、眼镜
  息屏或宿主回收页面后是否还能准时核对，取决于宿主的页面
  生命周期，未经真机验证——家人不要依赖它做全天候监护。
- 真机头部稳定检测与 2 秒凝视驻留的手感（老人的头部自然抖
  动是否会让驻留难以攒满、±25° 锥形区在真实户型里是否合
  适）；登记朝向只对登记时坐的位置成立，换座位需重新 MARK。
- 家人预设留言的 TTS 播报效果（语速、音量对老人是否够清楚）
  与 DUE 视觉状态在单色绿小屏上的可读性，需真机请老人本人
  试戴确认。
- 触控板手势（单击/滑动/双击）与点头在本 Agent 键位映射下
  的真机触发情况；零权限声明在 Studio 导入与真机运行时是
  否被宿主接受（预期无碍，未实测）。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Elder Day is a calm all-day checklist for an elder living alone: six family-preset items - morning medicine, water, lunch, afternoon medicine, an evening walk, doors and windows - each tied to a time and to the direction of a household object. Look at the object steadily for two seconds to confirm it. An item past its time is announced once, in the family's own preset words, and only while the agent is open. It records what was looked at and confirmed; it never gives medical advice.

（487 字符）

### Opening Message

Hi, I'm **Elder Day** — six small things, one calm day.

Your family sets the times once. Each item points at something at home — the pill bottle, the water cup, the table, the door. When you have done one, just **look at its object steadily for two seconds**, or tap **DONE**. If a time passes and an item is still open, I will say the family's reminder line once. **Swipe** moves between items, and **SPEAK** tells you where the day stands.

（442 字符）

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-elder-day-index.png`（aix preview 首页：ELDER DAY 初始态，六件清单、常驻「提醒只在本页打开时播报」行、DONE/MARK/TIME/LIST/SPEAK/DEMO 按钮齐全，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-elder-day-demo.png`（DEMO 演示日 16:10：3/6 已确认（gaze/tap 如实标注）、下午吃药 DUE 并已播报一次（事件行留痕）、选中项停在到期事项上，本地文件）
- Image 3：`artifacts/preview-elder-day-done.png`（DEMO 中逐项确认剩余三件后的 DAY DONE 态：TODAY 6/6 DONE、汇总只念一次，本地文件）
- Video：待真机补 — 真机录制「家人 MARK 四个实物方向 → 把一件事项 TIME 调到近处时刻 → 到点 DUE 播报一次 → 逐件凝视确认 → DAY DONE 听汇总」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 3 张图；还需至少 1 个视频，总数保持在 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Six-item all-day gaze checklist for an elder living alone: morning medicine 08:00 (pill bottle), water 10:00 (cup), lunch 12:00 (table), afternoon medicine 15:00 (pill bottle), evening walk 17:00 (door), doors & windows 21:00 (door). Confirming an item means looking at its household object: bind each item once to the head heading of its object (MARK, a one-time family setup), then a steady 2-second look inside a ±25° cone confirms it as "gaze" (250 ms tick accumulation; leaving the cone or moving the head resets the count, so a fast sweep earns nothing). Tap ("tap") and steady-nod-while-facing ("nod") confirmations are recorded as their own methods, and items that share an object inherit one registered heading.
- Due announcements that follow unfinished state, not just the clock: while the page is open it checks every 30 seconds; an item whose preset time has arrived and is still unconfirmed is flagged DUE and announced exactly once per day, speaking the family's preset line for that item verbatim. The announcement is recorded in the day log, so reopening the page never re-shouts it; the item stays visually DUE until confirmed, and an item confirmed early never becomes due at all.
- Family-preset schedule with safe editing: item times step in 30-minute increments (TIME button) - there is no free-text time entry to mistype - and the plan (items, times, objects, preset lines, headings) persists as text on-device. Labels and spoken lines are fixed presets in this build, and that is stated in the UI and docs.
- Text-only day record: every confirmation is logged as {item, time, method} per date, newest first, kept for at most 7 days; a new date starts a fresh list automatically (even across midnight with the page open) and yesterday's record stays intact for the family to review.
- Medical restraint by design (same discipline as med-look): confirming records that the elder looked at the object and says it is done - the agent cannot verify a dose was swallowed, and it never gives dosage logic, missed-dose judgements, or make-up-dose advice. An overdue medicine item is announced only as "not confirmed yet", in the family's own preset words.
- Deliberately zero permissions: no camera (nothing is verified by image), no microphone (no dictation - times step by button), no location. The app.json declares no permissions at all, for an agent that may stay open all day.
- Gesture-first daily operation (temple touchpad, dossier §3.2.1): single tap = contextual primary action (confirm / next unconfirmed / speak the day once all confirmed), swipe = move selection, double-tap = host back, steady nod = confirm only while facing the selected item's object - a nod never edits the plan. MARK and TIME stay on buttons on purpose: they are one-time family setup, and the README gesture map says so.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
