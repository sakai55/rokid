# 西湖集合点 — Agent Notes

DI58。中国组：中国在地 × 指向性 × 路缘坡。

## Design contract

中国杭州西湖边，年长游客与家人在湖边走散后不用掏手机，凭 GPS 方位距离回到登记的集合亭。

## Counts

内容集：6 个集合点（断桥／平湖秋月／三潭印月码头／雷峰塔下／曲院风荷东门／苏堤北口）。到着记录按实数计。

## Storage

存储键 `chinaWestlakeMeetV1`（所选集合点、已登记集合点名称与经纬度及登记时间、到着记录数组、lastError）。

## Gesture map

| 镜腿手势 | 按键事件 | 本台作用 |
|---|---|---|
| 单指点按 | Enter | 主确认（指引页为测位置） |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换集合点 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 未登记时指引页明示尚未登记，绝不编造位置。
- 定位被拒记 E7003，其余定位失败记 E7002；距离为估算值，按 10 米取整。
- 登记的集合点是用户本人的定位，不是查到的地点。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- GPS 三件套：app.json 声明 GEOLOCATION；pages/guide/index.ink 的 saveTap 登记、primaryTap 测位置、_calc 做八方位换算与距离计算。
