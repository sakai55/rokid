# 西湖集合点

**Studio 导入地址**（复制到 Global AIUI Studio 的 Import Project 输入框）：

```
https://github.com/sakai55/rokid/tree/agent-china-westlake-meet
```

[china-westlake-meet.aix](https://raw.githubusercontent.com/sakai55/rokid/main/aix/china-westlake-meet.aix)

## 功能

西湖边年长游客与家人走散后，不用掏手机：先选集合点并登记定位，再凭八方位与距离走回集合亭，到着后留一条记录。

## 场景

中国杭州西湖边，年长游客与家人在湖边走散后，戴着眼镜、不用掏手机，凭 GPS 方位与距离回到登记的集合亭。

## 方向构成

中国在地 × 指向性（GPS 方位距离）× 路缘坡（年长游客不用掏手机、不用低头看屏）。指向性承担方位距离案内，路缘坡承担免手持、低门槛的登记与到着流程。

## 眼镜独占能力

锚定地点的方向（GPS cardinal 方位＋距离的返程）：登记与指引都在眼前完成，手机做不到在双手扶栏杆、牵着孩子时不掏机走回集合点。接线：app.json 声明 GEOLOCATION；pages/guide/index.ink 的 saveTap 调 navigator.geolocation.getCurrentPosition 登记；同页 primaryTap 再调定位并经 _calc（经纬度差→方位角→八方位换算＋haversine 距离，10 米取整）出方位距离；未登记或定位被拒时明示降级，绝不编造位置。

## 页面

| 页面 | 职责 |
|---|---|
| pages/index | 6 个集合点选点，去指引或看记录 |
| pages/guide | 登记集合点、测方位距离、到着记录 |
| pages/record | 最近 6 条到着记录与合计 |

## 内容集

6 个集合点：断桥、平湖秋月、三潭印月码头、雷峰塔下、曲院风荷东门、苏堤北口。到着记录按实数计。

## 跨会话持久化

存储键 `chinaWestlakeMeetV1`。存所选集合点、已登记集合点名称与经纬度及登记时间、到着记录数组、lastError。

## 权限

`GEOLOCATION`。语音播报不需要清单权限，相机不用。

## 手势映射

| 镜腿手势 | 按键事件 | 本台作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（各页主按钮） |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## 错误码

- `E5001` 存储写入失败
- `E5002` 存储读取失败
- `E3005` 语音播报失败
- `E8001` 页面跳转失败
- `E7002` 定位不可用或定位失败
- `E7003` 定位权限被拒

失败时屏显裸码，lastError 里同时记裸码、slug、版本与原文。

## 预览截图

![preview-china-westlake-meet-index.png](../screenshots/china-westlake-meet/preview-china-westlake-meet-index.png)
![preview-china-westlake-meet-guide.png](../screenshots/china-westlake-meet/preview-china-westlake-meet-guide.png)
![preview-china-westlake-meet-record.png](../screenshots/china-westlake-meet/preview-china-westlake-meet-record.png)

## 提审资料

### Feature Description

西湖边年长游客与家人走散后，不用掏手机：先选集合点并登记定位，再凭八方位与距离走回集合亭，到着后留一条记录。

### Opening Message

西湖边走散了？先选集合点，我帮你用方位和距离带回去，不用掏手机。

### Preview Media

[preview-china-westlake-meet-video.mp4](https://raw.githubusercontent.com/sakai55/rokid/main/screenshots/china-westlake-meet/preview-china-westlake-meet-video.mp4)
![preview-china-westlake-meet-index.png](../screenshots/china-westlake-meet/preview-china-westlake-meet-index.png)
![preview-china-westlake-meet-guide.png](../screenshots/china-westlake-meet/preview-china-westlake-meet-guide.png)
![preview-china-westlake-meet-record.png](../screenshots/china-westlake-meet/preview-china-westlake-meet-record.png)


### Change Log

- Features：首版功能，见上文页面表。
- Improvements：无。
- Fixes：无。

## 设备测试信息

| 项目 | 内容 |
|---|---|
| Studio 名称 | 待填 |
| Version / Build | 待填 |
| App Category | 待填 |
| Intent Description | 待填 |
| Agent ID | 待填 |
| 状态 | 待填 |
