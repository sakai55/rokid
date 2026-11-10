# 蒸包子守候 - Agent Notes

WA24. 中国在地 × 注意力（多锅计时守候）× 指向性（转头切包子位）。

## Design contract

中国家庭蒸包子时，做饭者双手沾面，看向一种包子、点头登记计时，多锅不蒸过。

## Counts

6 种包子与建议蒸制秒数：鲜肉包 900 秒、素菜包 720 秒、豆沙包 600 秒、小笼包 480 秒、叉烧包 780 秒、南瓜包 660 秒。

## Storage

存储键 `chinaBaoziWatchV1`（各包子计时、出锅记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切包子位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
