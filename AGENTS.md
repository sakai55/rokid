# 踢毽子游戏 - Agent Notes

GA83. 中国在地 × 游戏 × 指向性。

## Design contract

家庭聚会时家人只用头部方向选落点、点头踢毽子，10 轮结算。

## Counts

8 种踢法：正踢／侧踢／后踢／盘踢／拐踢／抹踢／绷踢／跳踢。10 轮目标踢法由固定序列 [正踢，盘踢，侧踢，跳踢，拐踢，抹踢，后踢，绷踢，盘踢，侧踢] 出，序列写进代码可数。

## Storage

存储键 `chinaJianziGameV1`（最佳成绩、结算记录数组、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 分段动作：转头一次只切一种踢法，必须回中才能再切，绝不连续转圈。
- 无传感器时按钮换踢法可玩，计分逻辑不变。
- 目标序列固定写进代码，不声称随机出题。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 传感器接线：pages/play/index.ink 的 _startSensor（存在性守卫）＋_onYaw（回正门）＋ onHeadGesture 点头踢毽子。
- 10 轮固定序列写进代码，结算按实数计。
