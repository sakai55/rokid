# expiry-check — 临期检查（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-expiry-check
```


50 个「指向性生活问题」Agent 的第 03 个。冰箱和囤货柜里的食品总是放到
过期才发现：看着包装拍一下日期区域，日期你亲口/手动确认，眼镜算好
剩余天数、排好紧急顺序管起来，3 天内到期的出声提醒你。

## 预览截图

截图统一存放于仓库根目录 `screenshots/expiry-check/`。

![首页初始状态](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/expiry-check/preview-expiry-check-index.png)

![DEMO 加入 3 件样例后的临期清单（按紧急排序，2 件带 ! 紧急标记）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/expiry-check/preview-expiry-check-list.png)

## 解决的问题

牛奶、鸡蛋、酸奶塞在冰箱深处，包装上的到期日字小又难找，等发现时
已经过期。手机记备忘要掏手机、打字、设日期，还不会自己按紧急程度
排队。本 Agent 把流程挂在视线上：看哪包、拍哪包，日期确认后自动
入清单，临期自己喊你。

## 指向性设计（为什么必须用眼镜）

- **凝视即指向（GAZE）+ 长焦拍日期区**：看着包装，用
  `ImageCapture.takePhoto({mode:'telephoto'})` 拍包装上的日期区域 —
  你看着的那包就是要登记的那包，不用把食品一件件拿出来对手机。
- **头部稳定 = 凝视确认**：`enableWorldAwareness()` 开启世界感知后，
  `onOrientationStabilityChange` 报告头部稳定时才进入可用状态
  （HEAD STEADY）；点头（`onHeadGesture` 的 `nod`）第一次触发
  LOOK 拍照，拍照后再次点头即确认 ADD — 用点头代替腾手点按钮。
- **日期由用户确认（诚实边界）**：AIUI 运行时没有 OCR 接口，照片
  读不出日期。拍完照后，日期用步进器确认（FIELD 切年/月/日，
  ArrowUp/ArrowDown 调整，默认今天），物品名用语音确认
  （SpeechRecognition，zh-CN）；界面全程标注
  「user-confirmed, no OCR」，绝不冒充 OCR 结果。
- **清单在视线内常驻**：临期清单按到期日升序排在眼前，≤3 天高亮
  标「!」，过期标「EXPIRED」，抬头打开就知道先吃哪件；清单用
  wx 同步存储持久化，关掉重开不丢。
- **耳朵收警告**：SPEAK 用 `speechSynthesis.speak` 朗读由真实清单
  生成的临期摘要，不用盯着小字看。

## 功能流程

1. 看着包装的日期区域，稳住头 → 状态变 `HEAD STEADY`
2. 点头，或点 LOOK，或按 Enter / GlobalHook → telephoto 拍照，
   显示照片字节数
3. 确认日期：FIELD 按钮切换步进器聚焦字段（年/月/日，中括号标出），
   ArrowUp / ArrowDown 调整；确认名字：点 NAME 说出物品名
   （ASR zh-CN），无 ASR 时如实提示并轮换内置名称
   （牛奶/鸡蛋/酸奶/面包/剩菜）
4. 点 ADD 或再次点头加入清单（最多 6 项）：自动算剩余天数并
   按紧急程度重排，≤3 天标「!」，过期标「EXPIRED」
5. REMOVE 删除最紧急的一项，CLEAR 清空；清单经
   `wx.setStorageSync('expiryWatchlist', …)` 持久化
6. 点 SPEAK 朗读临期摘要（由当前清单实时生成）
7. DEMO 按钮：依次加入内置样例食品（到期偏移 +1/+2/+5/0/-1/+9 天
   轮换，名称带「(样例)」），预览即可看到排序与紧急标记

> 诚实说明：运行时没有 OCR，日期永远是用户确认的，不是照片识别
> 的；样例食品是内置演示数据，名称带「(样例)」标注，不冒充真实
> 登记记录。

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | 取流并用 telephoto 模式拍摄所看包装的日期区域 |
| RECORD_AUDIO | NAME 语音确认物品名（SpeechRecognition 捕获麦克风音频） |

相机/麦克风只在用户触发时启动：拍完立即停掉全部媒体轨道，
识别器在页面卸载时 abort。

## 打包与预览

```bash
cd ~/workspace/rokid/expiry-check
~/tools/bin/aix pack . -o ../dist/expiry-check.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-expiry.js`；清单截图的点击序列为 canvas 内 DEMO (234, 192) 连点 3 次）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-expiry-check`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 expiry-check」，在冰箱前看着包装稳住头、
   点头拍照，确认日期入清单

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 14.48 KB（本地打包 `dist/expiry-check.aix`） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 打包：`aix pack` 成功；`aix list` 核对包内含 README.md、AGENTS.md、
  app.js、app.json、package.json、pages/index/index.ink
  （artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：首页初始态完整渲染（步进器默认今天、月份聚焦）；
  DEMO 连点 3 次后清单出现牛奶（样例）/鸡蛋（样例）/酸奶（样例）
  3 项，按剩余 1 天 / 2 天 / 5 天升序排列，前两项带「!」紧急标记，
  头部计数与 URGENT 计数同步更新。

**未验证**

- 真机相机取流与 telephoto 模式拍日期区域的效果（预览主机无相机，
  LOOK 的 FAIL 路径已如实写明原因，真机待测）。
- 真机 SpeechRecognition（zh-CN）说物品名的识别效果（预览走内置
  名称回退路径，真机待测）。
- 真机头部稳定检测、点头手势、TTS 朗读临期摘要的效果。
- **运行时没有 OCR**：日期一律用户确认，本 Agent 不做、也不声称
  做照片文字识别；这是已知的产品边界，不是待补的验证项。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Expiry Check keeps your fridge honest. Look at a food package and photograph its date area in telephoto mode, then confirm the expiry date with a glanceable stepper or by voice. The agent computes days left, keeps a persistent watchlist sorted by urgency, flags anything within 3 days, marks expired items, and reads the near-expiry summary aloud so nothing quietly goes off.

### Opening Message

Hi, I'm **Expiry Check** — I watch your food dates so nothing expires unnoticed.

Aim at a package, hold your head steady, then nod or tap **LOOK** to photograph its date area. Confirm the date with the stepper (tap **FIELD** to switch year/month/day, arrow keys to adjust) and tap **NAME** to say the item. Tap **ADD** or nod again — I compute the days left and keep the list sorted by urgency. Tap **SPEAK** to hear what needs eating first, or **DEMO** to try sample items.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-expiry-check-index.png`（aix preview 首页：EXPIRY CHECK 初始态，含日期确认框、步进器（默认今天）、LOOK/FIELD/NAME 与 ADD/DEMO/SPEAK 按钮及空清单，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-expiry-check-list.png`（DEMO 加入 3 件样例后的清单态：按剩余天数升序、2 件带「!」紧急标记、URGENT 计数，本地文件）
- Video：待真机补 — 真机录制「看包装 → 点头拍照 → 确认日期 → 加入清单 → 朗读临期提醒」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Gaze-directed expiry logging: head-stability gaze confirmation (HEAD STEADY), nod to photograph and nod to confirm, ImageCapture telephoto-mode photo of the package date area, with wx camera fallback.
- Honest date confirmation with no OCR: a year/month/day stepper (FIELD cycles focus, arrow keys adjust, today by default) plus item names by SpeechRecognition (zh-CN) with a built-in name-cycle fallback when ASR is unavailable; the UI labels every date as user-confirmed.
- Persistent watchlist of up to 6 items in wx sync storage, sorted by days left with automatic day counts, "!" flags within 3 days and EXPIRED flags; REMOVE drops the most urgent item, CLEAR empties the list.
- SPEAK reads a near-expiry summary generated from the actual list; DEMO adds rotating built-in sample foods so the sorted list and urgency flags are visible without camera or microphone.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
