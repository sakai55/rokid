# 中国京剧游戏集

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-peking-opera-games-shuu
```

[china-peking-opera-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-peking-opera-games-shuu.aix)

## 功能

中国京剧游戏集：家庭等待时间，全家用一副眼镜玩 20 个京剧游戏，每个游戏结算计分、成绩跨会话保存。

## 场景

中国家庭等待时间，全家用眼镜玩京剧游戏，每个游戏结算计分。

## 方向构成

中国在地 × 游戏 × 指向性 × 注意力。

## 眼镜独占能力

视线与头部方向协调＋点头主确认：方向游戏靠转头选方向、点头确认，不用掏手机。接线：每游戏页 onHeadGesture 点头触发 primaryTap，方向页 g02/g07/g12/g17 的 _startSensor＋_onYaw；命中判定用 ["左", "中", "右"].indexOf 比较。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 20 个游戏总览 |
| pages/g01 | 脸谱数数 |
| pages/g02 | 生角方向 |
| pages/g03 | 京剧问答 |
| pages/g04 | 画脸谱步骤 |
| pages/g05 | 脸谱算数 |
| pages/g06 | 锣鼓数数 |
| pages/g07 | 旦角方向 |
| pages/g08 | 脸谱问答 |
| pages/g09 | 穿行头步骤 |
| pages/g10 | 锣鼓算数 |
| pages/g11 | 行当数数 |
| pages/g12 | 净角方向 |
| pages/g13 | 行当问答 |
| pages/g14 | 开嗓步骤 |
| pages/g15 | 行当算数 |
| pages/g16 | 水袖数数 |
| pages/g17 | 丑角方向 |
| pages/g18 | 锣鼓问答 |
| pages/g19 | 耍水袖步骤 |
| pages/g20 | 京剧记录 |

## 内容集

20 个工具：19 个游戏（数数 4、问答 4、方向 4、步骤 4、算数 3）＋1 个记录工具。数数目标 10/12/8/15，方向每局 6 轮，步骤每局 5 步，算数 7+5、9+4、8+6。

## 跨会话持久化

存储键 `chinaPekingOperaGamesShuuV1`（已选游戏、每游戏最佳、已结算记录、lastError）。

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

![preview-china-peking-opera-games-shuu-index.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-index.png)
![preview-china-peking-opera-games-shuu-g01.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g01.png)
![preview-china-peking-opera-games-shuu-g02.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g02.png)
![preview-china-peking-opera-games-shuu-g03.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g03.png)
![preview-china-peking-opera-games-shuu-g04.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g04.png)
![preview-china-peking-opera-games-shuu-g05.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g05.png)
![preview-china-peking-opera-games-shuu-g06.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g06.png)
![preview-china-peking-opera-games-shuu-g07.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g07.png)
![preview-china-peking-opera-games-shuu-g08.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g08.png)
![preview-china-peking-opera-games-shuu-g09.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g09.png)
![preview-china-peking-opera-games-shuu-g10.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g10.png)
![preview-china-peking-opera-games-shuu-g11.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g11.png)
![preview-china-peking-opera-games-shuu-g12.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g12.png)
![preview-china-peking-opera-games-shuu-g13.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g13.png)
![preview-china-peking-opera-games-shuu-g14.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g14.png)
![preview-china-peking-opera-games-shuu-g15.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g15.png)
![preview-china-peking-opera-games-shuu-g16.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g16.png)
![preview-china-peking-opera-games-shuu-g17.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g17.png)
![preview-china-peking-opera-games-shuu-g18.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g18.png)
![preview-china-peking-opera-games-shuu-g19.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g19.png)
![preview-china-peking-opera-games-shuu-g20.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g20.png)
![preview-china-peking-opera-games-shuu-g01-s2.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g01-s2.png)

## 提审资料

### Feature Description

中国京剧游戏集：家庭等待时间，全家用一副眼镜玩 20 个京剧游戏，每个游戏结算计分、成绩跨会话保存。

### Opening Message

京剧时间到！选个游戏、点头开玩，我帮你记分。

### Preview Media

[preview-china-peking-opera-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-video.mp4)
![preview-china-peking-opera-games-shuu-index.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-index.png)
![preview-china-peking-opera-games-shuu-g01.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g01.png)
![preview-china-peking-opera-games-shuu-g02.png](../../screenshots/china-peking-opera-games-shuu/preview-china-peking-opera-games-shuu-g02.png)

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
