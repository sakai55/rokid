# Shinkansen Quiet（新干线静音守卫）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-shinkansen-quiet
```

**AIX 直接下载**（最新版）：[shinkansen-quiet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/shinkansen-quiet.aix)

JP01 · 日本本地化系列。交互哲学：**沉默守卫 Silence Keeper**。在静音车厢里，最难自知的是「我自己的声音有多大」：戴着耳机说话会不自觉放大音量，电话响起时慌忙接听的前几秒最吵。本 Agent 把「自己有没有越线」外包给眼镜：它只监测佩戴者近场发声强度，平时一个字都不显示，只有越线才出现，并提醒你去连接处。它不转写、不录音、不评价别人——那是实时字幕和会议转写（底座能力）的事，与它无关。

## 预览截图

![预览-index](<../screenshots/shinkansen-quiet/preview-shinkansen-quiet-index.png>)
![预览-s2](<../screenshots/shinkansen-quiet/preview-shinkansen-quiet-s2.png>)
![预览-s3](<../screenshots/shinkansen-quiet/preview-shinkansen-quiet-s3.png>)
![预览-s4](<../screenshots/shinkansen-quiet/preview-shinkansen-quiet-s4.png>)

## 在地性

日本新干线有明确的车厢礼仪：手机调静音、通话去车厢连接处（デッキ）、交谈压低音量。这不是泛泛的「安静」，而是全车厢共同遵守的成文规矩，一个人破例全车厢都听得见。

## 功能流程（闭环）

- 守候： Web Audio 分析近场声压（只算强度，不录存、不转写），声压条实时起伏
- 越线：超过你设的阈值才点亮提醒并 TTS 一句「デッキへどうぞ」，同时记一次越线
- 复盘：峰值与越线次数留在本页内存，点头即确认消账，下车关页即忘

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 ARM 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `RECORD_AUDIO` | 麦克风/语音路径（强度分析或 ASR；不录存） |

## 诚实边界

- 声压是相对强度，不是校准分贝值；真机麦克风模式（wearer 近场）可用性以设备为准，不可用时如实报 SKIP，核心提醒逻辑不受影响
- 练习模式（PRACTICE）的声压是模拟值，只用于熟悉流程，界面与播报都会明说「练习」

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/shinkansen-quiet
~/tools/bin/aix pack . -o ../dist/shinkansen-quiet.aix
~/tools/bin/aix list ../dist/shinkansen-quiet.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Shinkansen Quiet（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | Worn on a Shinkansen quiet car: monitors the wearer voice level and reminds them to move to the deck when they get loud. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Shinkansen quiet-car self guard. It watches only YOUR voice level through the mic (level only, never recorded, never transcribed) and stays invisible until you cross your own threshold - then it reminds you once to step to the deck for calls. Peak and crossing count live in page memory and are gone when you close it.

### Opening Message

> ## Shinkansen Quiet
> 
> In a quiet car, the hardest sound to judge is your own. Arm me and I will watch only your voice level - no recording, no transcription. Stay under your line and I stay invisible. Cross it, and I will say one thing: please take the call to the deck.

### Preview Media

- `preview-shinkansen-quiet-index.png` — 初始状态
- `preview-shinkansen-quiet-s2.png` — 演示状态 2
- `preview-shinkansen-quiet-s3.png` — 演示状态 3
- `preview-shinkansen-quiet-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：沉默守卫 Silence Keeper；仪表横条：中央大读数 + 声压横条 + 阈值刻度

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
