# 煮汤圆守候 - Agent Notes

WA36. 中国在地 × 注意力（多锅计时守候）× 指向性（转头切锅位）。

## Design contract

中国家庭煮汤圆时做饭者双手忙，看向一口锅、点头登记计时，多锅不煮破。

## Counts

6 组汤圆与建议煮制秒数：黑芝麻 600 秒、花生 540 秒、鲜肉 480 秒、豆沙 420 秒、紫薯 360 秒、南瓜 300 秒。

## Storage

存储键 `chinaTangyuanWatchV1`（各锅计时、出锅记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 只按时间提醒，不声称测熟度；熟度以现场判断为准。
- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切锅位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
