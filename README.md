# 踢毽子游戏

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-jianzi-game
```

[china-jianzi-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-jianzi-game.aix)

## 功能

家庭聚会时家人只用头部方向选落点、点头踢毽子，10 轮结算最佳成绩，成绩跨会话保存。

## 场景

家庭聚会时家人只用头部方向选落点、点头踢毽子，10 轮结算。

## 方向构成

中国在地 × 游戏 × 指向性。

## 眼镜独占能力

视线与头部方向协调：眼睛与头的朝向即选择，点头即踢毽子，玩的过程中不用手持机、不用低头。接线：pages/play/index.ink 的 _startSensor（AbsoluteOrientationSensor 存在性守卫）＋_onYaw（回正 armed 门：|yaw|<0.15 回中待命，左右转头各切一种踢法）＋ onHeadGesture 点头触发 primaryTap 踢毽子；无传感器时按钮换踢法兜底。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 规则、8 种踢法与最佳成绩 |
| pages/play | 10 轮选踢法踢毽子，踢中计分，结算写记录 |
| pages/record | 最近 6 局与合计、最佳 |

## 内容集

8 种踢法：正踢／侧踢／后踢／盘踢／拐踢／抹踢／绷踢／跳踢。10 轮目标踢法由固定序列 [正踢，盘踢，侧踢，跳踢，拐踢，抹踢，后踢，绷踢，盘踢，侧踢] 出，序列写进代码可数。

## 跨会话持久化

存储键 `chinaJianziGameV1`（最佳成绩、结算记录数组、lastError）。

## 权限

无清单权限。语音播报不需要清单权限，相机与定位不用。

## 手势映射

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## 错误码

- `E5001` 存储写入失败
- `E5002` 存储读取失败
- `E3005` 语音播报失败
- `E8001` 页面跳转失败
- `E7001` 头部传感器不可用或读数失败

- 分段动作：转头一次只切一种踢法，必须回中才能再切，绝不连续转圈。
- 无传感器时按钮换踢法可玩，计分逻辑不变。
- 目标序列固定写进代码，不声称随机出题。

## 预览截图

![preview-china-jianzi-game-index.png](../screenshots/china-jianzi-game/preview-china-jianzi-game-index.png)
![preview-china-jianzi-game-play.png](../screenshots/china-jianzi-game/preview-china-jianzi-game-play.png)
![preview-china-jianzi-game-play-s2.png](../screenshots/china-jianzi-game/preview-china-jianzi-game-play-s2.png)
![preview-china-jianzi-game-record.png](../screenshots/china-jianzi-game/preview-china-jianzi-game-record.png)

## 提审资料

### Feature Description

家庭聚会时家人只用头部方向选落点、点头踢毽子，10 轮结算最佳成绩，成绩跨会话保存。

### Opening Message

毽子拿好了，看目标踢法、转头选踢法、点头踢，10 轮见分晓。

### Preview Media

[preview-china-jianzi-game-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-jianzi-game/preview-china-jianzi-game-video.mp4)
![preview-china-jianzi-game-index.png](../screenshots/china-jianzi-game/preview-china-jianzi-game-index.png)
![preview-china-jianzi-game-play.png](../screenshots/china-jianzi-game/preview-china-jianzi-game-play.png)
![preview-china-jianzi-game-play-s2.png](../screenshots/china-jianzi-game/preview-china-jianzi-game-play-s2.png)

### Change Log

- Features：首版功能见上文页面表。
- Improvements：无。
- Fixes：无.

## 设备测试信息

| Studio 名称 | 待填 |
|---|---|
| Studio 名称 | 待填 |
| Version / Build | 待填 |
| App Category | 待填 |
| Intent Description | 待填 |
| Agent ID | 待填 |
| 状态 | 待填 |
