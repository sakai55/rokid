# Hanbok Rental（韩服租赁账）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-hanbok-rental
```

KR11 · 韩国本地化系列。交互哲学：**衣物核对 Garment Check**。本 Agent 是一张韩服租赁核对单：四件租赁物品（上衣、裙子、饰品、包）逐件确认，焦点用标记指着当前件，剩余时间大字显示，延长按 30 分钟一档加。四件全确认后 GO 一次即为「可归还」，再由你去店里交还。它不计时拍照、不识衣服，只守「件数齐了没有、时间还剩多少」这两件事。

## 预览截图

![预览-index](<../screenshots/hanbok-rental/preview-hanbok-rental-index.png>)
![预览-s2](<../screenshots/hanbok-rental/preview-hanbok-rental-s2.png>)
![预览-s3](<../screenshots/hanbok-rental/preview-hanbok-rental-s3.png>)
![预览-s4](<../screenshots/hanbok-rental/preview-hanbok-rental-s4.png>)

## 在地性

한국의 궁궐 일대에는 한복 대여점이 늘어서 있다. 한복을 입고 궁궐에 들어가고, 정해진 시간 안에 저고리, 치마, 장신구, 가방을 빠짐없이 반납해야 한다. 빠진 물품 하나가 보증금 문제로 이어지기 쉽다.

## 功能流程（闭环）

- 逐件核对：四件物品各一行，焦点行带标记，CHECK 逐件打勾或取消，点头即 CHECK 当前件
- 时间持有：剩余时间大字显示，EXTEND 按 30 分钟一档延长，时间只按用户登记的租期走
- 归还确认：四件全确认后 GO 标记可归还并 TTS 播报，否则 GO 只播报还缺几件

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 NEXT 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 租期、租金与押金规则各店不同，本账本只按用户登记的时间与物品走，不做店家系统对接，界面明示
- 物品是否真的在手、是否完好，由本人目视确认，Agent 不用相机核验
- 宫殿入场规则以现场告示为准，Agent 不做实时查询

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/hanbok-rental
~/tools/bin/aix pack . -o ../dist/hanbok-rental.aix
~/tools/bin/aix list ../dist/hanbok-rental.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Hanbok Rental（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a hanbok rental shop near a palace: checks four rented pieces and holds the remaining rental time. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Hanbok rental checklist for palace-area rental shops: four rented pieces - top, skirt, accessory, bag - are checked one by one with a focus marker, remaining rental time is shown big, and extensions add 30 minutes at a time. When all four are checked, GO marks the set ready to return. It never photographs or identifies garments; it only counts what you confirmed.

### Opening Message

> ## Hanbok Rental
> 
> A rented hanbok is four pieces, and one missing piece is a deposit problem. I keep the checklist: top, skirt, accessory, bag, one line each, with the focus on the piece you are holding. Time left stays big on screen, extensions add thirty minutes, and when all four are checked I tell you the set is ready to return.

### Preview Media

- `preview-hanbok-rental-index.png` — 初始状态
- `preview-hanbok-rental-s2.png` — 演示状态 2
- `preview-hanbok-rental-s3.png` — 演示状态 3
- `preview-hanbok-rental-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：衣物核对 Garment Check；衣物四行单：每件一行带焦点标记 + 大字剩余时间

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
