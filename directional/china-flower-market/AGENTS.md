# 斗南花市选摊 - Agent Notes

DI74. 中国在地 × 指向性（转头选摊）× 注意力（逐项确认）。

## Design contract

中国昆明斗南花市买花者双手提袋，靠转头选摊、点头逐项确认 4 项，买完记一次。

## Counts

摊位 6 个×确认项 4 项＝24 个确认项。

## Storage

存储键 `chinaFlowerMarketV1`（已选摊位、买完记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 价格与新鲜程度以现场摊位为准，内置清单为示例。
- 无传感器时可用按钮选摊位。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/index/index.ink 的 _startSensor＋_onYaw。
