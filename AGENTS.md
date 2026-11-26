# 舞狮游戏 - Agent Notes

GA98. 中国在地 × 游戏 × 指向性（转头选招式）。

## Design contract

中国家庭舞狮时间，孩子与家人用眼镜玩 10 轮舞狮招式比拼，转头选招式、点头开练。

## Counts

舞狮招式 8 式：起势、采青、酣睡、出洞、抓痒、施礼、惊跃、上楼台。10 轮固定目标序列 [5, 1, 7, 0, 4, 6, 2, 3, 5, 1] 写在代码里。

## Storage

存储键 `chinaLionDanceGameV1`（最佳成绩、已结算记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 分数只来自真实点头与点按，不虚构分数。
- 招式判定为演示判定、非物理识别：点头开练只比对选定招式与目标招式，不检测真实舞狮动作。
- 分段动作：一次转头只换一个招式，须回中再换，绝不转圈。
- 目标序列固定写在代码里，不声称随机抽取。
- 无传感器时按钮切招式可玩，计分规则不变。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/play/index.ink _startSensor＋_onYaw（回正武装）＋点头开练。
- 10 轮固定序列 [5, 1, 7, 0, 4, 6, 2, 3, 5, 1] 写在代码里，与 GA93/GA94/GA96/GA83/GA87 均不同，结算按真实命中数。
- 判定：与 china-festival-game-shuu 的迷你游戏「舞狮节奏」机制与内容集不同，标题不用「舞狮节奏」（见 README 判定说明）。
