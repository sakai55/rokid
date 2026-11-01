# 高铁站集合

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-rail-meet
```

**AIX 直接下载**（最新版）: [china-rail-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-rail-meet.aix)

DI53 · 中国在地 × 指向性 × 路缘坡。中国高铁站内，年长旅客与家人走散后不用掏手机，凭 GPS 方位距离回到登记的集合点

## 预览截图

![preview-china-rail-meet-index.png](../screenshots/china-rail-meet/preview-china-rail-meet-index.png)
![preview-china-rail-meet-guide.png](../screenshots/china-rail-meet/preview-china-rail-meet-guide.png)
![preview-china-rail-meet-record.png](../screenshots/china-rail-meet/preview-china-rail-meet-record.png)
![preview-china-rail-meet-record-s2.png](../screenshots/china-rail-meet/preview-china-rail-meet-record-s2.png)

## 方向构成

中国在地 × 指向性 × 路缘坡。

## 结构与功能

index/guide/record。

## 内容集计数

集合点 6 处：北京南站·南广场东侧长椅、上海虹桥站·出发层问询处旁长椅、广州南站·东广场集合柱旁、成都东站·西进站口长椅、深圳北站·东广场长椅、武汉站·东进站口长椅；到着记录按实际条数计。跨会话持久化：存储键 `chinaRailMeetV1`。

## 眼镜独占能力

GPS cardinal 锚定：`app.json` 声明 `GEOLOCATION`；`pages/index/index.ink` 的 `saveTap` 与 `pages/guide/index.ink` 的 `primaryTap` 调用 `navigator.geolocation.getCurrentPosition`（存在性守卫，缺失或报错报 E7002，权限被拒报 E7003）；`pages/guide/index.ink` 的 `_calc` 由经纬度差算方位角再换算为 8 方位（北／东北／东／东南／南／西南／西／西北），haversine 距离 10 米取整。方角案内是回到集合点的必经步；未登记时明示“未登记”，不编造位置。

## 权限

`GEOLOCATION` 一个。定位被拒或不可用时如实降级，不编造位置；TTS 与头部传感器不需要清单权限。

## 诚实边界

- 距离是含误差的概算，不是精确步行路线。
- 站内 GPS 信号弱时可能测不出来，测不出会如实说。
- 未登记的地点不做案内；集合点以本人登记为准，站内官方指引优先。

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
| 状态 | 未真机验证 |


## 提审资料

Feature Description: 中国高铁站内走散后的集合助手：登记集合点后凭 GPS 方角与距离走回去，到着可记录，不用掏手机。


Opening Message: 走散了别慌。先登记集合点，再看方角与距离走回去，到了就记一笔。


Preview Media:

- `preview-china-rail-meet-index.png`

- `preview-china-rail-meet-guide.png`

- `preview-china-rail-meet-record.png`


> 正式提审需媒体文件 3–5 个（含视频 ≥1 个、≤60 秒）；视频待 GO 真机录制后补。


Change Log — Build 1.0.0:

- Features added: 初版
- Improvements: 无（初版）
- Fixes: 无（初版）
