# 中国棋牌游戏集

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-board-games-shuu
```

[china-board-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-board-games-shuu.aix)

## 功能

中国棋牌游戏集：家庭等待时间，全家用一副眼镜玩 20 个棋牌游戏，每个游戏结算计分、成绩跨会话保存。

## 场景

中国家庭等待时间，全家用眼镜玩棋牌游戏，每个游戏结算计分。

## 方向构成

中国在地 × 游戏 × 指向性 × 注意力。

## 眼镜独占能力

视线与头部方向协调＋点头主确认：方向游戏靠转头选方向、点头确认，不用掏手机。接线：每游戏页 onHeadGesture 点头触发 primaryTap，方向页 g02/g07/g12/g17 的 _startSensor＋_onYaw；命中判定用 ["左", "中", "右"].indexOf 比较。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 20 个游戏总览 |
| pages/g01 | 象棋数子 |
| pages/g02 | 军棋方向 |
| pages/g03 | 扑克问答 |
| pages/g04 | 华容道步骤 |
| pages/g05 | 接龙算数 |
| pages/g06 | 围棋数子 |
| pages/g07 | 斗兽棋方向 |
| pages/g08 | 麻将问答 |
| pages/g09 | 九连环步骤 |
| pages/g10 | 数独算数 |
| pages/g11 | 五子棋数子 |
| pages/g12 | 飞行棋方向 |
| pages/g13 | 掷骰子问答 |
| pages/g14 | 鲁班锁步骤 |
| pages/g15 | 猜拳算数 |
| pages/g16 | 跳棋数子 |
| pages/g17 | 抽牌方向 |
| pages/g18 | 翻牌问答 |
| pages/g19 | 孔明锁步骤 |
| pages/g20 | 棋牌游戏记录 |

## 内容集

20 个工具：19 个游戏（数数 4、问答 4、方向 4、步骤 4、算数 3）＋1 个记录工具。数数目标 10/12/8/15，方向每局 6 轮，步骤每局 5 步，算数 7+5、9+4、8+6。

## 跨会话持久化

存储键 `chinaBoardGamesShuuV1`（已选游戏、每游戏最佳、已结算记录、lastError）。

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
- 无传感器时方向游戏可用按钮选方向，传感器失败显示 E7001。
- 20 个游戏名已与全部既有 hub 标题逐个复核，零重名。

## 预览截图

![preview-china-board-games-shuu-index.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-index.png)
![preview-china-board-games-shuu-g01.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g01.png)
![preview-china-board-games-shuu-g02.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g02.png)
![preview-china-board-games-shuu-g03.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g03.png)
![preview-china-board-games-shuu-g04.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g04.png)
![preview-china-board-games-shuu-g05.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g05.png)
![preview-china-board-games-shuu-g06.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g06.png)
![preview-china-board-games-shuu-g07.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g07.png)
![preview-china-board-games-shuu-g08.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g08.png)
![preview-china-board-games-shuu-g09.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g09.png)
![preview-china-board-games-shuu-g10.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g10.png)
![preview-china-board-games-shuu-g11.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g11.png)
![preview-china-board-games-shuu-g12.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g12.png)
![preview-china-board-games-shuu-g13.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g13.png)
![preview-china-board-games-shuu-g14.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g14.png)
![preview-china-board-games-shuu-g15.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g15.png)
![preview-china-board-games-shuu-g16.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g16.png)
![preview-china-board-games-shuu-g17.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g17.png)
![preview-china-board-games-shuu-g18.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g18.png)
![preview-china-board-games-shuu-g19.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g19.png)
![preview-china-board-games-shuu-g20.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g20.png)
![preview-china-board-games-shuu-g01-s2.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g01-s2.png)

## 提审资料

### Feature Description

中国棋牌游戏集：家庭等待时间，全家用一副眼镜玩 20 个棋牌游戏，每个游戏结算计分、成绩跨会话保存。

### Opening Message

棋牌时间到！选个游戏、点头开玩，我帮你记分。

### Preview Media

[preview-china-board-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-board-games-shuu/preview-china-board-games-shuu-video.mp4)
![preview-china-board-games-shuu-index.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-index.png)
![preview-china-board-games-shuu-g01.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g01.png)
![preview-china-board-games-shuu-g02.png](../screenshots/china-board-games-shuu/preview-china-board-games-shuu-g02.png)

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
