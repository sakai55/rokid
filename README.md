# 煮粽子守候

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-zongzi-watch
```

[china-zongzi-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-zongzi-watch.aix)

## 功能

中国家庭煮粽子时，做饭者双手沾水、看向一种粽子、点头登记计时，到时提醒出锅并留记录，多锅不煮过。

## 场景

中国家庭煮粽子时，做饭者双手沾水，看向一种粽子、点头登记计时，多锅不煮过。

## 方向构成

中国在地 × 注意力（多锅计时守候）× 指向性（转头切粽子位）。

## 眼镜独占能力

视线与头部方向协调＋双手忙时点头计时：双手沾水时无法掏手机，转头到哪种粽子就守哪种粽子，点头即登记。接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头触发 primaryTap 登记计时。守候页 onLoad 读存储 selected 定初始点位。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 6 种粽子与建议秒数 |
| pages/watch | 转头切粽子位、点头登记计时、到时提醒出锅 |
| pages/record | 出锅记录 |

## 内容集

6 种粽子与建议煮制秒数：鲜肉粽 7200 秒、豆沙粽 5400 秒、蛋黄粽 6600 秒、蜜枣粽 4800 秒、白粽 3600 秒、八宝粽 6000 秒。

## 跨会话持久化

存储键 `chinaZongziWatchV1`（各粽子计时、出锅记录、lastError）。

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

- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切粽子位可玩，计时本身不依赖传感器。

## 预览截图

![preview-china-zongzi-watch-index.png](../screenshots/china-zongzi-watch/preview-china-zongzi-watch-index.png)
![preview-china-zongzi-watch-watch.png](../screenshots/china-zongzi-watch/preview-china-zongzi-watch-watch.png)
![preview-china-zongzi-watch-watch-s2.png](../screenshots/china-zongzi-watch/preview-china-zongzi-watch-watch-s2.png)
![preview-china-zongzi-watch-record.png](../screenshots/china-zongzi-watch/preview-china-zongzi-watch-record.png)

## 提审资料

### Feature Description

中国家庭煮粽子时，做饭者双手沾水、看向一种粽子、点头登记计时，到时提醒出锅并留记录，多锅不煮过。

### Opening Message

中国家庭煮粽子时，做饭者双手沾水、看向一种粽子、点头登记计时，到时提醒出锅并留记录，多锅不煮过。

### Preview Media

[preview-china-zongzi-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-zongzi-watch/preview-china-zongzi-watch-video.mp4)
![preview-china-zongzi-watch-index.png](../screenshots/china-zongzi-watch/preview-china-zongzi-watch-index.png)
![preview-china-zongzi-watch-watch.png](../screenshots/china-zongzi-watch/preview-china-zongzi-watch-watch.png)
![preview-china-zongzi-watch-watch-s2.png](../screenshots/china-zongzi-watch/preview-china-zongzi-watch-watch-s2.png)

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
