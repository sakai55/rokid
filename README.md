# photo-level — 拍照水平（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-photo-level
```


50 个「指向性生活问题」Agent 的第 44 个。用眼镜拍照（或者举着
手机拍）总是歪：地平线斜几度，照片立刻显得业余；构图没感觉，
主体永远死在正中央。本 Agent 的取景框就是你的眼睛——三分法网
格和气泡水平仪直接浮在透视显示上、叠在你正看的真实场景上，
头部横滚实时可见；摆平了，点头就是快门；每张拍完当场判定
LEVEL ✓ 还是 TILTED 几度，念给你听。

## 预览截图

截图统一存放于仓库根目录 `screenshots/photo-level/`。

![首页初始状态：三分法网格（含四个 + 交叉点）、ROLL 读数、静态 TIP、SNAP/CALIB/GRID 与 SPEAK/DEMO 按钮及常驻诚实行](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/photo-level/preview-photo-level-index.png)

![DEMO 态横滚 −8.0°：气泡偏到左端，地平线字形倾斜，判定 TILTED −8.0°（PITCH +2.0° 同时显示）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/photo-level/preview-photo-level-tilted.png)

![DEMO 扫到 −1.0°：进入 ±2° 水平带，LEVEL ✓ 高亮，气泡回到中心附近](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/photo-level/preview-photo-level-level.png)

![拍下一张（DEMO 照片 0 字节）：拍摄记录 #1 显示时间、横滚 −1.0°、判定 LEVEL ✓，TIP 已轮换到下一条](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/photo-level/preview-photo-level-shot.png)

## 解决的问题

照片歪不歪，取决于按下快门那一刻相机横滚了几度——而人对自己
头部倾斜的感知很迟钝，2–3 度的歪斜看不出来、拍出来很明显。手
机水平仪要低头看屏幕，眼线和取景同时断掉。本 Agent 把水平仪
放进视线里：你看着场景，余光就有气泡和 ROLL 读数；CALIB 一次
把「你觉得平的姿势」设成零点，之后摆头到 LEVEL ✓ 再点头，照
片就是正的。构图上，三分法网格与交叉点常驻眼前，静态提示轮
换着提醒你把主体放交叉点、地平线压三分线——不用背理论，看着
摆就行。

## 指向性设计（为什么必须用眼镜）

- **看向即取景（GAZE 透视叠加）**：眼镜显示是透视的，页面画
  的三分法网格直接叠在真实场景上——运行时没有（也拿不到）
  相机实时预览流，页面里**不存在取景画面**，照片只在快门那
  一刻才由 `ImageCapture.takePhoto({mode:'default'})` 拍下
  （wx CameraContext 回退，同 #41）。手机做不到这一点：它的
  网格必须画在屏幕画面上，眼睛得离开场景。
- **头部即水平仪（HEAD 姿态分解）**：`AbsoluteOrientationSensor`
  四元数做标准 ZYX 欧拉分解，roll 分量就是你的头部横滚，
  实时换算成气泡位置与 ROLL 读数；pitch 分量作俯仰提示同时
  显示。判定带宽 |roll| ≤ 2°——比人眼能察觉的歪斜更严。
- **相对校准绕开未定坐标系（同 #42 ALIGN 思路）**：宿主传感
  器坐标系的零点与轴向没有文档固定，绝对读数不可轻信。
  CALIB 把你当下姿势的 RAW roll/pitch 定为会话零点，判定全
  程用相对量；RAW 原始值同时常驻小字行显示，零点是多少、
  原始读数是多少，从不藏起来。
- **点头快门（HANDS-FREE）**：头部稳定时点头即快门，双手可
  以扶着东西、抱着孩子、端着相机姿势不动；单击触控板
  （Enter）与 SNAP 按钮等效。点头纪律是严的：不稳不动、
  没有朝向读数时如实拒绝——因为这张的判定正是快门的产出，
  盲拍无意义。

## 手势映射

本 Agent 的全部主流程（摆平 → 拍照 → 听判定 / 切网格）都可以
只用眼镜腿触控板手势 + 头部动作完成，不必点屏幕按钮。手势与
键码的对应来自官方文档档案 §3.2.1。

| 手势 | 键码 | 在本 Agent 中的动作 |
|---|---|---|
| 单击触控板 | Enter | SNAP 拍照（只有这一个含义——快门永不意外；与 SNAP 按钮等效） |
| 滑动触控板 | ArrowUp / ArrowDown | 轮换网格样式：FULL 三分法 → HORIZON 只留水平线 → OFF 关网格（反向滑动逆序） |
| 双击触控板 | Backspace | 返回 / 关闭（由宿主处理，本 Agent 只记录事件） |
| 长按触控板 | —（系统级） | 唤醒 AI 助手（系统功能，不经过本 Agent） |
| 头部稳定时点头 | onHeadGesture `nod` | SNAP 拍照（须头部稳定且有实时朝向读数；无读数时如实拒绝，判定记不了的照片不盲拍） |
| 屏幕按钮 | — | 保留 5 个：SNAP（快门，与手势等效）、CALIB（把当前姿势定为水平零点，手势不代办）、GRID（切网格，与滑动等效）、SPEAK（朗读上一张判定）、DEMO（无传感器时模拟横滚扫动） |

## 功能流程

1. 打开即取景：三分法网格（含四个 `+` 交叉点）浮在你真实的
   视野上，ROLL 大字与气泡水平条实时显示头部横滚，PITCH 同
   行给出；RAW 原始读数与来源（SENSOR / DEMO / NONE）在小字
   行常驻
2. CALIB（建议每次先做）：摆出你认为平的头部姿势点 CALIB，
   当前 RAW roll/pitch 成为本次会话零点；没有传感器读数时
   如实拒绝
3. 构图：看着场景摆头——主体对交叉点、地平线压三分线；
   一行 TIP 静态提示每次拍照/切网格轮换一条（提示是固定文
   字，本 Agent 不做场景分析）；滑动或点 GRID 在 FULL /
   HORIZON / OFF 间切换网格
4. 摆平：盯着气泡回到中心、判定变 LEVEL ✓（|roll| ≤ 2°）
5. 拍照：头部稳定时点头，或单击触控板，或点 SNAP——判定在
   按下瞬间冻结（roll/pitch/时间），照片 Blob 读完字节数即
   丢弃，只留一条拍摄记录（≤6 条，会话内）
6. SPEAK：念上一张的判定（水平很好 / 向左·右歪了 N 度）；
   列表里每张的时间、横滚、判定随时可查

> 诚实边界：**照片从不保存**——本 Agent 不写任何存储，照片
> 字节在读完大小后即被丢弃，它只回答「拍得正不正」，不做相
> 册；要留照片请用宿主/手机的正常拍照流程。**判定量的是头部
> 横滚**，不是照片像素：相机与头部刚性同向时两者一致，这个
> 前提与传感器坐标系对应关系一起列在下方「未验证」里，不冒
> 充成片检测。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | SNAP 时 `ImageCapture.takePhoto`（default 模式）拍一张照片，只读字节数作拍摄记录，照片从不保存 |

朝向传感器不需要单独权限声明；不录音（无 RECORD_AUDIO）、
不用定位。相机只在用户触发快门时启动，用完立即停掉全部媒体
轨道。本 Agent 不写任何 wx 存储——校准、拍摄记录、照片全部
只活在本次会话内存里。

## 打包与预览

```bash
cd ~/workspace/rokid/photo-level
~/tools/bin/aix pack. -o../dist/photo-level.aix
~/tools/bin/aix preview. --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-level.js`，独立页面副本 `preview-level.html`；点击序列为
canvas 内坐标 DEMO (352, 297) 进入演示 → DEMO ×3 到 −1.0° →
SNAP (89, 267) 拍下演示照片；全部状态行均为单行，按钮位置在各
态间不变，坐标经截图视觉确认）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-photo-level`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 photo-level」，在真实场景实测：
   **第一优先核对传感器分量对应关系**——正对一个已知平直的
   场景（桌面边缘/门框），慢慢把头向左、向右各歪约 10 度，
   看 ROLL 读数变化的是不是横滚分量、符号方向与 SPEAK 的
   「向左/向右」是否一致；再低头/抬头看 PITCH 分量；然后验
   证 takePhoto 拍到的画面与所见是否同框（网格边缘对场景边
   缘）、点头快门的误触率、CALIB 后 LEVEL ✓ 判定的照片实际
   歪斜（把照片导到手机上量）

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 22.0 KB（本地打包 `dist/photo-level.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 姿态与判定逻辑（Node 实测）：把页面对象以 wx /
  AbsoluteOrientationSensor / ImageCapture /
  speechSynthesis 全部打桩加载进 Node，共 95 条断言全过——含
  四元数→roll/pitch 提取（测试四元数由轴角旋转经 Hamilton
  乘积独立构造，q = qz(yaw)·qy(pitch)·qx(roll)：identity、
  纯 roll ±、纯 pitch ±、纯 yaw 不串扰、两组组合姿态、大俯
  仰 80°，共 14 项比对全在 0.05° 内；零/未归一化四元数如实
  返回 null）；LEVEL 带宽边缘（1.9° ✓ / 2.0° ✓ / 2.1° ✗，
  负侧对称）；CALIB 归零数学（无读数拒绝、存 RAW 为零点、
  在校准姿势校正值归零、移动 +3.0° 后校正值 +3.0° 且判
  TILTED、RAW 行保留原始值）；SNAP 记录（takePhoto 参数为
  default 模式、判定取按下瞬间冻结的 roll、相机轨道拍完停
  止、无传感器时判定 n/a 仍记录、ImageCapture 缺失走 wx 回
  退、相机全失败如实 FAIL 且不记假照片、列表上限 6 条丢最
  旧并注明）；点头纪律（不稳忽略、无读数如实拒绝且相机从
  不触发、稳 + 有读数才拍照、非 nod 手势忽略）；手势与网
  格（Enter = SNAP、滑动 FULL → HORIZON → OFF 循环且交叉
  点只在 FULL 显示、Backspace 只记事件）；DEMO 扫动
  （−8° 起步逐步扫到 +7°、−1° 处 LEVEL ✓ 可预览、DEMO 照
  片标注且 0 字节、退出恢复进入前的校准）；SPEAK 判定
  （无照片如实、LEVEL 念水平很好、负 roll 念向左歪、正
  roll 念向右歪、TTS 从不设置 utterance.lang）；气泡条
  （0° 居中、大倾斜钉在两端、无读数无气泡）；**全程零 wx
  存储读写**（setStorageSync / getStorageSync 调用计数均为
  0）。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被.aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图四张（见下方
  Preview Media）：首页初始态完整渲染（三分法网格与四个 `+`
  交叉点位置正确、ROLL/RAW/HEAD 各行、TIP 与 GRID 行、五按
  钮及常驻诚实行）；点 DEMO 到达横滚 −8.0° 态：气泡偏左
  端、地平线倾斜字形、TILTED −8.0° 与 PITCH +2.0° 正确渲
  染；再点 DEMO ×3 到达 −1.0°：LEVEL ✓ 高亮、气泡近中
  心；点 SNAP 后拍摄记录 #1（时间、roll −1.0°、LEVEL ✓、
  0B DEMO）与 TIP 轮换正确渲染。

**未验证**

- **真机传感器分量对应关系（第一优先）**：档案没有固定宿主
  `AbsoluteOrientationSensor` 的坐标系——本文的 roll / pitch
  是按标准 ZYX 分解命名的两个分量，它们在真机上是否分别对
  应「画面横滚 / 点头俯仰」、正负号与 SPEAK 的「向左歪 /
  向右歪」是否一致，都要真机对着已知平直场景核对（同 #06
  左右核对的口径）。若对应关系不同，受影响的是分量命名与
  方向词；CALIB 相对归零的判定框架仍然成立（判的是「离你
  定的平直姿势歪了多少」），且 RAW 原始值一直并行显示。
- **takePhoto 与所见同框性**：相机的位置、FOV 与显示视场
  （480×352）的关系未经真机验证——网格在显示里框住的范
  围，与照片实际拍到的范围可能不一致（偏、窄或宽）；判定
  记录的是头部横滚，不是照片像素的横滚，两者一致的前提
  （相机与头部刚性同向、安装无固定偏角）同样待真机量照片
  验证。
- 真机水平仪手感：传感器采样率与抖动下 ROLL 读数的平滑度
  （本 build 未做滤波）、±2° 判定带宽在行走/手持场景是否
  过严或过松、点头快门在构图姿势下的误触率；照片在真机上
  的去向（本 Agent 不保存照片——宿主相机通道是否另行把眼
  镜照片同步到手机相册，是宿主的行为，不在本 Agent 的声明
  范围内）。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Photo Level keeps your glasses photos straight. The display is see-through, so a rule-of-thirds grid and a live level float over the real scene in front of you - no camera feed, and a photo is taken only when you shoot. Roll and pitch come from the orientation sensor; CALIB zeroes them against the head pose you call level. Shoot with a steady nod, the temple tap or SNAP. Each shot is graded LEVEL or TILTED with its exact roll. Photos are never saved - session only.

（469 字符）

### Opening Message

Hi, I'm **Photo Level** - straighter photos, eyes up.

The grid and level float **over the real scene** in front of you - there is **no camera feed**; a photo is taken only at the shot. **ROLL** shows your head tilt live, **PITCH** your nod angle. **CALIB** once for the pose you call level. Shoot with a **steady nod**, a **temple tap**, or **SNAP**. Every shot is graded **LEVEL** or **TILTED** with its roll, and **SPEAK** reads the last verdict. Photos are **never saved**.

（477 字符）

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-photo-level-index.png`（aix preview 首页：三分法网格含四个 + 交叉点、ROLL/RAW/HEAD 各行、快门与校准按钮、常驻诚实行，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-photo-level-tilted.png`（DEMO 横滚 −8.0°：气泡偏左端、地平线倾斜、TILTED 判定与 PITCH 同显，本地文件）
- Image 3：`artifacts/preview-photo-level-level.png`（DEMO 横滚 −1.0°：LEVEL ✓ 高亮、气泡近中心，本地文件）
- Image 4：`artifacts/preview-photo-level-shot.png`（拍下演示照片后：拍摄记录 #1 含时间/横滚/判定/0B DEMO 标注，TIP 已轮换，本地文件）
- Video：待真机补 — 真机录制「对着真实场景 CALIB → 摆头到 LEVEL ✓ → 点头拍照 → SPEAK 念判定」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 4 张图；还需至少 1 个视频，总数保持在 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- See-through viewfinder: a rule-of-thirds grid with the four intersection points marked (+) is drawn on the page, floating over the wearer's real view on the see-through display - the runtime offers no camera preview feed and this agent shows none; a photo exists only at the moment of the shot. Grid styles cycle FULL thirds / HORIZON lines only / OFF via temple swipe or the GRID button.
- Live level from the orientation sensor: roll and pitch are extracted from the AbsoluteOrientationSensor quaternion by the standard ZYX Euler decomposition (verified in Node against independently composed quaternions), shown as a big ROLL readout with a bubble level and horizon glyph, plus the RAW uncalibrated values always visible on their own line. LEVEL is judged at |roll| <= 2 degrees; pitch is displayed as tilt guidance and never gates the verdict.
- Relative calibration: CALIB stores the current RAW roll/pitch as this session's zero - the head pose the wearer calls level - sidestepping the host's undocumented sensor frame; every later reading and verdict is relative to it, and CALIB is honestly refused when there is no reading. Nothing is persisted: the calibration lives in the session only.
- Shutter with a frozen verdict: a steady-head nod, the temple tap (Enter) or SNAP takes the photo with ImageCapture in default mode (wx camera-context fallback); the corrected roll/pitch and time are frozen at the press instant, and the shot record (time, roll, pitch, LEVEL/TILTED verdict, byte count) is kept in a session list of at most 6. The photo Blob itself is discarded right after its size is read - photos are never saved, and this agent writes no storage at all. SPEAK reads the last shot's verdict aloud; a nod with no orientation reading is refused honestly instead of shooting blind, while SNAP without a sensor still records a shot with an n/a verdict.
- Static composition tips rotate on every shot and grid change (subject on a cross point, horizon on a third line, leave space before a gaze, and two more) - fixed guidance text, labelled as such; the agent performs no scene analysis and detects neither subjects nor horizons.
- DEMO sweeps a simulated roll from -8 degrees through the LEVEL band to +7 degrees so both verdicts preview without a sensor; DEMO shots are labelled and recorded at 0 bytes, and leaving DEMO restores the wearer's calibration untouched.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
