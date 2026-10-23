# posture-guard — 姿势守卫（Rokid 眼镜 AIUI Agent）

50 个「指向性生活问题」Agent 的第 32 个。低头看手机、看电脑
久了脖子僵——你不是不知道要抬头，你是没意识到这一低头就
是四十分钟。本 Agent 先让你看正前方校准一次「你的平视」，
之后持续监测头部俯仰：低过平视 25° 就给这一段低头计时，
超限时轻轻出声提醒一次「抬头休息一下」，抬头即停。

> ⚠️ **诚实定位（先读）**：它量的是**头低的角度**，不是
> 你的脖子。它测不到颈椎受力，也不知道你在看什么——桌上
> 摊一本书读，低头角度和玩手机一模一样，照样计时。它是
> 休息提醒，不是体态检测仪，更不是医疗建议；脖子持续
> 疼痛请看医生。

## 预览截图

截图统一存放于仓库根目录 `screenshots/posture-guard/`。

![未校准初始态：预览主机无传感器如实显示 SRC: NONE，等待看正前方点 CAL](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/posture-guard/preview-posture-guard-index.png)

![DEMO 监测中：模拟低头 34°，演示时钟 60 倍速使这一段跨过 20 分钟上限，提醒已触发（抬头休息一下）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/posture-guard/preview-posture-guard-reminder.png)

## 解决的问题

颈椎的账是按「连续低头时长」算的，但人对低头时长完全没
有感觉：刷手机「就看五分钟」，抬头时一个小时没了。手机
的屏幕使用时间统计管的是 App，管不了你的头低了多久；
定个番茄钟又太粗——中间你明明抬头活动过，它照样响。
眼镜的独特之处在于：它就戴在你的头上，头部俯仰角是它的
原生读数。把「这一段低头」做成一个有暂停、有清零规则的
状态机，提醒才贴合真实的脖子，而不是贴合钟表。

## 指向性设计（为什么必须用眼镜）

- **俯仰 = 头部原生读数（HEAD）**：`AbsoluteOrientationSensor`
  四元数取俯仰。低头是绕眼镜横轴（镜腿轴线）的转动，对应
  ZYX 欧拉分解的 `atan2(2(wx+yz), 1−2(x²+y²))`；合成
  四元数验证：平视佩戴约 +90°、低头 30° 约 +60°、抬头
  20° 约 +110°，且不随头部朝向（yaw）变化。
- **校准定平视（CAL）**：读数的绝对值没有意义——每个人
  戴眼镜的角度都不同。看正前方点 CAL，当前读数就是你的
  平视基准，DROOP 永远是「基准 − 当前读数」，正数 = 头在
  平视以下。基准与上限存 wx 同步存储 `postureGuard`。
- **低头段状态机（防骗规则）**：DROOP > 25° 算 DOWN 并
  累计这一段（stretch）；抬头不到 10 秒只**暂停**（扭头
  看一眼门不算休息），满 10 秒才**清零**并重新武装提醒；
  累计达到上限，提醒在这一段里恰好触发**一次**。传感器
  读数缺失时一切暂停——不累计、也不清零。
- **耳朵提醒（TTS）**：超限时大字「抬头休息一下」+ 朗读
  「你已经低头二十分钟了，抬头看看远处，活动一下脖子。」
  （分钟数随上限变）。SPEAK 随时朗读本次统计：累计低头、
  最长一段、已提醒次数。
- **不编读数（诚实边界）**：来源如实标注
  `SENSOR / DEMO / NONE`；没有读数时 CAL 直接拒绝，绝不
  编造一个平视基准（同 #07 / #30 的规则）。

## 功能流程

1. 校准（一次性）：舒适地看正前方，点 CAL → 平视基准
   落盘；换了使用姿势（坐 ↔ 躺）重新 CAL 即可
2. 监测：打开 Agent 后自动计时——低头超过 25°，STRETCH
   开始累计；短暂抬头（<10 秒）只暂停，抬头满 10 秒
   清零；达到上限（LIMIT 轮换 5 / 10 / 20 分钟，默认 20）
   朗读提醒一次，此后这段内不再重复
3. 统计：列表常驻 STRETCH 进度、本次累计低头、最长
   一段、提醒次数；SPEAK 朗读统计；RESET 开新会话
   （保留校准），CLEAR 清除校准
4. DEMO 仿真：内存里模拟一位监测中的佩戴者（不写存储、
   不覆盖真实校准）：平视 90°、当前低头 34°、进行中的
   一段已累计 18:24 / 20:00，本次统计为纯常数（最长一段
   24:12 + 当前段 18:24 = 累计 42:36，此前已提醒过
   1 次）。演示时钟 60 倍速——进入几秒后这一段跨过
   上限、提醒真实触发；再点 DEMO 在低头 34° / 抬头 −6°
   间切换。DEMO 中点 CLEAR 退出演示并恢复真实校准

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不声明任何权限：不用相机、不用麦克风、不用定位 |

app.json 无 `permissions` 字段（同 #07 / #15 / #28 / #30）；头部
朝向传感器在 AIUI 里不需要单独的权限声明。

## 打包与预览

```bash
cd ~/workspace/rokid/posture-guard
~/tools/bin/aix pack . -o ../dist/posture-guard.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-posture.js`；Shot A = 初始未校准态无点击；Shot B = 点
DEMO 一次（canvas 坐标 238,316，视觉定位确认）等待约 4 秒，
演示时钟 60 倍速使 STRETCH 跨过 20:00、提醒态入镜）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-posture-guard`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 posture-guard」，先看正前方点 CAL，
   再低头看手机：把 LIMIT 临时切到 5 分钟验证提醒触发一次、
   中途抬头 5 秒验证只暂停不清零、抬头 15 秒验证清零，
   然后切回 20 分钟日常使用

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 17.5 KB（本地打包 `dist/posture-guard.aix`，含本 README） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留；
  app.json 无 `permissions` 字段（零权限，与设计一致）。
- 俯仰数学：用 Node 载入页面对象的 `_pitchDeg` 喂合成
  四元数——单位四元数 0°、平视佩戴姿态 90°、低头 30°
  得 60°、抬头 20° 得 110°、叠加 50° yaw 后仍为 90°
  （俯仰读数与朝向无关）；坏四元数返回 null；DROOP 符号
  验证（低头为正、抬头为负）。
- 低头段状态机：Node 加载页面对象（wx 打桩）跑 61 条断言
  全过——DOWN 时间逐 tick 累计、299750ms 不提醒 /
  300000ms 恰好触发（上限 5 分钟档）、提醒文案与上限
  分钟数一致、同一段内持续低头不重复提醒、抬头 9750ms
  只暂停（段保留、提醒不重新武装、抬头时间不计入累计）、
  抬头满 10000ms 清零并重新武装、新一段可再次触发、
  DROOP 恰好 25° 不算 DOWN / 25.1° 算、读数缺失时段与
  抬头计时双双冻结、RESET 保校准清统计、CLEAR 清校准
  并落盘、校准经存储往返恢复、上限 5/10/20 轮换并落盘。
- DEMO 确定性：同套断言验证 DEMO 落点——模拟平视 90°、
  低头 34°、STRETCH 恰为 18:24 / 20:00、最长 24:12 与
  当前段 18:24 合计恰为累计 42:36（纯常数、无 Date）、
  列表行文案与 DROOP 行与断言一致；60 倍速时钟下 6 个
  有效 tick 推进到 19:54 不触发、第 7 个跨过 20:00 触发
  提醒且文案为 PLAN 的二十分钟句；DEMO 全程不写 wx
  存储，CLEAR 退出后恢复真实设置。
- 打包：`aix pack` 成功（大小见上表）；`aix list` 核对包内含
  AGENTS.md、app.js、app.json、package.json、README.md、
  pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：初始未校准态完整渲染（预览主机无可用
  方向传感器，如实显示 `SRC: NONE`，CAL 拒绝路径与设计
  一致）；DEMO 态渲染出低头 34°、STRETCH 跨过上限后
  的提醒态（大字「抬头休息一下」），与 Node 断言的演示
  时钟行为一致。

**未验证**

- 真机 AbsoluteOrientationSensor 的俯仰精度/零点与 5Hz
  读数下状态机的实际手感——预览主机没有可用传感器，
  未测；尤其眼镜佩戴松紧、镜腿角度对平视基准的影响，
  要在真机上校准后低头看一段手机才有结论。
- 25° 阈值与「抬头 10 秒清零」在真机日常使用中是否合
  适（会不会提醒太勤/太钝）——经验规则，需真机长时
  佩戴调整。
- TTS 提醒（超限朗读与 SPEAK 统计）在真机上的效果。
- 本 Agent 不判断颈椎状态，这是设计定位而非缺陷：
  持续疼痛请就医。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Posture Guard watches your head pitch so long phone-and-laptop sessions stop ending in a stiff neck. Calibrate once by looking straight ahead; from then on the glasses measure how far your head droops below that neutral. Droop past 25 degrees for the limit you pick (5, 10 or 20 minutes - brief lifts under 10 seconds only pause the clock) and it speaks one gentle reminder to look up and roll your neck. Session totals, longest stretch and reminder count stay on screen.

### Opening Message

Hi, I'm **Posture Guard** - I keep an eye on how long your head stays down.

Look **straight ahead** and tap **CAL** once. After that I time every head-down stretch: droop past **25 degrees** counts as down, a lift under **10 seconds** only pauses the clock, and at your **limit** (tap LIMIT: 5 / 10 / 20 min) I remind you **once** per stretch to look up. I measure **head pitch only**, not your spine - a break reminder, not medical advice. Persistent pain? Please see a doctor.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-posture-guard-index.png`（aix preview 初始未校准态：SRC: NONE、等待 CAL，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-posture-guard-reminder.png`（DEMO 提醒态：模拟低头 34°，60 倍速时钟使 STRETCH 跨过 20:00 上限，大字「抬头休息一下」，本地文件）
- Video：待真机补 — 真机录制「看正前方 CAL → 低头看手机（LIMIT 临时切 5 分钟）→ 提醒触发 → 抬头 15 秒清零」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Head-pitch monitoring from the AbsoluteOrientationSensor quaternion: pitch is the ZYX-Euler X angle (nodding about the glasses' lateral axis), validated in Node against synthetic quaternions (level worn pose about +90 degrees, nod down 30 about +60, look up 20 about +110, invariant to yaw). DROOP is always the difference from your own calibrated neutral, never an absolute anatomical claim.
- One-tap calibration (CAL): look straight ahead and the current reading becomes your neutral, persisted on-device in wx storage (key postureGuard, together with the reminder limit); CAL honestly refuses when no pitch reading exists instead of inventing a neutral, and re-calibrating invalidates the running stretch.
- Head-down stretch state machine (250 ms tick): droop over 25 degrees counts as DOWN and accumulates; a lift under 10 seconds only pauses the stretch (a glance at the door earns no fresh neck), a lift of 10 seconds or more resets it and re-arms the reminder; a missing sensor reading freezes everything - no growth, no reset. At the limit the reminder fires exactly once per stretch: big on-screen break prompt plus a spoken Chinese reminder whose minute count follows the limit.
- Reminder limit selector (LIMIT): 5 / 10 / 20 minutes, default 20, persisted; session stats always on screen (current stretch against the limit, session head-down total, longest stretch, reminder count) and readable aloud via SPEAK; RESET starts a new session keeping the calibration, CLEAR removes it; DEMO simulates a wearer mid-session in memory only (neutral 90 degrees, droop 34 degrees, stretch seeded at 18:24 of 20:00 from pure constants, session stats seeded coherently) on a stated 60x accelerated clock so the reminder genuinely fires seconds after entry, and further DEMO taps toggle the simulated head down/up.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
