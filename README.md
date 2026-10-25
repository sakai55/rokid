# Cafe Stamp（咖啡店印章卡）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-cafe-stamp
```

KR13 · 韩国本地化系列。交互哲学：**도장 카드 Stamp Card**。本 Agent 是一张只记章的卡：10 格章盘，买一杯 STAMP 盖一章，满 10 章 FREE 换一杯并清盘重记，盖错 UNDO 撤回最后一章。换过的免费杯数单独计数。它不绑定任何店铺系统、不查余额，卡面规则（几章换一杯）以店内告示为准，界面明写。

## 预览截图

![预览-index](<../screenshots/cafe-stamp/preview-cafe-stamp-index.png>)
![预览-s2](<../screenshots/cafe-stamp/preview-cafe-stamp-s2.png>)
![预览-s3](<../screenshots/cafe-stamp/preview-cafe-stamp-s3.png>)
![预览-s4](<../screenshots/cafe-stamp/preview-cafe-stamp-s4.png>)

## 在地性

韩国咖啡店的印章卡（스탬프 카드）是常见的常客制度：买一杯盖一章，集满 10 个换一杯免费。最容易乱的是「这张卡到底盖了几个、免费那杯换了没有」——尤其多家店的卡混在一起时。眼镜不扫码、不认店，只守这一张卡的章数与兑换。

## 功能流程（闭环）

- 盖章：STAMP 每按一次加一章，章盘实时填满，满 10 章时大字提示可换免费杯
- 兑换：FREE 只在满 10 章时生效，兑换后章盘清零、免费杯数 +1；未满时只声提醒不兑换
- 纠错：UNDO 撤回最后一章，盖错当场可改；换过的免费杯数单独留存不随清盘消失

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 STAMP 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- 章数由本人手动登记，Agent 不扫码、不连店铺系统，盖错请在兑换前用 UNDO 修正
- 「10 章换一杯」是本卡的目安口径，各店规则不同，以店内告示为准，界面明示
- 免费杯的实际兑换以店员确认为准，Agent 的 FREE 只记一次兑换意向与结果

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/cafe-stamp
~/tools/bin/aix pack . -o ../dist/cafe-stamp.aix
~/tools/bin/aix list ../dist/cafe-stamp.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Cafe Stamp（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Korean cafe: tracks one stamp card toward ten stamps and records each free-drink redemption. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Cafe stamp card: one card, ten stamps, one free drink. STAMP adds a stamp per coffee, the ten-cell card fills in plain sight, FREE redeems only at ten stamps and clears the card, and UNDO takes back a mistaken stamp. It never scans, never connects to any shop system, and the shop's own sign decides the rule.

### Opening Message

> ## Cafe Stamp
> 
> A stamp card fails on two small questions: how many stamps are on it, and has the free drink been claimed. I keep one card: ten cells, one stamp per coffee, and the free drink only when the card is full. A mistaken stamp comes straight back off. The shop's sign makes the rule, not me.

### Preview Media

- `preview-cafe-stamp-index.png` — 初始状态
- `preview-cafe-stamp-s2.png` — 演示状态 2
- `preview-cafe-stamp-s3.png` — 演示状态 3
- `preview-cafe-stamp-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：도장 카드 Stamp Card；도장 격자판：10칸 도장 셀 + 교환 행

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
