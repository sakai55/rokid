# My Bus Watch（等车守望）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-my-bus-watch
```

路缘坡效应系列 C02（FILTER 守望型）。全盲或低视力的人等某一路公交，最难的不是「车来了没有」，而是「来的这辆是不是我的那一路」：车头号看不见，问路人要看运气，坐错车比错过车更麻烦。本 Agent 只守你登记的那一路：听到车声，对准车头点 CHECK，它拍长焦照片、让主机大模型只读车头线路号、跟目标比对，只报一个结论——就是这辆，上车；或者这辆是 X 路，不是你的，继续等。其他车一律过滤，不出声。

## 预览截图

![预览-初始设置](<../screenshots/my-bus-watch/preview-my-bus-watch-index.png>)
![预览-演示开始](<../screenshots/my-bus-watch/preview-my-bus-watch-demo.png>)
![预览-守车中](<../screenshots/my-bus-watch/preview-my-bus-watch-watch.png>)
![预览-不是这辆](<../screenshots/my-bus-watch/preview-my-bus-watch-miss.png>)
![预览-就是这辆](<../screenshots/my-bus-watch/preview-my-bus-watch-hit.png>)

## 解决的问题

等车对视障者是一个过滤问题，不是识别问题：站台上每辆车都要判断一次，判断成本全落在「看不见」的人身上。眼镜在这里的价值不是「替你看世界」，而是**替你守一个目标**：你只管听车声、转头对准车头，核对与比对交给它，结论只在命中或换车时才出声。普通人低头玩手机等车、戴耳机听不清报站、行李挡着视线时，同样会坐错车或错过车——这就是路缘坡效应的溢出：先为看不见车头号的人把「只对一路车出声」做扎实，暂时看不清的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：全盲/低视力者，等特定一路公交，通道断的是「车头线路号的读取与比对」——拿掉这类人群，本 Agent 立刻不成立：健全人看一眼车头号就能完成判断，不需要守候与过滤。
- **② 通道改造**：语音是主通道，零屏幕依赖。所有指令、结论、提醒都由 TTS 播报一次；操作只有点头（头稳时 = CHECK 拍车头）、单击（情境 GO）、滑动（调线路号）。屏幕只是给有视力帮手和预览看的镜像，流程本身不依赖它。
- **③ 溢出地图**：普通人在这些情境下会用它：低头族等车、戴降噪耳机、夜里站台灯光差、拉着行李背对车流——都是「暂时看不清/听不清车头号」的时刻。

## 注意力外包设计（FILTER 守望型）

- **目标先行，结论后行**：SETUP 必须先填目标线路（>0）才能开始守车；没填目标拒绝开始并明说。目标一旦开始守，FIELD 可在目标与上辆之间切换修正，防填错。
- **CHECK 只核一件事**：`telephoto` 长焦拍车头 + 主机 LLM，提示词写死为「只回答线路号数字，例如 128；读不清回答 NONE，不要解释」。解析只取第一个 1–4 位数字；读不清、无数字、超范围，一律记为 SKIP，守车继续，绝不猜一辆车出来。
- **每个新上辆值只判一次**：命中 → HIT 语音一次「就是这辆，Y 路，上车吧」，横幅直到 GO（已上车）；不命中 → 语音一次「这辆是 X 路，不是你的 Y 路，继续等」；同一上辆值重复出现不再重播。查车次数只计新值，不计重复。
- **2 分钟留意节律，只在本页打开时**：250 ms tick 引擎计 tick，每 2 分钟在守车中语音一次「留意一下有没有车来」，直到下一次 CHECK / 上辆更新或 GO 稍后（恰好顺延一个节律）。关页即停，界面常驻行明示。
- **与慧眼的分工**：慧眼是通用「看图识物/读字」——问一句、答一句。本 Agent 不做通用场景描述：它不回答「站台上有什么」，只解决「来的这辆是不是我登记的那一路」这一个闭环。识别只在 CHECK 一步里出现，且只问车头线路号。
- **手动备用路径**：相机或 LLM 不可用时，步进（+1/+10/−1、滑动）与 DICT 口述（先做佩戴者麦模式可用性检查，结果单独一行 MIC CHECK，再走宿主 ASR；支持阿拉伯数字与中文数字，解析不了如实拒绝、绝不猜）填入上辆线路，走同一套比对逻辑。备用路径不是第二套标准，结论口径完全一致。
- **零持久化**：不调用任何存储 API；目标与查车记录只活在页面内存里，关页即忘。

## 功能流程

1. **SETUP**：FIELD 在目标线路 ↔ 上辆线路间切换当前编辑项；步进 +1/+10/−1 或滑动调整；DICT 口述线路号（先 MIC CHECK 再 host ASR）。GO 开始守车（目标未填拒绝）。
2. **WATCH**：每 2 分钟语音提醒留意车声；听到车声，对准车头点 CHECK（或头稳点头）拍车头核线路；或步进/口述填入上辆线路。命中 → HIT 横幅；不命中 → 继续等；没读清 → 再对准一点。
3. **收尾**：HIT 后 GO = 已上车（DONE）；DONE 后 GO 开始全新一轮。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO：SETUP 时开始守车；提醒待处理时 = 稍后（顺延一个节律）；其余守车时 = 朗读状态；HIT 时 = 已上车；DONE 时 = 新的一轮 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 当前编辑项 +1 / −1（目标或上辆线路都用它） |
| 点头（头稳时） | `onHeadGesture('nod')` | 守车中 = CHECK 拍车头；其他阶段 = 只朗读，绝不开始/结束 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| +1 / −1 | 滑动的镜像，精确修正一位 |
| +10 | 大跨度赶步（线路号两三位数时连按滑动太慢） |
| FIELD | 切换编辑项（目标 ↔ 上辆，填错目标时可修正） |
| DICT | 口述线路号（双手占用/不想连按时的快速路径，先 MIC CHECK 再 host ASR） |
| CHECK | 拍车头核线路（点头的镜像，头不方便动时用） |
| GO ✓ | Enter 的镜像（情境主操作） |
| SPEAK | 随时听守车状态（点头的镜像） |
| DEMO | 演示：目标 128 路 → 来了 56 路（不是）→ 来了 120 路（不是）→ 来了 128 路（命中）；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `CAMERA` | CHECK 拍车头（`telephoto` 长焦）；拍不到或 LLM 不可用时如实 SKIP，改用步进/口述 |
| `RECORD_AUDIO` | 佩戴者口述线路号（DICT）；口述前先做 getUserMedia 佩戴者模式可用性检查。Agent 不听报站、不录环境音 |

只申请 2 项。麦克风模式只作用于 getUserMedia 流，永不影响宿主 `SpeechRecognition`；聆听状态标注为 (host ASR)。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/my-bus-watch
~/tools/bin/aix pack . -o ../dist/my-bus-watch.aix
~/tools/bin/aix list ../dist/my-bus-watch.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-my-bus-watch`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 My Bus Watch 智能体」。
5. 验收点：真实站台走完一轮（登记目标 → 听到车声对准车头 CHECK → 非目标车报「不是这辆」→ 目标车报「就是这辆」）；故意把车头对偏/遮挡一次，确认如实 SKIP 且守车继续；DICT 口述中文线路号（如「一百二十八」）能填入且可核对；等满 2 分钟确认只提醒一次且横幅等到 CHECK/稍后才消失；关掉本页后确认不再提醒（设计如此）。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | My Bus Watch（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Target-route bus watcher: register one route, photo-check each approaching bus head sign, speak only the match/miss verdict. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（CAMERA 只在 CHECK 路径，RECORD_AUDIO 为 DICT 语音通道）。
- `aix pack` 成功（约 17.4 KB），`aix list` 确认 artifacts 已排除、包内为 6 个源文件。
- 预览截图 5 张已生成并逐张目检：初始设置、演示开始、守车中、不是这辆（上辆 120 路，查车 2 次）、就是这辆（命中 128 路，查车 3 次）各状态均与设计一致；DEMO 点击坐标经探针标定（400, 250）。

**未验证（如实说明）**
- 宿主 TTS 实际发声、头部手势/稳定性事件在真机上的投递、车头 `telephoto` 拍照与 LLM 读线路号的真机表现（远距离、反光、车头号字体、夜间）均待真机验证；CHECK 在任何一步缺失时如实 SKIP，手动备用路径始终可用。
- 本 Agent 不判断车辆是否停靠本站、不判断车门位置、不保证目标车一定会在本站停车；命中只表示「这辆车的车头号是目标线路」，上车前仍需按站台实际情况确认。
- 本 Agent 是生活辅助，不替代任何医疗或康复判断；视障用户在站台使用时仍需注意脚下与车流安全。

## 提审资料 (Review Submission)

### Feature Description

> Target-route bus watcher for blind and low-vision riders. Register the one route you want, then wait: when a bus comes, point your head at it and tap CHECK. A telephoto photo plus the host language model reads only the bus head sign and compares it with your target. It speaks only the verdict — this is your bus, board now, or this is route X, not yours, keep waiting. Other buses are filtered out, nothing is described, and an unreadable sign is reported as such, never guessed.

### Opening Message

> ## My Bus Watch
>
> Waiting for one specific bus, but you can't read the head sign? Register **that route**, then relax: when a bus comes, point your head at it and tap CHECK. I'll read the head sign, compare it with your route, and speak only the verdict — **this is your bus** or **this is route X, not yours, keep waiting**.
>
> *One route, one verdict. Unreadable signs are reported, never guessed.*

### Preview Media

- `preview-my-bus-watch-index.png` — 初始设置（目标线路未填）
- `preview-my-bus-watch-demo.png` — 演示开始（目标 128 路已选）
- `preview-my-bus-watch-watch.png` — 守车中（守 128 路）
- `preview-my-bus-watch-miss.png` — 不是这辆（上辆 120 路，查车 2 次）
- `preview-my-bus-watch-hit.png` — 就是这辆（命中 128 路，查车 3 次）

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 目标线路登记（步进 + 口述双路径，口述支持中文数字，先 MIC CHECK 再 host ASR）+ 开始前目标必填诚实校验
- CHECK 拍车头核线路（telephoto + LLM 只答线路号或 NONE）+ 手动步进/口述备用路径，同一比对口径
- 命中/不命中各语音一次，新上辆值才计查车次数，重复值不重播、不重计
- 2 分钟留意节律（只在本页打开时，提醒待 CHECK/稍后消解）+ 纯手势主流程（滑动调号、单击情境主操作、点头 = CHECK）+ DEMO 全程演示（56 路 miss → 120 路 miss → 128 路 hit）

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
