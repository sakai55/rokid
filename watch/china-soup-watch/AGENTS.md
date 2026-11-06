# 煲汤守候 - Agent Notes

WA16. 中国在地 × 注意力（多锅计时守候）× 指向性（转头切锅位）。

## Design contract

中国家庭煲汤者双手忙，看向一口汤锅、点头登记计时，多锅不煲过。

## Counts

6 种汤与建议煲汤秒数：鸡汤 3600 秒、排骨汤 3000 秒、鱼汤 1800 秒、冬瓜汤 1200 秒、莲藕汤 2400 秒、玉米汤 1500 秒。

## Storage

存储键 `chinaSoupWatchV1`（各汤计时、出锅记录、lastError）。

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
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记。
