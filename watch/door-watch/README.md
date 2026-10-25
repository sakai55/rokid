# Door Watch（门口守望）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-door-watch
```


注意力外挂系列 W05（WATCH 守望型）。在里屋开会、戴着耳机工作时，门铃、敲门、快递全靠运气听见。本 Agent 的做法：你坐在平常的位置看一眼门，把门的朝向登记下来；之后它替你守听门口的响动模式——出现敲门状的连响或门铃状的一声长音时，它按登记的方向叫你一次「刚才有一阵响动 — 正门在你右后方，去看一眼」；你转头看向门停住 1 秒，这次提醒就算闭环。

![预览-初始](<../../screenshots/door-watch/preview-door-watch-index.png>)
![预览-演示提醒](<../../screenshots/door-watch/preview-door-watch-nudge.png>)
![预览-回看确认](<../../screenshots/door-watch/preview-door-watch-acked.png>)

## 解决的问题

里屋 + 耳机 = 门口的声音世界被关在外面：快递敲了门没听见、门铃响了没人应，事后只剩一张「投递未成功」的条子。本 Agent 把「分一分神留意门口」外包出去：它在你的视线边缘守着声音的电平形状，有值得起身看一眼的响动模式才叫你一次，方向还是你熟悉的「相对你」的位置语言。你继续开会、继续敲键盘，耳朵外包给它。

## 注意力外包设计

- **对 PLAN 原案的如实改编（先说清）**：立项行写的是「守听门铃/敲门特征声 + 转头 SCAN 报正门方向」。但本平台**没有声音分类**（听不出这是门铃还是敲门），也**没有声源定位**（声音本身不带方向）。照字面做就是编造能力，所以本 Agent 改成两个诚实部件：方向来自登记、电平只认形状。下文与界面、语音措辞全程按这个口径，绝不出现「听出门铃」「声音从左边来」之类说法。
- **方向来自登记，永远如此**：坐在你平常的位置，面对门点 SET，当前头部朝向即被绑给这扇门（标签可选正门/后门/院门）。没有朝向读数时登记如实拒绝，绝不编造方向。之后它报的每一个方向都是「登记朝向 − 你当前朝向」的相对量（右后方、左前方……），你转身它就跟着换算——哪怕没开守听，界面也随时显示门现在在你的哪个方向。
- **守听只认电平形状**：全向（omnidirectional）麦克风流只喂给一个 AnalyserNode 电平表（250 ms 一拍，全部计时用 tick 计数）。一段响声按形状分类：**尖峰** = 电平峰值过尖峰阈值且持续 ≤2 秒；**连响（敲门状）** = 5 秒内出现 2 个尖峰 → 触发；**长音（门铃状）** = 电平在门铃下限与尖峰阈值之间持续 1–3 秒 → 触发。单个尖峰（锅盖落地、抽屉一响）不触发；持续 3 秒以上的大声响（电视、水流、免提通话）故意不作信号——太含糊，什么都说明不了；对不上任何形状的响段会被忽略，事件行会如实写明。
- **一段响动只叫一次**：触发时语音一次（句式见上，只说到「有一阵响动」为止，判断那是什么声的是你的眼睛）；横幅留在眼前，直到你**转头看向门、头稳住停满 1 秒**（回看确认，记 face）或点 ACK（记 tap）。冷却期内再出现模式算同一段响动，不重复喊；要连续安静满 10 秒才重新布防，下一次响动才是新的一段。
- **灵敏度只是电平阈值**：灵敏 / 标准 / 安静屋三档把尖峰阈值（基准 0.60）与门铃下限（基准 0.50）按 ×0.75 / ×1.0 / ×1.25 缩放，仅此而已，界面上明示「只是电平阈值」。
- **没有语音识别**：本 Agent 根本没有 ASR 环节；麦克风模式只作用于这条 getUserMedia 电平流，不存在「模式让识别更准」。音频从不录制、从不保存、从不上传，活下来的只有一个响度数字。
- **守听只在本页打开时存在**：界面常驻一行明示。零持久化：不调用任何存储 API，登记与计数只活在页面内存里，关页即忘。

## 功能流程

1. **登记（SET）**：坐在平常的位置，看着门点 SET 打开登记；滑动换门标签（正门/后门/院门），单击绑定。再点 SET 可改登记（比如换了常坐位置）。
2. **守听（LISTEN）**：点 LISTEN 开全向麦守听，电平条实时显示；模式不被设备接受时回退默认麦克风并如实标注。灵敏度用 SENS 或滑动调整。
3. **被叫回看**：横幅出现后，转头看向门停 1 秒即确认（face），或点 ACK（tap）；SPEAK 或点头随时听状态（门的方向、守听开关、灵敏度、已提醒次数）。

## 手势映射

主流程（登记 → 守听 → 被叫 → 回看确认）只用滑动 + 单击（+ 点头听读）即可全程完成：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境主操作：登记中 = 绑定；有提醒待确认 = 确认（tap）；未登记门 = 打开登记；其余时候 = 朗读状态 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 登记中：换门标签；守望中：调灵敏度（灵敏/标准/安静屋） |
| 点头（头稳时） | `onHeadGesture('nod')` | 只朗读状态，绝不登记/确认/开关守听 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| SET | 打开/取消登记的镜像入口（手势路径是单击，非登记态单击会先走情境主操作） |
| SENS | 灵敏度切换的显式入口，与滑动互为镜像，方便真机自测时核对档位 |
| ACK | 回看确认的点按路径（起身不便转头、或朝向传感器不可用时用） |
| LISTEN | 守听开关：开麦是显式动作，必须由佩戴者主动触发，不做手势隐含开启 |
| SPEAK | 随时听状态（点头的镜像，头不方便动时用） |
| DEMO | 演示种子走完「孤立尖峰被忽略 → 连响触发 → 转头回看确认」全程（提审/自测用） |

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | 仅用于全向麦克风电平流（守听响动模式）；只计算响度数字，不录制、不保存、不上传 |

只申请 1 项。不用相机（不看门口画面），不用定位。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/door-watch
~/tools/bin/aix pack . -o ../dist/door-watch.aix
~/tools/bin/aix list ../dist/door-watch.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-door-watch`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Door Watch 智能体」。
5. 验收点：坐在常坐位置登记正门，确认界面方向随转头实时换算；开守听后让家人敲门两下，确认只被叫一次且方向措辞是登记的正门相对方向；故意在屋里摔一下锅盖（单个尖峰），确认不被叫；放一段持续大声的电视声，确认不被叫；被叫后转头看向门停 1 秒，确认以 face 闭环；关掉本页后再敲门，确认不再有任何提醒（设计如此）。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Door Watch（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Door watcher: door registered by heading from your seat, loudness-pattern nudges (knock-shaped burst / bell-length tone) spoken once with the registered direction, face-the-door acknowledgement. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**

- 静态校验：三处 JSON 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(`/`workers:` 误用；按钮全部 `bindtap`（共 6 个）。
- Node harness 57 条断言全过：无朝向时登记诚实拒绝、模式矩阵全项（单个尖峰被忽略且事件行给出解释 / 连响触发恰一次 / 门铃状长音触发恰一次 / 持续大声响不触发 / 冷却期模式算同一段不重复 / 安静满 10 秒重新布防 / 2.5 秒高电平段对不上任何形状）、方向措辞只来自登记且随当前朝向实时重算、回看确认的停留语义（头不稳/锥外/扫过都不算）、点按确认、灵敏度阈值缩放（标准档下 0.52 的尖峰不触发、灵敏档下同电平触发）、纯手势全程走通、点头只朗读、DEMO 全弧线（孤立尖峰 → 连响 → 转头 → face 确认 → 真实状态精确恢复）、OverconstrainedError 回退默认麦并标注、页面隐藏时停轨道、全程零 wx 调用、TTS 从不设置 lang、且全部语音文本扫描无任何「识别出/定位到」类断言。
- `aix pack` 成功（约 20.9 KB），`aix list` 确认 README.md 在包内、artifacts 已排除。
- 预览截图 3 张已生成并逐张目检：EVT 行与底部常驻诚实行均在画面内（点击坐标按布局状态分别探针标定：紧凑态 (400,220)、横幅态 (400,240)）。

**未验证（如实说明）**

- **没有声音分类、没有声源定位，这是本 Agent 的第一诚实边界**：它永远分不清门铃、敲门、微波炉到点和电视音效——只认电平形状。真机上阈值是否合用取决于你家里的实际声场：门远、墙厚时可能要调到「灵敏」；电视正对佩戴者时，电视里的敲门声同样能凑出连响形状。误报与漏报都可能发生，它是「多一只耳朵留意」，不是安防设备。
- 方向只对登记时坐的位置成立：换个座位，几何关系就变了，需要重新登记（同 #07 / #28 的纪律）。
- 守听只在本 Agent 页面打开期间成立；关页、切走或眼镜息屏后门口再响也不会有提醒，本 Agent 不声称后台监听。
- 宿主的头部手势/稳定性事件投递、真机 AnalyserNode 行为、TTS 实际发声，均待真机验证；麦克风开不起来时 LISTEN 如实 FAIL，方向显示部分（纯朝向）仍可用。

## 提审资料 (Review Submission)

### Feature Description（500 字符）

> Door watcher for anyone working in an inner room or wearing headphones who keeps missing doorbells, knocks and deliveries. Register the door once by facing it from your usual seat; after that an omnidirectional level watch reacts only to loud-sound patterns - a knock-shaped burst or a bell-length tone - and nudges you once per episode with the door direction relative to you. No sound is ever identified and no direction ever comes from the sound; the watch runs only while open, nothing is stored.

### Opening Message（476 字符）

> ## Door Watch
>
> In an inner room or on headphones, the door is luck. Sit in your usual seat, face the door and tap **SET** - that heading is the only direction I will ever report. Start **LISTEN** and I watch loudness patterns only: a knock-shaped burst or a bell-length tone earns one nudge with the door direction. Turn to the door for a second to close the loop.
>
> *I never identify sounds and never locate them - patterns are level shapes, directions are your registration.*

### Preview Media

- `preview-door-watch-index.png` — 初始状态：未登记门，登记指南与诚实行
- `preview-door-watch-nudge.png` — DEMO 模拟连响触发：横幅 + 按登记方向的提醒（正门在你右后方）
- `preview-door-watch-acked.png` — DEMO 转头至 135°，回看确认（face）闭环完成

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 看向登记门：坐在常坐位置面对门绑定朝向 + 门标签，之后所有方向均为相对你的实时换算（不开守听也显示）
- 电平形状守听：全向麦只测响度；连响（5 秒内 2 个尖峰）与门铃状长音（1–3 秒中电平段）各触发一次提醒，单个尖峰与持续大声响故意不触发
- 一段响动只叫一次：冷却期模式算同一段，安静满 10 秒才重新布防
- 回看确认闭环：转头看向登记的门、头稳停满 1 秒确认（face），或点 ACK（tap）
- 灵敏度三档（灵敏/标准/安静屋），明示只是电平阈值缩放
- 纯手势主流程（单击情境主操作、滑动选标签/调灵敏度、点头只朗读）+ DEMO 全弧线演示

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
