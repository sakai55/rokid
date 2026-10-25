# Gye Circle（韩式互助会轮次账）

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-gye-circle
```

KR12 · 韩国本地化系列。交互哲学：**계 원형 Gye Circle**。本 Agent 是一本只记轮次的 계 账：四人轮流当「这次收的人」，轮盘中央就是本月收款人。PAY 记下本月已交齐，NEXT 才把轮盘转到下一个人；没交齐就转，声提醒拦住。转满一圈计一轮。它不收钱、不算利息、不催任何人，界面明写。

## 预览截图

![预览-index](<../screenshots/gye-circle/preview-gye-circle-index.png>)
![预览-s2](<../screenshots/gye-circle/preview-gye-circle-s2.png>)
![预览-s3](<../screenshots/gye-circle/preview-gye-circle-s3.png>)
![预览-s4](<../screenshots/gye-circle/preview-gye-circle-s4.png>)

## 在地性

계모임（계）是韩国熟人之间轮流出钱、轮流收款的互助制度：每月每人出一份，到期的一人收走一笔。最容易乱的不是金额，而是「这次轮到谁收、这个月大家交齐了没有」。眼镜不经手钱——只记轮次与交齐确认，金额与收付仍由成员当面处理。

## 功能流程（闭环）

- 轮盘保持：지영→민준→서연→현우 四人轮序，中央是本月收款人，前后两人分列上下
- 交齐确认：PAY 由本人确认本月已交齐后才允许转盘；未交齐时 NEXT 只声提醒不转
- 计轮：转满一圈计一轮，轮数单独计数；金额与收付方式成员当面定，Agent 不插手

## 手势映射

| 手势（镜腿触控板） | 键事件 | 在本 Agent 中的作用 |
|---|---|---|
| 单击 | Enter | 情境 GO（见 README 功能流程与界面 guide 行） |
| 上滑 / 下滑 | ArrowUp / ArrowDown | 见界面 guide 行的本 Agent 专属定义 |
| 点头（头稳时） | `onHeadGesture('nod')` | 本 Agent 的主确认（与 PAY 等价，见 guide 行） |
| 双击 | Backspace | 系统返回（不拦截） |

屏幕按钮均为上述手势的镜像，另加 SPEAK（随时听当前状态）与 DEMO（演示状态机，退出后真实状态原样恢复）。

## 权限

| 权限 | 用途 |
|---|---|
| （无） | 本 Agent 不申请任何权限；TTS 与传感器不需要清单权限，相机零调用（如适用） |

## 诚实边界

- Agent 不经手任何金钱，不记录金额、不计算利息、不催缴——只记「轮到谁」与「交齐与否」
- 交齐与否由本人确认，Agent 不做银行或转账核验；轮序与金额规则以该 계모임 成员的约定为准
- 成员名是示例轮序，实际成员与顺序以本 계모임 的约定为准

- TTS 用宿主固定音色，永不设置 utterance 的 `lang`（官方注明不生效）。

## 打包与预览

```bash
cd ~/workspace/rokid/gye-circle
~/tools/bin/aix pack . -o ../dist/gye-circle.aix
~/tools/bin/aix list ../dist/gye-circle.aix
```

## 真机测试信息

| 字段 | 值 |
|---|---|
| Studio 名称 | Gye Circle（待导入后回填） |
| Version / Build | 1.0.0 / 待导入后回填 |
| App Category | Life |
| Intent Description | At a Korean gye gathering: tracks whose turn it is to receive and whether this month is marked paid. |
| Agent ID | 待导入后回填 |
| 状态 | 本地构建完成，待导入 Studio |

## 提审资料 (Review Submission)

### Feature Description

> Gye circle: the Korean rotating savings circle, kept in order. Four members take turns receiving, the wheel shows who receives this month with the previous and next members beside them, and the wheel only turns once this month is marked paid. It never touches money, records no amounts, and never chases anyone.

### Opening Message

> ## Gye Circle
> 
> A gye only works when everyone knows whose turn it is and whether this month is settled. I keep that wheel: four members in turn, this month's receiver in the centre, and the wheel turns only after the month is marked paid. I never touch money and I never chase anyone - the circle belongs to its members.

### Preview Media

- `preview-gye-circle-index.png` — 初始状态
- `preview-gye-circle-s2.png` — 演示状态 2
- `preview-gye-circle-s3.png` — 演示状态 3
- `preview-gye-circle-s4.png` — 演示状态 4

> 正式提审需 3–5 个媒体文件且含 ≥1 段视频（≤60 s），视频待 GO 真机自测时补录。

### Change Log（Build 1.0.0）

**Features added**

- 首个版本：계 원형 Gye Circle；계 원형 휠：받을 차례 + 이전/다음 사람 + 납부 여부

**Improvements**

- 无（首个版本）

**Fixes**

- 无（首个版本）
