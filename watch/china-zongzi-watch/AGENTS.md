# 煮粽子守候 - Agent Notes

WA26. 中国在地 × 注意力（多锅计时守候）× 指向性（转头切粽子位）。

## Design contract

中国家庭煮粽子时，做饭者双手沾水，看向一种粽子、点头登记计时，多锅不煮过。

## Counts

6 种粽子与建议煮制秒数：鲜肉粽 7200 秒、豆沙粽 5400 秒、蛋黄粽 6600 秒、蜜枣粽 4800 秒、白粽 3600 秒、八宝粽 6000 秒。

## Storage

存储键 `chinaZongziWatchV1`（各粽子计时、出锅记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切粽子位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
