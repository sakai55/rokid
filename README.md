# Samgyeop Flip（烤肉翻面节拍）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-samgyeop-flip
```

**AIX 直接下载**（最新版）：[samgyeop-flip.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/samgyeop-flip.aix)

KR01 · 韩国本地化系列。交互哲学：**烤盘节拍 Grill Metronome**。本 Agent 是烤盘上的节拍器：一面 45 秒、翻面、一面 40 秒，到点只喊一句「뒤집으세요」，其余时间只显示盘心里的大秒数。它不判断熟度（没有任何传感器能替你判断，界面明写），只持有节奏与进度：翻了几面、剪了几段、几块肉已上桌。剪段（CUT）计数让「这批可以吃了」有明确节点，烤肉的人终于可以按节拍而不是按焦虑工作。它不识肉、不点评火候（慧眼的事），只守时间。

## 预览截图

![预览-index](<../screenshots/samgyeop-flip/preview-samgyeop-flip-index.png>)
![预览-s2](<../screenshots/samgyeop-flip/preview-samgyeop-flip-s2.png>)
![预览-s3](<../screenshots/samgyeop-flip/preview-samgyeop-flip-s3.png>)
![预览-s4](<../screenshots/samgyeop-flip/preview-samgyeop-flip-s4.png>)

## 在地性

韩式烤肉（삼겹살）是一桌人的共同工程：谁负责烤、什么时候翻面、什么时候剪段，全桌都在等一个节奏。翻早了没焦香，翻晚了就苦了——而负责烤的人往往自己吃不上几口。

## 功能流程（闭环）

- 节拍：双面秒数（45s/40s）自动轮换，盘心大字倒数，到点 TTS 只喊翻面
- 手动：等不及可 FLIP 提前翻面，节拍随之重置；点头 = FLIP（手上有油也能用）
- 剪段：CUT 逐次计剪段数，剪满块数即报「이 배치는 먹어도 돼요」，进入下一批

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 START 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 秒数是节奏目安（肉厚与火力不同需自行增减），熟度必须由人看颜色与弹性判断，Agent 不做食品安全结论
- 计时在页面隐藏时暂停（Ink 生命周期），回页后从暂停处继续，README 明示

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/samgyeop-flip
~/tools/bin/aix pack . -o ../dist/samgyeop-flip.aix
~/tools/bin/aix list ../dist/samgyeop-flip.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Samgyeop Flip（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Korean BBQ table: times meat flips and counts scissor cuts per batch. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Korean BBQ metronome: side one 45 seconds, flip, side two 40 - the grill face shows one big countdown and speaks only at the flip moment. Scissor cuts are counted until the batch is ready to eat. It keeps rhythm and progress, never judges doneness; that stays with your eyes, and the screen says so.

### Opening Message

> ## Samgyeop Flip
> 
> Grilling for the table means living by someone else's stomach. I keep the beat instead: 45 seconds, flip, 40 seconds, cut, eat. One number in the middle of the grill, one spoken word at the flip. Your hands stay on the tongs.

### Preview Media

- `preview-samgyeop-flip-index.png` — 初始状态
- `preview-samgyeop-flip-s2.png` — 演示状态 2
- `preview-samgyeop-flip-s3.png` — 演示状态 3
- `preview-samgyeop-flip-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：烤盘节拍 Grill Metronome；俯视圆烤盘：盘心大秒数 + 侧栏剪段账

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）

### Change Log（Build 1.0.1）

**Features added**

- 无

**Improvements**

- 按钮按本 Agent 的 UI 形态单独定型（形态见设计契约），不再与全系列共用同一套按钮

**Fixes**

- 颜色对齐真机单色绿面板：原纯白 #ffffff 改为绿色色阶（最亮绿 #7dff9e），深浅只用绿色表现

### Change Log（Build 1.0.2）

**Features added**

- 无

**Improvements**

- 无

**Fixes**

- 语言纯化：界面与语音文案统一为本地语言（日本=日语 / 韩国=韩语），逐个排查清除了混入的日文、中文文案（含 SCAN 提示词）
