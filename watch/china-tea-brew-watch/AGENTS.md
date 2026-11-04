# 功夫茶守候 - Agent Notes

WA12. 中国在地 × 注意力（多茶计时守候）× 指向性（转头切茶位）。

## Design contract

功夫茶冲泡时，泡茶者双手拿壶杯、看向一种茶、点头登记计时，多茶不泡过。

## Counts

6 种茶与建议冲泡秒数：铁观音 60 秒、普洱 90 秒、龙井 45 秒、大红袍 75 秒、菊花茶 120 秒、白茶 180 秒。

## Storage

存储键 `chinaTeaBrewWatchV1`（各茶计时、出汤记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每茶只说一次，出汤记录只由到时后的登记确认写下。
- 无传感器时按钮切茶位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记。
