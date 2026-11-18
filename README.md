# 跳绳游戏

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-ropejump-game
```

[china-ropejump-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-ropejump-game.aix)

## 功能

中国家庭跳绳时间，孩子与家人用眼镜玩 10 轮跳绳花样比拼，转头选花样、点头开跳，结算计分、最佳成绩跨会话保存。

## 场景

中国家庭跳绳时间，孩子与家人用眼镜玩 10 轮跳绳花样比拼，转头选花样、点头开跳。

## 方向构成

中国在地 × 游戏 × 指向性（转头选花样）。

## 眼镜独占能力

视线与头部方向协调＋点头主确认：转头选跳绳花样、点头开跳，不用掏手机。接线：pages/play/index.ink 的 _startSensor＋_onYaw（回正再武装、左退一个／右进一个、分段动作、绝不转圈）＋ onHeadGesture 点头触发 primaryTap 参赛；无传感器时按钮切花样可玩。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 8 种跳绳花样与最佳成绩 |
| pages/play | 10 轮花样配对、点头开跳、结算计分 |
| pages/record | 跳绳记录 |

## 内容集

跳绳花样 8 种：单摇跳、双摇跳、交叉跳、单脚跳、跑步跳、开合跳、后摇跳、并脚跳。10 轮固定目标序列 [2,0,5,1,7,3,6,4,2,0] 写在代码里。

## 跨会话持久化

存储键 `chinaRopeJumpGameV1`（最佳成绩、已结算记录、lastError）。

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

- 分数只来自真实点头与点按，不虚构分数。
- 分段动作：一次转头只换一个花样，须回中再换，绝不转圈。
- 目标序列固定写在代码里，不声称随机抽取。
- 无传感器时按钮切花样可玩，计分规则不变。

## 预览截图

![preview-china-ropejump-game-index.png](../screenshots/china-ropejump-game/preview-china-ropejump-game-index.png)
![preview-china-ropejump-game-play.png](../screenshots/china-ropejump-game/preview-china-ropejump-game-play.png)
![preview-china-ropejump-game-play-s2.png](../screenshots/china-ropejump-game/preview-china-ropejump-game-play-s2.png)
![preview-china-ropejump-game-record.png](../screenshots/china-ropejump-game/preview-china-ropejump-game-record.png)

## 提审资料

### Feature Description

中国家庭跳绳时间，孩子与家人用眼镜玩 10 轮跳绳花样比拼，转头选花样、点头开跳，结算计分、最佳成绩跨会话保存。

### Opening Message

跳绳时间到！对上目标花样、点头开跳，10 轮比出胜负。

### Preview Media

[preview-china-ropejump-game-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-ropejump-game/preview-china-ropejump-game-video.mp4)
![preview-china-ropejump-game-index.png](../screenshots/china-ropejump-game/preview-china-ropejump-game-index.png)
![preview-china-ropejump-game-play.png](../screenshots/china-ropejump-game/preview-china-ropejump-game-play.png)
![preview-china-ropejump-game-play-s2.png](../screenshots/china-ropejump-game/preview-china-ropejump-game-play-s2.png)

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
