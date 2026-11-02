# 春节游戏集

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-festival-game-shuu
```

**AIX 直接下载**（最新版）: [china-festival-game-shuu.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-festival-game-shuu.aix)

GA55 · 中国在地 × 游戏 × 注意力。春节家庭等待时间，全家用眼镜一本玩 20 个春节游戏。

AIX 包大小：61910 B

## 预览截图

![preview-china-festival-game-shuu-index.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-index.png)
![preview-china-festival-game-shuu-g01.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g01.png)
![preview-china-festival-game-shuu-g02.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g02.png)
![preview-china-festival-game-shuu-g03.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g03.png)
![preview-china-festival-game-shuu-g04.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g04.png)
![preview-china-festival-game-shuu-g05.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g05.png)
![preview-china-festival-game-shuu-g06.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g06.png)
![preview-china-festival-game-shuu-g07.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g07.png)
![preview-china-festival-game-shuu-g08.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g08.png)
![preview-china-festival-game-shuu-g09.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g09.png)
![preview-china-festival-game-shuu-g10.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g10.png)
![preview-china-festival-game-shuu-g11.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g11.png)
![preview-china-festival-game-shuu-g12.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g12.png)
![preview-china-festival-game-shuu-g13.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g13.png)
![preview-china-festival-game-shuu-g14.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g14.png)
![preview-china-festival-game-shuu-g15.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g15.png)
![preview-china-festival-game-shuu-g16.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g16.png)
![preview-china-festival-game-shuu-g17.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g17.png)
![preview-china-festival-game-shuu-g18.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g18.png)
![preview-china-festival-game-shuu-g19.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g19.png)
![preview-china-festival-game-shuu-g20.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g20.png)
![preview-china-festival-game-shuu-g01-s2.png](../screenshots/china-festival-game-shuu/preview-china-festival-game-shuu-g01-s2.png)

## 方向构成

中国在地 × 游戏 × 注意力。

## 结构与功能

index 枢纽＋g01–g20 共 21 页。枢纽一次显示 5 个游戏，点头打开选中游戏；每页一种春节小游戏玩法，完成后记入记录并保存该游戏最佳纪录。

## 内容集计数

春节游戏 20 个：贴福字方向、猜灯谜（自撰新谜 4 条）、包饺子计数（目标 10 个）、舞狮节奏（6 拍）、放鞭炮计时、写春联选字（4 题）、剪纸选样、年夜饭菜名问答（4 题）、压岁钱计算（4 题）、拜年顺序（5 步）、灯笼颜色、鞭炮数（目标 12 响）、糖瓜计数（目标 8 块）、门神选、对联配对（4 题）、元宵口味（4 题）、龙灯方向、庙会套圈计数（目标 6 圈）、剪窗花步骤（5 步）、春晚节目问答（4 题）。

跨会话持久化：存储键 `chinaFestivalGameShuuV1`。

## 眼镜独占能力

视线与头部方向协调＋免手持现场闭环：枢纽与各游戏页的 `onHeadGesture('nod')` 等价主确认，点头打开游戏、点头推进；g01 贴福字方向与 g17 龙灯方向的 `_startSensor` 用 `AbsoluteOrientationSensor`（typeof 守卫，yaw 阈值 ±0.35，回正强制）选方向；点头推进是每局游戏的必经步，全家围坐时不用轮流掏手机。

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

Feature Description: 春节家庭等待时间的游戏集：一本眼镜玩 20 个春节小游戏，贴福字、猜灯谜、包饺子计数、舞狮节奏全都有。

Opening Message: 过年等人时别干坐着。打开游戏集，点点头就能玩 20 个春节小游戏，玩完还有最佳纪录。

Preview Media:

- `preview-china-festival-game-shuu-video.mp4`
- `preview-china-festival-game-shuu-index.png`
- `preview-china-festival-game-shuu-g01.png`
- `preview-china-festival-game-shuu-g20.png`

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: 无（初版）
- Fixes: 无（初版）
