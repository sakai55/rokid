# 煲仔饭守候 - Agent Notes

WA20. 中国在地 × 注意力（多锅计时守候）× 指向性（转头切锅位）。

## Design contract

中国家庭做煲仔饭时，做饭者双手忙，看向一口砂锅、点头登记计时，多锅不煲过。

## Counts

6 种煲仔饭与建议煲制秒数：腊味 1800 秒、排骨 2100 秒、鸡肉 1500 秒、牛肉 1800 秒、香菇滑鸡 1500 秒、咸鱼茄子 1200 秒。

## Storage

存储键 `chinaClaypotWatchV1`（各煲仔饭计时、出锅记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切锅位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
