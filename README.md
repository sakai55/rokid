# 豆腐菜守候

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-tofu-watch
```

[china-tofu-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-tofu-watch.aix)

## 功能

中国家庭做豆腐菜时做饭者双手忙，看向一锅豆腐菜、点头登记计时，到时提醒出锅，出锅记录跨会话保存。

## 场景

中国家庭做豆腐菜时做饭者双手忙，看向一锅豆腐菜、点头登记计时，多锅不煮老。

## 方向构成

中国在地 × 注意力（守候）× 指向性（转头切锅位）。注意力承载多锅豆腐菜计时守候与到时提醒；指向性承载转头切锅位。

## 眼镜独占能力

视线与头部方向协调：转头切锅位、点头登记计时，不用掏手机。接线：pages/watch/index.ink 的 _startSensor＋_onYaw（回正再武装、左退一种／右进一种）＋ onHeadGesture 点头触发 primaryTap 登记；守候页 onLoad 读存储 selected 定初始锅位；无传感器时按钮切锅位可玩。传感器失败报 E7001。

## 页面

| 页面 | 页面 |
|---|---|
| pages/index | 6 组豆腐菜与建议计时秒数 |
| pages/watch | 看向切锅位、点头登记计时、到时提醒 |
| pages/record | 出锅记录 |

## 内容集

豆腐菜 6 组与家庭计时预设秒数：麻婆豆腐 600 秒、小葱拌豆腐 180 秒、鱼香豆腐 900 秒、豆腐脑 480 秒、家常豆腐 720 秒、豆腐丸子 1200 秒。6 个菜名均为完整菜名；与全部 watch 台的菜名逐一比对，0 逐字重复（“豆腐”仅在 china-hotpot-watch 中以单字食材出现一次，不计为菜名碰撞；china-market-photo / china-night-market 仅为提及）。

## 跨会话持久化

存储键 `chinaTofuWatchV1`（各锅豆腐菜计时、出锅记录、lastError）。

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

## 判定说明

“豆腐”在全仓仅出现于 6 个 .ink 文件：china-hotpot-watch 的 6 味火锅单中以单字食材“豆腐”出现一次，china-market-photo / china-night-market 仅为提及；无 dedicated 豆腐台。本台为 6 道完整豆腐菜（非单字食材），与既有 watch 菜名 0 逐字重复，按协调员裁定建。


## 诚实边界

- 只按时间提醒，不声称测熟度；熟度以现场判断为准。
- 计时秒数为家庭计时预设，不是实测熟度标准。
- 计时未到时点登记只报剩余时间，不写记录。
- 到时提醒每锅只说一次，出锅记录只由到时后的登记确认写下。
- 无传感器时按钮切锅位可玩，计时本身不依赖传感器。

## 预览截图

![preview-china-tofu-watch-index.png](../screenshots/china-tofu-watch/preview-china-tofu-watch-index.png)
![preview-china-tofu-watch-watch.png](../screenshots/china-tofu-watch/preview-china-tofu-watch-watch.png)
![preview-china-tofu-watch-watch-s2.png](../screenshots/china-tofu-watch/preview-china-tofu-watch-watch-s2.png)
![preview-china-tofu-watch-record.png](../screenshots/china-tofu-watch/preview-china-tofu-watch-record.png)


## 提审资料

### Feature Description

中国家庭做豆腐菜时做饭者双手忙，看向一锅豆腐菜、点头登记计时，到时提醒出锅，出锅记录跨会话保存。

### Opening Message

豆腐菜守候开始！看向一锅菜、点头登记计时，到时提醒你出锅。

### Preview Media

[preview-china-tofu-watch-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-tofu-watch/preview-china-tofu-watch-video.mp4)
![preview-china-tofu-watch-index.png](../screenshots/china-tofu-watch/preview-china-tofu-watch-index.png)
![preview-china-tofu-watch-watch.png](../screenshots/china-tofu-watch/preview-china-tofu-watch-watch.png)
![preview-china-tofu-watch-watch-s2.png](../screenshots/china-tofu-watch/preview-china-tofu-watch-watch-s2.png)

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
