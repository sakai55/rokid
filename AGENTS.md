# 跳绳游戏 - Agent Notes

GA87. 中国在地 × 游戏 × 指向性（转头选花样）。

## Design contract

中国家庭跳绳时间，孩子与家人用眼镜玩 10 轮跳绳花样比拼，转头选花样、点头开跳。

## Counts

跳绳花样 8 种：单摇跳、双摇跳、交叉跳、单脚跳、跑步跳、开合跳、后摇跳、并脚跳。10 轮固定目标序列 [2,0,5,1,7,3,6,4,2,0] 写在代码里。

## Storage

存储键 `chinaRopeJumpGameV1`（最佳成绩、已结算记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 分数只来自真实点头与点按，不虚构分数。
- 分段动作：一次转头只换一个花样，须回中再换，绝不转圈。
- 目标序列固定写在代码里，不声称随机抽取。
- 无传感器时按钮切花样可玩，计分规则不变。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：pages/play/index.ink _startSensor＋_onYaw（回正武装）＋点头参赛。
- 10 轮固定序列写在代码里，结算按真实命中数。
