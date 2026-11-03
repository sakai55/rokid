# 广场舞步 — Agent Notes

GA57。中国组：中国在地 × 游戏 × 指向性。

## Design contract

中国小区广场舞时间，家人只用头部方向选舞步、点头踩拍，玩广场舞步游戏，10 轮结算。

## Counts

内容集：8 种舞步（十字步／三步踩／转圈步／摆手步／踢腿步／小跑步／扭腰步／拍手步）；10 轮目标序列写进代码（十字步，摆手步，三步踩，拍手步，转圈步，扭腰步，踢腿步，小跑步，三步踩，摆手步）。结算记录按实数计。

## Storage

存储键 `chinaSquareDanceV1`（最佳成绩、结算记录数组、lastError）。

## Gesture map

| 镜腿手势 | 按键事件 | 本台作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（玩页为踩拍） |
| 上滑／下滑 | ArrowUp / ArrowDown | 换舞步 |
| 点头 | onHeadGesture('nod') | 等同主确认：踩拍 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 分段动作：转头一次只切一步，必须回中才能再切，绝不连续转圈。
- 无传感器时按钮换步可玩，计分逻辑不变。
- 目标序列固定写进代码，不声称随机出题。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 传感器接线：pages/play/index.ink 的 _startSensor（存在性守卫）＋ _onYaw（回正门）＋ onHeadGesture 点头踩拍。
