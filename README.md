# 太极游戏

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-taiji-game
```

[china-taiji-game.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-taiji-game.aix)

## 功能

中国家庭太极时间，孩子与家人用眼镜玩 10 轮太极招式比拼，转头选招式、点头开练，结算计分、最佳成绩跨会话保存。

## 场景

中国家庭太极练习时间，孩子与家人用眼镜玩 10 轮太极招式比拼，转头选招式、点头开练，结算计分。

## 方向构成

中国在地 × 游戏 × 指向性（转头选招式）。游戏承载 10 轮比拼循环；指向性承载转头选招式（左退一个／右进一个、回中再换）。

## 眼镜独占能力

头部方向协调：转头选太极招式、点头开练，不用掏手机。接线：pages/play/index.ink 的 _startSensor＋_onYaw（回正再武装、左退一个／右进一个、分段动作、绝不转圈）＋ onHeadGesture 点头触发 primaryTap 开练；无传感器时按钮切招式可玩。传感器失败报 E7001。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 8 式太极招式与最佳成绩 |
| pages/play | 10 轮招式配对、点头开练、结算计分 |
| pages/record | 太极记录 |

## 内容集

太极招式 8 式（二十四式太极拳实名：起势、野马分鬃、白鹤亮翅、搂膝拗步、手挥琵琶、倒卷肱、云手、金鸡独立；下势独立又称金鸡独立）。10 轮固定目标序列 [3, 0, 6, 2, 7, 4, 1, 5, 3, 0] 写在代码里，与 GA93 空竹 [1, 4, 0, 6, 2, 7, 3, 5, 1, 4]、GA83 踢毽子 [0, 4, 1, 7, 3, 5, 2, 6, 4, 1]、GA87 跳绳 [2, 0, 5, 1, 7, 3, 6, 4, 2, 0]、GA94 新西兰哈卡 [3, 6, 1, 7, 0, 4, 2, 5, 3, 6] 均不同（GA94 序列系打包前在本机仓库核对）。

## 跨会话持久化

存储键 `chinaTaijiGameV1`（最佳成绩、已结算记录、lastError）。

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


## 诚实边界

- 分数只来自真实点头与点按，不虚构分数。
- 招式判定为演示判定、非物理识别：点头开练只比对选定招式与目标招式，不检测真实太极动作。
- 分段动作：一次转头只换一个招式，须回中再换，绝不转圈。
- 目标序列固定写在代码里，不声称随机抽取。
- 无传感器时按钮切招式可玩，计分规则不变。

## 预览截图

![preview-china-taiji-game-index.png](../screenshots/china-taiji-game/preview-china-taiji-game-index.png)
![preview-china-taiji-game-play.png](../screenshots/china-taiji-game/preview-china-taiji-game-play.png)
![preview-china-taiji-game-play-s2.png](../screenshots/china-taiji-game/preview-china-taiji-game-play-s2.png)
![preview-china-taiji-game-record.png](../screenshots/china-taiji-game/preview-china-taiji-game-record.png)


## 提审资料

### Feature Description

中国家庭太极时间，孩子与家人用眼镜玩 10 轮太极招式比拼，转头选招式、点头开练，结算计分、最佳成绩跨会话保存。

### Opening Message

太极时间到！对上目标招式、点头开练，10 轮比出胜负。

### Preview Media

[preview-china-taiji-game-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-taiji-game/preview-china-taiji-game-video.mp4)
![preview-china-taiji-game-index.png](../screenshots/china-taiji-game/preview-china-taiji-game-index.png)
![preview-china-taiji-game-play.png](../screenshots/china-taiji-game/preview-china-taiji-game-play.png)
![preview-china-taiji-game-play-s2.png](../screenshots/china-taiji-game/preview-china-taiji-game-play-s2.png)

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
