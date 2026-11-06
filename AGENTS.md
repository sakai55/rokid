# 龙舟游戏集 - Agent Notes

GA63. 中国在地 × 游戏 × 指向性 × 注意力。

## Design contract

端午家庭等待时间，全家用眼镜一本玩 20 个龙舟游戏。

## Counts

20 个工具：19 个游戏（数数 4、问答 4、方向 4、步骤 4、算数 3）＋1 个记录工具。数数目标 12/10/15/8，方向每局 6 轮，步骤每局 5 步。

## Storage

存储键 `chinaDragonboatGamesV1`（已选游戏、每游戏最佳、已结算记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 分数只来自真实点头与点按，不虚构分数。
- 无传感器时方向游戏可用按钮选方向，传感器失败显示 E7001。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 独占接线：每游戏页点头触发，方向页 _startSensor。
