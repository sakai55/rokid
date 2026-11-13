# 放风筝游戏 - Agent Notes

GA77. 中国在地 × 游戏 × 指向性（转头选风向）。

## Design contract

中国家庭放风筝时只用头部方向选风向、点头放线，10 轮结算。

## Counts

风筝 6 只：蝴蝶风筝、老鹰风筝、龙风筝、金鱼风筝、燕子风筝、蜈蚣风筝；每局 10 轮，目标风向左／右／中／左／中／右／右／左／中／右。

## Storage

存储键 `chinaKiteGameV1`（已选风筝、最佳命中、放线记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 风向目标每局固定 10 轮，不声称测真实风速。
- 无传感器时按钮换方向可玩，传感器失败显示 E7001。
- 分数只来自真实点头与点按，不虚构分数。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/play/index.ink 的 _startSensor＋_onYaw＋点头放线；命中判定用 ["左", "中", "右"].indexOf 比较。
- 10 轮结算：10 轮后结算计分，成绩跨会话保存。
