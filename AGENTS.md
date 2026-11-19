# 蒸鱼守候 - Agent Notes

WA42. 中国在地 × 注意力（多蒸笼计时守候）× 指向性（转头切笼位）。

## Design contract

中国家庭蒸鱼时做饭者双手忙，看向一蒸笼、点头登记计时，多笼不蒸老。

## Counts

6 组蒸鱼与建议蒸制秒数：清蒸鲈鱼 600 秒、清蒸鲳鱼 540 秒、清蒸鳜鱼 660 秒、清蒸多宝鱼 720 秒、清蒸黄花鱼 480 秒、清蒸鲫鱼 420 秒。

## Storage

存储键 `chinaSteamedfishWatchV1`（各蒸笼计时、出笼记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 只按时间提醒，不声称测熟度；熟度以现场判断为准。
- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每笼只说一次，出笼记录只由到时后的登记确认写下。
- 无传感器时按钮切笼位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
