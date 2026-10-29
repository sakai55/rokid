# hotel-checkin — 入住巡检（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-hotel-checkin
```

**AIX 直接下载**（最新版）：[hotel-checkin.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/hotel-checkin.aix)


50 个「指向性生活问题」Agent 的第 DI43 个。住进酒店最怕的不是贵，是
**没底**：床单换没换、淋浴有没有热水、门锁牢不牢——凭感觉扫一眼
就住下，半夜才发现问题。本 Agent 把入住检查拆成固定的八个检查点
摆在你眼前，逐个领你走到跟前、看清楚、记下来：看过的打勾，有问题
的当场口述留档；漏看的，它用相对方向把你领回去。

## 预览截图

截图统一存放于仓库根目录 `screenshots/hotel-checkin/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/hotel-checkin/preview-hotel-checkin-index.png)

![DEMO 演示房间：4 个朝向已登记、2 项已检、正在驻留床头插座](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/hotel-checkin/preview-hotel-checkin-demo.png)

![DEMO 中给床头插座登记一条预置问题（预览宿主识别报错，再点 ISSUE 改走预置词条）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/hotel-checkin/preview-hotel-checkin-issue.png)

![八项全检完成：汇总态（OK/ISSUE 计数 + 问题朗读）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/hotel-checkin/preview-hotel-checkin-done.png)

## 解决的问题

入住检查没条理，是因为检查点散在整个房间、又没有一份清单盯着你：
床品在床上、热水在浴室、遥控不知道在哪个抽屉。本 Agent 的清单是
**绑在方向上的**——每个检查点登记一次你看向它的头部朝向，之后你
站在房间里转头，视线在哪个检查点稳稳停满 2 秒，哪个就算「看过」
被打勾；还没看的，它告诉你「往右转 80°」。检查从「想起来什么看
什么」变成「清单领着眼睛走」。

## 指向性设计（为什么必须用眼镜）

- **凝视即检查（GAZE/HEAD）**：检查点绑头部朝向后，「看向它 +
  头稳住连续 2 秒」就是一次凝视打勾（±25° 锥形区、250ms 一拍
  累计计时）——快速转头扫一圈每个点都「路过」却哪个都没看清，
  驻留规则让这种假检查拿不到 gaze 勾。
- **漏检按方位领回（GEO-H 的室内版）**：未检项按登记朝向算相对
  角，指引框给 8 向箭头与「TURN: RIGHT 120°」；朗读进度时同样
  报「最近的未看项在你右手边 X 度」。永远不报东南西北。
- **口述留档（MIC4 的检查口径）**：发现问题点 ISSUE，先做佩戴者
  模式麦克风**可用性检查**（结果单独记在 MIC CHECK 行，检查流
  不是识别输入），再由宿主 ASR 把你说的问题**原样**记下；没有
  识别能力的主机、或识别报错未出结果时，如实改走预置词条
  （无热水/有异味/破损/缺件），并标注是预置，不是假装在听。
- **手势优先（档案 §3.2.1）**：全部主流程只用触控板手势 + 头稳
  + 点头就能走完（见下方「手势映射」）；屏幕按钮与手势一一
  等效，只作点按备用。

## 手势映射

本 Agent 的全部主流程（选检查点 → 登记朝向 → 凝视/点按打勾 →
听进度/汇总）都可以只用眼镜腿触控板手势 + 头部动作完成。手势
与键码的对应来自官方文档档案 §3.2.1。

| 手势 | 键码 | 在本 Agent 中的动作 |
|---|---|---|
| 单击触控板 | Enter | 情景主操作：已全检完 = 朗读汇总；选中项未登记朝向 = 登记朝向（MARK）；选中项未检且已登记 = 点按打勾（OK，记为 tap）；选中项已检 = 跳到下一个未检项 |
| 滑动触控板 | ArrowUp / ArrowDown | 在 8 个检查点之间前后移动选中项 |
| 双击触控板 | Backspace | 返回 / 关闭（由宿主处理，本 Agent 只记录事件） |
| 长按触控板 | —（系统级） | 唤醒 AI 助手（系统功能，不经过本 Agent） |
| 头部稳定时点头 | onHeadGesture `nod` | 仅当你正对着选中检查点（登记朝向在 ±25° 内）且头稳时 = 打勾确认（记为 nod）；点头从不登记朝向、从不登记问题 |
| 屏幕按钮 | — | MARK（登记朝向：没有朝向就没有转向指引，这是凝视打勾的前提）、OK（点按打勾：给不想等 2 秒驻留的人一条如实入账的路）、ISSUE（登记问题：要开口述/选词条，必须有明确入口，点头按纪律不得代办）、PHOTO（拍照留档：可选动作，绝不与打勾绑定）、LIST（跳到下一个未检项：滑动是逐个移，LIST 是直达漏检）、SPEAK（朗读进度/汇总）、DEMO（无传感器时演示：点按步进朝向，转满一圈再点退出）、NEW（新入住重置：两段确认，防误触清掉整份记录） |

## 功能流程

1. 进房先逐个登记：滑动选中检查点，看着它点 MARK（或单击触控
   板），把当时的头部朝向绑给它；八个点都登记完只需一次
2. 逐项检查：转头看向检查点，头稳住停满 2 秒即凝视打勾（记
   `gaze`）；不想等就点 OK（记 `tap`）；正对着它点头也行
   （记 `nod`）——三种打勾方式在清单里分得清清楚楚
3. 发现问题：点 ISSUE，麦克风检查后直接说出问题（如「淋浴水压
   很小」），原样入账（记 `ASR`）；没识别能力的主机点 ISSUE
   轮换预置词条（记 `chip`）；识别报错时按提示再点一次 ISSUE，
   同样改走预置词条留档
4. 想留个影：点 PHOTO 给当前检查点拍一张（default 模式）——
   照片只在本会话内存里，**不保存**（见诚实说明）
5. 漏检不用慌：LIST 直达下一个未检项，指引框按登记朝向给出
   「TURN: RIGHT 120°」把你领回去
6. 八项全检完：自动朗读汇总一次——几项没问题、几项有问题，
   有问题的把口述备注逐条念出来；之后点 SPEAK 可重听
7. 记录只存文字（检查点、朝向、状态、打勾方式、问题备注、
   时间）于本机 `hotelCheckin`；下次打开自动恢复上次记录；
   换一家酒店点 NEW（两段确认）开新单

> 诚实说明：本 Agent 记录的是**你逐项看过**，不是**检查点本身
> 没问题**——床单干不干净、热水够不够热，靠的是你的眼睛和手，
> 眼镜判断不了。**照片不落盘**：AIUI 的 wx 存储存不下照片
> Blob，本 Agent 的照片只活在本次会话内存里，关掉即没；需要
> 留证（比如向酒店投诉）请用手机拍。本 Agent 也不会替你向
> 酒店交涉，汇总朗读就是给你的交涉清单。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | PHOTO 给检查点拍一张 default 模式照片，仅存本次会话内存，永不落盘、永不上传 |
| RECORD_AUDIO | ISSUE 前的佩戴者模式麦克风可用性检查（开流读回设置即停轨）与问题口述的一次性宿主识别 |

朝向传感器在 AIUI 里不需要单独的权限声明。相机与麦克风只在
用户点 PHOTO / ISSUE 时启动，用完立即停掉全部媒体轨道。

## 打包与预览

```bash
cd ~/workspace/rokid/hotel-checkin
~/tools/bin/aix pack . -o ../dist/hotel-checkin.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-hotel.js`，独立页面副本 `preview-hotel.html`；按钮点击坐标在
shot 脚本运行日志中按 canvas 坐标记录）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-hotel-checkin`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 hotel-checkin」，在真实房间里：站在床边
   逐个 MARK 八个检查点，转头凝视每个点 2 秒验证 gaze 打勾；
   故意快速转头扫一圈验证骗不到勾；对浴室淋浴登记一个问题，
   听汇总是否逐字念回你的口述；拍一张照片，退出重进验证照片
   确实不在（记录文字在）；故意漏检一项，验证 TURN 指引的
   左右与实际方位一致

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 25.4 KB（本地打包 `dist/hotel-checkin.aix`) |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 状态机测试：Node 里以 wx/传感器/识别/相机存根加载页面对象跑
  **103 条断言全过**——覆盖：无朝向时 MARK 拒绝、登记朝向落盘为
  纯文字、相对角符号约定（+ 为右）与 TURN 指引措辞/度数、最近
  漏检项选择、凝视覆盖规则（锥形区 + 头稳连续 2 秒按 250ms 拍
  累计、1.75 秒不算数）、快速扫视骗不到勾、头不稳不计时、离开
  锥形区计时清零、OK 打勾记为 tap 并自动前进、点头纪律（无
  登记/没对上/头不稳都忽略、对上且头稳记为 nod、点头从不登记
  朝向从不记问题）、ISSUE 口述路径（麦克风检查流在识别启动前
  已停轨、MIC CHECK 与聆听行分离、口述原样入账并落盘）、无
  ASR 主机的预置词条轮换、识别报错后改走预置词条、PHOTO 走 default 模式且所有落盘
  payload 经断言不含任何照片字节/标记、相机轨道拍后即停、
  汇总计数与问题备注朗读、只念一次、翻转状态不重念、SPEAK
  可重听更新后的汇总、NEW 两段确认（单点只布防、其他操作解
  防、二点才重置且旧会话照片一并丢弃）、纯手势全流程走完
  八项（Enter 登记/打勾、点头打勾、滑动选点、双击无副作用、
  全检完后 Enter 朗读汇总）、DEMO 种子（4 登记 2 已检、驻留
  预置、演示中零落盘、步满一圈退出并恢复真实记录）、记录在
  新页面加载时完整恢复、DEMO 中 NEW 被拒、TTS 从不设置
  lang、onUnload 清理无异常。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图四张（见
  Preview Media）：首页初始态、DEMO 演示房间、DEMO 预置问题
  登记、八项全检汇总态均完整渲染。

**未验证**

- **照片确实无法持久化（设计前提，第一优先核对）**：AIUI 的
  wx 存储按文档存不了 Blob，本 Agent 因此只把照片留在会话
  内存并在界面/README 明示「不保存」。真机需核对：宿主是否
  另有照片落盘通道（若有，也应在后续版本明确改口径，而不是
  让用户误以为照片留了证）。
- 真机头部稳定检测与 2 秒凝视驻留的手感（±25° 锥形区在真实
  房间尺度是否合适、站在房间不同位置时登记朝向的几何偏差）；
  登记朝向只对登记时站的位置成立，巡检时请站回相近位置。
- 真机麦克风可用性检查（wearer 模式读回）与宿主 ASR 对酒店
  场景口述（水压、花洒、异味等词）的实际识别率；口述是原样
  入账，识别错了就是错的备注——汇总朗读正是让你核对的一环。
- 触控板手势（单击/滑动/双击）与点头在本 Agent 键位映射下
  的真机触发情况。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Hotel Checkin walks you through an eight-point room inspection the moment you arrive: door lock and peephole, bedding, bedside sockets, shower, towels, AC remote, curtains and window lock, kettle. Bind each point to the direction you face it, then just look at it for two seconds to check it off, or tap ISSUE and dictate the problem - your words are kept verbatim. Missed points get turn guidance. Photos stay in the session only and are never saved.

（451 字符）

### Opening Message

Hi, I'm **Hotel Checkin** — eight things to look at before you unpack.

**Swipe** to pick a point, look at it and tap **MARK** once to bind its direction. After that, looking at it steadily for two seconds checks it off; **OK** works too. Found a problem? Tap **ISSUE** and say it — your words are kept verbatim, and the summary reads them back. I'll point you to anything missed. Photos are session-only and never saved.

（421 字符）

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-hotel-checkin-index.png`（aix preview 首页：HOTEL CHECK 初始态，八项清单、登记提示、MARK/OK/ISSUE/PHOTO/LIST/SPEAK/DEMO/NEW 按钮齐全，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-hotel-checkin-demo.png`（DEMO 演示房间：4 个检查点已登记朝向、2 项已检（gaze/tap 如实标注）、当前驻留床头插座 1.0s/2s，本地文件）
- Image 3：`artifacts/preview-hotel-checkin-issue.png`（DEMO 中对床头插座登记预置问题「无热水」：预览宿主的识别报错后按提示再点 ISSUE 改走预置词条，清单行显示来源 chip，本地文件）
- Image 4：`artifacts/preview-hotel-checkin-done.png`（八项全检完成汇总态：CHECKED 8/8、OK/ISSUE 计数、ALL DONE 指引行，本地文件）
- Video：待真机补 — 真机录制「进房逐个 MARK 登记 → 转头凝视打勾 → 对淋浴口述登记问题 → LIST 跳漏检 → 全检完听汇总」全过程（MP4），录好后放 `artifacts/` 并更新此处（总数保持 3–5 个，届时删减一张图）
- 状态：未齐（已有 4 张图；还需至少 1 个视频，总数保持在 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Eight-point check-in inspection: door lock & peephole, bedding, bedside sockets, shower, towels, AC remote, curtains & window lock, kettle - each with a concrete look-for cue. Every point can be bound to the head heading you face it from (MARK), and missed points are announced with relative turn guidance ("TURN: RIGHT 120°") plus a spoken nearest-missed direction. Cardinal directions are never used.
- Gaze check-off with an anti-sweep dwell rule: looking at a registered point within a ±25° cone with a steady head for a continuous 2 seconds checks it off as "gaze" (250 ms tick accumulation; leaving the cone or moving the head resets the count, so a fast sweep earns nothing). Tap check-off ("tap") and steady-nod check-off while facing the point ("nod") are recorded as their own methods - the list always shows how each point was actually checked.
- ISSUE notes with verbatim dictation: an issue runs a wearer-mode microphone availability check first (reported on its own MIC CHECK line; the check stream is stopped before recognition and never feeds it), then host speech recognition stores your problem note word for word and the completion summary reads issue notes back. On hosts without recognition - or when recognition errors out - ISSUE honestly falls back to labelled preset chips （无热水 / 有异味 / 破损 / 缺件） instead of pretending to listen.
- Session-only photos: PHOTO takes a default-mode picture of the selected point as an in-session record. Photos are never written to storage (blobs cannot persist there) and the UI says so on the photo line at all times - keep evidence on your phone if you need it beyond the session.
- Text-only stay record persisted on-device (points, headings, states, methods, notes, times) and restored on the next launch; NEW starts a new stay behind a two-step confirm that also drops the old session's photos.
- Gesture-first operation (temple touchpad, dossier §3.2.1): single tap = contextual primary action (bind / check / next / speak summary), swipe = move selection, double-tap = host back, steady nod = check off only while facing the selected point - a nod never registers a heading and never files an issue. Eight on-screen buttons mirror the gestures, each justified in the README gesture map.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
