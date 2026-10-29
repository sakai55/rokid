# Alarm Triage Visual（响声视觉分诊）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-alarm-triage-visual
```

**AIX 直接下载**（最新版）：[alarm-triage-visual.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/alarm-triage-visual.aix)

路缘坡效应系列 CC06（FILTER 守望型）。重度听障的人家里有个根本问题：烟感、门铃、水壶、洗衣机结束音、宝宝哭声——全是声音，对他就等于不存在，而 TTS 对他也没用。本 Agent 把声音变成光：全向守听，有响声整屏亮起大横幅；转头逐向采样声级，定出方向；你亲眼看到是什么在响，选类型、点确认，分诊横幅定格为「类型 + 方向」。

## 预览截图

![预览-初始](<../../screenshots/alarm-triage-visual/preview-alarm-triage-visual-index.png>)
![预览-有响声横幅](<../../screenshots/alarm-triage-visual/preview-alarm-triage-visual-alert.png>)
![预览-分诊定格](<../../screenshots/alarm-triage-visual/preview-alarm-triage-visual-triaged.png>)
![预览-已清除](<../../screenshots/alarm-triage-visual/preview-alarm-triage-visual-cleared.png>)

## 解决的问题

听障者的困境不是「听不清」，而是「根本不知道有声音在发生」——烟感响了不知道、门铃响了不知道、宝宝哭了不知道，错过的不是信息，是事件本身。眼镜在这里的价值是**把事件变成视线内的光**：守听不需要你盯着，响了横幅自己亮起来；方向不需要你猜，转头采样声级就能比出哪边最响；类型不需要机器瞎认，你亲眼看到声源，确认一下就定格。普通人戴降噪耳机工作、开会静音、夜里摘下助听器睡觉时，都是暂时听障——同一块板子照样用，这就是路缘坡效应的溢出：先为听不见的人把「声音变可见」做扎实，暂时听不见的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：重度听障者，在家里，通道断的是「声音事件的感知」——拿掉这类人群，本 Agent 立刻不成立：听得见的人不需要一块板子告诉他「有响声」。
- **② 通道改造**：输出通道彻底换掉：零语音依赖，全部信息视觉化——大横幅（类型 + 方向）、声级条（█░）、方位采样表。输入通道也换掉：不用耳朵等声音，用全向麦克风声级监测 + 转头逐向采样。TTS 只给旁边听得见的人读结果，佩戴者自己的通道永远是屏幕。
- **③ 溢出地图**：普通人在这些情境下会用它：戴降噪耳机专注工作、会议中手机静音、夜里摘助听器睡觉、工地/机房戴隔音耳罩——都是「暂时听不见，但需要知道家里/周围响了什么」的时刻。

## 注意力外包设计（FILTER 守望型）

- **守听代替盯听**：LISTEN 后全向守听一直开着，佩戴者不用竖着耳朵等；声级 ≥6 即亮横幅（ALERT），阈值与声级条全程可见。
- **方向靠采样比出来**：DIR 选朝向（左 / 正前方 / 右，佩戴者先转头、再点），SCAN 存该向实时声级；采两个方向以上，最高者即方向 verdict；没采样的向永远显示未测，绝不编一个方向。
- **类型只认佩戴者的眼睛**：声级计认不出是哪种电器，这是物理事实，不是功能缺口。TYPE 在固定六项里循环（烟感 / 门铃 / 水壶 / 洗衣机 / 宝宝哭声 / 其他声响），确认后才定格；没确认的分诊永远是「未确认」。
- **点头只朗读，绝不确认/清除**：分诊定格后一次误点头就确认或清除，都是故障模式。所以头稳点头在所有阶段都只朗读横幅（给旁边听得见的人听），确认与清除只能用明确的按钮/单击操作。
- **与慧眼和已有 Agent 的分工**：`sound-compass` 给健全人报方位且以听为前提；本 Agent 是**为听不见的人做的视觉分诊**，通道完全相反。慧眼没有任何「声音变横幅」的功能。

## 功能流程

1. **IDLE**：点 LISTEN 开始全向守听（先做全向麦模式可用性检查，结果单独一行 MIC CHECK）。
2. **LISTENING**：全向守听中，声级条实时走；声级 ≥6 自动进 ALERT，大横幅亮起「⚠ 有响声！」。
3. **ALERT**：转头向声源，DIR 选朝向、SCAN 采样；采两个方向以上最准；TYPE 选你亲眼确认的声源类型，点确认。
4. **TRIAGED**：分诊横幅定格（类型 + 最响方向），处理完点清除回 IDLE。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | LISTEN（开始守听；分诊已定格时不重复开） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | DIR 切换朝向（左 → 正前方 → 右） |
| 点头（头稳时） | `onHeadGesture('nod')` | 所有阶段 = 只朗读横幅，绝不确认、绝不清除 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| LISTEN | 开始全向守听（先 MIC CHECK 再声级监测） |
| SCAN | 在当前朝向采样实时声级 |
| DIR | 切换采样朝向（左 / 正前方 / 右） |
| 确认 ✓ | 把类型 + 最响方向定格为分诊横幅 |
| SPEAK | 给旁边听得见的人朗读横幅（佩戴者不靠它） |
| TYPE | 循环切换声源类型（佩戴者亲眼确认） |
| HELP | 语音说明用法（给旁边帮忙的人听） |
| 清除 | 分诊结束回 IDLE，流与采样全部清掉 |
| DEMO | 演示：有响声横幅（声级 9）→ 分诊定格（烟感 · 左）→ 清除；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | 全向麦克风守听（先做 getUserMedia 全向模式可用性检查，结果单独一行 MIC CHECK）与声级监测（Analyser） |

只申请 1 项。本 Agent 不用相机（分诊是声音变光，不是看），不用 ASR（警报声不是语音，识别不了）。麦克风模式只作用于 getUserMedia 流；TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/alarm-triage-visual
~/tools/bin/aix pack . -o ../dist/alarm-triage-visual.aix
~/tools/bin/aix list ../dist/alarm-triage-visual.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-alarm-triage-visual`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Alarm Triage Visual 智能体」。
5. 验收点：LISTEN 后 MIC CHECK 行显示全向模式读回值；真实响声（门铃/水壶）触发横幅；转头两个方向 SCAN 后方向 verdict 与实际声源方向一致；TYPE 选错时能改选、确认前分诊不提前定格；点头只朗读、不确认不清除；清除后采样与横幅全部归零。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Alarm Triage Visual（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Visual alarm triage for severe hearing loss: omnidirectional listening flashes a big banner on loud sounds, head-turn sampling finds the direction, and the wearer confirms the type — no hearing required. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（RECORD_AUDIO 只在守听路径）；CSS 无纯白与白色 rgba（只用绿色色阶）。
- `aix pack` 成功（7.77 KB），`aix list` 确认包内为源文件。
- 预览截图 4 张已生成并逐张目检：初始、响声横幅（声级 9）、分诊定格（烟感 · 左）、已清除各状态均与设计一致；DEMO 点击坐标经探针标定（画布 400, 300）。

**未验证（如实说明）**
- 宿主全向麦模式在真机上的读回值、Analyser 声级与真实声压的对应关系、声级阈值 6 在家庭环境中的误报率（电视、谈话声是否会误触发横幅）、头部手势/稳定性事件在真机上的投递均待真机验证；任何一步缺失时如实提示（未测/未确认），绝不编造方向或类型。
- 本 Agent 不识别电器种类、不判断声源身份；类型永远由佩戴者亲眼确认，认错类型时以佩戴者改选为准。
- 本 Agent 是生活辅助，不替代烟感报警器等安全设备，也不是医疗器械；烟感报警的处置仍以现场安全规范为准。

## 提审资料 (Review Submission)

### Feature Description

> Visual alarm triage for people with severe hearing loss. Smoke alarms, doorbells, kettles, washer tones, a crying baby — all sounds, all invisible to this wearer. This agent listens omnidirectionally and turns a loud sound into a big visual banner, samples sound levels as you turn your head to find the direction, and lets you confirm the source type you can see. No speech, no beeps, no hearing required — the screen is the alarm. A level meter cannot identify appliances, so the type is always confirmed by your own eyes, never auto-guessed.

### Opening Message

> ## Alarm Triage Visual
>
> You can't hear the smoke alarm, the doorbell, or the baby crying — so let the screen tell you. I'll watch for loud sounds, flash a **big banner** when one happens, help you find **which direction** it's loudest, and hold the triage — type + direction — in huge type until you clear it.
>
> *No hearing required. And I never guess the source: the type is always one you confirm with your own eyes.*

### Preview Media

- `preview-alarm-triage-visual-index.png` — 初始（守听未开）
- `preview-alarm-triage-visual-alert.png` — 有响声横幅（声级 9）
- `preview-alarm-triage-visual-triaged.png` — 分诊定格（烟感 · 左）
- `preview-alarm-triage-visual-cleared.png` — 已清除

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 全向守听（先 MIC CHECK 再 Analyser 声级监测，声级 ≥6 自动亮横幅）+ 转头逐向 SCAN 采样（最高声级向即方向 verdict，未采样向永远未测）+ TYPE 六项循环 + 确认定格分诊横幅（类型 + 方向）+ 清除回 IDLE
- 头稳点头只朗读（绝不确认/清除）+ HELP 用法语音 + DEMO 全程演示（响声横幅 → 分诊定格 → 清除）

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
