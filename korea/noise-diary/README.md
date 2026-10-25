# Noise Diary（层间噪音夜间日记）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-noise-diary
```

KR02 · 韩国本地化系列。交互哲学：**夜间日记 Night Diary**。本 Agent 只记自己家的账：夜间守候自家近场声响，超过阈值的时刻被钉在一条 22:00→06:00 的弧线上，晨起一次复盘播报——昨晚响了几次、最响在几点。它从不录音、不转写、不指向邻居（只测佩戴者近场，方向如实标注），更不会实时指责你：夜里它沉默记账，早上你才看日记。它与底座字幕/转写的区别是根本性的：它连声音内容是什么都不知道，只知道「几点、家里响了一声」。

## 预览截图

![预览-index](<../../screenshots/noise-diary/preview-noise-diary-index.png>)
![预览-s2](<../../screenshots/noise-diary/preview-noise-diary-s2.png>)
![预览-s3](<../../screenshots/noise-diary/preview-noise-diary-s3.png>)
![预览-s4](<../../screenshots/noise-diary/preview-noise-diary-s4.png>)

## 在地性

층간소음（层间噪音）是韩国公寓生活的头号邻里矛盾，严重到有专门的调解机构与「이웃사이센터」。矛盾的另一面是：很多人并不知道自家孩子跑跳、洗衣机夜洗、椅子拖动在楼下听起来有多响。

## 功能流程（闭环）

- 守候：夜间 ARM 后只算声压峰值事件（不录存），事件按时刻钉上夜间弧
- 日记：峰值事件保留时刻与相对强度（前 3 件），其余计数
- 复盘：REVIEW 播报昨夜汇总（次数/最响时刻/安静段），点头清空昨夜，关页即忘

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

- 近场声压无法区分声源（自家/楼上/窗外），日记只证明「这一带响过」，归因必须由人结合时刻判断，界面明示
- 声压为相对强度非校准分贝；麦克风不可用时报 SKIP，不伪造日记

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/noise-diary
~/tools/bin/aix pack . -o ../dist/noise-diary.aix
~/tools/bin/aix list ../dist/noise-diary.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Noise Diary（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | In a Korean apartment at night: logs the wearer home loud-moment times for a morning self-review. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Inter-floor noise night diary for Korean apartments: it keeps only YOUR home's account. Armed at night, it pins loud moments onto a 22:00-06:00 arc - time and relative level, never recordings, never content. In the morning it reads the diary back once: how many peaks, the loudest at what time. It never points at the neighbours.

### Opening Message

> ## Noise Diary
> 
> You cannot fix noise you never noticed making. Arm me at night and I will keep a silent diary of this home's loud moments - no recording, no words, just pins on the night arc. In the morning, we read it together once.

### Preview Media

- `preview-noise-diary-index.png` — 初始状态
- `preview-noise-diary-s2.png` — 演示状态 2
- `preview-noise-diary-s3.png` — 演示状态 3
- `preview-noise-diary-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：夜间日记 Night Diary；时钟弧线：夜间 8 小时弧 + 峰值时刻点，晨起复盘

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
