# Jitensha Guard（自行车骑行锁闭）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-jitensha-guard
```

JP10 · 日本本地化系列。交互哲学：**运动锁闭 Motion Lockout**。本 Agent 的交互哲学是反交互：停车时它是点检单（ブレーキ/タイヤ/ライト/鍵逐项确认），一旦判定骑行中（GEO 速度或陀螺仪活动），主界面立刻塌缩成一行大字「走行中 — 画面は見ないで」，所有按钮按下只回 LOCKED（功能全部失效），只在状态切换时用 TTS 说一句话。它不导航、不测速显摆、不记录轨迹（那是底座导航与运动 App 的事）；它存在的意义就是在你骑车时拒绝被使用，并把这份拒绝做得理直气壮。

## 预览截图

![预览-index](<../screenshots/jitensha-guard/preview-jitensha-guard-index.png>)
![预览-s2](<../screenshots/jitensha-guard/preview-jitensha-guard-s2.png>)
![预览-s3](<../screenshots/jitensha-guard/preview-jitensha-guard-s3.png>)
![预览-s4](<../screenshots/jitensha-guard/preview-jitensha-guard-s4.png>)

## 在地性

日本是自行车大国，也是规矩大国：ながらスマホ（骑车看手机）已入罚则，傘さし、イヤホン、並進都被交规点名。骑行中任何「看一眼屏幕」的设计，都是在诱导违法。

## 功能流程（闭环）

- 点检：停车状态逐项 CHECK（4 项），全过才显示「出発できます」
- 锁闭：速度 >2.2m/s 或陀螺活动超阈 → 骑行相：按钮全失效、屏幕单行化、仅 TTS 报状态切换
- 解锁：停稳 3 秒自动回到点检相；传感器全缺失时用 MODE 手动切换骑行相（SIM 为练习）

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 CHECK 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `GEOLOCATION` | 粗定位/高度/速度旁证（失败即 SKIP） |

## 诚实边界

- 骑行判定依赖 GEO 速度/陀螺仪，地下与隧道可能失效；判定不了时如实显示「判定不可」，并默认按停车相处理但播报提醒
- 本 Agent 不测距不测速存档；交规条文以日本现行道路交通法为准，罚则细节请查官方

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/jitensha-guard
~/tools/bin/aix pack . -o ../dist/jitensha-guard.aix
~/tools/bin/aix list ../dist/jitensha-guard.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Jitensha Guard（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | Cycling in Japan: pre-ride checklist at standstill, full interaction lockout while riding. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Bicycle guard with a lockout philosophy: at a standstill it is a 4-point pre-ride checklist; the moment riding is detected (GPS speed or gyro activity) the screen collapses to one line - RIDING, DO NOT LOOK - every button goes dead, and only TTS speaks state changes. It refuses to be used while you ride, on purpose.

### Opening Message

> ## Jitensha Guard
> 
> A glasses agent that refuses you. Parked, I am your checklist: brakes, tires, light, lock. Moving, I am one line of text and dead buttons - because looking at me while riding is exactly what the law, and I, forbid.

### Preview Media

- `preview-jitensha-guard-index.png` — 初始状态
- `preview-jitensha-guard-s2.png` — 演示状态 2
- `preview-jitensha-guard-s3.png` — 演示状态 3
- `preview-jitensha-guard-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：运动锁闭 Motion Lockout；极小面：骑行中一屏只剩一行大字，其余全黑

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
