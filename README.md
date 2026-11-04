# 功夫茶守候

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-tea-brew-watch
```

[china-tea-brew-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-tea-brew-watch.aix)

## 功能

功夫茶冲泡时，泡茶者双手拿壶杯、看向一种茶、点头登记计时，到时提醒出汤并留记录。

## 场景

功夫茶冲泡时，泡茶者双手拿壶杯、看向一种茶、点头登记计时，多茶不泡过。

## 方向构成

中国在地 × 注意力（多茶计时守候）× 指向性（转头切茶位）。

## 眼镜独占能力

视线与头部方向协调＋双手忙时点头计时：双手拿壶杯时无法掏手机，转头到哪种茶就守哪种茶，点头即登记。接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头触发 primaryTap 登记计时。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 6 种茶与建议秒数 |
| pages/watch | 转头切茶位、点头登记计时、到时提醒出汤 |
| pages/record | 出汤记录 |

## 内容集

6 种茶与建议冲泡秒数：铁观音 60 秒、普洱 90 秒、龙井 45 秒、大红袍 75 秒、菊花茶 120 秒、白茶 180 秒。

## 跨会话持久化

存储键 `chinaTeaBrewWatchV1`（各茶计时、出汤记录、lastError）。

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
- 到时提醒每茶只说一次，出汤记录只由到时后的登记确认写下。
- 无传感器时按钮切茶位可玩，计时本身不依赖传感器。

## 预览截图

![preview-china-tea-brew-watch-index.png](../screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-index.png)
![preview-china-tea-brew-watch-watch.png](../screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-watch.png)
![preview-china-tea-brew-watch-watch-s2.png](../screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-watch-s2.png)
![preview-china-tea-brew-watch-record.png](../screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-record.png)

## 提审资料

### Feature Description

功夫茶冲泡时，泡茶者双手拿壶杯、看向一种茶、点头登记计时，到时提醒出汤并留记录。

### Opening Message

功夫茶冲泡时，泡茶者双手拿壶杯、看向一种茶、点头登记计时，到时提醒出汤并留记录。

### Preview Media

[preview-china-tea-brew-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-video.mp4)
![preview-china-tea-brew-watch-index.png](../screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-index.png)
![preview-china-tea-brew-watch-watch.png](../screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-watch.png)
![preview-china-tea-brew-watch-watch-s2.png](../screenshots/china-tea-brew-watch/preview-china-tea-brew-watch-watch-s2.png)

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
