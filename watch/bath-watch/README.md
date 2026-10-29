# 浴缸守望 bath-watch

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-bath-watch
```

**AIX 直接下载**（最新版）：[bath-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/bath-watch.aix)


注意力外挂系列 **WA02**（守望型 WATCH）· Rokid 眼镜 AIUI Agent

站在浴缸边看一眼登记，倒计时在你视线里走着，你尽管去收
拾行李；估时到 80% 它先叫你准备，到 100% 它按「相对
你的方向」叫你回去，并把提醒留在眼前，直到你真的走回
浴室看回浴缸——回看本身就是确认。

## 预览截图

![初始界面：还没登记浴缸，提示站在浴缸边点 SET](<../../screenshots/bath-watch/preview-bath-watch-index.png>)

![DEMO：放水途中水声电平早早掉落，收到一次电平提醒](<../../screenshots/bath-watch/preview-bath-watch-drop.png>)

![估时走完报警后转头看回浴缸，回看确认（face）闭环](<../../screenshots/bath-watch/preview-bath-watch-acked.png>)

## 解决的问题

浴缸放水是最典型的「守着干等」：水龙头一开，人就被拴在
浴室门口——走开去收拾行李、叠衣服，回来不是还差一大截
白等，就是已经溢了一地。问题不在水龙头，在于「估算水什
么时候满」这件事需要一个人持续分神去盯，而人一忙就忘。

本 Agent 外包的正是这份「守着放水」的注意力：登记之后，
倒计时由它数着；到点之前它先喊你准备，到点它按方向喊
你回去；确认不靠你按键，而是你真的走回去看了一眼——注
意力闭环就此合上。

## 注意力外包设计

- 外包哪种注意力：**守望型（WATCH）**——持续低强度
  的时间监视，外加一层「环境声变了没有」的余光。它不
  需要你的眼睛，只需要一个不走神的时钟、一个知道
  「浴缸在哪个方向」的登记簿，和一条只测响度的电平
  流。
- 为什么必须是眼镜（胸前设备做不了）：登记与确认都长
  在视线轴上。登记 = 你站在浴缸边看着它点 SET，头部
  朝向（`AbsoluteOrientationSensor`）就是浴缸的地
  址；提醒 = 按相对方向喊「右后方的浴缸满了，回去关
  水」，你拎着行李箱不用读屏就知道往哪走；确认 = 你
  走回去看回浴缸、停满 1 秒，回看动作本身完成确认。
  胸前挂的设备看不见你看向哪里，也没法把「你刚才真
  的回头看了一眼」变成信号——它的提醒只能靠你掏出
  手机按键确认，注意力闭环断在最后一公里。
- 两段提醒而不是一段：80% 先给「准备回去」的预告，
  100% 才正式报警——人从行李堆里抽身需要缓冲，只
  有到点才喊的提醒，实测总是慢一拍。
- 电平守听只是加层，不是主菜：水声电平在前半段早早
  掉下去时它多提醒一次；没有这层，倒计时闭环也完整
  成立。

## 功能流程

1. 登记（SET）：站在浴缸边，看着浴缸，单击触控板
   （或点 SET）打开登记；下滑换缸大小（小 / 标准 /
   大），上滑换估满时长（5 / 10 / 15 / 20 分钟），再
   单击开始。这缸水从此绑定当前朝向。一次只守一缸；
   放水中再点 SET 只武装替换，再点一次打开登记、确
   认后才换掉当前这缸。放水中点 TIME 可加 2 分钟。
2. 守望：界面随时显示剩余时间、已走百分比与浴缸相对
   你当前脸朝向的方向（「浴缸在你右后方」）。方向永
   远是相对量，不报东南西北。
3. 预警（80%）：TTS 朗读一次「浴缸快满了，准备回去
   关水」。
4. 正式报警（100%）：TTS 按当时的相对方向朗读一
   次，如「正后方的浴缸满了，回去关水」；横幅留在眼
   前，不重复喊。
5. 回看确认：走回浴室看向浴缸——头稳住、朝向落入登
   记朝向 ±15° 内，入锥只算开始、再连续停满 1 秒
   ——即确认（记 `face`）；也可点 ACK（记 `tap`）。
   快速扫过不算，离开锥形区重新计时。
6. 守听（LISTEN，可选）：开启后全向麦克风流只喂一
   个电平表；先听到持续水声电平，之后电平掉到近静
   默持续满 8 秒、且掉落是在估时前半段开始的，提醒
   一次「水声电平掉下去了，去看一眼浴缸」（每缸一
   次）。关页面或再点一次 LISTEN 立即停麦。
7. DEMO：播入一缸演示水（估时 5 分钟、已放 35%，
   浴缸在正前方、演示头背对着它，守听以模拟电平开
   启）；每点一次 DEMO 朝向 +45° 并快进估时 8%，
   可依次预览早段电平掉落提醒、80% 预警、正式报警
   与回看确认；转完一圈多后再点一次退出并恢复你真
   实的这缸水，全程不写任何存储。

## 手势映射

档案 §3.2.1 触控板手势。登记、计时、两段提醒、回看确
认全流程可仅用手势与转头完成；按钮只作兜底与发现入
口。

| 手势 | 系统键 | 本 Agent 行为 |
|---|---|---|
| 单击 | Enter | 情景主操作：登记中 = 开始计时；浴缸等回看 = 确认（tap）；替换已武装 = 打开登记；未登记 = 打开登记；放水中 = 朗读状态 |
| 上滑 | ArrowUp | 登记中 = 换估时档（5→10→15→20 循环）；其余时候无选中项可换（一次一缸） |
| 下滑 | ArrowDown | 登记中 = 换缸大小（小→标准→大循环）；其余时候无选中项可换（一次一缸） |
| 双击 | Backspace | 返回（宿主处理，本页不拦截） |
| 头部稳定时点头 | `onHeadGesture('nod')` | 只朗读状态——点头永不登记、永不确认（防误触；确认只认回看或单击） |
| 转头看回浴缸并停稳 1 秒 | 朝向传感器 + 稳定事件 | 回看确认（face）：浴缸朝向 ±15° 内、头稳住、入锥后再连续 1 秒 |

保留的 6 个按钮及理由：SET 是登记入口（手势的单击与之
等价，但新用户需要可见入口）；TIME 是放水中加估时的唯
一入口；ACK 是不便转头时（如抱着一摞衣服侧身）的确认兜
底；LISTEN 涉及麦克风开启，必须有明确可见的开关，绝不
自动开麦；SPEAK 与点头等价，留给不方便点头的场景；
DEMO 是无浴缸环境下预览完整闭环的唯一入口。

## 权限

| 权限 | 用途 | 说明 |
|---|---|---|
| RECORD_AUDIO | 只在点 LISTEN 后开启全向 getUserMedia 流，喂 AnalyserNode 电平表做电平守听 | 音频从不录制/保存/上传；关页面立即停轨 |

倒计时、朝向登记、回看确认、TTS 都不需要任何权限。本
Agent **不写任何 wx 存储**——登记、剩余时间、电平都只
在本次会话内存里，页面关掉一切消失。

## 打包与预览

在本目录执行：

```bash
~/tools/bin/aix pack . -o ../dist/bath-watch.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

包文件 `bath-watch.aix`（约 23.5 KB），预览截图见上
（本地预览管线生成，artifacts/ 不入包）。

## 真机测试（Path 1）

1. 在 Global AIUI Studio 用 GitHub 子目录导入本分支：
   `https://github.com/sakai55/rokid/tree/agent-bath-watch`
2. Studio 里构建并保存新版本（Device Debug →
   Repackage and Save），等到云端打包完成提示。
3. 手机端打开海外版 Hi Rokid App：设置 → 开发者选项
   → AIUI → 更新眼镜资源包，等「智能体资源包下载成
   功」。
4. 对眼镜说「乐奇，打开浴缸守望智能体」，或在智能体列
   表里打开，然后按下面的清单验收。

真机验收清单（建议）：

- [ ] 站在浴缸边登记一缸（估时选短档如 5 分钟做测
      试），走开后方向词与浴室实际方位一致
- [ ] 80% 预警只喊一次；100% 报警只喊一次、方向正
      确；不转头时横幅一直在、不重复喊
- [ ] 走回浴室看回浴缸停满 1 秒：确认并显示 face；
      单击 ACK 路径同样成立；快速扫过不被确认
- [ ] 放水中点 SET：只武装替换、不丢当前缸；确认替
      换后新缸从头计时
- [ ] LISTEN 开启、水声正常时把水龙头关掉：约 8 秒
      后收到一次电平掉落提醒且措辞只有「电平掉下去
      了」；同一缸不再重复；估时后半段关水则不提醒
- [ ] LISTEN 状态下关页面重开：麦克风已释放（重开后
      是关闭状态）
- [ ] 故意把估时设短（如水龙头只开一半、估时按全开
      设）：确认报警后回看时水位未满——即 README 的
      「估时就是估时」诚实说明与实际一致

## 真机测试信息

| 字段 | 内容 |
|---|---|
| Studio 名称 | 待导入后回填 |
| Version / Build | 1.0.0（首版，待导入后回填 Build 号） |
| App Category | 待导入后回填（提审时按内容填写） |
| Intent Description | Bath Watch: look-to-register tub fill timer with 80% pre-alert and look-back acknowledgement |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成（静态校验 + Node harness 123/123 + 预览截图），未导入 Studio、未真机测试 |

## 验证情况

### 已验证

- 静态校验通过：app.json / package.json / `<script def>`
  JSON 解析；`<script setup>` 与 app.js 的 `node
  --check`；无 `Page(` / `App(` / `Widget(` /
  `workers:` 残留；按钮恰 6 个 bindtap。
- Node harness 123 条断言全过（wx / 朝向传感器 /
  getUserMedia / AnalyserNode / TTS 桩 + 手动 tick 驱
  动）：登记流程与无朝向拒绝、缸大小作为纯标签不改
  计时数学；并行于登记的持续倒计时、TIME 加 2 分钟；
  80% 预警单次触发（含 79% 不触发的边界）、100% 正
  式报警按相对方向朗读且仅一次、横幅留存；回看确认
  的锥形（±15°）与「入锥开始 + 连续 1 秒」语义（不
  足不确认、错向不确认）；替换的武装 + 确认两段语
  义（武装不丢缸、确认才换、朝向取打开登记那一
  刻）；点头永不登记/确认（只朗读状态）；电平守
  听：未听到水声前的静默不触发、2 秒水声才布防、4
  秒短掉落不触发、8 秒早段掉落只提醒一次且措辞为电
  平口径、同一缸第二次掉落不提醒、后半段才开始的
  掉落被静默消费并在事件行说明；
  OverconstrainedError 回退默认麦克风并如实标注；
  onHide 停麦停表；纯手势全流程（Enter/上滑/下滑完
  成登记与确认）；DEMO 播种、掉落提醒、预警、报
  警、回看确认、退出后真实缸原样恢复；**全程 wx 存
  储写入次数 = 0**；任何 utterance 的 `lang` 从未被
  设置；任何朗读文本从不声称检测到水位状态。

### 未验证

- **电平不是水位识别（最重要的边界）**：AIUI 运行
  时没有声音分类器，本 Agent 只测 RMS 电平。它不能
  分辨水声、吹风机、洗衣机和电视声；水龙头开得小
  时，水声电平可能根本过不了 0.2 的布防线，掉落提
  醒就不会成立；浴室回声、门开门关都会改变电平基
  线。0.2 / 0.08 两个阈值与 8 秒持续时长的「手感」
  只能在真实浴室里校准，本地预览无麦克风、无真实
  声场，未验证。
- **估时与真实水位的偏差**：80% / 100% 都是相对你
  设的分钟数。水压、水龙头开度、缸体形状都会让真实
  满溢时刻漂移——漂移量只能真机实测，本 Agent 不
  做任何水位推断。
- 宿主真机上 getUserMedia + AnalyserNode 的持续电平
  行为（采样稳定性、增益、与系统降噪的相互作用）未
  验证；`microphoneMode: 'omnidirectional'` 只作用
  于这条电平流，模式的真机可用性靠 getSettings 回
  读标注，未验证。
- 真机朝向传感器在浴室环境（转身、弯腰、蒸汽）的
  yaw 漂移与稳定事件表现未验证；±15° 锥形 + 1 秒
  停留的体感需真机调。
- TTS 在真机的播报音量与家中噪声下的可懂度未验
  证（本 Agent 无「喊第二遍」机制——如真机证明听不
  清，需重新设计，而不是偷偷重复播报）。
- 守望只在 Agent 打开时存在：息屏/退出后的行为以
  宿主为准，本 Agent 不做任何后台承诺。

## 提审资料 (Review Submission)

> Global Studio「提审」页逐项对应，导入后可直接抄录。

### Feature Description（473 字符，上限 500）

Bath Watch outsources the tub-filling wait. Stand at the tub and register it once: it binds to that head heading with your own fill-time estimate, then counts down while you go and pack. At 80 percent it calls you to get ready; at 100 percent it calls you back by direction, and the alert stays until you walk back and look at the tub. An optional level watch nudges you once if the water sound level drops away early. Level only; it never claims to sense the water itself.

### Opening Message（496 字符，上限 500，支持 Markdown）

Hi, I am **Bath Watch** - I keep the fill timer, you go pack.

Stand at the tub, look at it and tap **SET**: swipe down for the tub size, swipe up for your estimated minutes, tap again to start. I count down in your view and call you at **80%**, then again when your estimate runs out. The alert waits until you **look back at the tub** for a second - that glance closes the loop. Turn on **LISTEN** and I nudge you once if the sound level drops away early - level only; I cannot sense the water.

### Preview Media

提审要求 3–5 个文件，且至少 1 张图 + 1 个视频（视频
≤60 秒）。本地已生成 3 张预览图（见上方「预览截图」，
中央存于仓库 `screenshots/bath-watch/`）：

1. `preview-bath-watch-index.png` — 初始界面：空登记簿
   与诚实常驻行
2. `preview-bath-watch-drop.png` — DEMO：放水途中水声
   电平早段掉落，收到一次电平提醒
3. `preview-bath-watch-acked.png` — 估时报警后回看确认
   （face）闭环后的状态

视频（1 个，≤60 秒，真机拍摄「登记 → 预警 → 报警 →
回看确认」完整闭环）：**待真机测试时补拍**，补齐后再
提审。

### Change Log

**Build 1.0.0（首版）**

Features added:

- 看向浴缸登记：头部朝向绑定 + 缸大小/估时两维滑动选
  择；缸大小仅作标签，倒计时以佩戴者估时为准
- 两段叫回：80% 预警朗读一次，100% 按相对方向朗读
  一次 + 横幅留存，确认语义为「回看」（±15° / 入锥
  后连续 1 秒）或单击 ACK
- 替换两段确认：放水中再登记必须先武装再确认，绝不
  静默丢弃当前这缸
- LISTEN 电平守听：全向电平流；听到水声后、电平早
  段掉落持续 8 秒单次提醒；回落/后半段掉落不提醒
- DEMO 一缸播种（35% 进度 + 模拟电平），完整预览掉
  落提醒、预警、报警与回看确认闭环

Improvements:

- （首版，无）

Fixes:

- （首版，无）
