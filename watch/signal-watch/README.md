# Signal Watch（叫号守望）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-signal-watch
```


注意力外挂系列 WA04（WATCH 守望型）。医院、银行、取餐窗口叫号时，眼睛必须死盯大屏，闭眼歇一下就可能过号。本 Agent 的做法：佩戴者只在开始时用自己的眼睛看一眼大屏，把「你的号」和「当前号」填进来（步进器或口述），之后的盯屏工作交给节律提醒——每隔一段节律语音叫你回看一眼、更新当前号；只差 3 个号时提前喊你准备，到号时喊你，过号了就如实说过号。

![预览-填写](<../../screenshots/signal-watch/preview-signal-watch-index.png>)
![预览-演示回看](<../../screenshots/signal-watch/preview-signal-watch-demo.png>)
![预览-准备](<../../screenshots/signal-watch/preview-signal-watch-ready.png>)
![预览-到号](<../../screenshots/signal-watch/preview-signal-watch-called.png>)

## 解决的问题

叫号场景里，人的注意力被一块大屏绑架：不敢闭眼、不敢走神，因为错过没有回放。本 Agent 把「盯」外包给节律，把人的眼睛降级为每几分钟一次的「采样器」：看一眼、报个数，其余时间放心歇眼。速度与 ETA 只由佩戴者自己的更新算出，慢了快了都是真实节律的反映。

## 注意力外包设计

- **号码来自佩戴者的眼睛，永远如此**：MY（你的号）与 NOW（当前号）只能由佩戴者步进输入或口述输入——口述的是 ta 自己看到的那个号。Agent **不读大屏**（不截屏、不做屏幕识别）、**不听广播**（不识别叫号播报）；麦克风只收佩戴者本人的口述。
- **节律守望（WATCH）**：250 ms tick 引擎，全部计时用 tick 计数。回看节律 CAD 可选 1/2/5 分钟（默认 2 分钟）：到点语音一次「回看一下大屏，更新当前号」+ 横幅常驻，直到佩戴者更新 NOW（任一输入路径）或点 GO 稍后（LATER，恰好顺延一个节律）。
- **差值/速度/ETA 只来自你的更新**：每次 NOW 更新按 tick 打戳；速度 = 第一次打戳到最近一次之间前进的号数 ÷ tick 时间，并注明「据你的 N 次更新」（10 秒内的步进连点算一次回看）。ETA = 差值 ÷ 速度；更新不足或号码没前进时如实显示「rate unknown yet」，不编造。
- **三档状态，句句一次**：差 ≤3 → READY，语音一次「只差 N 个号了，准备过去」（差 4 不触发；差值重新大于 3 后会重新武装）；差 = 0 → CALLED，语音一次「到你的号了」，横幅直到点 DONE；更新显示 NOW > MY → PASSED，语音一次「已经过号了，去服务台问问」，界面明说已过几个，不假装没事。
- **开始前的诚实校验**：MY 必须大于 NOW，否则拒绝开始并问「你的号已经过了？」——已经过号的号码不进守望流程。
- **提醒只在本页打开时存在**：界面常驻一行明示。零持久化：不调用任何存储 API，号码只活在页面内存里，关页即忘。

## 功能流程

1. **SETUP**：FIELD 在「你的号 → 当前号 → 场馆」间切换当前编辑项；步进 +1/+10/−1 或滑动调整；DICT 口述你看到的号（先做佩戴者麦模式可用性检查，结果单独一行 MIC CHECK，再走宿主 ASR；中文数字与阿拉伯数字都能解析，解析不了就如实拒绝、绝不猜）；场馆（医院/银行/取餐/其他）只是标签。GO 逐项推进并开始守望（校验见上）。
2. **WATCH**：节律到点提醒回看 → 你看一眼大屏，步进/滑动/口述更新 NOW → 差值、速度、ETA 即时重算。任何时刻 SPEAK 或点头可听当前差值与 ETA。
3. **收尾**：CALLED/PASSED 后 GO = DONE 结束本轮；DONE 后 GO 开始全新一轮填写。

## 手势映射

主流程（填写 → 开始 → 回看更新 → READY/CALLED → DONE）只用滑动 + 单击（+ 点头听读）即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 主操作 GO（情境化）：填写时推进字段/开始守望；提醒待处理时 = 稍后（LATER）；CALLED/PASSED 时 = DONE；其余时候 = 朗读状态 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 当前数值 +1 / −1（填写与守望中更新 NOW 都用它） |
| 点头（头稳时） | `onHeadGesture('nod')` | 只朗读当前差值/ETA，绝不开始/更新/稍后/结束 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由；手术/排队场景手不方便时靠手势即可）：

| 按钮 | 理由 |
|---|---|
| +1 / −1 | 滑动的镜像，精确修正一位 |
| +10 | 大跨度赶步（当前号离你的号还远时连按滑动太慢） |
| FIELD | 切换编辑项（手势的 Enter 会逐项推进，FIELD 可任意跳回修改） |
| DICT | 口述输入你看到的号（双手占用/不想连按时的快速路径） |
| CAD | 切换回看节律 1/2/5 分钟（大厅快慢不同，需要现场调） |
| GO ✓ | Enter 的镜像（主操作） |
| SPEAK | 随时听差值/ETA（点头的镜像，头不方便动时用） |
| DEMO | 演示种子数据走完 READY→CALLED→PASSED 全程（提审/自测用） |

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | 仅用于佩戴者口述自己看到的号码（DICT）；口述前先做 getUserMedia 佩戴者模式可用性检查。Agent 不听广播、不录环境音 |

只申请 1 项。麦克风模式只作用于 getUserMedia 流，永不影响宿主 `SpeechRecognition`；聆听状态标注为 (host ASR)。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/signal-watch
~/tools/bin/aix pack . -o ../dist/signal-watch.aix
~/tools/bin/aix list ../dist/signal-watch.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-signal-watch`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Signal Watch 智能体」。
5. 验收点：医院/银行真实排队场景走完一轮（填写 → 节律提醒 → 更新 → READY → CALLED）；故意填错一次大小关系，确认被拒绝并听到「你的号已经过了？」；故意更新到过号，确认如实进入 PASSED；DICT 口述中文数字（如「一百二十八」）能填入且可核对；闭眼等待一个节律，确认只提醒一次且横幅等到更新/稍后才消失；关掉本页后确认不再有任何提醒（设计如此）。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Signal Watch（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Queue-number look-back watcher: wearer-entered numbers, cadence look-back prompts, ready/called/passed alerts. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**

- 静态校验：三处 JSON 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(`/`workers:` 误用。
- Node harness 105 条断言全过：开始校验（含 MY≤NOW 诚实拒绝并语音发问）、步进口述双路径录入（含中文数字解析、二百五/一千二等进位读法、垃圾口述如实拒绝、麦克风检查先于 ASR 的顺序断言）、节律每个间隔只响一次 + 稍后顺延整整一个节律 + 更新 NOW 重置节律、差值/速度/ETA 按 tick 打戳更新计算（含连点算一次更新、回退修正后速度诚实归零）、READY 在差 3 触发（差 4 不触发）且可重新武装、CALLED 在差 0、PASSED 在更新过头时如实出现、纯手势全程走通、点头只朗读、全程零 wx 调用、TTS 从不设置 lang。
- `aix pack` 成功（约 20.4 KB），`aix list` 确认 README.md 在包内、artifacts 已排除。
- 预览截图 4 张已生成并逐张目检：EVT 行与底部常驻诚实行均在画面内（点击坐标经帧哈希探针标定）。

**未验证（如实说明）**

- **号码只能由佩戴者提供，这是设计边界而非缺陷**：本 Agent 没有读屏能力（平台无此 API 路径供本场景使用），也不会听叫号广播；速度/ETA 的准确性取决于佩戴者回看更新是否及时，更新越稀疏估计越粗。
- 节律提醒只在本 Agent 页面打开期间触发；关页、切走或眼镜息屏后的行为以真机为准，本 Agent 不声称后台提醒。
- 宿主 ASR 对中文数字的真实识别率、嘈杂大厅里的口述可用性、宿主 TTS 实际发声、宿主的头部手势/稳定性事件投递，均待真机验证；DICT 在宿主 ASR 不可用时如实 SKIP，步进路径始终可用。
- getUserMedia 佩戴者模式在真机上的 settings 回读值待真机确认；检查失败不阻塞口述（口述走宿主 ASR，与麦模式无关）。

## 提审资料 (Review Submission)

### Feature Description（482 字符）

> Queue watcher for clinics, banks, food counters. Read the hall screen once with your own eyes: enter your number and the number now called, by stepper or dictation. The agent owns the staring: it prompts a look-back every 1/2/5 min, tracks the gap, estimates pace and a rough ETA from your updates, speaks when 3 numbers remain, calls out at your number, and says plainly if it passed. It never reads the screen or hears announcements; reminders run only while open, nothing stored.

### Opening Message（446 字符）

> ## Signal Watch
>
> Staring at the call screen so you don't miss your number? Enter **your number** and the **number now called** — both read by your own eyes, stepped in or dictated. Then rest your eyes: I'll prompt you to look back every few minutes, track the gap from your updates, warn you at 3 to go, and call out when it's you. If it already passed, I'll say so plainly.
>
> *Numbers come from you — I never read the screen or listen to the PA.*

### Preview Media

- `preview-signal-watch-index.png` — SETUP 填写（双号未填，场馆标签与编辑指南）
- `preview-signal-watch-demo.png` — DEMO 守望中：回看提醒待处理（MY 128 / NOW 117，差 11）
- `preview-signal-watch-ready.png` — READY：只差 2 个（演示更新至 126），速度/ETA 来自演示更新
- `preview-signal-watch-called.png` — CALLED：到号横幅（演示更新至 128）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 双号填写（步进 + 口述双路径，口述支持中文数字，进位读法与 DI25 同源解析）+ 开始前 MY>NOW 诚实校验
- 节律回看守望（1/2/5 分钟可选）：语音提醒 + 横幅待办，更新消解或顺延一个节律
- 差值/速度/ETA 实时计算，速度只来自佩戴者自己的打戳更新并如实标注样本数
- READY（差 ≤3）/ CALLED（差 0）/ PASSED（已过号）三态各语音一次，PASSED 明说不掩饰
- 纯手势主流程（滑动调值、单击情境主操作、点头只朗读）+ DEMO 全程演示

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
