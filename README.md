# PCbang Session（网吧座席会话账）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-pcbang-session
```

KR09 · 韩国本地化系列。交互哲学：**座席账本 Seat Ledger**。本 Agent 只记一本座席账：系统每播报满一小时，本人点一下 +1H（或点头）记一个时间块；点餐时 ORDER 记一笔（滑动换菜单候选）；离座时 END 亮出预估结算额（机时费+餐费）让你心里有数。它不与 PC 管家系统联动（费率与总价以柜台结算为准）、不替你下单（订单仍走座位屏）、不提醒休息（那是健康类应用的事）——它只保证这一座的时间和吃喝，有一本你自己记的账。

## 预览截图

![预览-index](<../screenshots/pcbang-session/preview-pcbang-session-index.png>)
![预览-s2](<../screenshots/pcbang-session/preview-pcbang-session-s2.png>)
![预览-s3](<../screenshots/pcbang-session/preview-pcbang-session-s3.png>)
![预览-s4](<../screenshots/pcbang-session/preview-pcbang-session-s4.png>)

## 在地性

PC방 是韩国的生活基础设施：按小时计费、座位上就能点餐送到手边，泡面和饮料的钱和机时费一起结算。人在局内最分不了心——系统播报「1시간 경과」时手在键盘鼠标上，点了什么、攒了多少，离座结账时才发现。

## 功能流程（闭环）

- 记时：+1H 逐块登记时间（点头 = +1H），费率 ₩1,000/h 为目安单价
- 记餐：滑动选菜单候选，ORDER 逐笔登记，餐费实时累计
- 结算：END 亮出预估总额（机时+餐费分开列），再按 = 新会话

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 +1H 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 时间块靠本人逐块登记，不是与 PC 管家系统的实时联动；费率是演示目安（₩1,000/h），实际以店内价目与柜台结算为准
- 订单只登记在本地账里，不会真的发到厨房；下单仍走座位屏

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/pcbang-session
~/tools/bin/aix pack . -o ../dist/pcbang-session.aix
~/tools/bin/aix list ../dist/pcbang-session.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | PCbang Session（待导入后回填） |
| Version / Build | 1.0.1 / 待导入后回填 |
| App Category | Life |
| Intent Description | In a Korean PC cafe: logs hour blocks and seat food orders into a running estimated bill. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> PCbang Session: a seat ledger for Korean PC cafes. Log each hour block with a tap or a nod when the house system announces it, log every snack and drink order to your seat, and see the running estimated bill - machine time plus food - before you walk to the counter. No link to the cafe's own billing system; the counter total rules.

### Opening Message

> ## PCbang Session
> 
> Deep in a match, the hours and the ramen add up silently. I keep your seat ledger: one tap per hour block, one tap per order, and your estimated bill - time plus food - whenever you glance up. The counter's total is the real one; mine keeps you unsurprised.

### Preview Media

- `preview-pcbang-session-index.png` — 初始状态
- `preview-pcbang-session-s2.png` — 演示状态 2
- `preview-pcbang-session-s3.png` — 演示状态 3
- `preview-pcbang-session-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：座席账本 Seat Ledger；显示器边框面：边框内三行账（时间/订单/候选）+ 大字预估结算额

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）

### Change Log（Build 1.0.1）

**Features added**

- 无

**Improvements**

- 无

**Fixes**

- 语言纯化：界面与语音文案统一为本地语言（日本=日语 / 韩国=韩语），逐个排查清除了混入的日文、中文文案（含 SCAN 提示词）
