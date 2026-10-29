# queue-sense — 排队估算（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-queue-sense
```

**AIX 直接下载**（最新版）：[queue-sense.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/queue-sense.aix)


50 个「指向性生活问题」Agent 的第 DI45 个。排队最熬人的不是等，
是**不知道还要等多久、不知道隔壁队是不是更快**。原计划是「看向
队伍拍照估算人数」——这里先把诚实改法写在最前面：**本机没有可靠
的从照片数人的路径，本 Agent 不从照片数人**。人数用你自己的眼睛
数、手指点（看着队伍，前面一个人点一次）；眼镜负责它真正能干的
事——**实测这支队伍的服务速度**，再把两个数乘起来给你一个有出
处的粗估，并同时盯住最多三支队伍，告诉你哪支最快。

## 预览截图

截图统一存放于仓库根目录 `screenshots/queue-sense/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/queue-sense/preview-queue-sense-index.png)

![DEMO 播入两支已测队伍（A 12 人约 9 分钟、B 8 人约 4 分钟，BEST 裁决行已出）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/queue-sense/preview-queue-sense-demo.png)

![切到 C 队手工数人并标记一次已服务（只有计数、还没有速度的如实状态）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/queue-sense/preview-queue-sense-counting.png)

## 解决的问题

排队时你其实能拿到两个一手数字，只是没人帮你记：前面有几个人
（看一眼就能数），队首多久走一个人（看一会儿就能测）。手机记
这个要掏出来、解锁、低头点——队伍挪一步你就得再掏一次。眼镜
的用法是反的：眼睛一直看着队伍，手指在镜腿上点，数和测都在
视线里完成；该不该换队，听它一次朗读对比就知道。

## 指向性设计（为什么必须用眼镜）

- **看向即计数（GAZE）**：你的视线沿着队伍扫过去，COUNT+ 一
  下一个人——计数动作和「看」是同一个动作，不需要把视线从队
  伍上移开去对着手机点。照片（wide 模式）只是这支队伍的样子
  的会话记录，**从不用于数人**（见下方诚实说明）。
- **盯住队首测速（HEAD/WATCH）**：你站在原地看着队首，队首每
  服务完一个人，头稳住点一下头（或点 SERVED），眼镜就记下一
  个时刻；速度 = 标记间隔的平均，是这支队伍此时此地的真实速
  度，不是任何时刻表的推测。
- **多队一眼对比（SCAN）**：三支队伍 A/B/C 各自数、各自测，
  SPEAK 一次朗读全部并给出裁决——换不换队在听到裁决的那一
  秒决定，不用三支队伍来回跑着看。
- **手势优先（档案 §3.2.1）**：全部主流程只用触控板手势 +
  头稳 + 点头就能走完（见下方「手势映射」）；屏幕按钮都是与
  手势等效的镜像入口。

> 诚实说明（原计划的改法）：计划行写的是「看向队伍/站牌拍照
> 估算人数」。运行时没有可靠的人数识别路径（档案 §4.3 无 OCR，
> 更无人数计数 API），硬做只会得到编造的数字。本 Agent 改为
> 佩戴者点按计数 + 实测服务速度：人数是你亲眼数的，速度是眼
> 镜实测的，估算是这两个真数的乘积。计划行里的「结合时刻信
> 息给建议」落在 DICT 备注上：你把站牌上的班次口述进来，它作
> 为**你的话**单独显示，永不混进实测估算。

## 手势映射

本 Agent 的全部主流程（数人 → 标已服务 → 切换队伍 → 听对比）
都可以只用眼镜腿触控板手势 + 头部动作完成，不必点屏幕按钮。
手势与键码的对应来自官方文档档案 §3.2.1。

| 手势 | 键码 | 在本 Agent 中的动作 |
|---|---|---|
| 单击触控板 | Enter | COUNT+：给当前队伍的人数 +1（数人是排队时的主动作，所以占单击） |
| 滑动触控板 | ArrowUp / ArrowDown | 轮换当前队伍 A → B → C（两个方向都可） |
| 双击触控板 | Backspace | 返回 / 关闭（由宿主处理，本 Agent 只记录事件） |
| 长按触控板 | —（系统级） | 唤醒 AI 助手（系统功能，不经过本 Agent） |
| 头部稳定时点头 | onHeadGesture `nod` | 给当前队伍标一次 SERVED（你正看着队首，这是最自然的时刻记录法）；点头从不数人 |
| 屏幕按钮 | — | 保留 9 个，逐个有理由：COUNT+ / SERVED（与单击/点头等效的主动作镜像）、UNDO（数错一位的修正，手势没有「减一」的干净对应）、QUEUE（与滑动等效）、JOINED（「我往前挪了一位」：人数 −1 并重设位置基准，是独立语义而非服务样本）、PHOTO（拍一张当前队伍的 wide 照片作会话记录）、DICT（口述备注）、SPEAK（朗读三队对比与裁决）、DEMO（播入两支已测队伍预览裁决） |

## 功能流程

1. 站进一支队伍，看着队伍从队首往回数：前面一个人，点一次
   COUNT+（或单击触控板）；数错了 UNDO 退一位
2. 站着看队首：每服务完一个人，点 SERVED（或头稳住点一下
   头）——第 2 次标记起，界面出现实测速度（如「~43 s/person ·
   from 3 served (2 intervals)」）和粗估等待（「~9 min
   (rough)」）
3. 队伍往前挪、你跟上时点 JOINED：人数 −1，估算立刻按新的
   人数重算（JOINED 只动人数与位置基准，不冒充服务样本）
4. 旁边还有队伍？滑动触控板切到 B（再滑到 C），同样数人、
   标已服务；三支队伍在总览行里并排显示
5. 站牌/窗口贴着班次信息时点 DICT，把它口述进来（如「每 10
   分钟一班」）——它显示在 YOUR NOTE 区，是你的话，不进估算
6. 拿不准换不换队时点 SPEAK：它朗读三队的人数与约等时间，
   给出「X 队最快」；没测到速度的队伍会被点名「数据不足」而
   不是被猜一个名次
7. 想留个样子点 PHOTO：wide 照片只作本次会话记录（只留字节
   数与时间），关掉页面就没了，更不会被拿去数人
8. DEMO 按钮：播入 A（12 人、实测 42.5 秒/人、约 9 分钟）与
   B（8 人、实测 30 秒/人、约 4 分钟）两支队伍，SPEAK 立刻
   能预览裁决；再点一次退出，恢复你真实的三支队伍

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | PHOTO 时拍 wide 模式照片作会话记录（只留字节数与时间，从不用于数人、从不保存） |
| RECORD_AUDIO | DICT 前的佩戴者模式麦克风可用性检查，以及把你口述的班次备注用宿主识别记下来 |

只申请这两个权限：没有定位；朗读走宿主 TTS，朝向稳定性与点头
手势在 AIUI 里不需要单独的权限声明。相机/麦克风只在用户点
PHOTO / DICT 时开启，用完立即停轨。本 Agent 不写任何本地存储，
也没有网络行为。

## 打包与预览

```bash
cd ~/workspace/rokid/queue-sense
~/tools/bin/aix pack . -o ../dist/queue-sense.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-queue.js`，独立页面副本 `preview-queue.html`；按钮点击
坐标在 shot 脚本运行日志中按 canvas 坐标记录）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-queue-sense`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 queue-sense」，找一支真实的队站进去：
   看着队伍单击数完前面的人；盯着队首，每服务完一个点一次头
   标记 SERVED，核对第二次标记后出现的速度与估算是否与你的
   体感接近；旁边有第二支队时滑动切过去数一遍，点 SPEAK 听
   裁决是否合理；对着站牌口述一次班次备注，核对备注逐字无误
   且估算数字在口述前后没有变化；点 PHOTO 确认照片行如实写
   明只作会话记录

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 20.8 KB（本地打包 `dist/queue-sense.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后语法解析通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 状态机测试：Node 里以 wx/ASR/相机/TTS 存根 + 可控 tick 时钟
  加载页面对象跑 **62 条断言全过**——覆盖：计数与 UNDO 的 0
  下限、Enter=COUNT+ 与滑动切队的手势接线、三队计数互不干扰、
  SERVED 时刻取 tick 累计值（不取墙钟）、单次标记无速度、两
  次标记速度 = 间隔、三次标记速度 = 间隔均值、同一拍两次标记
  无速度、估算 = 人数 × 速度与「~X min (rough)」显示、JOINED
  只减人数并重设基准（不产生服务样本、估算随新人数重算、0
  下限）、对比裁决（明确胜者、分钟相同则人少者胜、有人数无
  速度者被点名数据不足、无任何队伍时的如实朗读）、口述备注
  逐字入账且口述前后估算逐秒不变、MIC CHECK 独立成行且检查
  流在宿主 ASR 启动前已停轨、无识别主机时 DICT 如实 SKIP 不
  编造、wide 照片只留字节数（不动人数、不动速度、拍后停
  轨）、点头纪律（头动时忽略、头稳才记 SERVED、点头从不数
  人、非点头手势忽略）、纯手势全流程走通、DEMO 种子速度
  （42.5 / 30 秒每人）与退出后真实会话完整恢复、TTS 从不设
  置 lang、全流程存储零写入零读取。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图三张（见
  Preview Media）：首页初始态完整渲染；DEMO 态两支已测队伍
  与 BEST 裁决行正确；切到 C 队手工计数态显示「还没有速度」
  的如实文案。

**未验证**

- **真机头部稳定检测与点头手势在本 Agent 的实际触发情况**：
  排队时人会不自觉晃动，头稳判定太严会让点头记 SERVED 记不
  上、太松会误记——阈值要按真机体感再调；记不上时 SERVED 按
  钮是等效入口。
- 真机宿主 SpeechRecognition 对班次口述（数字 + 单位，如「每
  10 分钟一班」）的识别准确率：备注是逐字入账的，识别错了备
  注就是错的——汇总显示正是让你核对的一环；识别这件事本身
  走宿主麦克风，佩戴者模式检查流不改变它（审计口径）。
- 真机 wide 照片的实际字节量与取景范围（与佩戴者所见是否同
  框未经验证）；照片在本 Agent 里只是记录，这个未验证项不影
  响计数与估算的可信度。
- 速度样本在真实队伍中的稳定性（队首换人、临时开新窗口会让
  前几个样本失真）：估算已标注 rough 并显示样本数，但「样本
  多少才够信」要靠真机排队实测的体感定标。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Stuck in a queue and wondering whether to switch lines? Queue Sense measures the queue in front of you instead of guessing. Look along the line and tap once per person ahead; tap again each time someone at the front is served, and it learns the real seconds-per-person rate and shows a rough wait. Track up to three queues, hear which is fastest, and dictate the posted headway as your own note - kept strictly separate from the measured numbers.

（446 字符）

### Opening Message

Hi, I'm **Queue Sense** — I time the queue so you don't have to guess.

Look along the queue and tap **COUNT+** (or single-tap the touchpad) once for each person ahead of you. Each time someone at the front finishes, tap **SERVED** or nod with your head held steady — I learn the real service rate and show a rough wait. **Swipe** switches between queues A, B and C, and **SPEAK** tells you which one is fastest. A note you dictate stays your words only — it never changes the measured estimate.

（495 字符）

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-queue-sense-index.png`（aix preview 首页：QUEUE SENSE 初始态，含实测区/你的记录区两框与 COUNT+/UNDO/SERVED/QUEUE/JOINED/PHOTO/DICT/SPEAK/DEMO 九个按钮，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-queue-sense-demo.png`（DEMO 态：A 12 人实测 42.5 秒/人约 9 分钟、B 8 人实测 30 秒/人约 4 分钟，总览行与 BEST: B 裁决行完整显示，本地文件）
- Image 3：`artifacts/preview-queue-sense-counting.png`（切到 C 队手工计数态：数了 5 人、标记 1 次已服务，速度行如实显示「1 served marked - one more gives a rate」，本地文件）
- Video：待真机补 — 真机录制「站进队伍看着队伍单击数人 → 盯队首点头标记已服务 → 滑动切到隔壁队再数 → SPEAK 朗读对比裁决」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 3 张图；还需至少 1 个视频，总数保持在 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Wearer-counted queue sizes: look along a queue and tap COUNT+ (or single-tap the temple touchpad) once per person ahead of you, with UNDO for a miscount and JOINED for "I moved up one" - JOINED re-bases your position and updates the estimate without pretending to be a service sample.
- Measured service rate: tap SERVED (or nod with your head steady while watching the front) each time someone at the front finishes; from the second mark the agent computes the real seconds-per-person rate from tick-counted intervals (immune to preview-host clock drift) and shows the estimate as people x rate, always next to its sample count. One mark honestly says counting-only; two marks in the same second honestly say keep watching.
- Three queues compared: queues A, B and C are counted and measured independently; SPEAK reads every queue's headcount and rough wait and names the fastest - rounded-minute ties go to fewer people, and a queue with people but no measured rate is called out as not enough data instead of being ranked on a guess.
- Your note, walled off: dictate the posted headway (after a wearer-mode mic availability check, via host speech recognition) and it is stored verbatim under YOUR NOTE, visibly separate from the measured numbers; it is never parsed and never changes the estimate (test-asserted).
- Photo as record only: an optional wide-mode photo of the current queue is kept as a session record (byte count and time only; the image itself is dropped and never saved). It is never used to count people - counting is the wearer's eyes and taps, stated on screen, in the photo line, and in this copy.
- Gesture-first operation (temple touchpad, dossier section 3.2.1): single tap = COUNT+, swipe = switch the active queue, double-tap = host back, steady-head nod = mark SERVED (a nod never counts a person). Nine on-screen buttons mirror the gestures or cover actions gestures deliberately do not perform; each is justified in the README gesture map.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
