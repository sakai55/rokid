# 烤鸭守候 - Agent Notes

WA28. 中国在地 × 注意力（多盘计时守候）× 指向性（转头切烤盘位）。

## Design contract

中国家庭做烤鸭时，做饭者双手忙，看向一烤盘、点头登记计时，多盘不烤糊。

## Counts

6 种烤制与建议烤制秒数：北京烤鸭 3600 秒、烤乳猪 3000 秒、烤羊排 2700 秒、烤鸡 2400 秒、烤鱼 1800 秒、烤蔬菜 1200 秒。

## Storage

存储键 `chinaRoastduckWatchV1`（各烤盘计时、出炉记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每盘只说一次，出炉记录只由到时后的登记确认写下。
- 无传感器时按钮切烤盘位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
