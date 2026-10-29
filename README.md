# Greet Name Hold（名字拿住）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-greet-name-hold
```

**AIX 直接下载**（最新版）：[greet-name-hold.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/greet-name-hold.aix)

路缘坡效应系列 CC05（HOLD 拿住型）。面盲（面孔失认）的人最怕的一刻：熟人迎面热情打招呼，你知道他是熟人，却想不起名字——而你只有几秒钟必须回应。本 Agent 不认脸（本平台根本没有人脸识别 API，假装能认脸是撒谎），它只替你**拿住已经说出来的名字**：对方自报姓名时听下来，或者你口述刚听到的名字，整段对话期间名字一直显示在视线里，旁边还有你预存的一句备注，对话结束一键清除。

## 预览截图

![预览-初始设置](<../screenshots/greet-name-hold/preview-greet-name-hold-index.png>)
![预览-演示存好](<../screenshots/greet-name-hold/preview-greet-name-hold-demo.png>)
![预览-拿住名字](<../screenshots/greet-name-hold/preview-greet-name-hold-holding.png>)
![预览-已清除](<../screenshots/greet-name-hold/preview-greet-name-hold-cleared.png>)

## 解决的问题

面盲者的问题不是「认不出是熟人」，而是「名字到嘴边出不来」——几秒内必须回应，慌且尴尬。眼镜在这里的价值不是「替你认人」，而是**替你拿住名字**：名字一旦说出来，就由它在整段对话里替你拿着，你不用一边寒暄一边在脑子里死死攥着名字；备注（如「上次聊过孩子升学」）同时在场，寒暄不断档。普通人人人都有「名字到嘴边想不起」时刻——会议、婚礼、家长会就是普通人的暂时面盲场，这就是路缘坡效应的溢出：先为想不起名字的人把「拿住」做扎实，暂时想不起的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：面盲（面孔失认）者，熟人迎面打招呼，通道断的是「面孔→名字的提取」——拿掉这类人群，本 Agent 立刻不成立：普通人看一眼脸就能想起名字，不需要一个替他拿住名字的外挂。
- **② 通道改造**：输入通道彻底换掉：不用脸、不用猜，只用**说出来的话**——对方自报姓名（LISTEN 远场听 + 采用确认）或佩戴者口述（DICT）。输出通道是视线内的大字名字卡 + 一句备注 + 对话计时，不靠记忆、不靠声音提醒。对话进行中保持静默，不出声报名字（出声反而暴露你忘了）。
- **③ 溢出地图**：普通人在这些情境下会用它：大型会议、婚礼、家长会、校友聚会、刚入职见新同事——都是「熟人太多、名字到嘴边」的时刻。

## 注意力外包设计（HOLD 拿住型）

- **名字先行，拿住后行**：SETUP 必须先存名字（非空）才能开始拿住；没名字拒绝开始并明说。备注可空，名字不可空。
- **名字只来自说出来的话，绝不猜**：DICT 口述（先做佩戴者麦模式可用性检查，结果单独一行 MIC CHECK，再走宿主 ASR；转写去标点空格后原样存入）；LISTEN 远场听对方说话（先做远场麦模式可用性检查，再走宿主 ASR；转写只显示为「听到的原话」，不存入，直到佩戴者点采用）。采用进名字要求名字长度（≤6 字），超长拒绝进名字、必须存备注或口述短名——整句寒暄绝不能冒充名字。
- **拿住后清除，不留痕**：HOLDING 期间名字大字常驻 + 备注 + 对话计时（250 ms tick 引擎，每秒刷新显示）；CLEAR 一键清除名字与备注，进入 DONE；DONE 后 GO 开始新的一次。对话结束名字不留、不跨对话复用。
- **点头只朗读，绝不开始/清除**：对话中一次误点头就清除名字，正是最要命的故障模式。所以头稳点头在所有阶段都只朗读状态，开始与清除只能用明确的按钮/单击操作。
- **与慧眼的分工**：慧眼没有此功能（平台无人脸识别）。`badge-reader` 读的是名牌文字，本 Agent 抓的是**口头姓名**，且专用于无名牌场景——对方自报姓名的那几秒。
- **零持久化**：不调用任何存储 API；名字、备注、原话、计时只活在页面内存里，关页即忘，一次对话一轮。

## 功能流程

1. **SETUP**：FIELD 在名字 ↔ 备注间切换当前编辑项；DICT 口述填入（先 MIC CHECK 再 host ASR）；或 LISTEN 听对方说话，听到原话后点采用存入（名字限 ≤6 字）。
2. **HOLDING**：GO 开始拿住——名字大字常驻视线，备注在下，对话计时在走；SPEAK 可听名字与备注；CLEAR = 对话结束清除。
3. **收尾**：CLEAR 后进入 DONE（已清除）；DONE 后 GO 开始新的一次。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO：SETUP 时开始拿住；拿住中 = 朗读；DONE 时 = 新的一次 |
| 上滑 / 下滑 | ArrowUp / ArrowDown | FIELD 切换（名字 ↔ 备注） |
| 点头（头稳时） | `onHeadGesture('nod')` | 所有阶段 = 只朗读，绝不开始拿住、绝不清除 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| FIELD | 切换编辑项（名字 ↔ 备注） |
| DICT | 口述填入当前项（先 MIC CHECK 再 host ASR） |
| LISTEN | 远场听对方说话（先远场 MIC CHECK 再 host ASR，只显示原话、不自动存入） |
| 采用 | 佩戴者确认后把原话存入当前项（名字限 ≤6 字，超长拒绝） |
| GO ✓ | Enter 的镜像（情境主操作） |
| SPEAK | 随时听名字与备注（点头的镜像） |
| CLEAR | 对话结束清除（拿住中唯一的清除路径） |
| HELP | 语音说明用法（第一次用时听一遍） |
| DEMO | 演示：名字李明 + 备注「上次聊过孩子升学」→ 开始拿住（计时约 2 分半）→ 对话结束清除；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | 佩戴者口述名字/备注（DICT，佩戴者模式检查）与远场听对方说话（LISTEN，远场模式检查）；每次使用前都先做 getUserMedia 模式可用性检查，结果单独一行 MIC CHECK |

只申请 1 项。本 Agent 不用相机（不看脸），TTS 输出不需要权限。麦克风模式只作用于 getUserMedia 流，永不影响宿主 `SpeechRecognition`；聆听状态标注为 (host ASR)。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/greet-name-hold
~/tools/bin/aix pack . -o ../dist/greet-name-hold.aix
~/tools/bin/aix list ../dist/greet-name-hold.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-greet-name-hold`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Greet Name Hold 智能体」。
5. 验收点：真实对话走完一轮（对方自报姓名 → LISTEN 听到原话 → 采用存名字 → GO 拿住 → 整段对话名字常驻 → 结束 CLEAR → 已清除）；故意说一长句寒暄后点采用存名字，确认拒绝并提示存备注；DICT 口述名字与备注能填入且可核对；对话中点头确认只朗读、不清除；关页后名字不残留。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Greet Name Hold（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Spoken-name holder for face blindness: never recognises faces, holds a name once spoken, shows it with one note for the whole conversation, clears when the conversation ends. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（RECORD_AUDIO 只在 DICT/LISTEN 路径）；CSS 无纯白与白色 rgba（只用绿色色阶）。
- `aix pack` 成功（约 15.1 KB），`aix list` 确认 artifacts 已排除、包内为源文件。
- 预览截图 4 张已生成并逐张目检：初始设置、演示存好（李明 + 备注）、拿住名字（计时约 2 分半）、已清除各状态均与设计一致；DEMO 点击坐标经探针标定。

**未验证（如实说明）**
- 宿主 TTS 实际发声、头部手势/稳定性事件在真机上的投递、佩戴者/远场麦模式在真机上的读回值、host ASR 对姓名的识别表现（同音名、方言口音、嘈杂环境）均待真机验证；DICT/LISTEN 在任何一步缺失时如实提示，手动流程不受影响。
- 本 Agent 不做人脸识别、不做声纹识别、不判断对方身份；名字只来自说出来的话，存错名字时以佩戴者核对为准。
- 本 Agent 是生活辅助，不替代任何医疗或心理判断；面盲是认知差异，不是本 Agent 诊断或治疗的对象。

## 提审资料 (Review Submission)

### Feature Description

> Spoken-name holder for people with face blindness. This agent never recognises faces — there is no face-recognition API here. When someone introduces themselves, capture their spoken name or dictate the name you just heard, and the agent holds it in view for the whole conversation, with one note you saved ("last time we talked about school admissions" style). When the conversation ends, one tap clears it. A name is stored only from speech you confirm, never guessed.

### Opening Message

> ## Greet Name Hold
>
> Someone greets you warmly — and the name just won't come? Don't panic and don't guess. Capture the name **as spoken**, and I'll hold it in your view for the whole conversation, with your one note beside it. When the conversation ends, **one tap clears it**.
>
> *No face recognition, no guessing. A name enters only through speech you confirm.*

### Preview Media

- `preview-greet-name-hold-index.png` — 初始设置（名字未存）
- `preview-greet-name-hold-demo.png` — 演示存好（李明 + 备注）
- `preview-greet-name-hold-holding.png` — 拿住名字（计时约 2 分半）
- `preview-greet-name-hold-cleared.png` — 已清除

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 名字/备注登记（DICT 口述 + LISTEN 远场听 + 采用确认，名字限 ≤6 字，超长拒绝进名字）+ 开始前名字必填诚实校验
- 整段对话拿住（大字名字卡 + 备注 + 对话计时，拿住中静默不出声）+ 一键清除（DONE 后 GO 新开一轮）+ 头稳点头只朗读（绝不开始/清除）+ HELP 用法语音
- DEMO 全程演示（李明 + 备注 → 拿住计时约 2 分半 → 清除）

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
