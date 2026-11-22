# 唐诗游戏集

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-tang-poetry-games-shuu
```

[china-tang-poetry-games-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-tang-poetry-games-shuu.aix)

## 功能

中国家庭唐诗时间，全家用眼镜玩 20 个唐诗游戏，背诗、认诗、算诗句，计分结算、最佳成绩跨会话保存。

## 场景

中国家庭等待时间，全家用眼镜一本玩 20 个唐诗游戏，背诗、认诗、算诗句，计分结算。

## 方向构成

中国在地 × 游戏 × 指向性（头动方向游戏）× 注意力（最佳成绩守候）。游戏承载玩法循环；指向性承载 4 个方向游戏（g02/g07/g12/g17，6 轮，转头定方位）；注意力承载每局最佳成绩跨会话保存。

## 眼镜独占能力

头部方向协调＋点头主确认：全部游戏页 onHeadGesture('nod') 等同主确认；方向页 g02/g07/g12/g17 用 AbsoluteOrientationSensor 读 yaw，±0.35 触发换区、回中（|yaw|<0.15）再武装；传感器失败报 E7001；无传感器时按钮换区可玩，计分规则不变。接线：各方向页 _startSensor＋_onYaw＋点头 primaryTap。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 唐诗游戏集：20 个游戏与最佳记录 |
| pages/g01 | 静夜思数数 |
| pages/g02 | 春晓方向 |
| pages/g03 | 登鹳雀楼问答 |
| pages/g04 | 悯农步骤 |
| pages/g05 | 咏鹅数数 |
| pages/g06 | 江雪问答 |
| pages/g07 | 望庐山瀑布方向 |
| pages/g08 | 早发白帝城步骤 |
| pages/g09 | 枫桥夜泊数数 |
| pages/g10 | 绝句问答 |
| pages/g11 | 春夜喜雨步骤 |
| pages/g12 | 山居秋暝方向 |
| pages/g13 | 相思数数 |
| pages/g14 | 鹿柴问答 |
| pages/g15 | 送元二使安西步骤 |
| pages/g16 | 黄鹤楼送孟浩然之广陵算数 |
| pages/g17 | 赠汪伦方向 |
| pages/g18 | 望天门山算数 |
| pages/g19 | 凉州词算数 |
| pages/g20 | 出塞记录 |

## 内容集

唐诗 20 首（静夜思、春晓、登鹳雀楼、悯农、咏鹅、江雪、望庐山瀑布、早发白帝城、枫桥夜泊、绝句、春夜喜雨、山居秋暝、相思、鹿柴、送元二使安西、黄鹤楼送孟浩然之广陵、赠汪伦、望天门山、凉州词、出塞；作者与诗文按古诗文网核对，凉州词取王之涣“黄河远上白云间”本）。机制：数数 4（目标字数 20/18/28/20）、方向 4（g02/g07/g12/g17，各 6 轮）、问答 4（作者与诗句实测题）、步骤 4（每首 4 句＋整首背一遍，共 5 步）、算数 3（诗中数字题）、出塞记录 1。20 个游戏名与全部已建 hub 标题（games/＋japan/＋korea/ 共 454 个）及龙舟/民间/春节/中秋/灯会/京剧 6 个 hub 的 121 个标题逐一比对，0 碰撞。

## 跨会话持久化

存储键 `chinaTangPoetryGamesShuuV1`（已选游戏、各游戏最佳成绩、已结算记录、lastError）。

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
- 方向判定为演示判定、非物理识别：点头只比对选定方位与目标方位，不检测真实动作。
- 分段动作：一次转头只换一个方位，须回中再换，绝不转圈。
- 诗文为公共领域唐诗，作者与文本已核对；问答答案均为真实唐诗事实。

## 预览截图

![preview-china-tang-poetry-games-shuu-index.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-index.png)
![preview-china-tang-poetry-games-shuu-g01.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g01.png)
![preview-china-tang-poetry-games-shuu-g02.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g02.png)
![preview-china-tang-poetry-games-shuu-g03.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g03.png)
![preview-china-tang-poetry-games-shuu-g04.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g04.png)
![preview-china-tang-poetry-games-shuu-g05.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g05.png)
![preview-china-tang-poetry-games-shuu-g06.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g06.png)
![preview-china-tang-poetry-games-shuu-g07.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g07.png)
![preview-china-tang-poetry-games-shuu-g08.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g08.png)
![preview-china-tang-poetry-games-shuu-g09.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g09.png)
![preview-china-tang-poetry-games-shuu-g10.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g10.png)
![preview-china-tang-poetry-games-shuu-g11.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g11.png)
![preview-china-tang-poetry-games-shuu-g12.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g12.png)
![preview-china-tang-poetry-games-shuu-g13.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g13.png)
![preview-china-tang-poetry-games-shuu-g14.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g14.png)
![preview-china-tang-poetry-games-shuu-g15.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g15.png)
![preview-china-tang-poetry-games-shuu-g16.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g16.png)
![preview-china-tang-poetry-games-shuu-g17.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g17.png)
![preview-china-tang-poetry-games-shuu-g18.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g18.png)
![preview-china-tang-poetry-games-shuu-g19.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g19.png)
![preview-china-tang-poetry-games-shuu-g20.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g20.png)
![preview-china-tang-poetry-games-shuu-g01-s2.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g01-s2.png)


## 提审资料

### Feature Description

中国家庭唐诗时间，全家用眼镜玩 20 个唐诗游戏：数数、方向、问答、步骤、算数各有机制，点头游玩、计分结算、最佳成绩跨会话保存。

### Opening Message

唐诗时间到！20 个唐诗游戏都在一副眼镜上，点头开玩，背诗比出胜负。

### Preview Media

[preview-china-tang-poetry-games-shuu-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-video.mp4)
![preview-china-tang-poetry-games-shuu-index.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-index.png)
![preview-china-tang-poetry-games-shuu-g01.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g01.png)
![preview-china-tang-poetry-games-shuu-g02.png](../../screenshots/china-tang-poetry-games-shuu/preview-china-tang-poetry-games-shuu-g02.png)

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
