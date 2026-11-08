# 颐和园集合点 - Agent Notes

DI73. 中国在地 × 指向性 GPS × 路缘坡（年长游客）。

## Design contract

颐和园里年长游客与家人走散，双手扶栏不用掏手机，凭 GPS 方位距离回到登记的集合亭。

## Counts

集合点 6 处：东宫门、仁寿殿、排云殿、佛香阁、十七孔桥、昆明湖东堤。

## Storage

存储键 `chinaSummerpalaceMeetV1`（已选集合点、已登记集合点、到达记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 距离为估算值，按 10 米取整；屋内或 GPS 弱区如实显示测不到，不编造位置。
- 未登记集合点时不给方位指引。
- 预览无 GPS 时只交 3 张截图，不以无定位状态充数。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- GPS 接线：app.json GEOLOCATION＋getCurrentPosition＋_calc 八方位换算。
