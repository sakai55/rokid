# 丽江集合点 - Agent Notes

DI112. 中国在地 × 指向性 GPS × 路缘坡（古城游客）。

## Design contract

丽江古城游客双手扶栏不用掏手机，凭 GPS 方位距离回到登记的集合点。

## Counts

集合点 6 处：大水车、忠义市场、玉河广场、五一街、三眼井、大石桥。

## Storage

存储键 `chinaLijiangMeetV1`（已选集合点、已登记集合点、到达记录、lastError）。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 距离为估算值，按 10 米取整；屋内或 GPS 弱区如实显示测不到，不编造位置。
- 未登记集合点时不给方位指引。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- GPS 接线：app.json GEOLOCATION＋getCurrentPosition＋_calc 八方位换算（R=6371000，10 米取整）。
- 截图按 3 张交付（guide-s2 须先登记且预览无 GPS 而不可达，不硬造）。
- 判定：同古城的丽江古城拍照核对（directional/china-oldtown-photo）机制不同（GPS 返程集合 vs 拍照逐点核对），按兵马俑／长城 meet＋photo 共存先例建；6 个集合点与该台拍照点无逐字重复（见 README 判定说明）。
