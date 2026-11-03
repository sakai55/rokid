# 火锅守候 — Agent Notes

WA10。中国组：中国在地 × 注意力 × 指向性。

## Design contract

中国家庭吃火锅时，涮菜者双手拿筷子漏勺、看向一口锅、点头登记计时，多锅不涮过。

## Counts

内容集：6 组锅／菜品（毛肚／羊肉卷／虾滑／豆腐／金针菇／菠菜），建议涮时各为 15／30／180／120／60／30 秒。出锅记录按实数计。

## Storage

存储键 `chinaHotpotWatchV1`（各锅计时、菜品与建议秒数及开始时间、出锅记录数组、lastError）。

## Gesture map

| 镜腿手势 | 按键事件 | 本台作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（守候页为登记计时） |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换锅位 |
| 点头 | onHeadGesture('nod') | 等同主确认：登记计时 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次；出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切锅位可玩，计时本身不依赖传感器。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 守候接线：pages/watch/index.ink 的 _startSensor（存在性守卫）＋ _onYaw 切锅位 ＋ primaryTap 登记／出锅。
