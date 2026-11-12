# 潘家园选摊指南 - Agent Notes

DI86. 中国在地 × 指向性（转头选摊）× 注意力（逐项确认）。

## Design contract

潘家园古玩市场买古玩的人双手提袋，靠转头选摊、点头逐项确认，买完记一次。

## Counts

摊位 6 个×确认项 4 项＝24 个确认项：瓷器摊、玉器摊、字画摊、铜器摊、木雕摊、旧书摊；每摊确认问过价了、看过成色了、讲过价了、装好袋了。

## Storage

存储键 `chinaPanjiayuanMarketV1`（已选摊位、买完记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 价格与真伪以现场摊位与行家为准，不声称鉴定。
- 无传感器时可用按钮选摊位。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/index/index.ink 的 _startSensor＋_onYaw。
