# 广场舞步

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-square-dance
```

[china-square-dance.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-square-dance.aix)

## 功能

小区广场舞时间，家人只用头部方向选舞步、点头踩拍，玩 10 轮广场舞步游戏并结算最佳成绩。

## 场景

中国小区广场舞时间，家人只用头部方向选舞步、点头踩拍，玩广场舞步游戏，10 轮结算。

## 方向构成

中国在地 × 游戏（10 轮舞步玩法闭环）× 指向性（头部方向选步）。游戏承担开始／踩拍／计分／结算闭环，指向性承担头向选步机制。

## 眼镜独占能力

视线与头部方向协调：眼睛与头的朝向即选择，点头即踩拍，玩的过程中不用手持机、不用低头。接线：pages/play/index.ink 的 _startSensor（AbsoluteOrientationSensor 存在性守卫）＋ _onYaw（回正 armed 门：|yaw|<0.15 回中待命，左右转头各切一步）＋ onHeadGesture 点头触发 primaryTap 踩拍；无传感器时按钮换步兜底。

## 页面

| 页面 | 职责 |
|---|---|
| pages/index | 规则、8 种舞步与最佳成绩 |
| pages/play | 10 轮选步踩拍，命中计分，结算写记录 |
| pages/record | 最近 6 局与合计、最佳 |

## 内容集

8 种舞步：十字步、三步踩、转圈步、摆手步、踢腿步、小跑步、扭腰步、拍手步。10 轮目标舞步由固定序列 [十字步，摆手步，三步踩，拍手步，转圈步，扭腰步，踢腿步，小跑步，三步踩，摆手步] 出，序列写进代码可数。

## 跨会话持久化

存储键 `chinaSquareDanceV1`。存最佳成绩、结算记录数组、lastError。

## 权限

无清单权限。语音播报不需要清单权限，相机与定位不用。

## 手势映射

| 镜腿手势 | 按键事件 | 本台作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（各页主按钮） |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## 错误码

- `E5001` 存储写入失败
- `E5002` 存储读取失败
- `E3005` 语音播报失败
- `E8001` 页面跳转失败
- `E7001` 头部传感器不可用或读数失败

失败时屏显裸码，lastError 里同时记裸码、slug、版本与原文。

## 预览截图

![preview-china-square-dance-index.png](../screenshots/china-square-dance/preview-china-square-dance-index.png)
![preview-china-square-dance-play.png](../screenshots/china-square-dance/preview-china-square-dance-play.png)
![preview-china-square-dance-record.png](../screenshots/china-square-dance/preview-china-square-dance-record.png)

## 提审资料

### Feature Description

小区广场舞时间，家人只用头部方向选舞步、点头踩拍，玩 10 轮广场舞步游戏并结算最佳成绩。

### Opening Message

广场舞时间到了，转头选步、点头踩拍，来打一局十轮舞步。

### Preview Media

[preview-china-square-dance-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-square-dance/preview-china-square-dance-video.mp4)
![preview-china-square-dance-index.png](../screenshots/china-square-dance/preview-china-square-dance-index.png)
![preview-china-square-dance-play.png](../screenshots/china-square-dance/preview-china-square-dance-play.png)
![preview-china-square-dance-record.png](../screenshots/china-square-dance/preview-china-square-dance-record.png)


### Change Log

- Features：首版功能，见上文页面表。
- Improvements：无。
- Fixes：无。

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名称 | 待填 |
| Version / Build | 待填 |
| App Category | 待填 |
| Intent Description | 待填 |
| Agent ID | 待填 |
| 状态 | 待填 |
