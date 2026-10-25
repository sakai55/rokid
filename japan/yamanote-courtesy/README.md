# Yamanote Courtesy（通勤礼仪站序提示）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-yamanote-courtesy
```

JP07 · 日本本地化系列。交互哲学：**站名线图 Station Line Cue**。本 Agent 不导航（底座 AR 导航的事），不管你在哪，只管「礼仪动作在正确的站触发」：你登记一条固定通勤站序（演示为山手线品川→东京段），每到一站由你单击确认（列车 API 不存在，如实说明；GEO 只作粗核对），终点前一站自动亮出三件套礼仪清单，逐件点头销项。它的本体是情境提示的时机，不是位置本身。

## 预览截图

![预览-index](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-index.png>)
![预览-s2](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-s2.png>)
![预览-s3](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-s3.png>)
![预览-s4](<../../screenshots/yamanote-courtesy/preview-yamanote-courtesy-s4.png>)

## 在地性

東京的通勤礼仪是写在身体里的：リュックは前に抱える、スマホはマナーモード、降りる駅の一つ前から出口側へ寄る。做不到不是没素质，是专注看手机时真的会忘——尤其是要在終点駅下车、又怕坐过站的人。

## 功能流程（闭环）

- 登记：固定站序 6 站（演示段），目的地预设为终点站
- 推进：ARRIVE 逐站确认推进，横线圆点随之迁移；GEO 键可试取粗定位作旁证（失败即 SKIP，不阻塞）
- 触发：终点前一站自动进入礼仪模式——背包前抱/静音模式/靠门准备，CUE 或点头逐件完成

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 ARRIVE 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| `GEOLOCATION` | 粗定位/高度/速度旁证（失败即 SKIP） |

## 诚实边界

- 没有任何列车实时 API：到站推进以本人确认为准，GEO 只是粗旁证（站间距离短时可能分不清相邻站），界面与 README 均明示
- 站序为演示段；换乘与支线未做，换线请重开并登记新段（方法在 README）

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/yamanote-courtesy
~/tools/bin/aix pack . -o ../dist/yamanote-courtesy.aix
~/tools/bin/aix list ../dist/yamanote-courtesy.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Yamanote Courtesy（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | Life |
| Intent Description | On a Tokyo commuter train: advances a registered station sequence and fires courtesy cues one stop before the destination. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Commute courtesy cues on a station line: register your fixed 6-station run and I advance only on your tap - there is no train API, and I say so. One stop before your destination I light the courtesy set: backpack to the front, phone on manner mode, move toward the door. I never navigate; timing the manners is the whole job.

### Opening Message

> ## Yamanote Courtesy
> 
> Not navigation - timing. Register your usual run, tap as each station passes, and one stop before yours I will remind you: backpack forward, phone silent, drift to the door. Arrive already polite.

### Preview Media

- `preview-yamanote-courtesy-index.png` — 初始状态
- `preview-yamanote-courtesy-s2.png` — 演示状态 2
- `preview-yamanote-courtesy-s3.png` — 演示状态 3
- `preview-yamanote-courtesy-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：站名线图 Station Line Cue；横线站序图：圆点串成的线路，当前站在横线上满亮

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
