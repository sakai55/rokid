# 校门口集合

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-school-meet
```

**AIX 直接下载**（最新版）: [china-school-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-school-meet.aix)

DI56 · 中国在地 × 指向性 × 路缘坡。中国小学放学时，年长家长与孩子在校门口走散后不用掏手机，凭 GPS 方位距离回到登记的集合柱。

AIX 包大小：12261 B

## 预览截图

![preview-china-school-meet-index.png](../screenshots/china-school-meet/preview-china-school-meet-index.png)
![preview-china-school-meet-guide.png](../screenshots/china-school-meet/preview-china-school-meet-guide.png)
![preview-china-school-meet-guide-s2.png](../screenshots/china-school-meet/preview-china-school-meet-guide-s2.png)
![preview-china-school-meet-record-s2.png](../screenshots/china-school-meet/preview-china-school-meet-record-s2.png)

预览说明：预览环境无 GPS，从案内页记的到校记录在预览里显示为通用名“集合点”，真机上记的是已登记集合点的名字。

## 方向构成

中国在地 × 指向性 × 路缘坡。

## 结构与功能

index／guide／record 共 3 页。首页选集合点并登记，方角案内页测位并显示方位距离，到校后记一笔；记录页看最近 6 条。

## 内容集计数

集合点 6 处：东门集合柱、西门长椅、南门传达室旁、北门花坛边、操场入口集合牌、幼儿园门口长椅；8 方位：北／东北／东／东南／南／西南／西／西北；到校记录按实际条数计。

跨会话持久化：存储键 `chinaSchoolMeetV1`。

## 眼镜独占能力

锚定地点的方向（GPS cardinal）：`app.json` 声明 `GEOLOCATION`；`pages/index/index.ink` 的 `saveTap` 调用 `navigator.geolocation.getCurrentPosition` 登记集合点（存在性守卫，缺失报 E7002，被拒报 E7003）；`pages/guide/index.ink` 的 `primaryTap` 再次测位，`_calc` 由经纬度差算方位角再换算为 8 方位，haversine 距离 10 米取整。方角案内是回到集合点的必经步；未登记时明示“未登记”，不编造位置。

## 权限

`GEOLOCATION` 一个。定位被拒或不可用时如实降级，不编造位置；TTS 与头部手势不需要清单权限。

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
- `E7002` 定位失败（GPS 不可用／测位报错）
- `E7003` 定位权限未给（位置利用被拒）

## 设备测试信息

| Studio 名 | 未填写 |
| Version | 1.0.0 |
| App Category | 未填写 |
| Intent Description | 未填写 |
| Agent ID | 未填写 |
| 状态 | 未导入 |

## 提审资料

Feature Description: 中国小学放学时走散后的集合助手：登记校门口集合点后凭 GPS 方角与距离走回去，到校可记录，不用掏手机。

Opening Message: 走散了别慌。先登记集合点，再看方角与距离走回去，到了就记一笔。

Preview Media:

- `preview-china-school-meet-video.mp4`
- `preview-china-school-meet-index.png`
- `preview-china-school-meet-guide.png`
- `preview-china-school-meet-record-s2.png`

Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: 无（初版）
- Fixes: 无（初版）
