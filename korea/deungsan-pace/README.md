# Deungsan Pace（登山配速账）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-deungsan-pace
```

KR06 · 韩国本地化系列。交互哲学：**海拔配速 Elevation Pace**。本 Agent 管腿不管路：它在一条山形剖面线上钉你的进度（8 段自登记），休息与补水逐次落账，补水落后于时长时轻声提醒；高度只在你按下 GEO 时取一次作记录（取不到如实 SKIP）。它坚决不导航、不指路（底座 AR 导航的事）——岔路口请看路牌与地图；它只回答一个问题：以你现在的配速与补水，这双腿还撑不撑得住下山。

## 预览截图

![预览-index](<../../screenshots/deungsan-pace/preview-deungsan-pace-index.png>)
![预览-s2](<../../screenshots/deungsan-pace/preview-deungsan-pace-s2.png>)
![预览-s3](<../../screenshots/deungsan-pace/preview-deungsan-pace-s3.png>)
![预览-s4](<../../screenshots/deungsan-pace/preview-deungsan-pace-s4.png>)

## 在地性

등산（登山）是韩国的全民周末仪式：북한산、관악산周末人满为患，山友文化讲究配速与补水，下山伤膝更是常识。山里最容易失守的不是路线——是「再撑一段」的配速账。

## 功能流程（闭环）

- 剖面：8 段进度以 GO/单击逐段推进，山形线上的 ● 随之迁移
- 落账：REST/WATER 逐次登记，剖面下常驻「休息 n · 补水 n/目安」
- 旁证：GEO 取一次高度与粗经纬度作记录（失败 SKIP）；补水规则是时长目安，界面明示非医疗标准

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 REST 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `GEOLOCATION` | 粗定位/高度/速度旁证（失败即 SKIP） |

## 诚实边界

- 进度段为自登记（无轨迹记录、无距离测量）；高度来自单次 GEO，气压高度计不存在于本平台，如实说明
- 补水目安（约 30 分钟一杯）是登山常识的节奏提示，不是医疗建议；不适请立即下山或求助

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/deungsan-pace
~/tools/bin/aix pack . -o ../dist/deungsan-pace.aix
~/tools/bin/aix list ../dist/deungsan-pace.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Deungsan Pace（待导入后回填） |
| Version / Build | 1.0.2 / 待导入后回填 |
| App Category | Life |
| Intent Description | Hiking in Korea: logs segment progress, rests and water intake against a profile line; no navigation. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Mountain pace ledger, not a navigator: your climb as 8 segments on a profile line, rest and water logged pin by pin, a gentle nudge when water falls behind time. GEO takes a one-shot altitude record when you ask, and fails honestly. Trails are for signs and maps; legs are what I keep accounts for.

### Opening Message

> ## Deungsan Pace
> 
> I do not know the trail, and I will not pretend to. I know your legs' ledger: which segment you are on, when you last rested, whether water is keeping up with time. The mountain is yours; the pace is mine.

### Preview Media

- `preview-deungsan-pace-index.png` — 初始状态
- `preview-deungsan-pace-s2.png` — 演示状态 2
- `preview-deungsan-pace-s3.png` — 演示状态 3
- `preview-deungsan-pace-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：海拔配速 Elevation Pace；海拔剖面线：文字山形线 + 休息/补水钉点

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
