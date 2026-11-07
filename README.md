# 月饼守候

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-mooncake-watch
```

[china-mooncake-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-mooncake-watch.aix)

## 功能

中秋烤月饼时，做饼者双手沾面、看向一烤盘、点头登记计时，到时提醒出炉并留记录，多盘不烤糊。

## 场景

中秋烤月饼时，做饼者双手沾面，看向一烤盘、点头登记计时，多盘不烤糊。

## 方向构成

中国在地 × 注意力（多盘计时守候）× 指向性（转头切盘位）。

## 眼镜独占能力

视线与头部方向协调＋双手忙时点头计时：双手沾面时无法掏手机，转头到哪一烤盘就守哪一烤盘，点头即登记。接线：pages/watch/index.ink 的 _startSensor＋_onYaw＋点头触发 primaryTap 登记计时。守候页 onLoad 读存储 selected 定初始点位。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 6 种月饼与建议秒数 |
| pages/watch | 转头切盘位、点头登记计时、到时提醒出炉 |
| pages/record | 出炉记录 |

## 内容集

6 种月饼与建议烤制秒数：广式 1800 秒、苏式 1500 秒、蛋黄 2100 秒、五仁 1800 秒、冰皮 1200 秒、豆沙 1500 秒。

## 跨会话持久化

存储键 `chinaMooncakeWatchV1`（各月饼计时、出炉记录、lastError）。

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
- 到时提醒每盘只说一次，出炉记录只由到时后的登记确认写下。
- 无传感器时按钮切盘位可玩，计时本身不依赖传感器。

## 预览截图

![preview-china-mooncake-watch-index.png](../screenshots/china-mooncake-watch/preview-china-mooncake-watch-index.png)
![preview-china-mooncake-watch-watch.png](../screenshots/china-mooncake-watch/preview-china-mooncake-watch-watch.png)
![preview-china-mooncake-watch-watch-s2.png](../screenshots/china-mooncake-watch/preview-china-mooncake-watch-watch-s2.png)
![preview-china-mooncake-watch-record.png](../screenshots/china-mooncake-watch/preview-china-mooncake-watch-record.png)

## 提审资料

### Feature Description

中秋烤月饼时，做饼者双手沾面、看向一烤盘、点头登记计时，到时提醒出炉并留记录，多盘不烤糊。

### Opening Message

中秋烤月饼时，做饼者双手沾面、看向一烤盘、点头登记计时，到时提醒出炉并留记录，多盘不烤糊。

### Preview Media

[preview-china-mooncake-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-mooncake-watch/preview-china-mooncake-watch-video.mp4)
![preview-china-mooncake-watch-index.png](../screenshots/china-mooncake-watch/preview-china-mooncake-watch-index.png)
![preview-china-mooncake-watch-watch.png](../screenshots/china-mooncake-watch/preview-china-mooncake-watch-watch.png)
![preview-china-mooncake-watch-watch-s2.png](../screenshots/china-mooncake-watch/preview-china-mooncake-watch-watch-s2.png)

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
