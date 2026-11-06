# 寺庙拍照核对 - Agent Notes

DI68. 中国在地 × 指向性（视线拍照核对）× 注意力。

## Design contract

中国寺庙参观者双手拿香与导览册，看向殿区、点头触发拍照核对 12 个拍照点，差一处不算走完。

## Counts

6 处殿区 × 2 个拍照点 = 12 个拍照点（大雄宝殿：正门／佛像前；天王殿：正门／弥勒像前；藏经阁：正门／经架前；钟楼：正门／大钟前；鼓楼：正门／大鼓前；山门：正门／石狮前）。

## Storage

存储键 `chinaTemplePhotoV1`（已选殿区、已打勾拍照点、拍照时间与字节数、走完记录、lastError）。照片本身只在会话内保留，不持久化。

## Gesture map

| 单指点按 | Enter | 主确认 |
| 上滑／下滑 | ArrowUp / ArrowDown | 切换选项 |
| 点头 | onHeadGesture('nod') | 等同主确认 |
| 双击 | Backspace | 返回上一页 |

## Honest boundaries

- 照片只作本人核对，不识别他人正脸，不声称自动识别景点。
- 没拍照不能确认走完，未打勾的拍照点只提醒，不写记录。
- 预览无相机时拍照如实失败，绝不伪造成成功。

## Validation

- 中文纯度：假名与韩文字符数为 0（静态机检）。
- 禁用名单 grep：0 命中。
- 拍照接线：pages/photo/index.ink photoTap（getUserMedia + ImageCapture.takePhoto）；Blob 转 data URL 用 arrayBuffer + 分块 btoa，FileReader = 0。
