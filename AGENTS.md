# 烧烤守候 - Agent Notes

WA30. 中国在地 × 注意力（多烤架计时守候）× 指向性（转头切烤位）。

## Design contract

中国家庭烧烤时双手忙，看向一烤架、点头登记计时，多架不烤糊。

## Counts

6 种烤物与建议烤制秒数：羊肉串 600 秒、鸡翅 900 秒、玉米 1200 秒、茄子 900 秒、五花肉 720 秒、秋刀鱼 480 秒。

## Storage

存储键 `chinaBbqWatchV1`（各烤架计时、出炉记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 只按时间提醒，不声称测熟度；熟度以现场判断为准。
- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每架只说一次，出炉记录只由到时后的登记确认写下。
- 无传感器时按钮切烤位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
