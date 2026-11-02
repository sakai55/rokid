# 包饺子守候

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-dumpling-watch
```

**AIX 直接下载**（最新版）: [china-dumpling-watch.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-dumpling-watch.aix)

WA08 · 中国在地 × 注意力 × 指向性。中国家庭包饺子时做饭者双手沾面，看向一口蒸锅、点头登记计时，多锅不蒸过。

AIX 包大小：12013 B

## 预览截图

![preview-china-dumpling-watch-index.png](../screenshots/china-dumpling-watch/preview-china-dumpling-watch-index.png)
![preview-china-dumpling-watch-watch.png](../screenshots/china-dumpling-watch/preview-china-dumpling-watch-watch.png)
![preview-china-dumpling-watch-watch-s2.png](../screenshots/china-dumpling-watch/preview-china-dumpling-watch-watch-s2.png)
![preview-china-dumpling-watch-record-s2.png](../screenshots/china-dumpling-watch/preview-china-dumpling-watch-record-s2.png)

## 方向构成

中国在地 × 注意力 × 指向性。

## 结构与功能

index／watch／record 共 3 页。首页选蒸锅与馅料，守候页看向切槽位、点头登记计时或出锅，记录页看最近 6 条出锅记录。

## 内容集计数

蒸锅／馅料 6 组：大蒸锅·猪肉白菜饺（20 分钟）、中蒸锅·韭菜鸡蛋饺（15 分钟）、小蒸锅·虾仁饺（12 分钟）、电蒸箱·玉米饺（18 分钟）、竹蒸笼·素三鲜饺（15 分钟）、平底锅·煎饺（10 分钟）；守候槽位 3 个；出锅记录按实际条数计。

跨会话持久化：存储键 `chinaDumplingWatchV1`。

## 眼镜独占能力

视线与头部方向协调＋解放双手的第一视角：`pages/watch/index.ink` 的 `_startSensor` 用 `AbsoluteOrientationSensor`（typeof 守卫，缺失走按键兜底）以 yaw 三区切槽位，`onHeadGesture('nod')` 等价主确认，点头登记计时或出锅；计时到时语音提醒是防止蒸过的必经步。双手沾面时不用掏手机。

## 权限

无清单权限。头部传感器与 TTS 不需要清单权限。

## 诚实边界

- 本机只做屏上与语音呈现的流程，不承诺真机之外的能力。
- 失败时只显示裸错误码，不把英文报错原文直接上屏。
- 未登记、未测位、未到时的状态如实显示，不编造结果。

## 错误码

失败时在眼镜屏上显示裸码，TTS 只读码本身，最近一次错误写入持久化数据的 `lastError`（含码、本机 slug、版本与原文）。本机可能出现的码：

- `E5001` 记录保存失败（存储写入异常）
- `E5002` 记录读取失败（读取／解析异常）
- `E3005` 播报失败（TTS speak 异常）
- `E8001` 页面切换失败（navigateTo／navigateBack 异常）
- `E7001` 朝向传感器不可用或报错

## 设备测试信息

| Studio 名 | 未填写 |
| Version | 1.0.0 |
| App Category | 未填写 |
| Intent Description | 未填写 |
| Agent ID | 未填写 |
| 状态 | 未导入 |

## 提审资料

Feature Description: 中国家庭包饺子时的多锅守候：双手沾面时看向蒸锅、点头登记计时，到时语音提醒出锅，多锅不蒸过。

Opening Message: 手上沾着面也别慌。看向那口锅，点一下头就开始计时，到时我会提醒你出锅。

Preview Media:

- `preview-china-dumpling-watch-video.mp4`
- `preview-china-dumpling-watch-index.png`
- `preview-china-dumpling-watch-watch.png`
- `preview-china-dumpling-watch-record-s2.png`

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: 无（初版）
- Fixes: 无（初版）
