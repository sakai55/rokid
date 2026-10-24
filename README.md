# meter-reader — 抄表助手（Rokid 眼镜 AIUI Agent）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-meter-reader
```


50 个「指向性生活问题」Agent 的第 27 个。水表、电表、燃气表
的数字又小、位置又高、光线又差，抄完写在纸上回头就丢，更
没人帮你算「这个月用了多少、比上个月多还是少」。眼镜就在
你脸上：抬头看表盘，长焦拍一张留底（只作你自己的视觉
副本，永不被读取），嘴里把数字逐位报出来，它解析成数值
**大字显示等你亲眼核对**，点 SAVE 才入账。USAGE 视图按
真实存入的读数算出本期用量，和上一期比，波动超过 ±50%
就亮出「用量异常」提醒你去查漏水、漏电、漏气。

## 预览截图

截图统一存放于仓库根目录 `screenshots/meter-reader/`。

![READ 模式：空历史初始态（METER 电表 / READ 待报 / USAGE 与 COMPARE 占位行完整渲染）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/meter-reader/preview-meter-reader-index.png)

![USAGE 模式：DEMO 播种两块表各 3 条后选水表（本期 44 吨 · 上期 20 吨，「! 用量异常： 比上期多 120% — 查漏水」）](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/meter-reader/preview-meter-reader-usage.png)

## 解决的问题

抄表的难不在抄，在**记与比**：读数抄在烟盒、便签上，月底
找不齐；就算攒齐了，也没人愿意手算每期用量、再和上期比。
结果漏水漏电往往拖到账单翻倍才发现。眼镜把抄表压缩成
三步——看表盘（拍照留底）、报数字（逐位说出来）、点保存
（核对后入账），用量与异常从此自动算：每期用量 = 本次
读数 − 上次读数，异常 = 与上一期相差超过 ±50%。

## 指向性设计（为什么必须用眼镜）

- **看表盘 = 长焦留底（诚实定位）**：`ImageCapture.takePhoto
  ({mode:'telephoto'})` 对着高处小字表盘拍一张当你的视觉
  副本。运行时没有 OCR——照片永远不会被读取，表盘上的
  字一个也不会被识别。历史里的读数只来自你亲口报的数；
  照片是给你日后和物业对账看的，不是给机器读的。
- **报读数 = 解析后大字核对（读数永不自动保存）**：READ 先
  按文档方式做佩戴者模式（`microphoneMode:'wearer'`）
  麦克风检查——4 麦优先收你自己的声音，压过表箱间的回声
  ——再用 SpeechRecognition（zh-CN）听你报数。内置解析器
  两种报法都认：逐位报（「一二三四五」「12345」「幺二三
  四五」「一零二三」逐字拼接）和成数报（「八千三百二十
  一」= 8321、「九万九千九百九十九」= 99999，可带「…点
  五」小数尾）。解析结果大字显示在 READ 行：数字正是 ASR
  最容易听错的东西，所以必须你**亲眼核对**后点 SAVE
  （或 Enter）才入账；点头只朗读核对，绝不保存。差一位
  不用重报，FINE −1 / +1 / +10 修正；解析失败如实显示
  原文与「parse FAIL」，主机没有识别能力时如实 SKIP。
- **倒退拦截 + 换表基线**：表盘不会倒转。新读数比该表上次
  读数还小时 SAVE 直接拒绝并提示「听错了？换表点 NEW
  METER」——小的数要么是听错、要么是换了表。真换表先点
  NEW METER 武装一次，下一笔以换表基线存入：基线之后的
  用量从基线起算，任何比较都不跨换表断点。
- **用量汇总 = 真算**：每笔存 {表， 读数， 日期， 时间} 到
  wx 同步存储（`meterReadings`，总上限 36 条，超出丢最
  旧的）。USAGE 按存储顺序取同表相邻两期算用量，异常只
  比同一块物理表未断链的相邻两期，且波动须**超过** ±50%
  （恰好 50% 不算）且上期用量为正。SPEAK 朗读：「水表
  本期用量 44 吨。上期 20 吨。用量异常，比上期多 120%，
  查漏水。」异常只是「去看一眼」的提醒，不是漏损诊断。

## 功能流程

1. 站到表前：点 LOOK 长焦拍表盘留底
2. METER 选表（水表 / 电表 / 燃气表），点 READ 报出读数
   （逐位报最稳）；看 READ 行的大字核对——不对就 FINE
   微调或重报
3. 点 SAVE 入账；若被倒退拦截，先想清楚是听错还是换表：
   听错重报，换表点 NEW METER 再 SAVE
4. 点 USAGE 看本期 vs 上期用量；点 SPEAK 听它念；有
   「用量异常」就去查对应的漏水 / 漏电 / 漏气
5. DEMO 仿真：点 DEMO 用运行时 Date 的一次快照播种两块
   表各 3 条（电表 8120 → 8350 → 8620，用量 230 → 270，
   +17% 平稳；水表 320 → 340 → 384，用量 20 → 44，
   +120% 异常），直接切到 USAGE 并选水表看异常行

## 权限

| 权限 | 用途 |
|---|---|
| CAMERA | LOOK 长焦拍表盘留作你自己的视觉副本；照片只取字节数显示，从不被读取或识别 |
| RECORD_AUDIO | READ 报读数：先做佩戴者模式（wearer）麦克风可用性检查，识别由系统 SpeechRecognition 完成；只保存你确认过的读数文本，不录音、不保存音频 |

## 打包与预览

```bash
cd ~/workspace/rokid/meter-reader
~/tools/bin/aix pack . -o ../dist/meter-reader.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

本地预览截图走 `~/workspace/preview-tools/` 的本地 Ink + puppeteer 路线
（`shot-meter.js`；SEQ_B = 点 DEMO 一次（canvas 坐标 240,321）
播种两块表并切到水表 USAGE 异常视图）。

## 真机测试（海外版 · 云端下发 · Path 1）

1. 推到 GitHub 后，Global AIUI Studio（aiui-global.rokid.com，en-US）用
   分支导入：`https://github.com/sakai55/rokid/tree/agent-meter-reader`
   （该分支根目录即本 Agent 文件）
2. Studio 的 **Device Debug** 页签填 Basic Information，在 AIX Packaging
   点 **Repackage and Save**，确认顶部出现绿色
   **● Debug version ready — Ready for device debugging**
3. **Hi Rokid**（海外版 `com.rokid.sprite.global.aiapp`，不是国内版
   Rokid Ai App）→ 设置 → 开发者选项 → AIUI → 更新眼镜资源包，
   等「智能体资源包下载成功」
4. 对眼镜说「乐奇，打开 meter-reader」，在真实表箱前连抄
   几次：重点核对 ① READ 逐位报数在楼道环境音里的解析准
   确率（逐位报与成数报各试几次，核对环节是否够用）② 倒
   退拦截是否如期挡住故意报错的数、NEW METER 基线流程是
   否顺手 ③ LOOK 长焦拍高处表盘的清晰度（日后对账看不看
   得清）④ USAGE 用量与异常提醒是否与手算一致

## 真机测试信息（Global AIUI Studio · Device Debug）

| 项目 | 值 |
|---|---|
| Agent Name（Studio） | 待导入后回填 |
| Version（Build） | 1.0.0（待导入后回填） |
| App Category | 待导入后回填 |
| Intent Description | 待导入后回填 |
| Agent ID | 待导入后回填 |
| AIX Package Size | 约 22.0 KB（本地打包 `dist/meter-reader.aix`，含本 README；打包时间戳使字节数有 ±0.01 KB 抖动） |
| 状态 | 本地完成，待导入 Studio |
| Studio | aiui-global.rokid.com（en-US） |
| 下发方式 | 云端下发 → Hi Rokid（海外版）更新眼镜资源包 |

## 验证情况

**已验证**

- 静态检查：app.json / package.json JSON 解析通过；`<script def>` JSON
  解析通过；`<script setup>` 与 app.js 提取后 `node --check` 语法通过；
  全目录 grep 无 `Page(` / `App(` / `Widget(` / `workers:` 残留。
- 解析器与用量数学：用 Node 加载真实页面对象（wx 存根）跑
  68 条断言全过——解析电池：一二三四五→12345、12345→12345、
  八三二一→8321、一零二三→1023、1234.5→1234.5、八千三百
  二十一点五→8321.5、九万九千九百九十九→99999、二百→200、
  幺二三四五→12345、一万二千三百四十五→12345、8千3百21
  →8321，不可解析的输入（「你好」「表是多少」等）一律返回
  null 不猜数；用量：电表 230 → 270 为 +17% 不报警，水表
  20 → 44 为 +120% 报警；边界：恰好 +50% / −50% 不报警，
  +51% / −51% 报警；倒退拦截：8350 之后报 8000 被拒存，
  NEW METER 武装后以基线存入且其后用量从基线起算、比较
  不跨基线；无待确认读数时 SAVE 不存任何东西，FINE 能把
  近误修正后再入账；36 条上限丢最旧；wx 存储往返读回
  一致；DEMO 播种后水表异常行与用量行真实渲染、重复点
  DEMO 不堆积。
- 打包：`aix pack` 成功（大小见上表）；`aix list` 核对包内含
  AGENTS.md、app.js、app.json、package.json、README.md、
  pages/index/index.ink（artifacts/ 已被 .aixignore 排除）。
- 预览渲染：aix preview + 本地 Ink + puppeteer 截图两张（见下方
  Preview Media）：READ 空历史态完整渲染（METER/READ/
  HEARD/PHOTO/HISTORY 五行、四排按钮与汇总框齐全）；USAGE
  态 DEMO 播种后显示水表读数行（384 吨 · 本期 +44 /
  340 吨 · 本期 +20）与汇总框「本期 44 吨 · 上期 20 吨」
  及异常行「! 用量异常： 比上期多 120% — 查漏水」，与
  Node 断言一致。预览主机无相机与 SpeechRecognition，
  LOOK 的 FAIL 路径与 READ 的 SKIP 路径已在代码中实现
  并通过静态检查。
- **预览主机时钟说明（如实）**：本地 Ink 预览运行时的 `Date`
  是虚拟化的（月份在不同会话间漂移），因此预览截图里的
  日期是该虚拟时钟的日期，不是真实日历日期；DEMO 播种已
  改为从一次时钟快照以纯字符串推导全部日期与时间（三个月
  的月份间隔、用量的差值在截图中内部自洽）。用量数学只依
  赖读数值、与时钟无关。真机使用真实时钟，日期以设备
  时钟为准。

**未验证**

- 真机上 READ 报读数的端到端准确率——逐位报数是解析最
  稳的报法，成数报法（方言、「幺」以外的读法）解析器不
  保证，这是本 Agent 真机测试的第一号未知数；「大字核
  对 + FINE 微调 + 倒退拦截」是为此设计的三重兜底。
- 真机长焦拍高处表盘的清晰度与日后对账可用性、佩戴者
  模式（wearer）麦克风检查在真机上是否被接受、TTS 中文
  播报效果。
- wx 同步存储在眼镜重启后是否持久（跨月用量历史依赖它）。

---

## 提审资料（Review Submission）

> Global AIUI Studio → Submit 页签的 Review Information 逐项对应下面四段，
> 提交时整段复制。每次提交前重新确认 Preview Media。

### Feature Description

Meter Reader logs water, electricity and gas readings without ever reading the dial for you - no OCR. Photograph the dial telephoto as your record copy, tap READ and say the number, digit by digit or whole; the parsed value shows big for you to eyeball and fix before SAVE. A lower-than-last reading is blocked unless you mark a meter replacement. USAGE compares this period with the last and flags swings beyond 50 percent.

### Opening Message

Hi, I'm **Meter Reader** - I remember your water, electricity and gas readings, and I never pretend to read the dial (no OCR here). **LOOK** photographs it as your copy. **READ** listens to you say the number - digit by digit is safest - and shows it **big**: *check it*, only **SAVE** stores it, and a number lower than last time is blocked unless the meter was replaced. **USAGE** then shows this period versus the last and flags swings over 50%.

### Preview Media

提交要求：3–5 个 JPG/PNG 图片或 MP4 视频，至少含 1 张图和 1 个视频，每次提交前重新确认。

- Image 1：`artifacts/preview-meter-reader-index.png`（aix preview READ 态：空历史，METER 电表 / READ 待报 / USAGE 与 COMPARE 占位行完整渲染，本地文件，提交时从本地上传）
- Image 2：`artifacts/preview-meter-reader-usage.png`（USAGE 态：DEMO 播种后水表本期 44 吨 · 上期 20 吨与异常行「! 用量异常： 比上期多 120% — 查漏水」，本地文件）
- Video：待真机补 — 真机录制「LOOK 拍表盘 → READ 逐位报数 → 大字核对 → SAVE 入账 → USAGE 用量 + SPEAK 朗读」全过程（MP4），录好后放 `artifacts/` 并更新此处
- 状态：未齐（已有 2 张图；还需至少 1 个视频，总数补到 3–5 个后才可提交）

### Change Log

#### Build 1.0.0

**Features added**

- Dictated readings with a verify-before-save step: READ runs a one-shot zh-CN SpeechRecognition after a documented wearer-mode microphone check, and a built-in parser turns the spoken dial number into a value - digit-by-digit speech ('yi er san si wu', '12345', including 幺 for 1 and 一零二三 with its zero) and whole-number Chinese numerals （八千三百二十一 = 8321, 九万九千九百九十九 = 99999, optional decimal tail) alike. The parsed value is shown in big type and is NEVER auto-saved: SAVE (button or Enter) is the only way in, FINE -1/+1/+10 corrects a near-miss parse, unparseable dictation fails honestly with the raw heard text shown, and a head nod only reads values back - it cannot save.
- Backwards-reading block with a meter-replacement baseline: a new reading lower than the meter's stored last reading is refused with the reason on screen ('misheard? replaced?'), because dials do not run backwards; arming NEW METER stores the next value as a fresh baseline instead - usage after a replacement is computed from the baseline and no comparison ever crosses the swap.
- Per-meter history with period usage and anomaly flag: readings {meter, value, date, time} persist in wx storage (key meterReadings, up to 36, oldest dropped beyond the cap) for water （吨）, electricity （度） and gas （立方米）; the USAGE view computes the latest period's usage against the previous period of the same physical meter and flags swings beyond +/-50 percent (exactly 50 percent is not flagged) with a meter-specific check hint (water leak / electricity leak / gas leak), and SPEAK reads the usage summary aloud; DEMO seeds three months of electricity (normal, +17%) and water (anomalous, +120%) readings from a single clock snapshot so the previewed anomaly is genuinely computed.

**Improvements**

- None (initial release).

**Fixes**

- None (initial release).
