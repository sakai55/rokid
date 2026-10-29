# Last Sentence（上一句回放）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-last-sentence
```

**AIX 直接下载**（最新版）：[last-sentence.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/last-sentence.aix)

路缘坡效应系列 CC07（REVIEW 回放型）。听障 / 听觉处理障碍的人在群聊里最怕的一刻：语速一快，一句没跟上，后面整段都脱节——而通用字幕一闪而过，回不去。本 Agent 只做一件事：把最近的句子留住，让「上一句」可以定格回放。听着，攒着；没跟上，点上一句，那一句就钉在视线里不动；看完点头或点继续，回到直播。

## 预览截图

![预览-初始](<../screenshots/last-sentence/preview-last-sentence-index.png>)
![预览-直播攒句](<../screenshots/last-sentence/preview-last-sentence-live.png>)
![预览-上一句定格](<../screenshots/last-sentence/preview-last-sentence-frozen.png>)
![预览-已清除](<../screenshots/last-sentence/preview-last-sentence-cleared.png>)

## 解决的问题

群聊脱节不是「听力差一点」，而是「断点会传染」：一句没跟上，后面每句的指代都对不上，越往后越不敢问，最后整段放弃。实时字幕解决不了这个——它也是不可逆的流，闪过就是闪过。眼镜在这里的价值是**把流变成可以暂停的卷轴**：最近 6 句一直攒着，上一句随时可以钉住慢慢看，看的时候新话还在后面攒着，不丢。普通人在嘈杂餐厅、听外语、听方言、开会走神一秒时，同样需要「回放上一句」——这正是电视隐藏字幕被听人广泛使用的路缘坡原例：先为跟不上的人把「回放」做扎实，暂时跟不上的人顺带受益。

## 路缘坡效应：立项三问

- **① 坡道本体**：听障 / 听觉处理障碍者，在群聊中，通道断的是「连续语流的跟随」——拿掉这类人群，本 Agent 立刻不成立：听得顺的人不需要把上一句钉住。
- **② 通道改造**：输入是远场听群聊（先 MIC CHECK 再 host ASR）；输出是视觉回放——可暂停的信息流，而非不可逆的实时流。定格时大字只放一句，绝不把整段记录压上来；回放（TTS 读一句）只是辅助，佩戴者自己的通道永远是定格文字。
- **③ 溢出地图**：普通人在这些情境下会用它：嘈杂餐厅聚餐、听外语讲座、听带口音的发言、开会时走神一秒、学新领域术语——都是「就一句没跟上，后面全脱节」的时刻。

## 注意力外包设计（REVIEW 回放型）

- **只留最近 6 句，诚实说明**：滚动窗口满 6 句后旧句自然掉出，本 Agent 不是会议记录、不做全文转写；README 与界面都明说这一点，不让用户误以为整场会议都在里面。
- **上一句 = 倒数第二句**：你错过的那句，按定义是最新一句之前的那句；定格目标就是它（第 len-1 句是正在说的那句，钉它没有意义）。攒不够两句时拒绝定格并明说。
- **定格时新话不丢**：定格只冻住显示，ASR 仍在后面攒句；继续后回到最新一句，中间攒下的句子都在滚动列表里。
- **点头只回直播，绝不定格**：对话中一次误点头就定格，正是最要命的故障模式。所以头稳点头只在定格时起「继续」作用，平时点头什么都不做；定格只能用明确的按钮/滑动操作。
- **与慧眼和已有 Agent 的分工**：慧眼 / 整机转写是实时流；`ambient-captions` 是实时字幕；本 Agent 只做**可回放的最近一句**这一件事，不做通用字幕、不做会议记录。

## 功能流程

1. **IDLE**：点 LISTEN 开始听群聊（先做远场麦模式可用性检查，结果单独一行 MIC CHECK，再走 host ASR）。
2. **LIVE**：句子滚动保留最近 6 句，最新一句在上，滚动列表显示最近 4 句。
3. **FROZEN**：点上一句，倒数第二句大字定格；看完点头或点继续回直播；回放可把定格句读出来。
4. **收尾**：清除整段清掉回 IDLE；复位只解除定格（句子保留）。

## 手势映射

主流程只用滑动 + 单击 + 点头即可全程完成，不依赖盯屏点按钮：

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | LISTEN（开始听群聊；定格中不重复开） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 上一句（定格倒数第二句） |
| 点头（头稳时） | `onHeadGesture('nod')` | 定格时 = 继续回直播；平时 = 什么都不做，绝不定格 |
| 双击 | Backspace | 系统返回（不拦截） |
| 长按 | — | 唤醒助手（系统级，不拦截） |

屏幕按钮（每个都有保留理由）：

| 按钮 | 理由 |
|---|---|
| LISTEN | 开始听群聊（先远场 MIC CHECK 再 host ASR） |
| 上一句 | 定格倒数第二句（攒不够两句时拒绝） |
| 继续 | 解除定格回直播（点头的镜像） |
| SPEAK | 读当前句（定格句或最新句） |
| HELP | 语音说明用法 |
| 清除 | 整段清掉回 IDLE |
| 回放 | 把定格句（或最新句）读出来 |
| 复位 | 解除定格但保留句子（与清除区分） |
| DEMO | 演示：直播攒 3 句 → 定格上一句（第 2 句）→ 清除；退出后真实状态原样恢复 |

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | 远场听群聊（先做 getUserMedia 远场模式可用性检查，结果单独一行 MIC CHECK）与 host ASR 捕获 |

只申请 1 项。本 Agent 不用相机。麦克风模式只作用于 getUserMedia 流，永不影响宿主 `SpeechRecognition`；聆听状态标注为 (host ASR)。TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方文档注明该属性不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/last-sentence
~/tools/bin/aix pack . -o ../dist/last-sentence.aix
~/tools/bin/aix list ../dist/last-sentence.aix
~/tools/bin/aix preview . --html-out artifacts/preview.html
```

## 真机测试（GO 的 Path 1，无线缆）

1. 将本项目导入 Global AIUI Studio（GitHub 导入分支 `agent-last-sentence`）。
2. 在 Studio 中构建并保存新的 AIX 版本（构建与提审）。
3. 手机 Hi Rokid App：设置 → 开发者选项 → AIUI → 更新眼镜资源包，等到「智能体资源包下载成功」。
4. 在眼镜上语音打开：「乐奇，打开 Last Sentence 智能体」。
5. 验收点：LISTEN 后 MIC CHECK 行显示远场模式读回值；真实群聊走完一轮（听几句 → 上一句定格倒数第二句 → 新话继续攒 → 继续回最新句）；攒不够两句时点上一句确认拒绝；定格时点头确认只回直播、不重复定格；清除后句子与定格全部归零。

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Last Sentence（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | 待导入后回填 |
| Intent Description | Replayable last sentence for deaf and auditory-processing listeners: far-field captions keep the recent sentences, and one command freezes the previous sentence in view until you nod to continue. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 验证情况

**已验证（本地）**
- 静态校验：app.json、package.json 解析通过；从 .ink 抽出的 `<script setup>` 与 app.js 均 `node --check` 通过；无 `Page(`/`App(`/`Widget(` 误用；权限与实际使用一致（RECORD_AUDIO 只在听群聊路径）；CSS 无纯白与白色 rgba（只用绿色色阶）。
- `aix pack` 成功（7.46 KB），`aix list` 确认包内为源文件。
- 预览截图 4 张已生成并逐张目检：初始、直播攒 3 句、定格上一句（第 2 句「预算下周三之前要定下来。」）、已清除各状态均与设计一致；DEMO 点击坐标经探针标定（画布 400, 280——本 Agent 卡片较矮，按钮行高于 CC06 布局）。

**未验证（如实说明）**
- 宿主远场麦模式在真机上的读回值、host ASR 在群聊多说话人下的断句表现（谁的话算一句、重叠语音是否丢句）、连续 ASR 在真机上的持续能力、头部手势/稳定性事件在真机上的投递均待真机验证；任何一步缺失时如实提示（SKIP / 还没攒够两句），绝不编造句子。
- 本 Agent 不做说话人识别、不做会议记录、不保存全文；定格句以 ASR 原文为准，听错时以佩戴者核对为准。
- 本 Agent 是生活辅助，不替代助听设备或医疗判断；听力问题仍以专业评估为准。

## 提审资料 (Review Submission)

### Feature Description

> Replayable last sentence for deaf and auditory-processing listeners. In a fast group conversation, missing one sentence derails everything after it — and live captions scroll past and never come back. This agent keeps the recent sentences rolling, and one command freezes the previous sentence in huge type until you nod to continue. New speech keeps accumulating behind the freeze, so nothing is lost while you read. It keeps only the last few sentences — an honest short window, not a meeting transcript.

### Opening Message

> ## Last Sentence
>
> Missed a sentence in a fast group chat? Don't let the whole thread slip away. I'll keep the recent sentences rolling, and when you say **上一句**, I'll freeze that missed sentence right in your view — while new speech keeps piling up behind it. Nod when you've caught up, and you're back live.
>
> *A pausable stream, not an irreversible one. Only the last few sentences — never a full transcript.*

### Preview Media

- `preview-last-sentence-index.png` — 初始（没在听）
- `preview-last-sentence-live.png` — 直播攒 3 句
- `preview-last-sentence-frozen.png` — 定格上一句（第 2 句）
- `preview-last-sentence-cleared.png` — 已清除

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 远场听群聊（先 MIC CHECK 再 host ASR，连续模式）+ 句子滚动保留最近 6 句 + 上一句定格倒数第二句（攒不够两句拒绝）+ 定格时后台继续攒句 + 继续/点头回直播 + 清除整段 / 复位只解冻
- 回放读句 + HELP 用法语音 + DEMO 全程演示（攒 3 句 → 定格第 2 句 → 清除）

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
