# 豆腐菜守候 - Agent Notes

WA47. 中国在地 × 注意力（多锅豆腐菜计时守候）× 指向性（转头切锅位）。

## Design contract

中国家庭做豆腐菜时做饭者双手忙，看向一锅豆腐菜、点头登记计时，多锅不煮老。

## Counts

6 组豆腐菜与建议计时秒数：麻婆豆腐 600 秒、小葱拌豆腐 180 秒、鱼香豆腐 900 秒、豆腐脑 480 秒、家常豆腐 720 秒、豆腐丸子 1200 秒。

## Storage

存储键 `chinaTofuWatchV1`（各锅豆腐菜计时、出锅记录、lastError）。

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
- 判定：6 道完整豆腐菜，与既有 watch 菜名 0 逐字重复（见 README 判定说明）。
