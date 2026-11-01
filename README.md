# 厨房守候

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-kitchen-watch
```

**AIX 直接下载**（最新版）: [china-kitchen-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-kitchen-watch.aix)

WA06 · 中国在地 × 注意力 × 指向性。中国家庭厨房做饭者双手忙（切菜、颠勺），看向一口锅、点头登记计时，多锅火候不糊锅

## 预览截图

![preview-china-kitchen-watch-index.png](../screenshots/china-kitchen-watch/preview-china-kitchen-watch-index.png)
![preview-china-kitchen-watch-watch.png](../screenshots/china-kitchen-watch/preview-china-kitchen-watch-watch.png)
![preview-china-kitchen-watch-record.png](../screenshots/china-kitchen-watch/preview-china-kitchen-watch-record.png)
![preview-china-kitchen-watch-watch-s2.png](../screenshots/china-kitchen-watch/preview-china-kitchen-watch-watch-s2.png)

## 方向构成

中国在地 × 注意力 × 指向性。

## 结构与功能

index/watch/record。

## 内容集计数

锅具／菜品 6 组：汤锅·老火靓汤（大火转小火，30 分钟）、炒锅·青椒肉丝（大火快炒，8 分钟）、蒸锅·清蒸鲈鱼（大火蒸，12 分钟）、砂锅·煲仔饭（中小火，25 分钟）、奶锅·热牛奶（小火，5 分钟）、电饭煲·白米饭（自动档，40 分钟）；关火记录按实际条数计。跨会话持久化：存储键 `chinaKitchenWatchV1`。

## 眼镜独占能力

视线与头部方向协调：`pages/watch/index.ink` 的 `_startSensor` 用 `AbsoluteOrientationSensor` 四元数算 yaw，分左／中／右三区切换 3 个计时槽位，传感器缺失或启动失败报 E7001 并退到按键切换（上下键兜底）；点头经 `primaryTap` 登记计时或到时关火，计时是关火提醒必经步——未到时关火记录会被拒绝并报剩余分钟。

## 权限

无清单权限。头部传感器与 TTS 不需要清单权限；本机不用相机、不用定位。

## 诚实边界

- 守候只在本页打开期间按开始时间推算剩余分钟；关掉页面后不会后台提醒。
- 到时判断以目标时长为准，锅里实际火候仍由做饭者自己看一眼确认。
- 头向切换只对登记时站的位置成立，换站位后槽位方向会变。

## 错误码

失败时在眼镜屏上显示裸码，TTS 只读码本身，最近一次错误写入持久化数据的 `lastError`（含码、本机 slug、版本与原文）。本机可能出现的码：

- `E5001` 记录保存失败（存储写入异常）

- `E5002` 记录读取失败（读取／解析异常）

- `E3005` 播报失败（TTS speak 异常）

- `E8001` 页面切换失败（navigateTo／navigateBack 异常）

- `E7001` 朝向传感器不可用（构造／启动失败）


## 设备测试信息

| Studio 名 | 未填写 |
| Version | 1.0.0 |
| App Category | 未填写 |
| Intent Description | 未填写 |
| Agent ID | 未填写 |
| 状态 | 未真机验证 |


## 提审资料

Feature Description: 中国家庭厨房多锅守候：双手忙时看向一口锅、点头登记计时，到时语音提醒关火，多锅不糊。


Opening Message: 菜做到一半别盯表了。看向那口锅、点头登记，到时我叫你关火。


Preview Media:

- `preview-china-kitchen-watch-index.png`

- `preview-china-kitchen-watch-watch.png`

- `preview-china-kitchen-watch-record.png`


> 正式提审需媒体文件 3–5 个（含视频 ≥1 个、≤60 秒）；视频待 GO 真机录制后补。


Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: 无（初版）
- Fixes: 无（初版）
