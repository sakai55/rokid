# 拉面守候

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-noodle-watch
```

[china-noodle-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-noodle-watch.aix)

## 功能

拉面店做面者双手沾面、看向一口锅、点头登记计时，到时提醒出锅并留记录，多锅不煮过。

## 场景

中国拉面店做面者双手沾面，看向一口锅、点头登记计时，多锅不煮过。

## 方向构成

中国在地 × 注意力（多锅计时守候）× 指向性（转头切锅位）。

## 眼镜独占能力

视线与头部方向协调＋双手忙时点头计时：双手沾面时无法掏手机，看向哪口锅就守哪口锅，点头即登记。接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头触发 primaryTap 登记计时。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 6 种面与建议秒数 |
| pages/watch | 转头切锅位、点头登记计时、到时提醒出锅 |
| pages/record | 出锅记录 |

## 内容集

6 种面与建议煮面秒数：刀削面 180 秒、拉面 150 秒、担担面 120 秒、阳春面 90 秒、炸酱面 210 秒、牛肉面 240 秒。

## 跨会话持久化

存储键 `chinaNoodleWatchV1`（各面计时、出锅记录、lastError）。

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
- 无传感器时按钮切锅位可玩，计时本身不依赖传感器。

## 预览截图

![preview-china-noodle-watch-index.png](../../screenshots/china-noodle-watch/preview-china-noodle-watch-index.png)
![preview-china-noodle-watch-watch.png](../../screenshots/china-noodle-watch/preview-china-noodle-watch-watch.png)
![preview-china-noodle-watch-watch-s2.png](../../screenshots/china-noodle-watch/preview-china-noodle-watch-watch-s2.png)
![preview-china-noodle-watch-record.png](../../screenshots/china-noodle-watch/preview-china-noodle-watch-record.png)

## 提审资料

### Feature Description

拉面店做面者双手沾面、看向一口锅、点头登记计时，到时提醒出锅并留记录，多锅不煮过。

### Opening Message

拉面店做面者双手沾面、看向一口锅、点头登记计时，到时提醒出锅并留记录，多锅不煮过。

### Preview Media

[preview-china-noodle-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-noodle-watch/preview-china-noodle-watch-video.mp4)
![preview-china-noodle-watch-index.png](../../screenshots/china-noodle-watch/preview-china-noodle-watch-index.png)
![preview-china-noodle-watch-watch.png](../../screenshots/china-noodle-watch/preview-china-noodle-watch-watch.png)
![preview-china-noodle-watch-watch-s2.png](../../screenshots/china-noodle-watch/preview-china-noodle-watch-watch-s2.png)

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
