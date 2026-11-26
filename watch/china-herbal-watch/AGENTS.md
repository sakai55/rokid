# 中药煎药守候 - Agent Notes

WA49. 中国在地 × 注意力（多锅中药计时守候）× 指向性（转头切药位）。

## Design contract

中国家庭煎中药时煎药者双手忙，看向一锅中药、点头登记计时，多锅不煎过。

## Counts

6 组中药与家庭煎药计时预设秒数：当归 1800 秒、黄芪 2400 秒、甘草 1200 秒、茯苓 1800 秒、白芍 1500 秒、陈皮 900 秒。

## Storage

存储键 `chinaHerbalWatchV1`（各锅中药计时、出锅记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 只按时间提醒，不声称测药效、不给用药建议；本智能体不提供医疗建议，用药与煎药请遵医嘱。
- 计时秒数为家庭计时预设，不是实测标准，也不是医嘱。
- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切药位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头登记；守候页 onLoad 读存储 selected。
- 判定：原拟 china-soup-watch 已存在为 WA16，本台为替代概念（见 README 判定说明）。
