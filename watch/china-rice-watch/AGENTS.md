# 蒸米饭守候 - Agent Notes

WA46. 中国在地 × 注意力（多锅蒸米饭计时守候）× 指向性（转头切锅位）。

## Design contract

中国家庭蒸米饭时做饭者双手忙，看向一锅饭、点头登记计时，多锅不蒸老。

## Counts

6 组米饭与建议计时秒数：白米饭 1500 秒、糙米饭 2400 秒、八宝饭 3600 秒、糯米饭 2100 秒、杂粮饭 2700 秒、腊味饭 2400 秒。

## Storage

存储键 `chinaRiceWatchV1`（各锅蒸米饭计时、出锅记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 只按时间提醒，不声称测熟度；熟度以现场判断为准。
- 计时秒数为家庭计时预设，不是实测熟度标准。
- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切锅位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
