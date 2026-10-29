# home-find — 家中寻物（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-home-find
```

**AIX 直接下载**（最新版）：[home-find.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/home-find.aix)


50 个「指向性生活问题」Agent 的第 DI26 个（F 组家居生活第一个）。
东西一收起来就找不到：护照塞进哪个柜子了？备用钥匙挂哪儿了？
药盒是在床头柜还是书房？手机备忘录能记文字，记不了「你当时
站在哪、面朝哪看着它收进去的」。本 Agent 把登记挂在视线上：
收纳时看着收纳处，说出物品和具体位置，眼镜存下「物品 +
房间 + 口头线索 + 头部朝向 + 日期时间」；找时大字线索先把
你领回对的房间和柜子，再转头对齐登记朝向，确认你正对着
当时收纳的方向。

## 预览截图

截图统一存放于仓库根目录 `screenshots/home-find/`。

![STORE 登记模式（空登记初始态：物品 护照 / 房间 客厅已选、朝向 SRC NONE 如实标注）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/home-find/preview-home-find-index.png)

![FIND 寻物状态（DEMO 登记 3 件物品，朝向步进到 225° 时护照 210° 登记点相对角 −15°，箭头 ↑ 高亮 FACING THE SPOT，含大字记忆线索）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/home-find/preview-home-find-find.png)

## 解决的问题

「收起来就找不到」不是记性差，是收纳那一刻没有留下任何
线索：关上柜门，位置信息就只剩脑子里一点模糊印象，几天
后全无。本 Agent 让收纳动作本身生成线索——你本来就要
看着收纳处把东西放进去，顺手说两句话（什么东西、放哪层），
这条记忆就和你的朝向绑在一起存好了。找的时候不用满屋
乱翻，先看线索回对房间，再用转头确认方向。

## 指向性设计（为什么必须用眼镜）

- **收纳即登记 = 把位置绑在你的朝向上（HEAD）**：SAVE 时记录
  的不只是物品名，还有那一刻 `AbsoluteOrientationSensor`
  读到的头部朝向角（yaw）——「站在书房面朝 210° 把护照
  放进书柜第二层」是一个完整的场景记忆，手机拿在手里
  记不出这个朝向。
- **线索靠嘴、核对靠眼（诚实设计）**：ITEM 与 CLUE 各是一次
  一次性 SpeechRecognition（zh-CN）——动手前先按文档方式
  做佩戴者模式（`microphoneMode:'wearer'`）麦克风检查，4 麦
  优先收你自己的声音。识别结果**原样**显示在 ITEM / CLUE
  行等你核对后才 SAVE：听错的物品名存进去，就会按错名字
  找。主机没有识别能力时如实 SKIP，ITEM 改走五个预置物品
  （护照 / 备用钥匙 / 工具箱 / 药盒 / 充电器），CLUE 改走
  四个预置线索（柜子抽屉 / 架子第二层 / 盒子里 / 门后挂钩），
  不假装在听。
- **寻物 = 先读线索，再转头对齐**：FIND 里 ITEM 轮换已登记
  物品，回忆线索大字显示「护照 → 书房 · 书柜第二层 · 朝向
  210° 登记」；相对角 = 登记朝向 − 当前朝向，归一化到
  −180°…180°，|相对角| ≤ 15° 时高亮「FACING THE SPOT —
  look there」——你正对着当时收纳的方向（几何边界见下）。
- **挪窝就覆盖（ newest wins）**：同一物品重新登记会覆盖旧
  记录——东西挪了地方，最新位置说了算，状态行会如实标
  「old spot replaced」。记录存 wx 同步存储（key `homeFind`，
  最多 12 条，超出丢最旧的）。
- **看一眼留底（只作记录）**：LOOK 用默认模式
  `ImageCapture.takePhoto({mode:'default'})` 拍下收纳处当
  你的视觉副本，运行时没有 OCR，照片永不被读取；位置信息
  只来自你亲口说的线索。

## 功能流程

1. STORE（默认）：站在收纳处前看着它，点 ITEM 说物品
   （如「护照」），看 ITEM 行核对；点 CLUE 说具体位置
   （如「书柜第二层」），看 CLUE 行核对；ROOM 轮换房间
   （客厅 / 卧室 / 书房 / 厨房 / 玄关 / 阳台）
2. 点 SAVE，或头部稳定时点头 → 存 {物品， 房间， 线索，
   朝向°, 日期， 时间} 到 wx 同步存储（key `homeFind`，
   最多 12 条，同一物品重新登记覆盖旧记录）；已登记列表
   常驻显示「物品 · 房间 · 线索 · 朝向 · 日期 时间」，
   关掉重开还在（onLoad 读取、onUnload 落盘）；CLEAR 清空
   全部；LOOK 可先拍一张收纳处留底
3. FIND：点 MODE 切换，ITEM 轮换已登记物品 → 大字线索
   显示「护照 → 书房 · 书柜第二层 · 朝向 210° 登记」，
   回到书房、站到当初登记位置附近慢慢转头，转到 FACING
   THE SPOT 高亮就在那附近找；SPEAK 朗读线索 + 当前方向
4. DEMO：用一次时钟快照登记 3 个标注 DEMO 的物品（护照
   书房 书柜第二层 @210° / 备用钥匙 玄关 门后挂钩 @40° /
   药盒 卧室 床头柜抽屉 @300°）并切到 FIND 选中护照；
   之后每点一次 DEMO 朝向 +45°，转到 225° 时护照相对角
   −15° 进入 FACING THE SPOT — 预览可完整演示

> 诚实说明：这是「收纳记忆」，不是物品追踪。眼镜记住的是
> 你当时把它收在哪、面朝哪，不是物品现在在哪；东西被别人
> 拿走或挪过（且没重新登记），指引到的仍是你上次登记的
> 位置。另外朝向只对登记时站的位置成立：登记的是「从我站
> 的地方看向收纳处」的方向，找时要回到登记房间、站到当初
> 登记位置附近再转头，站在别的房间角度对不上是几何使然。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | LOOK 以默认模式拍收纳处留作你自己的视觉副本；照片只取字节数显示，从不被读取或识别 |
| RECORD_AUDIO | ITEM / CLUE 语音登记：先做佩戴者模式（wearer）麦克风可用性检查，识别由系统 SpeechRecognition 完成；只保存你确认过的物品名与线索文本，不录音、不保存音频 |

朝向传感器不需要额外权限声明；本 Agent 不用定位。

## 打包与预览

```bash
cd ~/workspace/rokid/home-find
~/tools/bin/aix pack . -o ../dist/home-find.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-home.js`；SEQ_B = canvas 内 DEMO (240, 297) 连点 6 次：
登记 3 个 DEMO 物品并切到 FIND，再步进朝向 45°/90°/135°/180°/225°
到 FACING THE SPOT；注意 artifacts/preview.html 需先把 importmap 的
jspm 地址换成本地 `/ink/index.js` 再复制到 preview-tools/www/）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-home-find`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 home-find」，在家真实收纳场景试几天：
   重点核对 ① ITEM / CLUE 在日常环境声里听物品名与位置词的
   准确率（登记前核对环节是否够用）② 回到登记房间、站回
   登记位置附近转头时 FACING THE SPOT 亮起的角度是否对得上
   真实收纳处 ③ 同一物品挪窝后重新登记覆盖旧记录是否符合
   直觉 ④ LOOK 拍收纳处的照片日后对账看不看得清

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 20.8 KB（本地打包 `dist/home-find.aix`，含本 README；打包时间戳使字节数有 ±0.01 KB 抖动） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 行为与朝向数学：用 Node 加载真实页面对象（wx 存根）跑 49 条
  断言全过——初始 STORE 态 SRC NONE 如实显示、无朝向时 SAVE
  拒绝且不存任何记录（绝不编造朝向）；无 SpeechRecognition 时
  ITEM / CLUE 的 SKIP 预置轮换路径（物品→备用钥匙、线索→
  架子第二层）与 ROOM 轮换正确；DEMO 一次登记 3 条（护照
  书房 书柜第二层 @210° / 备用钥匙 玄关 门后挂钩 @40° /
  药盒 卧室 床头柜抽屉 @300°），三条的日期/时间字符串完全
  相同（一次快照、纯字符串推导），自动切 FIND 且大字线索行
  为「护照 → 书房 · 书柜第二层 · 朝向 210° 登记」；朝向步进
  5 次到 225° 时相对角 −15°、FACING THE SPOT 高亮亮起，
  SPEAK 文本为「护照在书房，书柜第二层。你当时站在书房
  朝向 210 度登记的。……」；相对角公式另测 12 个用例（含
  ±15° 边界、16° 刚出界、跨 0° 缠绕 40° 对 350° = +50°
  RIGHT-FRONT、正后方 180°），符号约定与兄弟 Agent 一致
  （相对角 = 登记朝向 − 当前朝向，正值 = 在你右边）；同一
  物品重新登记覆盖旧记录且状态行标注、12 条上限丢最旧、
  wx 存储 key `homeFind` 读写往返、DEMO 重入不堆积、FIND
  里 ITEM 轮换已登记物品，均通过。
- 打包：`aix pack` 成功（大小见上表）；`aix list` 核对包内含
  AGENTS.md、app.js、app.json、package.json、README.md、
  pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见
  下方 Preview Media）：STORE 态完整渲染（物品 护照 / 线索
  柜子抽屉 / 房间 客厅已选、无记录、朝向 SRC NONE 如实标注
  —— 预览主机方向传感器报错，代码按 NONE 路径处理，不编造
  朝向）；DEMO 连点 6 次后切到 FIND：3 条记录入列（STORED
  3/12），朝向步进到 225°，护照相对角 −15°，箭头 ↑ 且
  「FACING THE SPOT — look there」高亮，大字记忆线索完整
  显示。预览主机无相机与 SpeechRecognition，LOOK 的 FAIL
  路径与 ITEM / CLUE 的 SKIP 预置路径已在代码中实现，其中
  SKIP 路径经 Node 断言覆盖。
- **预览主机时钟说明（如实）**：本地 Ink 预览运行时的 `Date`
  是虚拟化的（日期/时刻与真实日历不一致），截图里记录行
  显示的日期时间是该虚拟时钟的值；DEMO 登记已改为从一次
  时钟快照以纯字符串推导全部日期与时间，保证同批 3 条记录
  的日期时间完全一致、不互相漂移。真机使用真实时钟，日期
  以设备时钟为准。

**未验证**

- 真机 AbsoluteOrientationSensor 朝向读数的精度与零点参考
  （朝向是机身/头部相对方位，真机待测；本 Agent 只用登记与
  寻物两次读数的相对关系，零点漂移会影响指引准确度，已在
  设计上如实说明）。
- 真机上「收纳登记 → 换日后按线索 + 转头找回」的全流程，
  以及离开登记位置几米后朝向几何的实际误差——未实测；本
  Agent 的定位是同一房间内的收纳回忆辅助。
- ITEM / CLUE 在真实居家环境（电视声、家人说话）里对物品
  名与位置词的识别准确率——真机测试的第一号未知数；
  「登记前亲眼核对 ITEM / CLUE 行」就是为此设计的兜底。
- 真机头部稳定检测、点头手势、TTS 朗读线索的效果，以及
  佩戴者模式（wearer）麦克风检查在真机上是否被接受、LOOK
  默认模式拍收纳处的清晰度。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Home Find remembers where you put things away. Facing the storage spot, say the item ('passport') and the exact place ('second shelf of the bookcase'): it stores item, room, your spoken clue and your head heading together. Later, pick the item in FIND and the clue shows big - room, place, registered heading. Back in that room, turn slowly: when you face the heading you registered at, FACING THE SPOT lights up. Re-store an item and the newest spot wins.

### Opening Message

Hi, I'm **Home Find** — I remember where you put things away.

Putting something away? Look at the spot, tap **ITEM** and say what it is, tap **CLUE** and say where ('second shelf'), pick the **ROOM**, then **SAVE** — or nod while your head is steady. Check both lines before saving: I keep exactly what I heard. Hunting later? Switch to **FIND**, pick the item, go back to that room and turn slowly until **FACING THE SPOT** lights up. Tap **SPEAK** to hear the clue, or **DEMO** to try it now.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-home-find-index.png`（aix preview STORE 态：空登记，物品 护照 / 线索 柜子抽屉 / 房间 客厅已选、朝向 SRC NONE 如实标注，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-home-find-find.png`（FIND 态：DEMO 登记 3 件物品并步进朝向到 225°，大字线索「护照 → 书房 · 书柜第二层 · 朝向 210° 登记」、箭头 ↑ 与高亮「FACING THE SPOT — look there」，本地文件）
- Video：待真机补 — 真机录制「看着收纳处 ITEM 说物品 + CLUE 说位置 + SAVE 登记 → 回到该房间 FIND 转头 FACING THE SPOT 亮起 + SPEAK 朗读」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Storage registration bound to head heading: face the spot where you are putting something away, say the item and the exact place, pick the room and SAVE — item, room, spoken clue, orientation-sensor heading and date/time are stored together on-device in wx storage (key homeFind, up to 12 records, loaded on open and saved on close). Re-storing the same item replaces its old record on purpose: you moved it, so the newest spot wins, and the UI says so.
- Spoken item and clue with a verify-before-save step: ITEM and CLUE each run a one-shot zh-CN SpeechRecognition after a documented wearer-mode microphone check, and the heard text is shown verbatim on screen for the wearer to eyeball before SAVE stores it; on hosts without recognition both honestly report SKIP and cycle presets instead (five items, four clues), and SAVE refuses when no heading exists instead of inventing one — the heading source is honestly labeled SENSOR / DEMO / NONE at all times.
- FIND re-finding by clue plus heading: FIND shows the memory clue big ('passport -> study, second shelf of the bookcase, registered at 210 degrees'), SPEAK reads it aloud ('The passport is in the study, second shelf of the bookcase. You registered it standing in the study facing 210 degrees.'), and the relative angle to the stored heading drives an 8-way arrow with a FACING THE SPOT highlight within 15 degrees; LOOK photographs the storage spot in default mode purely as your own record copy (never read, no OCR), and DEMO stores three labeled items at 210 / 40 / 300 degrees from a single clock snapshot, enters FIND, and steps the simulated heading +45 degrees per tap so the FACING state is previewable end to end.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
