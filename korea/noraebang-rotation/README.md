# Noraebang Rotation（练歌房公平轮值）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-noraebang-rotation
```

KR07 · 韩国本地化系列。交互哲学：**公平轮值 Fair Rotation**。本 Agent 就是那个轮盘：四位歌手的名字排成环，当前唱者大字居中，上一位、下一位半亮待命；每首歌的预约号登记在唱者名下，唱完 DONE 自动轮转。PASS 是明着来的跳过（记「양보」让唱，不算偷唱）。它不听唱功、不打分、不录音（那是底座转写与评分机厂商的事），只守公平这一件事：麦克风该在谁手里。

## 预览截图

![预览-index](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-index.png>)
![预览-s2](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-s2.png>)
![预览-s3](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-s3.png>)
![预览-s4](<../../screenshots/noraebang-rotation/preview-noraebang-rotation-s4.png>)

## 在地性

노래방（练歌房）是韩国聚会的第二场标配，规矩就一条：轮流唱，谁也不能霸麦，谁也不许被落下。实际包厢里总有人连唱三首、有人整晚没摸到麦——缺的不是规矩，是一个不偏心的轮盘。

## 功能流程（闭环）

- 轮盘：4 人环序常驻，当前唱者满亮大字，前后位半亮
- 点歌：SONG# 为当前唱者轮换登记预约号预设（唱前报号给点歌机）
- 轮转：DONE/点头 = 唱完轮转；PASS = 本轮让唱（环上标 양보，下轮回到队首优先）

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 DONE 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 人名为演示四人组；增减人数未做（环序逻辑支持，登记 UI 是后续课题）
- 预约号是主流点歌机的编号目安，实际以包厢机器曲库为准；本 Agent 不联网查曲

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/noraebang-rotation
~/tools/bin/aix pack . -o ../dist/noraebang-rotation.aix
~/tools/bin/aix list ../dist/noraebang-rotation.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Noraebang Rotation（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | Entertainment |
| Intent Description | In a Korean noraebang: rotates singing turns fairly and holds song reservation numbers. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Noraebang fair rotation wheel: four singers on a ring, the current one big in the middle, previous and next at half light. Song reservation numbers are held per singer, DONE rotates the mic, PASS yields openly and takes priority next round. No scoring, no recording - fairness is the whole machine.

### Opening Message

> ## Noraebang Rotation
> 
> Every room has a mic hog and a wallflower. I am the wheel that fixes both: your name big when it is your turn, your song number held ready, and a pass that yields in the open and comes back first next round.

### Preview Media

- `preview-noraebang-rotation-index.png` — 初始状态
- `preview-noraebang-rotation-s2.png` — 演示状态 2
- `preview-noraebang-rotation-s3.png` — 演示状态 3
- `preview-noraebang-rotation-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：公平轮值 Fair Rotation；圆桌轮盘：上一位/当前大字/下一位 + 人名环

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
